"""CEFR level (A1–B2) for each word in assets/vocabulary/words.json.

Our own assignment, not copied from any official list:

1. Hand-picked essentials (rank 0) are A1.
2. Frequency bands: rank <= 600 A1, <= 1600 A2, <= 2400 B1, else B2.
3. Survival topics (basics, time, people, food, home, travel, health) move
   one level down, never below A1: you need "das Krankenhaus" before you
   meet it often in films.
4. tool/vocab/levels.json overrides win. Keys are "article word" or just
   "word"; values "A1"…"B2". A German reviewer fills these in from the
   Level column of docs/word_review.csv.

    python3 tool/vocab/levels.py --apply    # add "level" to words.json
"""

import argparse
import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORDS = ROOT / "assets/vocabulary/words.json"
OVERRIDES = Path(__file__).resolve().parent / "levels.json"

LEVELS = ["a1", "a2", "b1", "b2"]
BANDS = [(600, "a1"), (1600, "a2"), (2400, "b1")]
SURVIVAL_TOPICS = {"basics", "time", "people", "food", "home", "travel", "health"}


def load_overrides() -> dict:
    if not OVERRIDES.exists():
        return {}
    data = json.loads(OVERRIDES.read_text(encoding="utf-8"))
    return {k: v for k, v in data.items() if not k.startswith("_")}


def level_for(word: dict, overrides: dict) -> str:
    article = word.get("article") or ""
    for key in (f"{article} {word['word']}".strip(), word["word"]):
        if key in overrides:
            return overrides[key].lower()

    rank = word.get("rank", 0)
    if rank == 0:
        return "a1"
    level = next((lvl for limit, lvl in BANDS if rank <= limit), "b2")
    if word.get("topic") in SURVIVAL_TOPICS:
        level = LEVELS[max(0, LEVELS.index(level) - 1)]
    return level


def apply(payload: dict, overrides: dict) -> collections.Counter:
    counts = collections.Counter()
    for w in payload["words"]:
        w["level"] = level_for(w, overrides)
        counts[w["level"]] += 1
    return counts


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                        help="write levels into words.json")
    args = parser.parse_args()
    payload = json.loads(WORDS.read_text(encoding="utf-8"))
    counts = apply(payload, load_overrides())
    print({lvl: counts[lvl] for lvl in LEVELS})
    if args.apply:
        WORDS.write_text(
            json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8")
        print(f"Updated {WORDS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
