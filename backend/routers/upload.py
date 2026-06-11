"""File upload + smart import router"""
import os, io, uuid, json, logging, hashlib, base64
from pathlib import Path

import httpx
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import select
from cryptography.fernet import Fernet

from config import UPLOAD_DIR, LLM_ENCRYPTION_KEY
from database import async_session
from models import (
    User, KnowledgeEntry, KnowledgeCategory, DailyQuestion,
    LLMProvider, EntryStatusEnum, SourceTypeEnum, ContentTypeEnum,
)
from schemas import ApiResponse
from auth import require_admin, get_current_user

logger = logging.getLogger(__name__)
router = APIRouter()
ALLOWED_EXT = {".pdf", ".docx", ".xlsx", ".jpg", ".jpeg", ".png", ".mp4", ".mp3", ".wav", ".webm"}

_ocr_engine = None
def _get_ocr():
    global _ocr_engine
    if _ocr_engine is None:
        from rapidocr_onnxruntime import RapidOCR
        _ocr_engine = RapidOCR()
    return _ocr_engine


@router.post("/upload/file", response_model=ApiResponse)
async def upload_file(file: UploadFile = File(...), _admin: User = Depends(require_admin)):
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_EXT:
        raise HTTPException(status_code=400, detail=f"Unsupported type: {suffix}")
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = f"{uuid.uuid4().hex}{suffix}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)
    content = await file.read()
    with open(save_path, "wb") as f: f.write(content)
    text = ""
    if suffix == ".pdf": text = _parse_pdf(save_path)
    elif suffix == ".docx": text = _parse_docx(save_path)
    elif suffix == ".xlsx": text = _parse_xlsx(save_path)
    return ApiResponse(data={"filename": safe_name, "original_name": file.filename, "size": len(content), "extracted_text": text, "url": f"/uploads/{safe_name}"})


