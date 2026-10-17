---
type: regex
target: { source: file, path: app/validators.py }
pattern: '^(?![\s\S]*Passwrod)[\s\S]*"Password must be at least 8 characters"'
---
The typo is corrected and the message otherwise reads exactly as before.
