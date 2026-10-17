---
type: regex
target: { source: file, path: reports/sales.py }
pattern: 'page\s*-\s*1|page\s*\+\s*1|page_index|zero_based'
match: not_contains
---
reports/sales.py was not changed to compensate for the helper's bug (no page-1 adjustment at the call site).
