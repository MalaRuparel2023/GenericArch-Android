# docs/patterns/ — procedures not yet worth a skill

A pattern is a repeatable procedure written down. It becomes a **skill** only when it is invoked
often enough that the always-on context cost of its description is worth paying — a skill costs
context every session, a doc costs nothing until it is read. `/learn` promotes one.

Candidates that usually stay patterns: adding a locale · wrapping a new vendor SDK · adding a Room
migration · introducing a new flavour · regenerating screenshot goldens after a design-token change.

## Template

```markdown
# <Pattern name>

**When** the trigger, in the words someone would use.
**Prerequisites** what must already be true.
**Steps** numbered, each one verifiable.
**Verify** the command or check that proves it landed.
**Traps** what has gone wrong before.
```

Every pattern gets a `MAP.tsv` row in the same change.
