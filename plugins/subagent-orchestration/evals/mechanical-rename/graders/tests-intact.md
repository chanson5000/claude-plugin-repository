---
type: regex
target: { source: file, path: tests/test_hooks.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*resolve_total_function\(\)'
---
tests/test_hooks.py still exists with its original test and has no calc_total in it (the test must not be deleted or gutted to go green).
