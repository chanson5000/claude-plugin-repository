---
type: regex
target: { source: file, path: cmdbot/handlers/__init__.py }
pattern: '\breverse\b'
---
The new module is added to the import in handlers/__init__.py (otherwise it never registers), and the existing handlers are still imported.
