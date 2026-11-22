#!/usr/bin/env python3
"""Build assets/vocabulary/words.json from open datasets.

Pipeline (runs on a developer machine, never in the app):
  1. FrequencyWords (German subtitles, CC BY-SA 4.0) -> which words matter most.
  2. English Wiktionary via kaikki.org/wiktextract (CC BY-SA 4.0 / GFDL)
     -> lemma, part of speech, der/die/das, plural, English meaning, topic.
  3. Tatoeba (CC BY 2.0 FR) -> a short German example + English translation.
  4. tool/vocab/curated.json -> hand-picked essentials, always included.

Usage:
  python3 tool/vocab/build_vocab.py            # downloads into tool/vocab/.cache
  python3 tool/vocab/build_vocab.py --size 3000

Only the small JSON output is committed; the ~1 GB cache is git-ignored.
"""

from __future__ import annotations

import argparse
import bz2
import json
import re
import sys
import urllib.request
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import levels  # noqa: E402  (CEFR levels, see levels.py)

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path(__file__).resolve().parent / ".cache"
OUT = ROOT / "assets" / "vocabulary" / "words.json"
CURATED = Path(__file__).resolve().parent / "curated.json"

SOURCES = {
    "de_50k.txt": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/de/de_50k.txt",
    "kaikki-german.jsonl": "https://kaikki.org/dictionary/German/kaikki.org-dictionary-German.jsonl",
    "deu_sentences.tsv.bz2": "https://downloads.tatoeba.org/exports/per_language/deu/deu_sentences.tsv.bz2",
    "eng_sentences.tsv.bz2": "https://downloads.tatoeba.org/exports/per_language/eng/eng_sentences.tsv.bz2",
    "deu-eng_links.tsv.bz2": "https://downloads.tatoeba.org/exports/per_language/deu/deu-eng_links.tsv.bz2",
}

# Parts of speech worth teaching. Articles are shown with nouns instead.
KEEP_POS = {"noun", "verb", "adj", "adv", "prep", "conj", "pron", "intj", "num", "det", "particle"}

# Senses with any of these tags are never shown to learners.
BAD_TAGS = {
    "vulgar", "offensive", "derogatory", "slur", "ethnic", "pejorative",
    "obsolete", "archaic", "dated", "historical", "rare", "poetic",
    "dialectal", "nonstandard", "misspelling", "alt-of", "abbreviation",
    "form-of", "Internet", "slang", "euphemistic", "humorous", "childish",
}
# Extra safety net for words that slip through the tags.
BLOCKLIST = {
    "scheiße", "scheisse", "arsch", "arschloch", "fick", "ficken", "verdammt",
    "verdammte", "hure", "schlampe", "wichser", "fotze", "schwanz", "titten",
    "nutte", "bastard", "mist", "kacke", "pisse", "idiot", "drogen", "töten",
    "mord", "mörder", "leiche", "waffe", "pistole", "gott", "jesus", "sex",
    "sexy", "nackt", "schwul", "blut", "erschießen", "umbringen", "hölle",
    "teufel", "verflucht", "dämon", "amen", "christus", "herrgott", "heilig", "köpfen",
    "heiliger", "töte", "tötet",
}

GENDER = {"masculine": "der", "feminine": "die", "neuter": "das"}

# Wiktionary category keywords -> app topic. First match wins.
TOPIC_RULES = [
    ("food", ["food", "beverage", "drink", "fruit", "vegetable", "meal", "meat",
              "dairy", "cooking", "baked goods", "spice", "sweets", "cuisine"]),
    ("health", ["medicine", "anatomy", "body", "disease", "health", "pharmac",
                "illness", "injur"]),
    ("travel", ["transport", "vehicle", "travel", "rail", "aviation", "road",
                "automotive", "tourism", "nautical", "ship"]),
    ("home", ["building", "housing", "room", "furniture", "household",
              "kitchen", "home", "architecture"]),
    ("work", ["occupation", "business", "econom", "money", "finance", "office",
              "employment", "trade", "commerce", "computing", "law", "school",
              "education"]),
    ("people", ["family", "people", "kinship", "relatives", "person", "male",
                "female", "children"]),
    ("time", ["time", "days of the week", "months", "seasons", "calendar",
              "chronology"]),
    ("nature", ["weather", "animal", "plant", "mammal", "bird", "tree",
                "flower", "nature", "geography", "colors", "colours",
                "landforms"]),
]
FUNCTION_POS = {"pron", "prep", "conj", "intj", "det", "particle", "num"}

