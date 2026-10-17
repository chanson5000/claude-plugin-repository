---
type: regex
target: { source: file, path: cmdbot/registry.py }
pattern: 'def register\(name\)[\s\S]*def dispatch\(line\)'
---
The registry itself was not rewritten; register and dispatch are still present.
