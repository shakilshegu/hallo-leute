# Vocabulary build

Generates `assets/vocabulary/words.json`: the ~3,000 most useful German words
with English meaning, der/die/das, plural, topic and an example sentence.
The app loads this file at startup, so there is no database.

```bash
python3 tool/vocab/build_vocab.py            # default: 3,000 words
python3 tool/vocab/build_vocab.py --size 5000
```

The first run downloads about 1.2 GB of source data into `tool/vocab/.cache/`,
which git ignores. Later runs take about 30 seconds.

How it works:

1. **Rank.** Counts every word form in German film subtitles (FrequencyWords)
   and credits it to its dictionary form, so *bin*, *ist* and *war* all count
   toward *sein*.
2. **Describe.** Looks each word up in English Wiktionary for its meaning,
   gender, plural and topic. Senses tagged vulgar, archaic, rare, slang and
   so on are skipped, and so are fake nouns like *das Ich*.
3. **Example.** Picks a short, natural Tatoeba sentence (3–9 words) built from
   other common words, with an English translation. Wiktionary's own examples
   are the fallback.
4. **Curate.** Always adds the hand-picked essentials in `curated.json`.

To change the list, edit `curated.json`, `BLOCKLIST` or the topic rules in
`build_vocab.py`, then run the script again and commit the new `words.json`.
See `assets/vocabulary/ATTRIBUTION.md` for licenses.