WORD_RE = re.compile(r"[A-Za-zÄÖÜäöüß]+")


def fetch(name: str) -> Path:
    path = CACHE / name
    if path.exists():
        return path
    CACHE.mkdir(parents=True, exist_ok=True)
    url = SOURCES[name]
    print(f"  downloading {url}", file=sys.stderr)
    tmp = path.with_suffix(path.suffix + ".part")
    urllib.request.urlretrieve(url, tmp)
    tmp.rename(path)
    return path


# ─────────────────────────── 1. frequency ───────────────────────────

def load_frequency(limit: int = 50000) -> dict[str, int]:
    freq: dict[str, int] = {}
    with open(fetch("de_50k.txt"), encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) == 2 and WORD_RE.fullmatch(parts[0]):
                freq[parts[0].lower()] = int(parts[1])
            if len(freq) >= limit:
                break
    return freq


# ─────────────────────────── 2. Wiktionary ───────────────────────────

CRUDE = re.compile(r"\b(horny|sex|sexy|sexual|suicide|corpse|fuck\w*|shit\w*|ass|arse|bitch\w*|dick|"
                   r"piss\w*|crap|bastard|whore|slut|cock|tits?|penis|vagina|"
                   r"behead\w*|kill\w*|murder\w*|rape\w*|nazi\w*|shut up|damn\w*|hell|genus|species|taxonomic)\b", re.I)
CRUDE_DE = re.compile(r"(fresse|verpiss|wayne|versaut|umgebracht|umgelegt|getötet|töte|bring\w* sich um|brachte sich|leiche|scheiß|arsch|verdammt)", re.I)

NOTE_PREFIXES = (
    "used ", "forms ", "denotes", "referring", "nominalization", "alternative",
    "[", "accusative", "dative", "genitive", "nominative", "inflection",
    "superlative", "comparative", "plural of", "indicates", "expresses",
    "introduces", "a person or animal of male gender", "the letter",
    "translated", "links ", "often ", "with ", "in ", "of ",
)


def clean_gloss(gloss: str) -> str:
    # Drop (possibly nested) parentheticals and bracketed notes.
    prev = None
    while prev != gloss:
        prev = gloss
        gloss = re.sub(r"\s*\([^()]*\)", "", gloss)
    gloss = re.sub(r"\s*\[[^\]]*\]", "", gloss)
    gloss = gloss.replace("(", "").replace(")", "")
    gloss = re.sub(r"\s+", " ", gloss).strip(" ;,.:")
    if not gloss or gloss.lower().startswith(NOTE_PREFIXES) or CRUDE.search(gloss):
        return ""
    parts = [p.strip() for p in gloss.split(",") if p.strip()]
    return ", ".join(parts[:2])


GLOSS_RULES = [
    ("food", "food eat eating drink bread meat fruit vegetable coffee tea beer wine milk "
             "cheese cake soup breakfast lunch dinner meal cook cooking restaurant sugar "
             "salt egg apple potato chocolate hungry thirsty taste delicious butter rice"),
    ("health", "doctor hospital medicine medication ill illness sick pain ache health body "
               "head heart blood injury wound nurse pharmacy fever tooth teeth eye ear hand "
               "arm leg foot stomach patient cancer disease"),
    ("travel", "train car bus station airport plane aeroplane airplane flight ticket street "
               "road travel trip journey drive driver ship boat map city town village "
               "country hotel bridge border passport bicycle tram taxi"),
    ("home", "house home apartment flat room kitchen bed door window table chair key "
             "garden wall floor roof bathroom shower furniture rent neighbour neighbor sofa"),
    ("work", "work job office boss colleague company business money pay salary meeting "
             "contract school teacher student university study learn lesson exam computer "
             "telephone phone email letter bank price buy sell shop customer law court"),
    ("people", "man woman child children boy girl mother father brother sister son "
               "daughter family friend wife husband parents baby people person guy lady "
               "grandmother grandfather uncle aunt cousin mum mom dad"),
    ("time", "time day week month year hour minute second morning evening night today "
             "tomorrow yesterday soon later always never early late monday tuesday "
             "wednesday thursday friday saturday sunday january february march april may "
             "june july august september october november december spring summer autumn "
             "winter clock birthday moment weekend"),
    ("nature", "weather sun rain snow wind sky sea lake river mountain forest tree flower "
               "animal dog cat horse bird fish earth cold warm hot colour color red blue "
               "green black white yellow nature fire star moon"),
]
GLOSS_INDEX = {w: t for t, words in GLOSS_RULES for w in words.split()}


