# .claude/notes/ — generated inventories

**Searched, never read.** If you had to read one in full, the row was not self-contained — fix the
row, not the reader.

Eleven inventories, generated from an adopting repo's own code by `androidArchSyncNotes`. Nine are
generated outright; `FEATURES.md` and `STYLE-GUIDE.md` are reviewer-gated and say so inside
themselves.

| Note | Generated from |
|---|---|
| `PROJECT.md` | `androidArchDoctor` — AGP, Gradle, Kotlin, KSP, JDK, SDKs, Compose BOM, flavours, build types, signing |
| `MODULE-GRAPH.md` | Gradle's project dependency model, plus a Mermaid diagram |
| `NAVIGATION.md` | `@Serializable` route classes + `NavHost` destinations |
| `API-MAP.md` | Retrofit interface annotations, or Ktor request builders |
| `ASSETS-COLORS.md` | `res/values*/colors.xml` + Compose `Color(0x…)` literals, flagging any outside the theme |
| `FONTS.md` | `res/font/`, `FontFamily` declarations |
| `STRINGS.md` | Every `strings.xml` across locales, **with a parity matrix** |
| `PERMISSIONS.md` | Merged manifest — permissions, exported components, deep links, `autoVerify` |
| `VARIANTS.md` | Flavours × build types × signing configs × `buildConfigField`s × placeholders |
| `FEATURES.md` | Module list + screens + states — **needs a reviewer** |
| `STYLE-GUIDE.md` | DesignSystem tokens + components — **needs a reviewer** |

## Rules

- A generated block carries its own caveat **inside it**, and a `Last synced` line.
- **Edit the affected rows in the same change** as the insertion or deletion. A full rescan is
  `/sync-app-notes` — the user's call, never started unprompted.
- Nothing here is hand-written. If you are tempted to hand-write a row, the generator has a gap.

**This repo has no Kotlin, so it generates none of these.** See `docs/GAPS.md` row 4.
