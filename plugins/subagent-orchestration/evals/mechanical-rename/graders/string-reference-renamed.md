---
type: regex
target: { source: file, path: shop/hooks.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*DEFAULT_TOTAL_FUNCTION\s*=\s*["'']compute_total["'']'
---
The string reference in shop/hooks.py (resolved via getattr) was renamed too.
