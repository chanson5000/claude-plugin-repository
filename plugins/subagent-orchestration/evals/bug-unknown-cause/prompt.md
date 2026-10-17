---
description: Symptom-only bug report; the cause lives in a different module than where it shows up.
tags: [orchestration, debugging, investigation]
runs: 3
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Edit, Write, Grep, Glob, Agent, Skill, "Bash(python3 -m unittest *)"]
expected_outcome: Root cause fixed in reports/pagination.py (1-indexed page offset); reports/sales.py not patched around it; all tests green.
---

In this small Python 3 project (standard library only), the sales report is wrong: the first page is missing its first rows, and the last page comes out empty. The tests in `tests/test_sales.py` are failing because of it. Please find the cause and fix it properly. Run the suite with `python3 -m unittest discover` from the project root and make sure everything passes.
