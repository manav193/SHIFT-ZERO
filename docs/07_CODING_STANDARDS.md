# 07 — Coding Standards & Naming Conventions

These are enforceable rules. CI fails on violations. When a rule conflicts with common sense in a specific case, add an inline `# STYLE: exempt because …` comment and document it in an ADR if the exemption is architectural.

## 1. Languages

- **GDScript 2.0** — primary. Static typing everywhere it is possible.
- **C# (.NET 8)** — allowed only in modules explicitly listed as C# in the TDD.
- **Shaders** — Godot Shader Language.
- **Config / data** — `.tres` (Godot Resource), `.json`, `.csv`. No YAML.

## 2. GDScript Rules

### 2.1 Typing

- Every parameter and return type is typed:

  ```gdscript
  func spawn_obstacle(pattern: ObstaclePattern, at: Vector2) -> Node2D:
      ...
  ```

- No untyped `var`. Local vars use inferred typing (`var x := 0`) but the type must be unambiguous.
- Prefer typed arrays: `Array[Modifier]` not `Array`.

### 2.2 Class declarations

- Every script that is instantiable declares a `class_name`:

  ```gdscript
  class_name ModifierManager
  extends Node
  ```

- Only one class per file.
- File name is the `snake_case` version of the class name.

### 2.3 Ordering inside a file

1. `class_name` + `extends`
2. `## Docstring` describing responsibility
3. `signal` declarations (with typed params)
4. `enum` declarations
5. `const` declarations
6. `@export` variables
7. Private `var` declarations
8. `_init()`, `_ready()`, other lifecycle callbacks
9. Public methods
10. Private methods (prefix `_`)

### 2.4 Naming

| Kind | Convention | Example |
|---|---|---|
| File / folder | `snake_case` | `modifier_manager.gd` |
| `class_name` | `PascalCase` | `ModifierManager` |
| Function | `snake_case` | `apply_modifier` |
| Private function | `_snake_case` | `_recompute_pool` |
| Variable | `snake_case` | `current_score` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_STACK` |
| Signal | past-tense `snake_case` | `modifier_activated` |
| Enum type | `PascalCase` | `enum ModifierTag` |
| Enum values | `SCREAMING_SNAKE_CASE` | `GRAVITY, TIME, VISUAL` |
| Node in scene | `PascalCase` | `PlayerController`, `HUDRoot` |
| Autoload | `PascalCase` | `EventBus`, `Logger` |

### 2.5 Signals

- Signals are always past-tense: something *happened*.
- All signal parameters are typed.
- Prefer channel-based EventBus over point-to-point signals for cross-system communication.

### 2.6 Functions

- Guideline: ≤ 50 lines, ≤ 5 parameters. Refactor if larger.
- Public functions have a `## docstring` if their name is not self-explanatory.
- Side effects belong in functions named as verbs (`apply_`, `emit_`, `save_`), pure functions as nouns or `get_/compute_`.

### 2.7 Comments & TODOs

- Comments explain **why**, not **what**.
- `TODO:` must include an owner and a ticket reference: `TODO(rk, #142): handle offline retry`.
- No commented-out code — delete it, Git remembers.

### 2.8 Error handling

- Public methods on Services return `Result<T>`. No exceptions across layers.
- `assert(...)` for invariants that must hold in dev; strip in release via a `dev_only` macro pattern.
- Never silently swallow errors — report via `push_warning`/`push_error`.

### 2.9 Nulls

- `Node` fields default to `null` and are asserted non-null in `_ready`.
- Public APIs never return `null` where a `Result` or a sentinel Resource would be clearer.

## 3. C# Rules (when used)

- Follow standard .NET conventions: `PascalCase` for types/methods/properties, `camelCase` for locals/params.
- One type per file. File name = type name.
- Nullable reference types **on**. `warnaserror` for `CS860*` nullable warnings.
- `async` methods end with `Async`.
- No LINQ in hot paths. Prefer `for` loops on inner-loop code.

