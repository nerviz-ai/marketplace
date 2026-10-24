# Nerviz · marketplace

Delivery vehicle for [Nerviz](https://github.com/nerviz-ai/nerviz).
It ships **three skills**, `/arch-adopt`, `/platform-upgrade` and `/new-project`, and one mod,
`nerviz-config`.

## Install

```bash
claude plugin marketplace add nerviz-ai/marketplace
claude plugin install nerviz@nerviz
```

Then, **inside the Java project** that should adopt the architecture:

```
/nerviz:arch-adopt
```

A plugin's skills are namespaced by the plugin's name, so it is
`/nerviz:arch-adopt` here. The copy this command installs **into the project**
is a project skill, not a plugin one, and is plain `/arch-adopt` from then on.

It reads the project's packages, proposes the closest architecture blueprint, fetches
the source repository, and writes the project's `.claude/`: the norms with their globs
derived for those packages, the development skills, the agents, the enforcement hook and
its schema. Review with `git diff`; undo with `git checkout -- .claude`.

## Bring a project up to the floor

`/arch-adopt` refuses a project that builds on a Spring Boot line older than the one the
architecture is written for. Inside that project:

```
/nerviz:platform-upgrade
```

It takes the build to the line the Initializr serves today — the version bump, the renamed
starters and test slices, the renamed configuration properties — through a recipe the source's
hook writes and the Apache-licensed OpenRewrite core runs through the project's own Maven or
Gradle wrapper, then fixes what no rename covers until the build is green. It never commits:
review with `git diff`, undo with `git checkout -- .`. It ends by printing `/arch-adopt`.

## Create a project

In the directory that should hold your projects — no clone of the source needed:

```
/nerviz:new-project
```

It fetches the source at its latest release tag into `nerviz-<tag>/` there, records which tag
and commit it fetched, and prints the next two moves: `cd nerviz-<tag> && claude`, then
`/init-project` inside that session. The generation runs there, with that tree's hooks
active, exactly as it does from a clone; the project is created next to the tree, in the
directory you started from. `--ref <tag|sha|main>` pins another ref.

## Project settings pane

`/nerviz-config` opens a pane over `ArchHook.jar config list` in a project that has the Nerviz
`.claude/`: the settings the project owns, the ones off their default marked, each change asked
in a dialog and written only through `config set` or `config unset`. It needs Claude Code 2.1.287
or later, stays silent where the project has no `.claude/hooks/ArchHook.jar`, and says to run
`/arch-adopt` for a jar older than the `config` mode. A mod is unsandboxed code; this one holds
no rule and starts no program but `java`. Source and design: `.claude/mods/nerviz-config/` and
decision `0187` in the source repository.

## What this repository does not carry

The norms, the development skills, the agents and the hook are **not** vendored here.
`/arch-adopt` fetches them from the source repository at adopt time, so there is one
source of truth and no per-release copy to keep in sync. What is vendored are the three skills
themselves — a plugin cannot fetch its own skill before it runs — and `.plugin-source.json`
records where each copy came from. CI fails if one has drifted. `new-project` reads
`arch-adopt`'s fetch steps by path, so the two are always synced at the same ref.

Once a project has adopted, the skill is inside that project too: updating it needs no
plugin. This marketplace is how the first install happens, not a runtime dependency.

## Updating the vendored copy

Automatic: every tag the source repository cuts reaches `.github/workflows/sync.yml` as a
`repository_dispatch`, which runs `./sync.sh <tag>`, sets `plugin.json`'s version, runs
`validate.yml` on the branch and opens a PR. Merging it is the publish. To sync by hand from
GitHub, run the `sync` workflow (an empty ref means the latest tag). It needs "Allow GitHub
Actions to create and approve pull requests" in Settings → Actions → General.

Locally:

```bash
./sync.sh            # pull at the ref recorded in .plugin-source.json
./sync.sh v1.2.0     # pull at this ref and record it
git diff             # review
```

A private source repository needs a token in the variable `.plugin-source.json` names
(`GH_TOKEN` by default); CI reads it from the `SOURCE_READ_TOKEN` secret and skips the
comparison rather than reporting a 404 as drift.

## Validating before publishing

```bash
claude plugin validate .
claude --plugin-dir . # load it without installing
```

`claude plugin validate` catches malformed YAML in a skill's frontmatter and nothing
else — it does not read `marketplace.json` and does not check that a field is one the
runtime recognizes. The workflow in `.github/workflows/validate.yml` covers the
manifests, the skill declarations, and the vendored copies.
