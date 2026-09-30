---
name: py-rustify
description: Plan migrating a Python project's linters, formatters, type checkers and pip to Rust tools like ruff, uv and ty, deciding tool by tool with the user. Invoke manually only.
license: MIT
metadata:
  author: Helias
  version: "0.1"
---

# py-rustify

Plan moving a Python project's dev tools to Rust replacements, decided tool by tool with the user.
**Planning only**: write the plan file, change nothing else.

## 1. Inventory

Find every dev tool the project uses and every file that configures or invokes it: tool configs
(`pyproject.toml`, `setup.cfg`, `tox.ini`, `.flake8`, …), requirements and lock files, pre-commit,
CI, task runners, docs, editor settings. Match each against:

| Current | Rust candidates |
|---|---|
| black, autopep8, yapf | ruff format |
| isort | ruff (`I` rules) |
| flake8 and plugins, pycodestyle, pyflakes, pyupgrade, autoflake, pydocstyle, bandit | ruff check |
| pylint | ruff check (partial coverage) |
| mypy, pyright | ty, pyrefly, zuban |
| pip, pip-tools, virtualenv, pipx, pyenv, poetry, pipenv, pdm | uv |
| pre-commit | prek |
| codespell | typos |

Done when every tool found is matched or marked kept (no candidate), each with every file that
configures or invokes it.

## 2. Assess

Weigh each matched tool against its candidates from current docs, never memory (these tools change
fast), and from this project:

- **Coverage**: enabled rules, plugins and options with no equivalent (a flake8 plugin ruff lacks,
  a mypy plugin ty doesn't support).
- **Drift**: files the formatter would reformat; diagnostics gained or lost.
- **Config**: whether every setting translates.
- **Maturity**: stable, beta or preview.
- **Speed and consolidation**: several tools and configs collapsing into one.

Measure drift with read-only dry runs via `uvx` (e.g. `ruff format --diff`,
`ruff check --no-fix --statistics`, `ty check`), translated config in a temp file outside the
project, caches off (ruff `--no-cache`). No uv or no network → say so and rely on docs.

Done when every matched tool has pros, cons, gaps, and measured numbers or why there are none.

## 3. Decide

One question per matched tool, one at a time, worded via `explain-in-simple-language` when
available: its assessment and your recommendation. Answers:

- **migrate**: to which candidate, when several;
- **keep**;
- **side by side**: the new tool runs next to the old one (e.g. a non-blocking CI job) until
  trusted.

Done when every matched tool has a decision and its reason.

## 4. Write the plan

Save to the planning directory the project's governing docs (e.g. `AGENTS.md`) name or already
use; none → `.agents/plans/py-rustify/py-rustify.PLAN.md`. A fresh session must execute it without
this conversation, so it holds:

- **Decisions**: every inventoried tool with its decision, candidate, reason and accepted gaps.
- **Steps** per migrated or side-by-side tool: pinned dependency changes; config translated setting
  by setting; every invoking file from the inventory updated; on migrate, the old tool's config and
  dependencies removed.
- **Order**: uv first, since the others install through it; reformatting in its own step, apart
  from rule fixes.
- **Verification** per step: exact commands and expected results.

Done when every decided tool and every inventory file it touches is covered.

## 5. Grill and hand off

Run `grill-me` on the plan; unavailable → grill inline: one question at a time with your
recommendation, exploring the code instead of asking what it answers. Write every settled change
into the plan. Then tell the user to clear the context (`/clear` or the agent's equivalent) and
prompt `execute the plan <plan path>`.

Done when grilling has ended, the plan reflects it, and the hand-off is given.
