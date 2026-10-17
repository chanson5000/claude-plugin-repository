---
type: regex
target: { source: file, path: cmdbot/handlers/reverse.py }
pattern: '@register\(\s*["'']reverse["'']\s*\)'
---
reverse.py registers the handler under the name "reverse" with the @register decorator, like its siblings.
