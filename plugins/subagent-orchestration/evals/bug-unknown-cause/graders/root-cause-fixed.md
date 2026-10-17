---
type: regex
target: { source: file, path: reports/pagination.py }
pattern: '^(?![\s\S]*=\s*page\s*\*\s*per_page)[\s\S]*page\s*-\s*1'
---
The off-by-one is fixed in reports/pagination.py: the 1-indexed page is converted to a 0-based offset and the original "start = page * per_page" is gone.