def topic_for(categories: list[str], pos: str, meaning: str) -> str:
    text = " | ".join(categories).lower()
    for topic, keys in TOPIC_RULES:
        if any(re.search(r"\b" + re.escape(k), text) for k in keys):
            return topic
    if pos in FUNCTION_POS:
        return "basics"
    first = re.split(r"[;,]", meaning)[0].lower()
    for tok in re.findall(r"[a-z]+", first):
        if tok in GLOSS_INDEX and tok not in {"the", "a", "to"}:
            return GLOSS_INDEX[tok]
    return "everyday"


def load_wiktionary(wanted: set[str]):
    """Return lemma entries and form->lemma links for words in `wanted`."""
    lemmas: dict[tuple[str, str], dict] = {}
    form_links: dict[str, set[tuple[str, str]]] = defaultdict(set)

    with open(fetch("kaikki-german.jsonl"), encoding="utf-8") as f:
        for n, line in enumerate(f):
            if n % 200000 == 0:
                print(f"  wiktionary: {n:,} entries scanned", file=sys.stderr)
            e = json.loads(line)
            word, pos = e.get("word", ""), e.get("pos", "")
            low = word.lower()
            if low not in wanted or pos not in KEEP_POS:
                continue
            if not WORD_RE.fullmatch(word):
                continue

            good, cats, gender, examples = [], [], None, []
            for s in e.get("senses", []):
                tags = set(s.get("tags", []))
                for fo in s.get("form_of", []) or []:
                    if fo.get("word"):
                        form_links[low].add((fo["word"], pos))
                if s.get("form_of") or tags & BAD_TAGS or not s.get("glosses"):
                    continue
                gloss = clean_gloss(s["glosses"][-1])
                if not gloss or len(gloss) > 60:
                    continue
                good.append(gloss)
                if len(good) <= 2:  # topic comes from the main senses
                    cats += [c.get("name", "") for c in s.get("categories", []) or []
                             if c.get("langcode") == "de"]
                    cats += s.get("topics", []) or []
                if gender is None:
                    gender = next((GENDER[t] for t in s.get("tags", []) if t in GENDER), None)
                for ex in s.get("examples", []) or []:
                    text, en = ex.get("text", ""), ex.get("english", "")
                    if (text and en and len(text) <= 70 and len(en) <= 80
                            and ex.get("bold_text_offsets")
                            and not CRUDE.search(en) and not CRUDE_DE.search(text)):
                        examples.append((text, en))

            if not good:
                continue
            if pos == "noun" and gender is None:
                continue
            plural = ""
            if pos == "noun":
                plural = next((fm["form"] for fm in e.get("forms", [])
                               if fm.get("tags") == ["plural"]), "")
            forms = {fm["form"] for fm in e.get("forms", [])
                     if WORD_RE.fullmatch(fm.get("form", ""))}

            key = (word, pos)
            if key in lemmas:  # same lemma split over several etymologies
                lemmas[key]["glosses"] += good
                lemmas[key]["examples"] += examples
                lemmas[key]["categories"] += cats
                continue
            lemmas[key] = {
                "word": word, "pos": pos,
                "article": (gender or "") if pos == "noun" else "",
                "plural": plural if plural != "-" else "",
                "glosses": good, "categories": cats, "examples": examples,
                "forms": forms,
            }
    return lemmas, form_links


def rank_lemmas(freq, lemmas, form_links):
    """Score each lemma by the frequency of all its forms."""
    by_low = defaultdict(list)
    for key in lemmas:
        by_low[key[0].lower()].append(key)

    score: dict[tuple[str, str], int] = defaultdict(int)
    for form, count in freq.items():
        targets = set(by_low.get(form, []))
        if not targets:  # "bin" -> sein, "Häuser" -> Haus
            targets = {(w, p) for (w, p) in form_links.get(form, ()) if (w, p) in lemmas}
        for t in targets:
            score[t] += count
    return sorted(score, key=lambda k: -score[k]), score


# ─────────────────────────── 3. Tatoeba ───────────────────────────

