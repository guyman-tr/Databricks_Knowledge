# Dictionary.AuthenticationReasonPOI

> Lookup table for Proof of Identity (POI) specific document authentication reasons. Exists in SSDT but **not deployed to the live database** — likely replaced by the unified Dictionary.AuthenticationReason table.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AuthenticationReasonPOI was designed to hold authentication reasons specific to Proof of Identity (POI) documents — a subset of KYC document types including passports, national IDs, and driver's licenses. The structure mirrors Dictionary.AuthenticationReason exactly (ReasonID + Reason columns).

**Important**: This table exists in the SSDT project but is **not deployed to the live database** (MCP query returns "Invalid object name"). This strongly suggests the table was either deprecated in favor of the unified Dictionary.AuthenticationReason table (which already covers POI-specific reasons like "Faces Do Not Match", "Face Was Not Detected", etc.) or was never fully implemented.

The SSDT file references it in BackOffice.GetDocumentAuthenticationReasons (JUNK-marked procedures), suggesting it was part of a refactoring effort that consolidated POI-specific and general reasons into a single table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Table is not deployed to production.

---

## 3. Data Overview

**Not deployed to live database.** MCP query returns: "Invalid object name 'Dictionary.AuthenticationReasonPOI'".

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | CODE-BACKED | Primary key for POI-specific authentication reason. Same structure as Dictionary.AuthenticationReason.ReasonID. Table not deployed — likely consolidated into the main AuthenticationReason table. |
| 2 | Reason | varchar(50) | YES | - | CODE-BACKED | Human-readable POI authentication reason description. Same structure as Dictionary.AuthenticationReason.Reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetDocumentAuthenticationReasons (JUNK) | ReasonID | JOIN | Legacy/deprecated procedure reference |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No active dependents found. Referenced only by JUNK-marked procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AuthenticationReason | CLUSTERED PK | ReasonID ASC | - | - | Active (DDL only — not deployed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AuthenticationReason | PRIMARY KEY | Unique reason identifier (FILLFACTOR 90) |

---

## 8. Sample Queries

### 8.1 Check if table exists (deployment verification)
```sql
SELECT  OBJECT_ID('Dictionary.AuthenticationReasonPOI') AS ObjectID;
```

### 8.2 Query from unified reason table instead
```sql
SELECT  ReasonID,
        Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
WHERE   Reason LIKE '%Face%'
   OR   Reason LIKE '%POI%'
ORDER BY ReasonID;
```

### 8.3 DDL-only reference
```sql
-- Table not deployed to live DB
-- Use Dictionary.AuthenticationReason for POI reasons
SELECT  ReasonID, Reason
FROM    Dictionary.AuthenticationReason WITH (NOLOCK)
WHERE   ReasonID IN (32, 47, 48, 51, 52)
ORDER BY ReasonID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AuthenticationReasonPOI | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AuthenticationReasonPOI.sql*