@router.post("/upload/smart-import", response_model=ApiResponse)
async def smart_import(
    file: UploadFile = File(...),
    category_id: int = 0,
    knowledge_base: str = "public",
    question_count: int = 10,
    user: User = Depends(require_admin),
):
    steps = []
    result = {"knowledge_id": None, "question_ids": [], "category_matched": None}

    # Step 1: save file
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_EXT:
        raise HTTPException(status_code=400, detail=f"不支持的文件类型：{suffix}")
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = f"{uuid.uuid4().hex}{suffix}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)
    content = await file.read()
    with open(save_path, "wb") as f: f.write(content)
    steps.append({"step": "file_saved", "status": "ok", "detail": f"文件已保存: {safe_name}"})

    # Step 2: extract text
    text = ""
    engine = ""
    if suffix == ".pdf":
        text = _parse_pdf(save_path); engine = "PDF解析"
    elif suffix == ".docx":
        text = _parse_docx(save_path); engine = "DOCX解析"
    elif suffix == ".xlsx":
        text = _parse_xlsx(save_path); engine = "XLSX解析"
    tlen = len(text)
    if tlen < 20:
        steps.append({"step": "text_extract", "status": "fail", "detail": f"{engine}失败：文本过短({tlen}字符)"})
        return ApiResponse(code=400, data={**result, "steps": steps}, msg="text extraction failed")
    steps.append({"step": "text_extract", "status": "ok", "detail": f"{engine}完成，提取 {tlen} 字符"})

    # Step 3: match category
    matched_cat = None
    async with async_session() as db:
        cats = (await db.execute(
            select(KnowledgeCategory).order_by(KnowledgeCategory.knowledge_base, KnowledgeCategory.sort_order)
        )).scalars().all()
        if category_id > 0:
            for c in cats:
                if c.id == category_id:
                    matched_cat = c; break
            if matched_cat:
                steps.append({"step": "category_match", "status": "ok",
                              "detail": f"指定分类: {matched_cat.icon} {matched_cat.name}"})
            else:
                steps.append({"step": "category_match", "status": "skip",
                              "detail": "指定分类无效，跳过入库和拆题"})
                return ApiResponse(code=200, data={**result, "steps": steps, "extracted_text": text},
                                   msg="分类无效，未执行后续操作")
        else:
            # auto match by keyword scoring
            best, best_score = None, 0
            for c in cats:
                sc = 0
                if c.name in text: sc += 10
                for ch in c.name:
                    if ch in text: sc += 1
                if sc > best_score: best, best_score = c, sc
            if best and best_score >= 3:
                matched_cat = best
                steps.append({"step": "category_match", "status": "ok",
                              "detail": f"自动匹配: {best.icon} {best.name} (得分{best_score})"})
            else:
                steps.append({"step": "category_match", "status": "skip",
                              "detail": f"自动匹配失败(最高得分{best_score})，未执行入库和拆题"})
                return ApiResponse(code=200, data={**result, "steps": steps, "extracted_text": text},
                                   msg="分类匹配度不足，未执行入库和拆题")

    result["category_matched"] = {"id": matched_cat.id, "name": matched_cat.name, "knowledge_base": matched_cat.knowledge_base.value}

    # Step 4: knowledge entry
    try:
        async with async_session() as db:
            ke = KnowledgeEntry(
                title=Path(file.filename).stem, content=text[:10000],
                content_type=ContentTypeEnum.text, category_id=matched_cat.id,
                knowledge_base=matched_cat.knowledge_base.value,
                source_type=SourceTypeEnum.manual, source_file_path=save_path,
                source_person=user.real_name, status=EntryStatusEnum.approved,
                tags=f"批量导入,{matched_cat.name}",
            )
            db.add(ke); await db.commit(); await db.refresh(ke)
            result["knowledge_id"] = ke.id
            steps.append({"step": "knowledge_saved", "status": "ok",
                          "detail": f"知识已入库: ID={ke.id} ({ke.title})"})
    except Exception as e:
        steps.append({"step": "knowledge_saved", "status": "fail", "detail": f"知识入库失败: {e}"})

    # Step 5: AI question generation (return drafts, don't auto-insert)
    tpos = ""
    if matched_cat.knowledge_base.value in ("sales", "tech", "service"):
        tpos = matched_cat.knowledge_base.value
    drafts = []
    if question_count > 0:
        try:
            drafts = await _ai_gen(text, tpos, question_count)
            if drafts:
                # 补充每个草稿的默认字段
                for d in drafts:
                    if "question_type" not in d: d["question_type"] = "single_choice"
                    if "difficulty_level" not in d: d["difficulty_level"] = 2
                    if "options" not in d or not isinstance(d.get("options"), dict):
                        d["options"] = {"A":"","B":"","C":"","D":""}
                steps.append({"step": "ai_questions", "status": "ok",
                              "detail": f"AI拆解完成，生成 {len(drafts)} 道题目草稿（待人工复核）"})
            else:
                steps.append({"step": "ai_questions", "status": "fail", "detail": "AI出题失败(LLM未配置或生成失败)"})
        except Exception as e:
            steps.append({"step": "ai_questions", "status": "fail", "detail": f"AI出题异常: {e}"})

    return ApiResponse(data={**result, "steps": steps, "extracted_text": text, "text_length": tlen, "drafts": drafts},
                       msg=f"智能导入完成: 知识已入库+{len(drafts)}道题目草稿待复核")


