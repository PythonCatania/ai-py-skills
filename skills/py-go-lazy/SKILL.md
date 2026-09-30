---
name: py-go-lazy
description: Add Python 3.15's `lazy` keyword to the imports a Python project's startup doesn't use, all of them or picked with the user by import cost. Invoke manually only.
license: MIT
metadata:
  author: Helias
  version: "0.2"
---

# py-go-lazy

Prefix `lazy` (PEP 810) to the imports a Python project's startup never uses, so their modules load
on first use instead. Run every command under Python 3.15 (e.g. `uv run --python 3.15`).

## 1. Scope

- **Python**: `lazy` is a SyntaxError before 3.15. If `requires-python` (or the project's
  equivalent) allows < 3.15, ask the user to upgrade the project to 3.15 first; stop unless they do.
- **Startup**: every entry point (`[project.scripts]`, `__main__.py`, the app or server module,
  `import pkg` for a library), each with a side-effect-free command that runs its startup (e.g.
  `cli --help`), confirmed with the user.

Done when the project requires 3.15+ and every entry point has a confirmed startup command.

## 2. Find

Baseline per startup command: the project modules it loads (**startup modules**, from
`-X importtime`) and its wall time over repeated runs (e.g. `hyperfine`).

A **candidate** is a module-scope import (including inside `if`/`with`, not `if TYPE_CHECKING:`)
in a startup module that passes both checks:

- **Runtime**: in a wrapper that calls `sys.set_lazy_imports("all")`, sets
  `sys.set_lazy_imports_filter` to allow laziness only when the importing module is a project
  module or `__main__`, then runs the entry point via `runpy`, the imported module is absent from
  `sys.modules` after startup. Third-party imports stay eager, so modules they load anyway, where
  `lazy` gains nothing, drop out.
- **Static**: reading the code, no startup path uses the name, including paths the run skipped
  (config-, platform- or argument-dependent branches). Startup uses a name it evaluates while a
  startup module executes: module-level statements and calls (followed into the called functions),
  decorators, base classes, class bodies, default argument values, and annotations only when
  evaluated at definition (e.g. pydantic models).

Never lazy; list with the reason:

- **Syntax**: inside `try`/`except`/`finally`; `from … import *`; `from __future__ import`.
- **Side effects**: registration (plugins, registries), monkey-patching, import-order dependence;
  often hinted by a name the module never references and doesn't re-export.

Done when every module-scope import in every startup module is a candidate, excluded with a
reason, or used at startup.

## 3. Choose

Ask the user, worded via `explain-in-simple-language` when available:

- **All**: make every candidate lazy.
- **By cost**: measure each candidate module's marginal import time and installed disk size,
  then sort candidates into groups, presented in order, one at a time, as a table (import,
  importing modules, marginal ms, disk size, reason) with your recommendation; the user confirms
  or moves items, or changes the cut-off, which re-sorts:
  1. **Eager, often used**: used on most runs soon after startup (the main command's path, every
     request handler, most subcommands); `lazy` only delays its cost and moves import errors to
     first use.
  2. **Lazy**: heavy and rarely used.
  3. **Eager, light**: below the cut-off.

  Marginal time: `-X importtime` cumulative for an `import <module>` statement
  (`importlib.import_module` hides the module's own line), in a fresh process that first runs
  startup with every candidate lazy (e.g. a scratch copy with `lazy` applied; not the Find filter,
  which also makes every non-project `lazy` import eager) and imports the modules confirmed eager
  so far, so re-measure after group 1: a module group 1 loads anyway costs 0. Propose a heavy
  cut-off from the numbers (e.g. share of baseline startup time).

Done when every candidate has a user-confirmed decision.

## 4. Apply

Prefix `lazy` to every import of each chosen module in every startup module: one eager import
still loads it. Split a statement whose modules got different decisions (`import a, b`).

Done when every import of every chosen module carries `lazy`.

## 5. Verify

- Rerun each startup command: every chosen module is absent from `sys.modules`. Present → find
  what loads it; a project import → offer to make it lazy too; a third-party one → report it.
- Measure wall time against the baseline.
- Run the project's tests, linters and type checkers: `lazy` defers import errors to first use, so
  a new failure may expose a side-effect import → revert it to eager. Report tools that can't
  parse `lazy`.

Done when every chosen module is confirmed unloaded at startup or reported, every check passes or
its failure is reported, and before/after wall times per startup command are reported.
