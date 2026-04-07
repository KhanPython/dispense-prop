# Changelog

## 5.0.0

- Complete recode with Structure of Arrays (SoA) data layout for cache-friendly batch processing
- Replaced `AttractSpeed` with `AttractDuration` using sigmoid easing curve
- Added `DynamicNumber` support - properties accept `number | Vector2 | (propInstance) -> number`
- Batch part movement via `workspace:BulkMoveTo` for reduced overhead
- O(1) swap-remove for prop cleanup instead of table.remove shifting
- OnSpawn errors no longer leak cloned props
