# BackOffice.ExcludePositionFromStatistics

> UPSERT on History.Position_Extra to flag whether a position should be excluded from statistical calculations.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - the position to flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.ExcludePositionFromStatistics allows BackOffice agents to mark a specific position as excluded from (or included in) statistical reporting. This is typically used to remove anomalous, erroneous, or compensation positions from performance metrics and analytics.

The procedure performs an UPSERT on `History.Position_Extra`: if the position has no extra record yet, one is created with `ExcludeFromStatistics` set and `TotalCompensation=0`; if an extra record already exists, only `ExcludeFromStatistics` is updated. A guard validates that the PositionID actually exists in `History.Position` before proceeding.

Note: The RAISERROR message text incorrectly reads "Billing.ExcludePositionFromStatistics" - this is a copy-paste artifact from a similarly-named billing procedure.

---

## 2. Business Logic

### 2.1 PositionID Existence Guard

**What**: Validates that the PositionID is non-null and exists in History.Position before attempting any write.

**Columns/Parameters Involved**: `@PositionID`, `History.Position`

**Rules**:
- IF @PositionID IS NULL OR NOT EXISTS (SELECT 1 FROM History.Position WHERE PositionID = @PositionID): RAISERROR(60000, 'Billing.ExcludePositionFromStatistics - PositionID not found') + RETURN (note: message text says "Billing." - copy-paste artifact).
- Prevents orphaned records in History.Position_Extra.

### 2.2 UPSERT on History.Position_Extra

**What**: Creates or updates the position's extra metadata row.

**Columns/Parameters Involved**: `@PositionID`, `@ExcludeFromStatistics`, `History.Position_Extra.ExcludeFromStatistics`, `History.Position_Extra.TotalCompensation`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM History.Position_Extra WHERE PositionID = @PositionID):
  - INSERT History.Position_Extra (PositionID, TotalCompensation, ExcludeFromStatistics) VALUES (@PositionID, 0, @ExcludeFromStatistics).
  - TotalCompensation is initialized to 0 on insert (not a parameter - no compensation by default).
- ELSE:
  - UPDATE History.Position_Extra SET ExcludeFromStatistics = @ExcludeFromStatistics WHERE PositionID = @PositionID.
  - Existing TotalCompensation is preserved (only the flag is updated).

**Diagram**:
```
Validate @PositionID exists in History.Position
  IF NOT EXISTS in History.Position_Extra
    -> INSERT (PositionID, TotalCompensation=0, ExcludeFromStatistics)
  ELSE
    -> UPDATE ExcludeFromStatistics only
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to flag. Must exist in History.Position or RAISERROR(60000) is raised. FK to History.Position.PositionID. |
| 2 | @ExcludeFromStatistics | BIT | NO | - | CODE-BACKED | Exclusion flag: 1 = exclude from statistics calculations, 0 = include. Written to History.Position_Extra.ExcludeFromStatistics. On INSERT, TotalCompensation is initialized to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | History.Position | Validator | EXISTS check - confirms position exists before writing. |
| @PositionID | History.Position_Extra | Modifier | UPSERT target - INSERT or UPDATE ExcludeFromStatistics. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice permissions layer | GRANT EXEC | Permission | No SQL-layer callers found. Called by BackOffice agents via UI/API. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ExcludePositionFromStatistics (procedure)
├── History.Position (table) - EXISTS guard
└── History.Position_Extra (table) - UPSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | EXISTS check - validates @PositionID before writing |
| History.Position_Extra | Table | UPSERT - INSERT on first touch, UPDATE ExcludeFromStatistics on subsequent calls |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice agent tooling | External | EXEC - called when flagging positions for statistical exclusion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PositionID guard | Safety | RAISERROR(60000) if @PositionID IS NULL or not in History.Position. |
| TotalCompensation=0 on INSERT | Behavior | New Position_Extra records always start with TotalCompensation=0. Compensation is managed separately. On UPDATE, existing TotalCompensation is preserved. |
| Copy-paste error in RAISERROR message | Bug | Error message reads "Billing.ExcludePositionFromStatistics" - should be "BackOffice.ExcludePositionFromStatistics". Harmless cosmetic issue. |
| No transaction wrapping | Convention | Single UPSERT with no explicit BEGIN TRAN/COMMIT. No @@ERROR check after write. |

---

## 8. Sample Queries

### 8.1 Exclude a position from statistics
```sql
EXEC BackOffice.ExcludePositionFromStatistics
    @PositionID = 123456789,
    @ExcludeFromStatistics = 1
```

### 8.2 Re-include a previously excluded position
```sql
EXEC BackOffice.ExcludePositionFromStatistics
    @PositionID = 123456789,
    @ExcludeFromStatistics = 0
```

### 8.3 Check exclusion status for a position
```sql
SELECT pe.PositionID, pe.ExcludeFromStatistics, pe.TotalCompensation
FROM History.Position_Extra pe WITH (NOLOCK)
WHERE pe.PositionID = 123456789
```

### 8.4 Find all currently excluded positions
```sql
SELECT pe.PositionID, pe.ExcludeFromStatistics, pe.TotalCompensation
FROM History.Position_Extra pe WITH (NOLOCK)
WHERE pe.ExcludeFromStatistics = 1
ORDER BY pe.PositionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ExcludePositionFromStatistics | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ExcludePositionFromStatistics.sql*