## 4. Shader Rules

- One shader per file, `.gdshader`.
- Uniforms grouped: `// uniforms: color`, `// uniforms: motion`.
- No branching on per-fragment uniforms; use `mix()` / `step()`.
- Every shader has a fallback flag `low_end_disable` — if the device is on the low tier, the material swaps to a fallback shader.

## 5. Resource (.tres) Rules

- All `.tres` are text (not binary) — diffable in Git.
- Every custom `Resource` subclass has an `@export_group` around related fields.
- Never store computed / cached fields in `.tres` — mark them `@export_storage = false` or compute at load.

## 6. Scene (.tscn) Rules

- Root node name = `PascalCase` matching the file's core purpose (`MainMenu`, `Player`).
- One responsibility per scene. If a scene has more than ~30 child nodes at the top level, split it.
- Never hardcode absolute paths — use scene-local `NodePath` and `@onready`.

## 7. Layer Dependency Rule (enforced by CI)

`scripts/check_layer_deps.py` scans `preload(...)` and `load(...)` calls:

- `core/` may reference: nothing except Godot built-ins.
- `services/` may reference: `core/`.
- `systems/` may reference: `core/`, `services/`.
- `gameplay/` may reference: `core/`, `services/`, `systems/`.
- `presentation/` may reference: any lower layer.
- **Same-layer references are allowed** but discouraged; prefer EventBus.
- Any violation fails PR.

## 8. Formatting

- Indentation: **tabs** (Godot native).
- Line length target 100, hard cap 120.
- One blank line between top-level members, two between logical sections.
- No trailing whitespace.
- LF endings (`.gitattributes` enforced).
- `gdlint` on CI.

## 9. Git Conventions

### 9.1 Branches

- `main` — always shippable.
- `feat/<short-slug>` — features.
- `fix/<short-slug>` — bug fixes.
- `chore/<short-slug>` — infra, CI, docs.
- `hotfix/<version>-<slug>` — patches against a shipped tag.

### 9.2 Commits

Conventional Commits: `type(scope): summary`.

Examples:
- `feat(modifier): add magnetic walls modifier`
- `fix(save): handle checksum mismatch on primary slot`
- `perf(spawner): pool obstacle nodes`
- `chore(ci): add perf gate workflow`

### 9.3 PRs

- Description references the ticket + a "why" paragraph + a screenshot/gif for UI changes.
- Requires: green CI (lint + tests + perf gate), 1 reviewer, no `TODO(no-owner)`.
- Squash merge only. `main` stays linear.

### 9.4 Tags & releases

- `v1.0.0`, `v1.0.1`, `v1.1.0-beta.1`. SemVer strict. See `13_VERSIONING_STRATEGY.md`.

## 10. Documentation Rules

- Every `services/*` module has a top-of-file `##` docstring stating the interface contract.
- Every ADR follows the template in `docs/decisions/_template.md`.
- Public APIs get inline docstrings usable by the Godot editor's hover tooltips.

## 11. Testing Rules

- Every new file in `services/` or `gameplay/modifiers/` ships with at least one test.
- Tests live in `tests/unit/` mirroring the source tree.
- Test names: `test_<action>_<expected_result>`.
- No sleep-based flakiness — use fake `TimeSource` in tests.

## 12. Forbidden Patterns

- ❌ `get_tree().root.get_node("/root/…")` navigation across layers. Use ServiceLocator or exported node refs.
- ❌ Global mutable singletons other than approved autoloads.
- ❌ String-typed magic constants — use `const` in a dedicated file per domain.
- ❌ Direct calls to `AdMob.show_...()` from gameplay — must go through `IAdsService`.
- ❌ `print()` in production paths. Use `Logger`.
- ❌ Reading files with hardcoded paths — always route via `Config` or `ResourceLoader`.

## 13. Style-guide Exceptions

Any exception:
1. Inline comment `# STYLE: exempt <rule-id> because <reason>`.
2. If systemic → an ADR in `docs/decisions/`.
