---
type: regex
target: { source: file, path: reports/sales.py }
pattern: 'paginate\(\s*rows\s*,\s*page\s*,\s*per_page\s*\)'
---
reports/sales.py still passes the page through to paginate unchanged.
