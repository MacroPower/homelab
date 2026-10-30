---
name: hass-reconcile
description: Reconcile the homelab repo's Home Assistant config with the live instance at hass.cin.macro.network. It diffs both ways (task hass:plan for the registry state, task hass:diff for the YAML), imports what the live instance has and git lacks into home/hass/state.k without overwriting hand edits, settles conflicts with the user, and applies the remaining git-side changes after the user approves. Use it whenever the user wants to sync, reconcile, or check drift between Home Assistant and the repo, pull UI changes into git, adopt new devices, areas, apps, integrations, or HACS repositories into state.k, or push home/hass changes to the live instance, even when they do not say "reconcile".
---

# Hass Reconcile

The repo declares Home Assistant (HA) in two parts, which `docs/hass.md` describes:

- **YAML config:** `home/hass/main.k` renders through `haconfig/` into a config directory. Nothing deploys it yet, because the delivery is an open decision (see the Delivery section of `docs/hass.md`).
- **Registry state:** `home/hass/state.k` declares floors, areas, labels, categories, device, entity, and integration settings, apps, HACS repositories, and the HTTP config. The `hastate` engine plans and applies it over HA's WebSocket API.

A reconcile runs five steps: diff, find what git lacks, import it and settle conflicts, apply, and report. Each step says what it runs and why.

## Questions

Call AskUserQuestion every time the reconcile needs the user's input. That covers a choice between git and live, an approval, a missing prerequisite, and an offer of extra work. Do not ask in plain chat and end the turn. The dialog keeps the reconcile going in one turn. It also returns an answer that you can act on, so you never guess what a free-text reply meant. When one option is the safe or usual choice, still ask, and mark that option as the recommendation.

Write each question so that it stands on its own, because the user might see only the dialog:

- Name the object and the values, such as `areas.office: floor "ground" in git, "upstairs" in HA`.
- Put the recommended option first and end its label with `(Recommended)`.
- Use `multiSelect` for a list of independent items, such as which live objects to import.
- Use the option `preview` to show a diff or a plan excerpt when the choice depends on it.

One call holds up to four questions, and each question offers two to four options. The user can always answer with their own text. When more than four decisions are pending, ask them over several calls, grouped by collection, and act on each batch before you ask the next. When a list holds more than four items, first ask whether to take them all, none, or pick, and then offer the items four at a time.

## Ground Rules

- **Approval:** run `task hass:apply` only after the user approves the exact final plan in this session through AskUserQuestion. `CLAUDE.md` requires this, and an approval of an earlier plan does not carry over to a changed one.
- **Hand edits:** never write an import over `home/hass/state.k`. The file holds comments, ordering, `tags.secret()` calls, and options that an import cannot reproduce. Import into the scratchpad and copy blocks from there.
- **Secrets:** the repo is public. Never write a secret value into it. Each app's comment names the options that the import left out. To manage one of them, write `tags.secret("<name>")`, declare the name in `HomeAssistant.secrets` in `home/hass/main.k` with a fake value, and ask the user to put the real value in the Pi's `secrets.yaml`. Hardware details, such as MAC addresses and device paths, are fine to commit.
- **SSH:** do not read `~/.ssh` or the SSH agent. `task hass:diff` uses SSH by itself.
- **Token:** the state tasks need `HASS_TOKEN`. When it is unset, ask whether the user wants to stop and rerun with the token, for example under `doppler run -p <project> -c <config> --`, or to continue with the YAML diff only.

## 1. Diff

Run `task hass:plan`. It renders `home/hass`, writes `.cache/hass/home/hass/state.json`, and prints each change with a symbol:

| Symbol | Meaning | Resolution |
| --- | --- | --- |
| `+` | git declares it, and live lacks it | ask whether to create it in HA or delete it from git |
| `~` | both hold it, and fields differ | ask which side wins |
| `-` | git prunes it | ask for a separate confirmation of the delete |
| `?` | live holds it in a collection that git manages, and git lacks it | ask which items to import |
| `!` | git declares an integration that HA lacks | ask whether to keep it, so the user adds it in the UI, or to remove it from git |

