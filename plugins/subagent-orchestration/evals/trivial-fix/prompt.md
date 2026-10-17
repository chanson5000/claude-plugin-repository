---
description: Trivial one-line typo fix; included as the overhead control where the plugin should not help.
tags: [orchestration, trivial, control]
runs: 3
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Edit, Write, Grep, Glob, Agent, Skill, "Bash(python3 -m unittest *)"]
expected_outcome: The misspelled word is corrected in the one message; nothing else changes; tests green.
---

Users reported a typo in one of our signup error messages: it currently reads "Passwrod must be at least 8 characters". Please fix the spelling. This is a small Python 3 project (standard library only); you can run the tests with `python3 -m unittest discover` from the project root.
