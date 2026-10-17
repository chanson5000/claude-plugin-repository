---
description: Fully decided cross-file rename; cheap to be wrong, nothing to figure out.
tags: [orchestration, rename, mechanical]
runs: 3
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Edit, Write, Grep, Glob, Agent, Skill, "Bash(python3 -m unittest *)"]
expected_outcome: calc_total renamed to compute_total in every file including the string reference; all tests green.
---

This project is a small Python 3 library (standard library only). The function `calc_total` in `shop/pricing.py` has a misleading name, so please rename it to `compute_total` everywhere it is used: the definition, every import and call site, the tests, and any place it is referred to by name as a string. Don't change behavior. Keep the tests green; you can run them with `python3 -m unittest discover` from the project root.
