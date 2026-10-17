---
type: regex
target: { source: file, path: cmdbot/handlers/__init__.py }
pattern: '^(?=[\s\S]*\becho\b)(?=[\s\S]*\bping\b)(?=[\s\S]*\bupper\b)'
---
echo, ping and upper are still imported in handlers/__init__.py.
