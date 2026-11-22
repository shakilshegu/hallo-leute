"""Tests for tool/vocab/levels.py. Run: python3 -m unittest tool/vocab/test_levels.py"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from levels import level_for  # noqa: E402


def w(rank, topic="everyday", word="Wort", article=""):
    return {"word": word, "article": article, "rank": rank, "topic": topic}


class LevelForTest(unittest.TestCase):
    def test_hand_picked_basics_are_a1(self):
        self.assertEqual(level_for(w(0, "basics"), {}), "a1")

    def test_frequency_bands(self):
        self.assertEqual(level_for(w(500), {}), "a1")
        self.assertEqual(level_for(w(600), {}), "a1")
        self.assertEqual(level_for(w(1200), {}), "a2")
        self.assertEqual(level_for(w(2000), {}), "b1")
        self.assertEqual(level_for(w(2900), {}), "b2")

    def test_survival_topics_move_one_level_down(self):
        self.assertEqual(level_for(w(2000, "health"), {}), "a2")
        self.assertEqual(level_for(w(2900, "food"), {}), "b1")
        self.assertEqual(level_for(w(300, "travel"), {}), "a1")  # not below A1

    def test_override_wins(self):
        word = w(2900, word="Krankenhaus", article="das")
        self.assertEqual(level_for(word, {"das Krankenhaus": "A1"}), "a1")
        self.assertEqual(level_for(word, {"Krankenhaus": "a2"}), "a2")


if __name__ == "__main__":
    unittest.main()
