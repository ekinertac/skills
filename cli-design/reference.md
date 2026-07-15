# CLI Design — Full Reference

Condensed from the [Command Line Interface Guidelines](https://clig.dev) (clig.dev) by Aanand Prasad, Ben Firshman, Carl Tashian, and Eva Parish. This file keeps the concrete rules and examples; the philosophy is summarized in `SKILL.md`. Read the original for the foreword and further-reading links.

Scope: single-purpose and multi-command CLI programs. Not full-screen TUI apps (vim, emacs) or GUIs.

**Two operators.** These rules serve humans at a keyboard and LLM agents driving the shell. The original guide predates the agent audience, so where it says "human-first, machine-second" for *output formatting*, read the machine side as a first-class consumer now, not an afterthought. The hard constraint agents add: every capability must be reachable non-interactively (flags/args/stdin), because an agent cannot answer a prompt, choose from a menu, or drive a full-screen UI. Interactive affordances are an optional convenience layered on top for humans; they must never be the only path to an action.

---

## The Basics

Get these wrong and the program is hard to use or a bad citizen in pipes and scripts.

- **Use an argument-parsing library.** Your language's built-in one or a good third-party one — they handle args, flag parsing, help text, and spelling suggestions sensibly.
  - Multi-platform: docopt. Bash: argbash. Go: Cobra, urfave/cli. Java: picocli. Kotlin: clikt. Node: oclif. Deno: `@std/cli` parseArgs. Perl: Getopt::Long. PHP: symfony/console, CLImate. Python: argparse, Click, Typer. Ruby: TTY. Rust: clap. Swift: swift-argument-parser.
- **Exit 0 on success, non-zero on failure.** Scripts read exit codes to decide success. Map the non-zero codes to the most important failure modes.
- **Send primary output to `stdout`.** Machine-readable output goes here — it's what piping carries by default.
- **Send messaging to `stderr`.** Logs, errors, diagnostics. So piped commands show these to the user instead of feeding them to the next command.

## Help

- **Extensive help when asked.** Show it on `-h` / `--help`, including per-subcommand help.
- **Concise help by default.** When a command needs args and gets none, print concise help instead of hanging: a description, one or two example invocations, flag descriptions (unless there are lots), and a pointer to `--help`. Exception: programs that are interactive by default (e.g. `npm init`).
- **`-h`, `--help`, and bare invocation all show help.** You should be able to append `-h` to anything and get help. Don't overload `-h` for anything else. For git-like tools, also support `myapp help`, `myapp help subcommand`, `myapp subcommand --help`, `myapp subcommand -h`.
- **Provide a support path** (website or GitHub link) in top-level help, and **link to web docs**, ideally to the specific subcommand's page.
- **Lead with examples.** Users reach for examples first. Show the common complex uses near the top; show real output when it clarifies and isn't too long. Build a story from simple to complex.
- **If you have loads of examples, move them** to a cheat-sheet command or web page so help text stays short.
- **Show the most common flags/commands first.** Git lists getting-started and common subcommands before the long tail.
- **Format help text** with bold headings for scannability, in a terminal-independent way (no raw escape characters when piped through a pager).
- **Suggest corrections for likely typos** (`brew update jq` → suggests `brew upgrade jq`). You may ask to run the suggestion; don't silently run it — a typo can be a logical mistake or a misused shell variable, and silently "fixing" it both hides risk and prevents the user from learning the real syntax.
- **If the command expects piped input and stdin is a TTY,** show help and quit (or log to stderr) instead of hanging like `cat`.

Example — `jq` with no args prints a description, an example, and points to `jq --help`. Heroku uses bold `USAGE`/`OPTIONS`/`EXAMPLES`/`COMMANDS` headings that emit no escape codes when paged.

## Documentation

Help text gives an immediate sense of the tool; documentation is the full detail — what it's for, what it isn't for, how it works.

- **Provide web docs.** Searchable and linkable; the most inclusive format.
- **Provide terminal docs.** Fast, version-matched, offline. Make them reachable through the tool itself, not only `man`.
- **Consider man pages.** Many users reflexively try `man mycmd`. Tools like ronn generate both man pages and web docs. `git` and `npm` expose man pages via `help` (`npm help ls` == `man npm-ls`).

## Output

- **Human-readable output is paramount.** Humans first, machines second. The simplest heuristic for whether a stream is read by a human is whether it's a TTY — every language has an `isatty` check.
- **Machine-readable output where it doesn't hurt usability.** Line-based text is the universal interface; a user should be able to pipe your output to `grep` and get what they expect. "Expect the output of every program to become the input to another." — Doug McIlroy.
- **`--plain`** for a tabular, one-record-per-line format when human-friendly output (e.g. cells split across lines to fit the width) would break `grep`/`awk`.
- **`--json`** for formatted JSON output — more structure for complex data, and pipes straight to `jq` and web services via `curl`.
- **Show brief output on success.** Traditional UNIX silence makes commands look hung (e.g. a slow `cp`). Err on the side of less, but rarely nothing. Provide `-q` to suppress non-essential output for scripts, avoiding clumsy `2>/dev/null`.
- **If you change state, tell the user** the new state, especially when it doesn't map directly to the request (see `git push` output).
- **Make current state easy to see** (`git status`), and **suggest next commands** in a workflow (git status hints at `add`/`restore`/`commit`).
- **Actions crossing the program's boundary should be explicit** — reading/writing files the user didn't pass (except internal cache/state), talking to a remote server.
- **Increase information density with ASCII art** where it helps (`ls -l` permission columns are scannable once learned).
- **Color with intention.** Highlight, or flag errors in red. Overuse makes color meaningless and harder to read.
- **Disable color when:** stdout/stderr isn't a TTY (check each stream individually — colored stderr is still useful when stdout is piped), `NO_COLOR` is set and non-empty, `TERM=dumb`, or `--no-color` is passed. Consider a `MYAPP_NO_COLOR` too.
- **No animations when stdout isn't a TTY** — stops progress bars becoming "Christmas trees" in CI logs.
- **Symbols/emoji where they clarify** — to distinguish things, catch attention, add character. Easy to overdo; don't make it look like a toy.
- **Don't print developer-only output by default.** Internal-understanding-only detail belongs in verbose mode. Get usability feedback from newcomers.
- **Don't treat stderr like a log file by default** — no `ERR`/`WARN` level labels or extra context unless in verbose mode.
- **Page long output** (like `git diff`) with e.g. `less -FIRX` (no paging if it fits one screen, case-insensitive search, color/formatting, leaves content on screen). Only page when stdin or stdout is a TTY. Language-native pagers (e.g. pypager) can be more robust than piping to `less`.

## Errors

Errors are where users most often reach for docs — turning errors into documentation saves everyone time.

- **Catch errors and rewrite them for humans,** with the fix: "Can't write to file.txt. You might need to make it writable by running 'chmod +w file.txt'."
- **Signal-to-noise ratio is crucial.** More irrelevant output = longer to find the mistake. Group many same-type errors under one explanatory header instead of printing many similar lines.
- **Put the most important information last** — the eye lands at the bottom, and on red text; use red intentionally and sparingly.
- **For unexpected/unexplainable errors,** provide debug and traceback info and how to file a bug — but keep signal-to-noise; consider writing the debug log to a file rather than the terminal.
- **Make bug reports effortless** — e.g. a URL pre-populated with as much info as possible.

## Arguments and flags

Terminology: **args** are positional (`cp foo bar`, order matters). **Flags** are named (`-r`, `--recursive`, `--file foo.txt`), order generally doesn't matter.

- **Prefer flags to args.** More typing, but clearer, and easier to evolve without ambiguity or breakage.
- **Full-length version of every flag** (`-h` and `--help`) — verbose forms are self-documenting in scripts.
- **Single-letter flags only for common ones,** especially at the top level, so you don't pollute the short-flag namespace.
- **Multiple args are fine for the same kind of thing** (`rm a.txt b.txt`, works with globbing `rm *.txt`).
- **Two+ args for *different* things is usually wrong.** Exception: a common primary action where brevity is worth memorizing (`cp src dest`).
- **Use standard flag names** so users can guess: `-a/--all`, `-d/--debug`, `-f/--force`, `--json`, `-h/--help` (help only), `-n/--dry-run`, `--no-input`, `-o/--output`, `-p/--port`, `-q/--quiet`, `-u/--user`, `--version`, `-v` (verbose or version — pick one, or use `-d` for verbose to avoid confusion).
- **Make the default right for most users.** Most people won't find and remember the right flag. `ls` would default to `ls -lhF` if designed today.
- **Prompt for missing input** — but **never *require* a prompt.** Always allow flags/args, and when stdin isn't a TTY, skip prompting and require the flags.
- **Confirm before dangerous actions,** scaled to the danger:
  - Mild (delete a file): maybe prompt; if the command is literally "delete," maybe not.
  - Moderate (delete a directory, a remote resource, a bulk change): prompt, and offer a dry run.
  - Severe (delete an entire app/server): make it hard to confirm by accident — require typing the resource's name, with a scriptable `--confirm="name"` alternative.
  - Watch for non-obvious destruction (changing a config number from 10 to 1 implicitly deleting 9 things).
- **Support `-` for stdin/stdout** on file args (`curl ... | tar xvf -`).
- **For optional flag values, allow a keyword like `none`** (`ssh -F none`) rather than an ambiguous blank value.
- **Make args/flags/subcommands order-independent** where the parser allows — users hit up-arrow and append a flag, and `mycmd subcmd --foo` should work as well as `mycmd --foo subcmd`.
- **Do not read secrets from flags.** `--password` leaks into `ps` output and shell history and encourages insecure env-var use. Accept secrets via a `--password-file` flag or stdin. (Even `--password $(< file)` leaks the same way.)

## Interactivity

Every interactive path must have a non-interactive twin. Agents, scripts, and CI can't answer prompts or navigate menus — if the only way to reach a result is interactive, those operators are locked out. Treat prompts and pickers as a convenience for humans that sits on top of a fully flag-driven core, never as the sole entry point.

- **Interactive elements only when stdin is a TTY** — otherwise a prompt can't work; throw an error naming the flag to pass.
- **A flag-driven equivalent for every wizard/menu/picker** — the same outcome reachable in one non-interactive invocation.
- **Honor `--no-input`** — disable all prompts; if input is required, fail and say which flag provides it.
- **Don't echo passwords** — turn off terminal echo (your language has a helper).
- **Let the user escape.** Make exit obvious (don't be vim). Keep Ctrl-C working during network I/O. For wrappers where Ctrl-C can't quit (ssh, tmux, telnet), document the escape sequence.

## Subcommands

For sufficiently complex tools, or a family of closely related tools (RCS vs git). They share global flags, help, config, storage.

- **Be consistent across subcommands** — same flag names for the same things, similar output formatting.
- **Consistent names across levels.** Two-level `noun verb` is common (`docker container create`); keep verbs consistent across nouns. Either `noun verb` or `verb noun` works; `noun verb` is more common.
- **No ambiguous or similar names** — `update` vs `upgrade` is confusing; disambiguate or rename.

## Robustness

- **Validate user input.** Bad data will arrive eventually; check early, bail before damage, make errors understandable.
- **Responsive beats fast.** Print something within 100ms. Before a network request, print something so it doesn't look hung.
- **Show progress for long work.** A spinner or progress bar makes a program feel faster; show ETA or at least motion so a stalled bar doesn't read as a crash. Libraries: tqdm (Python), schollz/progressbar (Go), node-progress (Node).
- **Parallelize thoughtfully.** Big usability win (`docker pull`'s multiple bars) but hard to report cleanly — use a library, keep output from interleaving confusingly, and always print the logs if a step behind a progress bar fails.
- **Make things time out.** Configurable network timeouts with a reasonable default so it never hangs forever.
- **Make it recoverable.** After a transient failure (dropped connection), up-arrow + enter should resume from where it left off.
- **Make it crash-only** where possible — defer or avoid cleanup so the program can exit immediately on failure/interruption. More robust and more responsive.
- **Expect misuse.** People wrap it in scripts, run many at once, use bad connections and untested environments (macOS filesystems are case-insensitive but case-preserving).

## Future-proofing

Subcommands, args, flags, config files, and env vars are all interfaces — you're committing to keeping them working. Semantic versioning only excuses so much; monthly major bumps are meaningless.

- **Keep changes additive** — add a new flag rather than changing a flag's behavior incompatibly, without bloating the interface.
- **Warn before a non-additive change.** When a user passes a flag you're deprecating, tell them it'll change, how to make their usage future-proof, and ideally stop warning once they've migrated.
- **Changing human-readable output is usually OK** — it's the only way to iterate. Push scripts toward `--plain`/`--json` for stability.
- **No catch-all subcommand.** Letting a bare first arg default to `run` means you can never add a subcommand of that name without breaking existing scripts.
- **No arbitrary abbreviations** of subcommands (`i` for `install`) — scripts will depend on the prefix and lock you out of new names. Explicit, stable aliases are fine.
- **No time bombs** — don't depend on an external server (yours included) that may vanish in 20 years; and don't add a blocking call to analytics either.

## Signals and control characters

- **On Ctrl-C (INT), exit as soon as possible.** Say something immediately before cleanup; put a timeout on cleanup so it can't hang forever.
- **On a second Ctrl-C during cleanup, skip it.** Tell the user what a second Ctrl-C will do, in case it's destructive (Docker Compose: "press Ctrl+C again to force"). Expect to be started in a state where prior cleanup never ran.

## Configuration

Configuration varies by specificity, stability, and complexity. Three categories:

1. **Varies per invocation** (debug level, dry run) → **flags** (env vars maybe too).
2. **Mostly stable, machine-specific** (non-default paths, color behavior, HTTP proxy) → **flags and probably env vars**; users may set them in a shell profile or `.env`. A dedicated config file only if sufficiently complex.
3. **Stable within a project, for all users** (like `Makefile`, `package.json`, `docker-compose.yml`) → **a version-controlled, command-specific file.**

- **Follow the XDG base-directory spec** — use `~/.config` rather than proliferating dotfiles. Supported by fish, yarn, wireshark, emacs, neovim, tmux, and others.
- **If you modify config that isn't yours, ask consent and say exactly what you're doing.** Prefer a new file (`/etc/cron.d/myapp`) over appending to a shared one (`/etc/crontab`); if you must append, mark it with a dated comment.
- **Precedence, highest to lowest:** flags → shell environment variables → project config (`.env`) → user config → system-wide config.

## Environment variables

- **Env vars are for behavior that varies with the run context** — the terminal session. They may duplicate flags/config or be distinct.
- **Names: uppercase letters, digits, underscores only, not starting with a digit** (so `O_O` and `OWO` are the only valid emoticons).
- **Aim for single-line values** — multi-line values break `env` usability.
- **Don't commandeer widely-used names** (see the POSIX env var list).
- **Check general-purpose vars when relevant:** `NO_COLOR`/`FORCE_COLOR`, `DEBUG`, `EDITOR`, `HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY`/`NO_PROXY`, `SHELL`, `TERM`/`TERMINFO`/`TERMCAP`, `TMPDIR`, `HOME`, `PAGER`, `LINES`/`COLUMNS`.
- **Read from `.env` where appropriate** — for vars stable within a directory, so users configure per-project without retyping. Libraries exist for Rust, Node, Ruby, etc.
- **Don't use `.env` as a substitute for a real config file** — it's not usually version-controlled (no history), string-only, easily disorganized, prone to encoding issues, and often ends up holding secrets it shouldn't.
- **Do not read secrets from environment variables.** They leak: exported vars reach every child process and logs; `curl -H "Authorization: Bearer $TOKEN"` exposes the token in process state (use `-H @file`); `docker inspect` and `systemctl show` expose them globally. Accept secrets via credential files, pipes, `AF_UNIX` sockets, or a secrets service.

## Naming

The program name is typed constantly — it must be easy to remember and type.

- **Simple, memorable word,** but not so generic it collides with other commands (ImageMagick and Windows both shipped `convert`).
- **Lowercase only, dashes only if you must** (`curl`, not `DownloadURL`).
- **Short,** but not so short you take a name reserved for core utilities (`cd`, `ls`, `ps`).
- **Easy to type** — Docker Compose went from the awkward one-handed `plum` to the smoother `fig`.

## Distribution

- **Distribute as a single binary if possible** (PyInstaller and similar for non-compiled languages). Otherwise use the platform's native package installer so files can be cleanly removed. Language-specific tools (e.g. a linter) can assume the interpreter is present.
- **Make uninstall easy,** and put the instructions at the bottom of the install instructions — right after installing is a common time to want to uninstall.

## Analytics

Users of the command line expect to control their environment; background data collection is surprising and resented.

- **Do not phone home usage or crash data without consent.** Be explicit about what you collect, why, how it's anonymized, and retention. Prefer opt-in; if opt-out, disclose clearly on first run / the website and make disabling easy. (Homebrew, Next.js, Angular are examples with documented practices.)
- **Consider alternatives:** instrument your web docs and downloads, and talk to users directly for feedback and feature requests.
