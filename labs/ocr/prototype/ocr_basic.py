"""Minimal OCR prototype utilities for labs usage."""
from __future__ import annotations

import io
from typing import Any

from PIL import Image

try:
    import pytesseract
except ModuleNotFoundError as exc:  # pragma: no cover - optional dependency
    raise RuntimeError(
        "pytesseract is required for labs OCR prototype. Install via `uv sync -E labs-ocr`."
    ) from exc


def run_ocr(content: bytes, *, lang: str = "eng", **kwargs: Any) -> str:
    """Run OCR using pytesseract and return extracted text."""
    image = Image.open(io.BytesIO(content))
    return pytesseract.image_to_string(image, lang=lang, **kwargs)
