# Apex.GetUserParametersUpdatesMask

> Retrieves the cumulative pending update bitmask for a customer from UserParameters, indicating which data fields have pending changes not yet sent to Apex Clearing.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns UpdatesMask |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetUserParametersUpdatesMask retrieves the pending data change bitmask for a customer. The application reads this mask to determine which Apex API update calls need to be made. Each bit in the mask corresponds to a specific user data field (using Dictionary.UserDataUpdatesMask values). A mask of 0 or no row means no pending changes.

---

## 2. Business Logic

No complex business logic. Simple SELECT UpdatesMask by GCID. Note: does NOT use NOLOCK - reads with shared locks for consistency.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to check for pending updates. |

**Returns**: UpdatesMask (int) from Apex.UserParameters. See [User Data Updates Mask](_glossary.md#user-data-updates-mask) for bitmask values.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserParameters | Read | Retrieves UpdatesMask by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetUserParametersUpdatesMask (procedure)
└── Apex.UserParameters (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserParameters | Table | Read UpdatesMask by GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check pending updates for a customer

```sql
EXEC Apex.GetUserParametersUpdatesMask @GCID = 85152;
-- Returns UpdatesMask = 0 (no pending changes)
```

### 8.2 Verify mask after a data change

```sql
EXEC Apex.GetUserParametersUpdatesMask @GCID = 12345;
-- If address changed: UpdatesMask includes 128 (HomeAddress bit)
```

### 8.3 Non-existent customer

```sql
EXEC Apex.GetUserParametersUpdatesMask @GCID = 999999;
-- Empty result if no UserParameters record
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetUserParametersUpdatesMask | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetUserParametersUpdatesMask.sql*
