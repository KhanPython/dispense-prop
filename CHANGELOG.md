# Changelog

## 5.1.0

### Fixed

- `OnSpawn` no longer has its changes silently clobbered. Engine setup (`PivotTo`, `CanTouch`, `CanQuery`, `CanCollide`, `Anchored`, `CollisionGroup`) now runs **before** `OnSpawn`, so user code has the final say (e.g. spawning anchored).
- Attracted props now preserve their current rotation instead of snapping to identity rotation when attraction begins - props that were tumbling during the `AttractDelay` window no longer visibly jerk upright when pulled.
- `bulkParts` / `bulkCFrames` no longer hold stale references to destroyed props across frames where no attractions occur - tail-cleanup now runs unconditionally.
- `OnAllRemoved` no longer fires on failed `Start` calls where zero props were successfully spawned.
- `OnAllRemoved` now uses the same delivery path in both the success and rollback flows (previously `pcall` in one path, `task.defer` in the other).
- Renamed `PropManager.Defaults.ClearMagnitude` → `PropManager.Defaults.RemoveMagnitude` to match the public settings key. The old key was silently unused.
- Fixed misleading error message when `OnSpawn` forgets to set `.Parent` - now explicitly mentions missing parent.
- `DynamicNumber` signature in the `5.0.0` changelog note corrected to `(propIndex: number) -> number`.

### Changed

- User callback errors (`OnSpawn`, `OnRemoved`, `OnAllRemoved`) are now surfaced via `warn` with a full traceback instead of being silently swallowed.
- `resolveDynamic` now warns when a user function returns a non-number before falling back to the default.
- `PropManager.Defaults` is now `table.freeze`'d - it was never a supported customization hook.
- Exported new types `Defaults` and `PropManagerImpl`; the module now returns a typed handle so callers get proper inference on `Start` and `Defaults`.

### Performance

- `update()` early-returns when there are no active props, skipping per-frame profiling and loop overhead.
- Target pivot positions are cached per-frame, cutting `GetPivot()` calls when multiple props share a target.
- `Property.SetProperty` rewritten: dropped the redundant `HasProperty` check and per-call closures, and now skips non-`BasePart` descendants entirely (Attachments, Welds, ParticleEmitters, etc.).
- `Start` rollback is now a single-pass descending walk, eliminating the intermediate `rollback` array allocation.
