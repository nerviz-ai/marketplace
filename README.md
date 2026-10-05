# Nerviz · marketplace

Delivery vehicle for [Nerviz](https://github.com/nerviz-ai/nerviz).
It ships **one skill**, `/arch-adopt`, and nothing else.

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

## What this repository does not carry

The norms, the development skills, the agents and the hook are **not** vendored here.
`/arch-adopt` fetches them from the source repository at adopt time, so there is one
source of truth and no per-release copy to keep in sync. What is vendored is the skill
itself — a plugin cannot fetch its own skill before it runs — and `.plugin-source.json`
records where that copy came from. CI fails if it has drifted.

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
