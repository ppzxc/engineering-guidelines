# Quickstart Validation Guide: PATCH updateMask Null-Clearing

This guide defines how to validate that the new RESTful API updateMask and null-clearing guidelines have been correctly implemented and documented in `plugins/guideline/skills/restful-api/SKILL.md`.

## Prerequisites
- The guidelines file must be updated: `plugins/guideline/skills/restful-api/SKILL.md`
- The evaluation test cases file must be updated: `docs/evaluation/test-cases.md` (or equivalent location)

## Validation Scenarios

### Scenario 1: Verify SKILL.md Documentation
Ensure that the new rules are explicitly described under the `PATCH` or `CRUD Behavior` section in `SKILL.md`.

1. **Verify implicit clearing (AIP-134)**:
   - Command: `grep -i "updateMask" plugins/guideline/skills/restful-api/SKILL.md`
   - Expected Output: Sections detailing that fields in `updateMask` but absent in body are cleared.
2. **Verify nested object dot-notation**:
   - Command: `grep -i "dot notation" plugins/guideline/skills/restful-api/SKILL.md` (or "profile.bio")
   - Expected Output: Instructions specifying dot notation support for nested sub-fields.
3. **Verify invalid path errors**:
   - Command: `grep -i "400" plugins/guideline/skills/restful-api/SKILL.md`
   - Expected Output: Documentation specifying that invalid mask paths return `400 Bad Request`.

### Scenario 2: Verify Test Cases Mapping
Check that the evaluation test cases cover these scenarios:
1. `TC-patch-clear-implicit`: Field specified in mask but omitted in body is cleared.
2. `TC-patch-clear-nested`: Nested dot-notation sub-field clearing.
3. `TC-patch-clear-invalid`: Invalid path returning 400.