def load_tatoeba():
    print("  tatoeba: reading links", file=sys.stderr)
    links = defaultdict(list)
    with bz2.open(fetch("deu-eng_links.tsv.bz2"), "rt", encoding="utf-8") as f:
        for line in f:
            de, en = line.rstrip("\n").split("\t")[:2]
            links[int(de)].append(int(en))
    en_needed = {e for ids in links.values() for e in ids}

    print("  tatoeba: reading English sentences", file=sys.stderr)
    english = {}
    with bz2.open(fetch("eng_sentences.tsv.bz2"), "rt", encoding="utf-8") as f:
        for line in f:
            sid, _, text = line.rstrip("\n").split("\t", 2)
            if int(sid) in en_needed:
                english[int(sid)] = text

    print("  tatoeba: indexing German sentences", file=sys.stderr)
    sentences = {}
    index = defaultdict(list)
    with bz2.open(fetch("deu_sentences.tsv.bz2"), "rt", encoding="utf-8") as f:
        for line in f:
            sid, _, text = line.rstrip("\n").split("\t", 2)
            sid = int(sid)
            ens = [english[e] for e in links.get(sid, []) if e in english]
            if not ens:
                continue
            tokens = WORD_RE.findall(text)
            if not 3 <= len(tokens) <= 9 or len(text) > 60:
                continue
            en_best = min(ens, key=len)
            if CRUDE.search(en_best) or CRUDE_DE.search(text) or any(q in text for q in '„“"«»'):
                continue
            sentences[sid] = (text, en_best, tokens)
            for tok in set(tokens):
                index[tok].append(sid)
    return sentences, index


AUX = {"haben", "habe", "hast", "hat", "habt", "hatte", "hätte", "sein", "bin",
       "bist", "ist", "sind", "seid", "war", "wäre", "werden", "werde", "wirst",
       "wird", "wurde", "würde", "zu", "sich"}


def search_tokens(entry) -> set[str]:
    word, pos = entry["word"], entry["pos"]
    if pos == "noun":
        return {word} | ({entry["plural"]} if entry["plural"] else set())
    tokens = {word, word.capitalize()}
    if pos in {"verb", "adj", "adv"}:
        stem = word[:-2] if pos == "verb" and word.endswith("en") else word
        prefix = stem[:3].lower()
        for f in entry["forms"]:
            fl = f.lower()
            if fl in AUX or not f.islower():
                continue
            # Real inflections share the stem (singt, gesungen ~ sing-).
            if fl.startswith(prefix) or fl[2:].startswith(prefix) or fl.startswith(stem[:2].lower()):
                tokens |= {f, f.capitalize()}
    return tokens


def pick_example(entry, sentences, index, known: set[str]):
    search = search_tokens(entry)
    candidates = {sid for tok in search for sid in index.get(tok, [])}
    noun = entry["pos"] == "noun"
    best, best_score = None, None
    for sid in candidates:
        text, en, tokens = sentences[sid]
        hits = [i for i, t in enumerate(tokens) if t in search]
        # A capitalised verb/adjective form mid-sentence is a different noun.
        if not noun and not any(i == 0 or tokens[i].islower() for i in hits):
            continue
        easy = sum(t.lower() in known for t in tokens) / len(tokens)
        exact = any(t.lower() == entry["word"].lower() for t in tokens)
        score = (
            not exact,
            -round(easy, 1),
            abs(len(tokens) - 6) // 2,
            text.endswith("!"),
            len(text),
        )
        if best_score is None or score < best_score:
            best, best_score = (text, en), score
    if best:
        return best
    if entry["examples"]:
        return min(entry["examples"], key=lambda x: len(x[0]))
    return ("", "")


