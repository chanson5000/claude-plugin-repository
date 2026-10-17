---
type: regex
target: { source: file, path: app/validators.py }
pattern: '^(?=[\s\S]*"Password must contain an upper case letter")(?=[\s\S]*"Email address must contain an @")(?=[\s\S]*"Username must not be empty")(?=[\s\S]*def validate_password)'
---
The other messages and functions in validators.py are untouched.
