---
type: regex
target: { source: file, path: shop/report.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*compute_total'
---
shop/report.py uses compute_total and has no calc_total left.
