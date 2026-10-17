---
type: regex
target: { source: file, path: tests/test_reverse.py }
pattern: '^(?=[\s\S]*def test_)(?=[\s\S]*dispatch)(?=[\s\S]*olleh)'
---
tests/test_reverse.py has test methods that exercise the handler through dispatch and check a reversed string.
