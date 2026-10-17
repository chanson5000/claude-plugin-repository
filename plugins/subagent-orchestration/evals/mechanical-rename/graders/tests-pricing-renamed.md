---
type: regex
target: { source: file, path: tests/test_pricing.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*compute_total'
---
tests/test_pricing.py imports and calls compute_total with no calc_total left.
