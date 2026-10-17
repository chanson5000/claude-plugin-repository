#!/usr/bin/env bash
# Scaffold: tiny validators module with a typo in one user-facing message.
# Tests check exception types and message fragments, so they pass before and after the fix.
set -euo pipefail
mkdir -p app tests
touch app/__init__.py tests/__init__.py

cat > app/validators.py <<'EOF'
"""Input validation for the signup form."""


class ValidationError(ValueError):
    """Raised with a message that is shown to the user."""


def validate_password(password):
    if len(password) < 8:
        raise ValidationError("Passwrod must be at least 8 characters")
    if password.lower() == password:
        raise ValidationError("Password must contain an upper case letter")


def validate_email(email):
    if "@" not in email:
        raise ValidationError("Email address must contain an @")


def validate_username(username):
    if not username.strip():
        raise ValidationError("Username must not be empty")
EOF

cat > tests/test_validators.py <<'EOF'
import unittest

from app.validators import (
    ValidationError,
    validate_email,
    validate_password,
    validate_username,
)


class ValidatorTests(unittest.TestCase):
    def test_short_password_rejected(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_password("Ab1")
        self.assertIn("at least 8 characters", str(ctx.exception))

    def test_lowercase_password_rejected(self):
        with self.assertRaises(ValidationError):
            validate_password("alllowercase")

    def test_good_password_accepted(self):
        validate_password("GoodPassw0rd")

    def test_email_needs_at_sign(self):
        with self.assertRaises(ValidationError):
            validate_email("nobody.example.com")

    def test_blank_username_rejected(self):
        with self.assertRaises(ValidationError):
            validate_username("   ")
EOF
