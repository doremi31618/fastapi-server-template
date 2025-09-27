"""Simple OCR benchmark harness for labs experiments."""
from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Iterable

from labs.ocr.prototype.ocr_basic import run_ocr

ROOT = Path(__file__).resolve().parents[3]
DATA_DIR = ROOT / "labs" / "ocr" / "data"
OUTPUT_DIR = ROOT / "docs" / "system-design" / "benchmarks"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def iter_samples(directory: Path) -> Iterable[Path]:
    for path in sorted(directory.glob("*.png")):
        yield path


def main() -> None:
    results = []
    for sample in iter_samples(DATA_DIR):
        content = sample.read_bytes()
        started = time.perf_counter()
        text = run_ocr(content)
        elapsed = time.perf_counter() - started
        results.append(
            {
                "sample": sample.name,
                "duration_sec": round(elapsed, 4),
                "characters": len(text),
            }
        )
    output = {"model": "pytesseract", "results": results}
    target = OUTPUT_DIR / "ocr-baseline.json"
    target.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(f"Benchmark written to {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
