---
description: One lookup for a screen, route, endpoint, string key, colour, drawable or module
argument-hint: <name or partial name>
---

# /find

```bash
./gradlew androidArchFind --q=$ARGUMENTS
```

One command instead of six searches. It looks across screens, `@Serializable` routes, Retrofit/Ktor
endpoints, string keys, colours, drawables and modules, and reports **where it is defined and who
uses it**.

## Before anything else

Run this before scaffolding. If the thing already exists, the work is a *change*, not a *new
feature* — and the `new-feature` skill should stop.

## The other three lookups

```bash
grep -i <topic> .claude/MAP.tsv          # which doc, note or pattern covers a topic
grep -i <topic> .claude/TASKS.tsv        # which task does this, and its contract
./gradlew androidArchFindTask --q="<what you want>"   # rediscover a task by intent
```

`MAP.tsv` is grepped, never read. `.claude/notes/` is searched, never read.
