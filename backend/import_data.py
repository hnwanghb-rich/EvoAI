"""
批量导入工具 —— 扫描资料目录，全部资料导入知识库
支持：PDF/DOCX/XLSX/MP4/MP3/WAV
"""
import os
import sys
import logging
import asyncio
from pathlib import Path

from database import async_session
from models import (
    KnowledgeEntry, KnowledgeCategory,
    EntryStatusEnum, SourceTypeEnum, ContentTypeEnum, KnowledgeBaseEnum,
)
from routers.upload import _parse_pdf, _parse_docx, _parse_xlsx

logger = logging.getLogger(__name__)

# 资料目录
SOURCE_DIR = os.getenv("IMPORT_SOURCE_DIR", r"D:\合群集团资料")

# 文件类型 → 处理方式 + 知识库映射
EXT_MAP = {
    ".pdf": ("text", "public", _parse_pdf),
    ".docx": ("text", "public", _parse_docx),
    ".xlsx": ("text", "public", _parse_xlsx),
    ".mp4": ("video", "public", None),
    ".mp3": ("audio", "public", None),
    ".wav": ("audio", "public", None),
    ".webm": ("video", "public", None),
    ".jpg": ("image", "public", None),
    ".jpeg": ("image", "public", None),
    ".png": ("image", "public", None),
}


