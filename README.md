# ai-py-skills

Agent skills for Python projects, from the Python Catania community. They follow the open
[Agent Skills](https://agentskills.io/specification) format, so they work with any agent that
supports it: Claude Code, Codex, GitHub Copilot, and others.

## Skills

- **[py-rustify](./skills/py-rustify/SKILL.md)** — plan moving a project's dev tools to Rust replacements (ruff, ty, uv, prek, typos), deciding tool by tool with you.
- **[py-go-lazy](./skills/py-go-lazy/SKILL.md)** — mark imports that startup doesn't use as lazy with Python 3.15's `lazy` keyword ([PEP 810](https://peps.python.org/pep-0810/)) and report the time saved.

py-rustify uses [grill-me](https://github.com/eai-org/agent-toolkit/tree/main/skills/grill-me),
and both skills use [explain-in-simple-language](https://github.com/eai-org/agent-toolkit/tree/main/skills/explain-in-simple-language),
from [agent-toolkit](https://github.com/eai-org/agent-toolkit) when they are installed; both work
without them.

## How to install the skills

Install all skills in one command:

```sh
git clone https://github.com/PythonCatania/ai-py-skills.git && cd ai-py-skills && ./install.sh
```

The script symlinks every skill in two layers: `~/.agents/skills`, the agent-neutral location,
gets one link per skill pointing into the repo; your agent's own skills dir, `~/.claude/skills` by
default, gets links pointing at those entries. Re-running is safe: correct links are left alone,
stale ones re-pointed, broken ones pruned.

Update in one command:

```sh
cd ai-py-skills && git pull && ./install.sh
```

For another agent, point `--skills-dir` at its user-level skills folder; agents that read
`~/.agents/skills` directly need nothing more. Options:

```sh
./install.sh --agents-dir DIR   # agent-neutral location (default: ~/.agents)
./install.sh --skills-dir DIR   # agent skills dir to wire (e.g. a project's .claude/skills)
./install.sh --force            # overwrite real files/dirs and foreign symlinks
./install.sh --help
```

To install a single skill by hand, through the same two layers:

```sh
mkdir -p ~/.agents/skills ~/.claude/skills
ln -s "$(pwd)/skills/py-rustify" ~/.agents/skills/
ln -s ~/.agents/skills/py-rustify ~/.claude/skills/
```
