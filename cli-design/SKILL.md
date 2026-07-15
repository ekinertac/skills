---
name: cli-design
description: 'Design and review command-line tools that follow established CLI conventions: help text, stdout/stderr split, exit codes, flags vs args, errors humans can act on, TTY-aware output/color, prompts, subcommands, config precedence, env vars, and naming. Use when building a new CLI or auditing an existing one''s UX. Also covers making a CLI agent-friendly: fully operable non-interactively so LLM agents, scripts, and CI can drive it. Trigger phrases: "build a CLI", "design a command-line tool", "review my CLI", "is this CLI well designed", "make my CLI agent-friendly", "non-interactive CLI", "add a subcommand", "CLI help text", "argparse/click/cobra/clap", "exit codes", "stdout vs stderr", "cli flags".'
---

# CLI Design

Conventions for command-line programs, based on the [Command Line Interface Guidelines](https://clig.dev) (clig.dev). Use when writing a new CLI or reviewing one you already have. The full rule set with examples lives in `reference.md` — load it when you need the detail behind a rule.

## The one idea underneath everything

A CLI today has two kinds of operators: **humans** at a keyboard, and **LLM agents** driving the shell. Design for both. The human wants a text UI that's pleasant to converse with; the agent wants every capability reachable without a human in the loop. These rarely conflict, and most rules below hit both at once.

**Non-interactive operability is a hard requirement, not a nice-to-have.** Agents (and scripts, and CI) can't answer a prompt, pick from a menu, or drive a full-screen UI. If the *only* way to do something is interactive, an agent simply cannot do it. So:

- Every action must be fully doable through flags/args/stdin, with no prompt required — ever.
- Prompts are an optional convenience for humans, layered on top; when stdin isn't a TTY, skip them and require the flags instead (fail with a message naming the flag, don't hang).
- Every confirmation needs a scriptable bypass (`--force`, or `--confirm="name"` for severe actions).
- Offer machine-readable output (`--json`, `--plain`) so an agent can parse results instead of scraping formatted text.
- Keep exit codes meaningful and errors on stderr with actionable text — that's how an agent detects and recovers from failure.

Guiding principles: follow existing conventions so the tool is guessable; say just enough (not silent, not a firehose); make functionality discoverable through help and suggestions; treat each run as one turn in a conversation; feel robust. Break a convention only with intention, and document it when you do.

## When to use

- Starting a new command-line tool and choosing its shape (args, flags, subcommands, output).
- Reviewing or auditing an existing CLI's usability.
- Adding a subcommand, flag, or output mode to something that already exists.
- Deciding config precedence, env var handling, or how to accept secrets.

Not for: full-screen TUI programs (vim/emacs-style), or GUI apps.

## Do this first — the non-negotiables

Get these wrong and the tool is broken or a bad pipe citizen.

1. **Use an arg-parsing library**, not hand-rolled parsing. Python: argparse/Click/Typer. Go: Cobra/urfave-cli. Rust: clap. Node: oclif. It handles flags, help text, and suggestions for free.
2. **Exit 0 on success, non-zero on failure.** Scripts depend on this. Map distinct failure modes to distinct non-zero codes.
3. **Primary output → `stdout`.** Anything machine-readable goes here; it's what pipes carry by default.
4. **Logs, errors, progress, prompts → `stderr`.** So piping `stdout` into the next command doesn't drag diagnostics along.

## Checklist by area

Skim the relevant block. Each line is a rule; `reference.md` has the why and the examples.

**Help**
- `-h`, `--help`, and (for git-like tools) `help` all show help; adding `-h` to anything shows help, never overload it.
- No args when args are required → print concise help (description, 1-2 examples, key flags, "pass --help for more"), not a hang.
- Lead with examples; put the most common flags/commands first; use terminal-independent bold headings.
- If you can guess a typo'd command, suggest it (`brew update` → "did you mean upgrade?"); ask, don't silently run it.
- Link to web docs and a support/issue path from top-level help.

**Output**
- Human-readable is paramount; detect TTY (`isatty`) to decide human vs machine formatting.
- Offer `--json` for structured output and `--plain` (one record per line) when pretty output breaks `grep`/`awk`.
- Say something on success but keep it brief; when you change state, tell the user what the new state is.
- Provide `-q`/`--quiet` to suppress non-essential output.
- Suggest the next command in a workflow (like `git status` does).

