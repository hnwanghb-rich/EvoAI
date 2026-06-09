"""
文件上传路由 —— 上传 + 附件解析（PDF/DOCX/XLSX）
"""
import os
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from config import UPLOAD_DIR
from schemas import ApiResponse
from auth import require_admin
from models import User

router = APIRouter()

# 允许的文件类型
ALLOWED_EXT = {".pdf", ".docx", ".xlsx", ".jpg", ".jpeg", ".png", ".mp4", ".mp3", ".wav", ".webm"}


@router.post("/upload/file", response_model=ApiResponse)
async def upload_file(
    file: UploadFile = File(...),
    _admin: User = Depends(require_admin),
):
    """上传文件并解析文本内容（PDF/DOCX/XLSX）"""
    # 1. 校验后缀
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_EXT:
        raise HTTPException(status_code=400, detail=f"不支持的文件类型：{suffix}")

    # 2. 保存文件
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = f"{uuid.uuid4().hex}{suffix}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)

    content = await file.read()
    with open(save_path, "wb") as f:
        f.write(content)

    # 3. 解析文本（PDF/DOCX/XLSX）
    extracted_text = ""
    if suffix == ".pdf":
        extracted_text = _parse_pdf(save_path)
    elif suffix == ".docx":
        extracted_text = _parse_docx(save_path)
    elif suffix == ".xlsx":
        extracted_text = _parse_xlsx(save_path)

    return ApiResponse(data={
        "filename": safe_name,
        "original_name": file.filename,
        "size": len(content),
        "extracted_text": extracted_text,
        "url": f"/uploads/{safe_name}",
    })


def _parse_pdf(path: str) -> str:
    """PDF → 提取文本"""
    try:
        from PyPDF2 import PdfReader
        reader = PdfReader(path)
        parts = []
        for page in reader.pages:
            t = page.extract_text()
            if t:
                parts.append(t)
        return "\n".join(parts)
    except Exception as e:
        return f"[PDF解析失败: {e}]"


def _parse_docx(path: str) -> str:
    """DOCX → 提取文本"""
    try:
        from docx import Document
        doc = Document(path)
        parts = [p.text for p in doc.paragraphs if p.text.strip()]
        return "\n".join(parts)
    except Exception as e:
        return f"[DOCX解析失败: {e}]"


def _parse_xlsx(path: str) -> str:
    """XLSX → 每行模板化为自然语言"""
    try:
        from openpyxl import load_workbook
        wb = load_workbook(path, read_only=True)
        rows_out = []
        for sheet_name in wb.sheetnames:
            ws = wb[sheet_name]
            headers = []
            for i, row in enumerate(ws.iter_rows(values_only=True)):
                if i == 0:
                    headers = [str(h) if h else f"列{j}" for j, h in enumerate(row)]
                    continue
                if any(cell is not None for cell in row):
                    parts = []
                    for j, cell in enumerate(row):
                        if cell is not None and j < len(headers):
                            parts.append(f"{headers[j]}：{cell}")
                    rows_out.append("；".join(parts))
        return "\n".join(rows_out[:500])  # 最多500行
    except Exception as e:
        return f"[XLSX解析失败: {e}]"
