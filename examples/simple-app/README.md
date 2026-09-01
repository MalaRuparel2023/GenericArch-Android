# examples/simple-app

A single-module app — the smallest thing the framework can usefully govern.

**Status: not built yet.** This directory holds the specification; the Gradle project follows once
the convention plugins are packaged as an included build.

## What it will demonstrate

| | |
|---|---|
| Modules | `:app` only |
| Convention plugins | `genericarch.android.application`, `genericarch.android.compose`, `genericarch.android.test` |
| Screens | one list screen with **every** content state — idle, loading, empty, offline, error, loaded |
| Tests | one screenshot test per state, one ViewModel unit test per state, all JVM |
| Checks | `androidArchCheck.sh` passes clean |

## Why a single-module example exists at all

Most teams meet a framework like this one with a one-module app and a deadline. If the smallest case
needs three modules before anything works, the framework does not get adopted — it gets a wiki page
and a shrug. `simple-app` is the proof that the rules bind at any size, and that the module split is
a response to growth rather than a prerequisite for starting.
