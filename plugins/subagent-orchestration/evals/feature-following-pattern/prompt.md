---
description: Ordinary feature work inside an existing registry pattern; needs reading siblings, writing code and tests.
tags: [orchestration, feature, standard]
runs: 3
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Edit, Write, Grep, Glob, Agent, Skill, "Bash(python3 -m unittest *)"]
expected_outcome: A reverse handler registered the same way as the others, imported in handlers/__init__.py, with tests in tests/test_reverse.py; all tests green.
---

This is a small Python 3 command bot (standard library only). Add a new `reverse` command that replies with its text argument reversed, so `reverse hello` gives `olleh`. Follow the same pattern the existing handlers use, including how they handle a missing argument, and put it in `cmdbot/handlers/reverse.py`. Add tests for it in `tests/test_reverse.py`, in the same style as the other test files. Run the whole suite with `python3 -m unittest discover` from the project root and make sure it passes.