# ─────────────────────────── main ───────────────────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=3000)
    args = ap.parse_args()

    curated = json.loads(CURATED.read_text(encoding="utf-8"))
    print("1/4 frequency list", file=sys.stderr)
    freq = load_frequency()
    wanted = set(freq) | {c["word"].lower() for c in curated}

    print("2/4 Wiktionary (this takes a few minutes)", file=sys.stderr)
    lemmas, form_links = load_wiktionary(wanted)
    ranked, scores = rank_lemmas(freq, lemmas, form_links)

    # Same spelling, different word class: pick the most useful class.
    pos_priority = ["pron", "det", "prep", "conj", "verb", "adv", "intj", "adj",
                    "noun", "num", "particle"]
    pos_override = {"ob": "conj", "hier": "adv", "ja": "intj", "nein": "intj",
                    "trotzdem": "adv", "zu": "prep", "also": "adv", "doch": "adv",
                    "da": "adv", "dann": "adv", "noch": "adv", "schon": "adv"}
    function_low = {w.lower() for (w, p) in lemmas if p in FUNCTION_POS | {"adv"}}
    verbadj_low = {w.lower() for (w, p) in lemmas if p in {"verb", "adj"}}
    keep_nouns = {"Morgen", "Leben", "Essen", "Recht", "Abend", "Wissen", "Gefühl"}

    def acceptable(key):
        word, pos = key
        if pos != "noun" or word in keep_nouns:
            return True
        low = word.lower()
        glosses = " ".join(lemmas[key]["glosses"]).lower()
        if "nominalization" in glosses:
            return False
        # "das Ich", "der Er", "das Ja": nouns made from function words.
        if low in function_low:
            return False
        # "der Armer": an inflected adjective listed as a noun.
        if any(p == "adj" for (_, p) in form_links.get(low, ())):
            return False
        # "das Haben", "die Gute": nouns made from verbs/adjectives.
        return low not in verbadj_low

    score_order = {k: i for i, k in enumerate(ranked)}
    ranked = [k for k in ranked if acceptable(k)]
    best_for_word: dict[str, tuple[str, str]] = {}
    for key in ranked:
        low = key[0]  # exact spelling: "sie" (she) and "Sie" (you) both stay
        cur = best_for_word.get(low)
        if low.lower() in pos_override:
            if key[1] == pos_override[low.lower()]:
                best_for_word[low] = key
            elif cur is None:
                best_for_word[low] = key
            continue
        if cur is None:
            best_for_word[low] = key
        elif scores[key] >= 0.8 * scores[cur]:
            # Near-tie: the more basic word class wins (zu = "to", not "shut").
            if pos_priority.index(key[1]) < pos_priority.index(cur[1]):
                best_for_word[low] = key
    ranked = sorted(set(best_for_word.values()), key=lambda k: score_order[k])

    chosen, seen = [], set()
    for key in ranked:
        word = key[0]
        if word.lower() in BLOCKLIST or word.lower() in {
            "der", "die", "das", "ein", "eine", "den", "dem", "des", "einen", "einem",
        }:
            continue
        if word in seen or len(word) < 2:
            continue
        seen.add(word)
        chosen.append(lemmas[key])
        if len(chosen) >= args.size:
            break
    known = {e["word"].lower() for e in chosen} | {"der", "die", "das", "ein", "eine"}

    print("3/4 Tatoeba examples", file=sys.stderr)
    sentences, index = load_tatoeba()

    print("4/4 writing JSON", file=sys.stderr)
    words = []
    curated_words = {c["word"] for c in curated}
    for c in curated:
        words.append({
            "word": c["word"], "article": c["article"],
            "pos": "noun" if c["article"] else "other",
            "meaning": c["meaning"], "plural": "",
            "topic": c["topic"], "rank": 0,
            "example": c["example"], "exampleMeaning": c["exampleMeaning"],
        })
    for rank, e in enumerate(chosen, start=1):
        if e["word"] in curated_words:
            continue
        parts = []
        for g in e["glosses"]:
            for part in re.split(r"\s*[;,]\s*", g):
                low = part.lower()
                if (not part or low.startswith(NOTE_PREFIXES) or CRUDE.search(part)
                        or low in {p.lower() for p in parts}):
                    continue
                parts.append(part)
        if not parts:
            continue
        glosses = parts[:3]
        while len(glosses) > 1 and len(", ".join(glosses)) > 40:
            glosses.pop()
        ex, ex_en = pick_example(e, sentences, index, known)
        words.append({
            "word": e["word"], "article": e["article"], "pos": e["pos"],
            "meaning": ", ".join(glosses), "plural": e["plural"],
            "topic": topic_for(e["categories"], e["pos"], ", ".join(glosses)), "rank": rank,
            "example": ex, "exampleMeaning": ex_en,
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "sources": {
            "frequency": "FrequencyWords by Hermit Dave (CC BY-SA 4.0)",
            "dictionary": "English Wiktionary via kaikki.org / wiktextract (CC BY-SA 4.0)",
            "examples": "Tatoeba (CC BY 2.0 FR)",
        },
        "words": words,
    }
    level_counts = levels.apply(payload, levels.load_overrides())
    print(f"Levels: {dict(level_counts)}")
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
                   encoding="utf-8")
    with_ex = sum(1 for w in words if w["example"])
    topics = defaultdict(int)
    for w in words:
        topics[w["topic"]] += 1
    print(f"wrote {len(words)} words ({with_ex} with examples) -> {OUT.relative_to(ROOT)}"
          f" [{OUT.stat().st_size / 1024:.0f} KB]", file=sys.stderr)
    print("topics:", dict(sorted(topics.items(), key=lambda x: -x[1])), file=sys.stderr)


if __name__ == "__main__":
    main()
