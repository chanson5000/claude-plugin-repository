---
type: regex
target: { source: file, path: shop/__init__.py }
pattern: '^(?![\s\S]*calc_total)[\s\S]*compute_total'
---
shop/__init__.py re-exports compute_total (import and __all__ string) with no calc_total left.