**Color & animation**
- Use color sparingly and with intent (red = error, highlight = attention).
- Disable color when: not a TTY, `NO_COLOR` set, `TERM=dumb`, or `--no-color`. Consider a `MYAPP_NO_COLOR` too.
- No spinners/progress animations when stdout isn't a TTY (keeps CI logs clean).

**Errors**
- Catch expected errors and rewrite them for humans, with the fix: "Can't write to file.txt. Run 'chmod +w file.txt'."
- Most important info last (the eye lands at the bottom); protect signal-to-noise; group repeated errors under one header.
- On unexpected errors, offer debug/traceback (consider a log file, not the terminal) and make bug reports effortless (pre-filled URL).

**Arguments & flags**
- Prefer flags to args; keep meaning order-independent where the parser allows.
- Every flag has a full-length form; reserve single-letter flags for common ones; use standard names (`-f/--force`, `-o/--output`, `-n/--dry-run`, `-v`, `--version`, etc.).
- Multiple args are fine for the same kind of thing (`rm a b c`); two args for *different* things is usually a smell (except `cp src dest`).
- Make the default right for most users. Prompt for missing input, but never *require* a prompt — always allow flags/args, and skip prompting when stdin isn't a TTY.
- Confirm before dangerous actions; scale the friction to the danger (mild → maybe prompt; severe → make them type the resource name, plus a scriptable `--confirm=name`).
- Support `-` to mean stdin/stdout for file args.
- **Never read secrets from a flag** (leaks to `ps`/history) — use `--x-file`, stdin, or a pipe.

**Interactivity** (every interactive path needs a non-interactive twin)
- Prompt only when stdin is a TTY; honor `--no-input`. When not a TTY, don't prompt — require the flag and fail with a message naming it.
- Any menu/picker/wizard must have a flag-driven equivalent that reaches the same result in one non-interactive invocation. An agent can't navigate the interactive version.
- Don't echo passwords; make Ctrl-C always work and make it clear how to escape.

**Subcommands**
- Be consistent across subcommands (flag names, output shape).
- Two-level `noun verb` (e.g. `docker container create`) is the common pattern; keep verbs consistent across nouns.
- Don't ship ambiguously-named pairs (`update` vs `upgrade`).

**Robustness & responsiveness**
- Validate input early, bail before damage.
- Print something within ~100ms; show progress for long work; print logs even when hidden behind a progress bar if something fails.
- Configurable network timeouts with sane defaults; be recoverable (up-arrow + enter resumes) and ideally crash-only.

**Future-proofing** (interfaces are a contract)
- Keep changes additive; warn before breaking a flag and tell users how to migrate.
- No catch-all default subcommand; no arbitrary prefix abbreviations (`i` for `install`) — explicit stable aliases only.
- Human-readable output can change; that's why scripts should use `--json`/`--plain`.

**Config, env vars, naming, distribution**
- Precedence, high → low: flags, shell env, project config (`.env`), user config, system config.
- Follow the XDG base-dir spec (`~/.config/...`). Per-invocation → flags; context-varying → env vars; project-stable → a version-controlled file.
- Env var names: uppercase/digits/underscore only; honor common ones (`NO_COLOR`, `DEBUG`, `EDITOR`, `PAGER`, `HTTP_PROXY`, `TERM`, `TMPDIR`, ...); **don't read secrets from env vars either** (they leak to logs, `docker inspect`, `systemctl show`).
- Name: short, lowercase, memorable, easy to type, not too generic.
- Distribute as a single binary when you can; make uninstall easy; never phone home without consent.

## Reviewing an existing CLI

Walk the checklist above against the tool and report concrete gaps, worst-first. Fast high-signal checks:
- Run it with no args, `-h`, `--help`, and a bogus flag — is help clear and are typos caught?
- Pipe it: `mycmd | cat` — does color/animation switch off, does structured data survive?
- Force an error — is the message actionable, on stderr, with a non-zero exit?
- Check `echo $?` after success and failure.
- Try a dangerous action — is there a confirmation proportional to the risk?

## Common mistakes

- Diagnostics on stdout, poisoning pipes. → stderr.
- Exit 0 even on failure. → map real exit codes.
- Silent on success *and* silent while working, so it looks hung. → brief success line, progress for long ops.
- Color/spinner escape codes dumped into CI logs. → gate on TTY + `NO_COLOR`.
- Secrets via `--password` or `$TOKEN`. → file/stdin/pipe only.
- Stack traces shown by default. → human message; traceback behind verbose or a log file.
- Hand-rolled flag parsing that breaks on `--flag=value` vs `--flag value`. → use the library.