The plan also prints problems, which block the apply, and warnings. Fix each problem in `state.k` before step 4. When a fix needs a choice, such as which of two objects keeps a name, ask.

Run `task hass:diff` for the YAML. It reads the Pi over SSH and prints a `git diff` from the live config to the render. When SSH fails, ask whether to continue with the state only or to stop while the user fixes SSH. The YAML has no apply path, so this step only reports. A file or a key that only the Pi holds, such as a hand-written package, can move into KCL under `home/hass/`. Ask which of those to port, with `multiSelect`, and port only the ones the user picks.

## 2. Find What Git Lacks

The plan's `?` lines cover only the collections that git owns object by object. Git manages only the devices, entities, and app options that it declares, so the plan never lists a new device setting or an undeclared app option. The bundled script finds those too:

```sh
task hass:import OUT=<scratchpad>/reconcile/live.k FORCE=1
uv run .claude/skills/hass-reconcile/scripts/missing.py --repo . \
  --import <scratchpad>/reconcile/live.k --state .cache/hass/home/hass/state.json
```

Use an absolute scratchpad path for `OUT`. The script renders the import and prints JSON:

- `missing`: each live object that git lacks, with `import_key`, the key that `live.k` uses for it.
- `fields`: each object that both hold, with the fields that live sets and git does not declare, by their KCL names, such as `options.log_level`.
- `collections`: each collection that live holds and git leaves unset. Git does not manage these.
- `unmatched`: each git object that the script cannot compare, such as an entity that git renames through `match`. Check it against the plan by hand.

## 3. Import and Settle

Ask which `missing` objects and `fields` entries to import, one question per collection, with importing all of them as the recommendation. Skip a pending rename from the plan, which shows up as a `missing` entity under its old id. For each item the user picks, copy its block from `live.k` into the same map in `state.k`, with the comment lines above it, or add the field lines to the existing object. Keep the order and comments that `state.k` already has.

Ask about each collection in `collections` before you adopt it, because git then manages that whole collection, and a later `prune` can delete objects in it.

Ask which side wins for each `~` change, with one question per object and the two values in the options. When live wins, copy the field values from `live.k` into `state.k`. When git wins, leave `state.k` as it is, and the apply changes HA.

A `+` object is either a new object in git or one that HA lost. When `git log -S '<key>' -- home/hass/state.k` shows an older commit that holds it, HA lost it after that commit, usually through the UI, so recommend deleting it from git. When only recent edits hold it, recommend creating it in HA. Ask in both cases.

When the import left out an option that holds a secret, and the user wants git to manage it, ask for the secret's name, and follow the Secrets rule.

After the edits, run `task hass:gate`, which `CLAUDE.md` requires after any change under `home/hass/`, and then `task hass:plan` again. The new plan must hold only the changes that the user chose to push. A `?` line that remains means that `state.k` still lacks a block.

## 4. Apply

When the plan shows no changes, skip this step.

Otherwise, ask for approval with AskUserQuestion, and put the final plan in the option preview. Offer `Apply`, `Apply and restart HA` when the plan downloads HACS integration code, and `Do not apply`. Name the changes that have side effects in the question:

- Each `-` delete. An app uninstall deletes the app's data, and a label delete removes the label from every device and entity.
- An `http` change. It restarts HA.
- A HACS download of integration code. HA loads it only after a restart.

After the user approves, run `task hass:apply YES=1`, with `RESTART=1` when the user chose the restart. The Bash tool has no terminal, so the task cannot ask for confirmation itself, and `YES=1` stands in for the approval that the user gave in the dialog. The apply plans again when it finishes and exits 1 when changes remain. When a step fails, the steps before it stay applied. Run `task hass:plan` again, and ask whether to retry, fix `state.k`, or stop.

## 5. Report

Tell the user:

- what you imported into `state.k`, by collection.
- what the apply changed, or that it did not run.
- what the YAML diff showed and that it is not deployed.
- what is left, such as a missing integration, a secret to add on the Pi, or an `unmatched` object.

Then ask whether to commit `home/hass/state.k` with the `commit` skill, with `Commit`, `Commit and push`, and `Leave uncommitted` as the options. Push only when the user picks it.
