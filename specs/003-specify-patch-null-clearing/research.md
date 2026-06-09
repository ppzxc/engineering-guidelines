# Research: PATCH updateMask Null-Clearing Behavior

This document records the research and key architectural decisions regarding the data clearing (nulling) behavior of PATCH requests using an updateMask in API designs.

## Key Decisions

### Decision 1: Implicit Field Clearing for Omitted Fields in UpdateMask
* **Decision**: If a field is specified in the `updateMask` but omitted (missing) from the Request Body payload, the server must clear that field (set to null or its default value).
* **Rationale**: This fully aligns with the **Google AIP-134** specification: *"If the update mask contains a field, but that field is missing from the request payload, the server must clear that field."* It provides a clean, native way to clear fields without forcing clients to pass explicit nulls in JSON (which some client frameworks omit by default).
* **Alternatives Considered**: 
  * *Option A (Ignore missing fields)*: Rejected because it deviates from the AIP-134 standard and makes it harder for some clients to perform field clearing.
  * *Option B (Fail the request)*: Rejected as it restricts client flexibility.

### Decision 2: Nested Object Clearing via Dot Notation
* **Decision**: Support dot notation (e.g., `profile.bio`) in the `updateMask` to allow granular, selective clearing of nested fields within structured objects.
* **Rationale**: Very common in real-world scenarios where clients need to clear a sub-field (e.g., `bio`) without clearing or re-sending the parent object (e.g., `profile` with `website`). Dot notation provides maximum efficiency and safety.
* **Alternatives Considered**:
  * *Option B (Top-level only)*: Rejected because it forces clients to download, modify, and re-upload the entire nested structure, which is prone to race conditions and wastes bandwidth.

### Decision 3: Fail Request on Invalid Mask Paths
* **Decision**: If the `updateMask` contains any path that does not map to a valid field in the resource schema, the server must immediately reject the request and return a `400 Bad Request` (INVALID_ARGUMENT).
* **Rationale**: AIP-134 standard behavior: *"If the update mask contains an invalid path, the request fails with a 400 Bad Request."* It prevents silent failures and helps client developers catch spelling mistakes or schema drift instantly (Fail-Fast).
* **Alternatives Considered**:
  * *Option A (Ignore invalid paths)*: Rejected because it hides client implementation bugs and leads to confusing behaviors.

## References
- [Google API Design Patterns - AIP-134: Update Methods](https://google.aip.dev/134)
