---
type: regex
target: { source: file, path: shop/invoice.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*compute_total'
---
shop/invoice.py uses compute_total and has no calc_total left.