async def batch_import():
    """批量导入主入口：扫描目录 → 逐个处理 → 写入数据库 → 输出统计报告"""
    if not os.path.isdir(SOURCE_DIR):
        logger.warning(f"资料目录不存在: {SOURCE_DIR}")
        return {"total": 0, "success": 0, "skipped": 0, "errors": [], "items": []}

    # 获取默认分类（第一个公共分类）
    default_cat_id = 1
    try:
        async with async_session() as db:
            from sqlalchemy import select
            r = await db.execute(
                select(KnowledgeCategory.id).where(
                    KnowledgeCategory.knowledge_base == "public"
                ).limit(1)
            )
            cat_id = r.scalar_one_or_none()
            if cat_id:
                default_cat_id = cat_id
    except Exception as e:
        logger.warning(f"获取分类失败: {e}")

    stats = {"total": 0, "success": 0, "skipped": 0, "errors": [], "items": []}

    # 遍历文件
    for root, dirs, files in os.walk(SOURCE_DIR):
        for fname in files:
            filepath = os.path.join(root, fname)
            suffix = Path(fname).suffix.lower()
            stats["total"] += 1

            if suffix not in EXT_MAP:
                stats["skipped"] += 1
                stats["errors"].append(f"{fname}: 不支持的文件类型 {suffix}")
                continue

            try:
                ct, kb, parse_fn = EXT_MAP[suffix]
                # 尝试用目录名推断知识库
                dir_name = Path(root).name
                if "销售" in dir_name:
                    kb = "sales"
                elif "技术" in dir_name or "维修" in dir_name:
                    kb = "tech"
                elif "客服" in dir_name or "售后" in dir_name:
                    kb = "service"

                title = Path(fname).stem

                # 文本类：解析并创建条目
                if parse_fn and suffix in (".pdf", ".docx", ".xlsx"):
                    text = parse_fn(filepath)
                    if text and len(text) > 10:
                        # 分段写入（500字一段）
                        chunks = _split_text(text, 500)
                        async with async_session() as db:
                            for i, chunk in enumerate(chunks):
                                ct_title = f"{title}（第{i+1}段）" if len(chunks) > 1 else title
                                entry = KnowledgeEntry(
                                    title=ct_title,
                                    content=chunk,
                                    content_type=ContentTypeEnum.text,
                                    category_id=default_cat_id,
                                    knowledge_base=kb,
                                    source_type=SourceTypeEnum.manual,
                                    source_file_path=filepath,
                                    source_person="系统导入",
                                    tags=f"批量导入,{dir_name}",
                                    status=EntryStatusEnum.approved,
                                )
                                db.add(entry)
                                await db.flush()
                                stats["items"].append({"title": ct_title, "file": fname, "type": "text"})
                            await db.commit()
                        stats["success"] += 1
                    else:
                        stats["skipped"] += 1
                        stats["errors"].append(f"{fname}: 无法提取文本")

                # 视频：创建视频条目
                elif suffix in (".mp4", ".webm"):
                    async with async_session() as db:
                        entry = KnowledgeEntry(
                            title=title,
                            content=f"视频文件：{fname}（位于 {dir_name}）\n\n请注意：视频内容需通过语音转写生成文字版，当前为原始文件记录。",
                            content_type=ContentTypeEnum.video,
                            category_id=default_cat_id,
                            knowledge_base=kb,
                            source_type=SourceTypeEnum.video,
                            source_file_path=filepath,
                            source_person="系统导入",
                            tags=f"批量导入,视频,{dir_name}",
                            status=EntryStatusEnum.approved,
                        )
                        db.add(entry)
                        await db.commit()
                        await db.refresh(entry)
                        stats["items"].append({"title": title, "file": fname, "type": "video"})
                    stats["success"] += 1

                # 音频：创建音频条目
                elif suffix in (".mp3", ".wav"):
                    async with async_session() as db:
                        entry = KnowledgeEntry(
                            title=title,
                            content=f"音频文件：{fname}（位于 {dir_name}）\n\n请注意：音频内容需通过语音转写生成文字版，当前为原始文件记录。",
                            content_type=ContentTypeEnum.audio,
                            category_id=default_cat_id,
                            knowledge_base=kb,
                            source_type=SourceTypeEnum.audio,
                            source_file_path=filepath,
                            source_person="系统导入",
                            tags=f"批量导入,音频,{dir_name}",
                            status=EntryStatusEnum.approved,
                        )
                        db.add(entry)
                        await db.commit()
                        await db.refresh(entry)
                        stats["items"].append({"title": title, "file": fname, "type": "audio"})
                    stats["success"] += 1

                # 图片：创建图片条目
                elif suffix in (".jpg", ".jpeg", ".png"):
                    async with async_session() as db:
                        entry = KnowledgeEntry(
                            title=title,
                            content=f"图片文件：{fname}",
                            content_type=ContentTypeEnum.image,
                            category_id=default_cat_id,
                            knowledge_base=kb,
                            source_type=SourceTypeEnum.manual,
                            source_file_path=filepath,
                            source_person="系统导入",
                            tags=f"批量导入,图片,{dir_name}",
                            status=EntryStatusEnum.approved,
                        )
                        db.add(entry)
                        await db.commit()
                        await db.refresh(entry)
                        stats["items"].append({"title": title, "file": fname, "type": "image"})
                    stats["success"] += 1

            except Exception as e:
                stats["errors"].append(f"{fname}: 导入异常 - {str(e)[:100]}")
                stats["skipped"] += 1
                logger.warning(f"导入失败 {fname}: {e}")

    # 输出报告
    report = (
        f"\n{'='*60}\n"
        f"批量导入完成\n"
        f"{'='*60}\n"
        f"总计: {stats['total']} 个文件\n"
        f"成功: {stats['success']} 个\n"
        f"跳过: {stats['skipped']} 个\n"
        f"错误: {len(stats['errors'])} 个\n"
    )
    if stats['errors']:
        report += "\n错误详情:\n"
        for e in stats['errors'][:20]:
            report += f"  - {e}\n"

    logger.info(report)
    print(report)
    return stats


def _split_text(text: str, max_chars: int = 500) -> list[str]:
    """按句子边界分段，尽量不截断句子"""
    chunks = []
    current = ""
    for char in text:
        current += char
        if len(current) >= max_chars and char in "。！？\n":
            chunks.append(current.strip())
            current = ""
    if current.strip():
        chunks.append(current.strip())
    return chunks or [text[:max_chars]]


# CLI 入口
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    asyncio.run(batch_import())
