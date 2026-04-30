# Dictionary.AuthenticationReasonSelfie

> Lookup table for selfie-specific document authentication reasons during biometric verification. Exists in SSDT but **not deployed to the live database** — likely replaced by the unified Dictionary.AuthenticationReason table.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AuthenticationReasonSelfie was designed to hold authentication reasons specific to selfie/biometric verification — the step where a customer's live photo is compared against their identity document. The structure mirrors Dictionary.AuthenticationReason exactly (ReasonID + Reason columns).

**Important**: This table exists in the SSDT project but is **not deployed to the live database** (MCP query returns "Invalid object name"). Similar to Dictionary.AuthenticationReasonPOI, this table was likely deprecated in favor of the unified Dictionary.AuthenticationReason table, which already contains selfie-specific reasons (e.g., ReasonID 47="Faces Do Not Match", 48="Indecisive", 50="Over Match", 51="Face Was Not Detected On POI", 52="Forged Selfie", 103="Fake Webcam", 104="Emulator", 105="Liveliness Not Detected", 106="Spoofing").

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Table is not deployed to production.

---

## 3. Data Overview

**Not deployed to live database.** MCP query returns: "Invalid object name 'Dictionary.AuthenticationReasonSelfie'".

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | CODE-BACKED | Primary key for selfie-specific authentication reason. Same structure as Dictionary.AuthenticationReason.ReasonID. Table not deployed — selfie reasons consolidated into the main AuthenticationReason table (IDs 47-52, 103-106). |
| 2 | Reason | varchar(50) | YES | - | CODE-BACKED | Human-readable selfie authentication reason. Same structure as Dictionary.AuthenticationReason.Reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active procedure references found.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AuthenticationReasonSelfie | CLUSTERED PK | ReasonID ASC | - | - | Active (DDL only — not deployed, FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AuthenticationReasonSelfie | PRIMARY KEY | Unique reason identifier |

---

## 8. Sample Queries

### 8.1 Check if table exists (deployment verification)
```sql
SELECT  OBJECT_ID('Dictionary.AuthenticationReasonSelfie') AS ObjectID;
```

### 8.2 Query selfie reasons from unified table
```sql
SELECT  ReasonID,
        Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
WHERE   Reason LIKE '%Selfie%'
   OR   Reason LIKE '%Face%'
   OR   Reason LIKE '%Webcam%'
   OR   Reason LIKE '%Emulator%'
   OR   Reason LIKE '%Spoofing%'
   OR   Reason LIKE '%Liveliness%'
ORDER BY ReasonID;
```

### 8.3 DDL-only reference
```sql
-- Table not deployed to live DB
-- Use Dictionary.AuthenticationReason for selfie reasons (IDs 47-52, 103-106)
SELECT  ReasonID, Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
WHERE   ReasonID IN (47, 48, 50, 51, 52, 103, 104, 105, 106)
ORDER BY ReasonID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AuthenticationReasonSelfie | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AuthenticationReasonSelfie.sql*
