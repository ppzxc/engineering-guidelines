# Data Model & Schema: PATCH updateMask Null-Clearing

This document defines the schema structures and logical behavior model for PATCH requests using an updateMask, facilitating standard data-clearing operations.

## Data Structures

### 1. PATCH Request Format
A standard partial update request payload consists of two elements:
- **Request Body (Resource)**: A JSON representation of the resource containing the fields to update or clear.
- **Update Mask (`updateMask`)**: A query parameter containing a comma-separated list of field paths (using dot notation for nesting) indicating which fields are targets for modification.

```json
{
  "updateMask": "name,profile.bio,profile.website",
  "resource": {
    "name": "Alice",
    "profile": {
      "bio": null
    }
  }
}
```

### 2. Behavioral Logic Matrix

Given a field path `F` specified in the `updateMask`:

| Body Payload State of `F` | Server Execution Behavior | Outcome on Resource |
|:---|:---|:---|
| Present with Non-Null Value (`"F": "value"`) | Update with new value | `F` becomes `"value"` |
| Present with Null Value (`"F": null`) | Clear the field | `F` becomes `null` or is removed |
| Absent (Omitted from JSON body) | Clear the field (AIP-134 standard) | `F` becomes `null` or default |

Given a field path `G` **NOT** specified in the `updateMask`:

| Body Payload State of `G` | Server Execution Behavior | Outcome on Resource |
|:---|:---|:---|
| Present (Any value or null) | Completely ignore | `G` remains unchanged |
| Absent | Completely ignore | `G` remains unchanged |

Given a field path `X` in `updateMask` that is **INVALID** (does not exist in schema):

| State of `X` | Server Execution Behavior | Outcome on Resource |
|:---|:---|:---|
| Any state | Reject request immediately | `400 Bad Request` (INVALID_ARGUMENT) |
