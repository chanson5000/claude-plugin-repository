---
type: regex
target: { source: file, path: shop/pricing.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*def\s+compute_total\s*\('
---
shop/pricing.py defines compute_total and no longer mentions calc_total.
