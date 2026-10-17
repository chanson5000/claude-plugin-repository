---
type: regex
target: { source: file, path: shop/cart.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*compute_total'
---
shop/cart.py uses compute_total and has no calc_total left.
