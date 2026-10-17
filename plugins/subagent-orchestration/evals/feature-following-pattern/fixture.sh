#!/usr/bin/env bash
# Scaffold: command registry "cmdbot" with three handlers (ping, echo, upper),
# each in its own module with its own test file. All tests pass initially.
set -euo pipefail
mkdir -p cmdbot/handlers tests

touch cmdbot/__init__.py tests/__init__.py

cat > cmdbot/registry.py <<'EOF'
"""Command registry: handlers register themselves by name with @register."""

HANDLERS = {}


def register(name):
    def decorator(func):
        if name in HANDLERS:
            raise ValueError(f"handler already registered: {name}")
        HANDLERS[name] = func
        return func

    return decorator


def dispatch(line):
    """Run a command line like 'echo hello' and return the reply string."""
    name, _, arg = line.strip().partition(" ")
    handler = HANDLERS.get(name)
    if handler is None:
        return f"error: unknown command '{name}'"
    return handler(arg.strip())
EOF

cat > cmdbot/handlers/__init__.py <<'EOF'
"""Importing a handler module registers it. Add new handlers to this import."""
from cmdbot.handlers import echo, ping, upper  # noqa: F401
EOF

cat > cmdbot/handlers/ping.py <<'EOF'
from cmdbot.registry import register


@register("ping")
def ping(arg):
    """Reply 'pong'; takes no argument."""
    return "pong"
EOF

cat > cmdbot/handlers/echo.py <<'EOF'
from cmdbot.registry import register


@register("echo")
def echo(arg):
    """Reply with the argument unchanged."""
    if not arg:
        return "error: echo needs text"
    return arg
EOF

cat > cmdbot/handlers/upper.py <<'EOF'
from cmdbot.registry import register


@register("upper")
def upper(arg):
    """Reply with the argument in upper case."""
    if not arg:
        return "error: upper needs text"
    return arg.upper()
EOF

cat > tests/test_ping.py <<'EOF'
import unittest

import cmdbot.handlers  # noqa: F401  (registers handlers)
from cmdbot.registry import dispatch


class PingTests(unittest.TestCase):
    def test_ping(self):
        self.assertEqual(dispatch("ping"), "pong")
EOF

cat > tests/test_echo.py <<'EOF'
import unittest

import cmdbot.handlers  # noqa: F401  (registers handlers)
from cmdbot.registry import dispatch


class EchoTests(unittest.TestCase):
    def test_echo(self):
        self.assertEqual(dispatch("echo hello there"), "hello there")

    def test_echo_without_text(self):
        self.assertEqual(dispatch("echo"), "error: echo needs text")
EOF

cat > tests/test_upper.py <<'EOF'
import unittest

import cmdbot.handlers  # noqa: F401  (registers handlers)
from cmdbot.registry import dispatch


class UpperTests(unittest.TestCase):
    def test_upper(self):
        self.assertEqual(dispatch("upper hello"), "HELLO")

    def test_upper_without_text(self):
        self.assertEqual(dispatch("upper"), "error: upper needs text")
EOF

cat > tests/test_registry.py <<'EOF'
import unittest

import cmdbot.handlers  # noqa: F401  (registers handlers)
from cmdbot.registry import HANDLERS, dispatch, register


class RegistryTests(unittest.TestCase):
    def test_unknown_command(self):
        self.assertEqual(dispatch("nope"), "error: unknown command 'nope'")

    def test_duplicate_registration_rejected(self):
        with self.assertRaises(ValueError):
            register("ping")(lambda arg: "x")

    def test_builtin_handlers_present(self):
        for name in ("ping", "echo", "upper"):
            self.assertIn(name, HANDLERS)
EOF