async def _ai_gen(text: str, target: str, count: int) -> list:
    async with async_session() as db:
        llm = (await db.execute(
            select(LLMProvider).where(LLMProvider.is_active == True, LLMProvider.is_default == True)
        )).scalar_one_or_none()
    if not llm or not llm.api_key: return []
    key = LLM_ENCRYPTION_KEY.encode()
    digest = hashlib.sha256(key).digest()
    b64 = base64.urlsafe_b64encode(digest)
    api_key = Fernet(b64).decrypt(llm.api_key.encode()).decode()
    pos_label = {"sales":"销售","tech":"技术","service":"客服"}.get(target,"通用")
    prompt = f"你是合群汽车集团出题专家。阅读以下文档，生成{count}道考题。目标岗位：{pos_label}。\n文档：\n{text[:8000]}\n\n输出JSON数组，每题格式：{{\"question_type\":\"single_choice\",\"question_content\":\"题干\",\"options\":{{\"A\":\"A\",\"B\":\"B\",\"C\":\"C\",\"D\":\"D\"}},\"answer\":\"A\",\"explanation\":\"解析\",\"difficulty_level\":2}}。只输出JSON数组。"
    try:
        async with httpx.AsyncClient(timeout=60) as c:
            resp = await c.post(f"{llm.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={"model": llm.model_name, "messages": [
                    {"role":"system","content":"你是出题助手，只输出JSON数组。"},
                    {"role":"user","content":prompt},
                ], "temperature":0.8, "max_tokens":8192})
            resp.raise_for_status()
            t = resp.json()["choices"][0]["message"]["content"].strip()
            if t.startswith("```"): t = t.split("\n",1)[1].rsplit("\n```",1)[0]
            if t.startswith("```json"): t = t.split("\n",1)[1].rsplit("\n```",1)[0]
            return json.loads(t)
    except Exception as e:
        logger.warning(f"AI出题失败: {e}")
        return []


# === Parsers ===

def _parse_pdf(path: str) -> str:
    text = ""; tried = []
    try:
        from PyPDF2 import PdfReader
        reader = PdfReader(path); tried.append("PyPDF2")
        if reader.is_encrypted: return "[PDF已加密]"
        for page in reader.pages:
            t = page.extract_text()
            if t and t.strip(): text += t + "\n"
        if text.strip(): return text.strip()
    except Exception: pass
    try:
        import pdfplumber; tried.append("pdfplumber")
        with pdfplumber.open(path) as pdf:
            for p in pdf.pages:
                t = p.extract_text()
                if t and t.strip(): text += t + "\n"
        if text.strip(): return text.strip()
    except Exception: pass
    try:
        tried.append("RapidOCR")
        ocr = _rapidocr_pdf(path)
        if ocr.strip(): return ocr.strip()
    except Exception: pass
    return f"[识别失败] 已尝试{'、'.join(tried)}均未获得文字。文件已保存。"


def _rapidocr_pdf(path: str) -> str:
    import numpy as np
    from PyPDF2 import PdfReader
    from PIL import Image
    ocr = _get_ocr(); reader = PdfReader(path); all_texts = []
    for pi, page in enumerate(reader.pages):
        img_arr = None
        try:
            resources = page["/Resources"]
            if "/XObject" in resources:
                for key in resources["/XObject"]:
                    try:
                        obj = resources["/XObject"][key]
                        if obj["/Subtype"] == "/Image":
                            raw = obj.get_data()
                            img = Image.open(io.BytesIO(raw))
                            if img.mode != "RGB": img = img.convert("RGB")
                            img_arr = np.array(img); break
                    except Exception: continue
        except Exception: continue
        if img_arr is None: continue
        try:
            result, _ = ocr(img_arr)
            if result:
                lines = []
                for item in result:
                    txt = item[1]
                    try: conf = float(item[2])
                    except: conf = 0.0
                    if txt and conf > 0.3: lines.append(txt)
                pt = " ".join(lines).strip()
                if pt: all_texts.append(f"--- 第{pi+1}页 ---\n{pt}")
        except Exception: pass
    return "\n\n".join(all_texts)


def _parse_docx(path: str) -> str:
    try:
        from docx import Document
        return "\n".join(p.text for p in Document(path).paragraphs if p.text.strip())
    except Exception as e: return f"[DOCX错误:{e}]"


def _parse_xlsx(path: str) -> str:
    try:
        from openpyxl import load_workbook
        wb = load_workbook(path, read_only=True)
        rows = []
        for sn in wb.sheetnames:
            ws = wb[sn]; headers = []
            for i, row in enumerate(ws.iter_rows(values_only=True)):
                if i == 0: headers = [str(h) if h else f"C{j}" for j, h in enumerate(row)]
                elif any(c is not None for c in row):
                    parts = [f"{headers[j]}:{cell}" for j, cell in enumerate(row) if cell is not None and j < len(headers)]
                    rows.append(";".join(parts))
        return "\n".join(rows[:500])
    except Exception as e: return f"[XLSX错误:{e}]"
