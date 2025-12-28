# Edge Cases and Improvements

This document outlines the edge cases that have been addressed and improvements made to the Prop Dispenser system.

## Edge Cases Addressed

### 1. Invalid Amount Parameter
**Issue:** The system accepted `amount` values of 0 or negative numbers, which could lead to unexpected behavior.

**Solution:** Added validation to ensure `amount >= 1` in the assertion check.

```lua
assert(
    typeof(amount) == "number" and amount % 1 == 0 and amount >= 1,
    "`amount` must be an integer number greater than or equal to 1"
)
```

### 2. Target Instance Destruction
**Issue:** If the target instance is destroyed while props are active, the system would error when trying to access `target:GetPivot()`.

**Solution:** Added a check at the beginning of `updateProp()` to validate the target still exists before processing:

```lua
-- Check if target instance still exists
if not target or not target:IsDescendantOf(game) then
    PropManager:_RemoveProp(prop)
    if settings.OnRemoved and typeof(settings.OnRemoved) == "function" then
        settings.OnRemoved(true)
    end
    return
end
```

### 3. Invalid Target Instance at Start
**Issue:** Target instance could be passed but not be part of the game hierarchy, leading to errors during runtime.

**Solution:** Added validation in the `Start()` function:

```lua
assert(targetInstance:IsDescendantOf(game), "`targetInstance` must be a descendant of game")
```

### 4. Zero Distance Vector Normalization
**Issue:** When a prop gets extremely close to the target (distance ≈ 0), attempting to normalize the direction vector with `.Unit` could cause issues or unnecessary calculations.

**Solution:** Added a distance threshold check before calculating direction:

```lua
-- Safety check: ensure distance is not too small to prevent division issues
if distance > 0.001 then
    local direction = distanceVector.Unit
    local moveDistance = math.min((settings.AttractSpeed or PropManager.Defaults.AttractSpeed) * dT, distance)
    local newPosition = propPosition + direction * moveDistance
    prop:PivotTo(CFrame.new(newPosition, targetPosition))
end
```

### 5. Naming Inconsistency
**Issue:** The defaults table used `ClearMagnitude` while the settings parameter used `RemoveMagnitude`, causing confusion.

**Solution:** Renamed `ClearMagnitude` to `RemoveMagnitude` in the defaults table for consistency:

```lua
PropManager.Defaults = {
    RemoveMagnitude = 5,  -- Previously ClearMagnitude
    AttractSpeed = 10,
    AttractDelay = 1,
    CollisionGroup = "Default",
}
```

## Additional Edge Cases to Consider

While the following edge cases exist, they are either by design or would require significant architectural changes:

### 1. Memory Leaks from Orphaned Groups
**Scenario:** If all props in a group are removed but the group table remains in `ActiveProps`.

**Current Behavior:** The `AncestryChanged` connection handles cleanup when props are destroyed, and the group is cleaned up when all props are removed.

**Recommendation:** Monitor for edge cases where groups might not be properly cleaned up in production use.

### 2. Performance with Large Prop Counts
**Scenario:** Spawning hundreds or thousands of props simultaneously.

**Current Behavior:** System uses `Heartbeat` for updates, which runs on every frame. Large numbers of props could impact performance.

**Recommendation:** Consider implementing object pooling or batch processing for large-scale prop management if needed. This is noted in the "Non-goals" section of the README.

### 3. Concurrent Start() Calls
**Scenario:** Multiple calls to `Start()` with overlapping or same instances.

**Current Behavior:** Each call creates a separate group with unique GUID, so they operate independently.

**Recommendation:** This is working as intended, but users should be aware that multiple groups can exist simultaneously.

### 4. PropTemplate Destruction During Cloning
**Scenario:** The `propTemplate` instance is destroyed between validation and cloning.

**Current Behavior:** The clone operation would fail and error.

**Recommendation:** This is an acceptable edge case as it represents misuse of the API. The pcall wrapper in `Start()` handles this gracefully.

### 5. Callback Function Errors
**Scenario:** User-provided callbacks (OnSpawn, OnRemoved, OnAllRemoved) throw errors.

**Current Behavior:** 
- `OnSpawn` errors are caught with pcall and result in prop removal
- Other callbacks are called without pcall protection

**Recommendation:** Current behavior is acceptable, but users should ensure callbacks don't yield or error. This is documented in the README.

## Best Practices for Users

1. **Validate Instances:** Always ensure target instances exist and are properly parented before calling `Start()`.

2. **Avoid Yielding:** Don't yield in callbacks, especially `OnRemoved` and `OnAllRemoved`, as documented.

3. **Handle Cleanup:** If you need to stop prop management before all props are removed, manually destroy the target instance to trigger cleanup.

4. **Test Edge Cases:** Test your implementation with edge cases like:
   - Destroying the target mid-operation
   - Very small or very large RemoveMagnitude/AttractMagnitude values
   - Props that fail to spawn (OnSpawn errors)

5. **Monitor Performance:** Keep prop counts reasonable (per the non-goals section) and monitor frame rates when spawning many props.

## Code Quality Improvements

1. **Fixed typo in README:** "Imporant" → "Important"
2. **Improved code clarity:** Separated distance vector calculation from magnitude for better readability and reuse
3. **Enhanced error messages:** All assertions provide clear, actionable error messages
4. **Consistent naming:** Aligned default values with documented parameter names
