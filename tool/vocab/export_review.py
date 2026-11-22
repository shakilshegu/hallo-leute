"""Exports the word review sheet (docs/word_review.csv) for a German speaker.

Order follows review priority: Pflege pack, IT & Büro pack, the hand-picked
basics, then the most frequent words up to --top (default 500).

    python3 tool/vocab/export_review.py
    python3 tool/vocab/export_review.py --top 200

Open the CSV in Google Sheets (File > Import). The reviewer fills in the
last four columns: Status (OK / Fix / Remove), Correction, Correct level
(A1–B2, only if the Level column is wrong) and Comment.
"""

import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORDS = ROOT / "assets/vocabulary/words.json"
PACKS = ROOT / "assets/vocabulary/packs.json"
OUT = ROOT / "docs/word_review.csv"

PACK_NAMES = {"care": "Pflege pack", "office": "IT & Büro pack"}
HEADER = [
    "#", "Section", "Level", "Article", "Word", "Plural", "Meaning (English)",
    "Example (German)", "Example (English)",
    "Status (OK / Fix / Remove)", "Correction", "Correct level", "Comment",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top", type=int, default=500)
    args = parser.parse_args()

    rows = []
    seen = set()

    def add(section, level, article, word, plural, meaning, example, example_en):
        key = (article, word)
        if key in seen:
            return
        seen.add(key)
        rows.append([len(rows) + 1, section, level.upper(), article, word,
                     plural, meaning, example, example_en, "", "", "", ""])

    packs = json.loads(PACKS.read_text(encoding="utf-8"))["packs"]
    for pack_id, entries in packs.items():
        name = PACK_NAMES.get(pack_id, pack_id)
        for article, word, _pos, meaning, plural, example, example_en in entries:
            add(name, "", article, word, plural, meaning, example, example_en)

    words = json.loads(WORDS.read_text(encoding="utf-8"))["words"]
    basics = [w for w in words if w["rank"] == 0]
    ranked = sorted((w for w in words if w["rank"] > 0), key=lambda w: w["rank"])
    for section, group in (("Basics", basics),
                           (f"Top {args.top}", ranked[: args.top])):
        for w in group:
            add(section, w.get("level", ""), w["article"], w["word"],
                w["plural"], w["meaning"],
                w["example"], w["exampleMeaning"])

    # utf-8-sig so Excel and Google Sheets show umlauts correctly.
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)
    print(f"Wrote {len(rows)} words to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
