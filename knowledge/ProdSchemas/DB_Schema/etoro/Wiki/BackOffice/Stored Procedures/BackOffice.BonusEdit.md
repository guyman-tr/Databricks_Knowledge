# BackOffice.BonusEdit

> Updates an existing bonus type's properties in BackOffice.BonusType, returning the SQL error code (0 = success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BonusTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the update path for BackOffice.BonusType catalog entries. It allows BackOffice administrators to modify an existing bonus type's classification hierarchy (ParentID), internal name, XML configuration, withdrawability flag, and active status.

BonusEdit is the counterpart to BonusAdd: BonusAdd creates new types, BonusEdit modifies them. Typical use cases include deactivating a deprecated bonus program (IsActive=0), reclassifying a type under a different department parent, or updating the configuration XML for parameterized bonus types.

Note: BonusEdit does NOT update HideFromAffwiz, DisplayName, or IsDepositRelated - these fields must be updated through direct data changes or other procedures if needed. The return value is @@ERROR (0=success, non-zero=SQL error code), unlike BonusAdd which returns the new ID.

---

## 2. Business Logic

### 2.1 Bonus Type Property Update

**What**: Updates 5 fields of an existing bonus type identified by BonusTypeID.

**Columns/Parameters Involved**: `@BonusTypeID`, `@ParentID`, `@Name`, `@Configuration`, `@IsWithdrawable`, `@IsActive`

**Rules**:
- UPDATE is unconditional - all 5 editable fields are overwritten with supplied values every time (no partial updates)
- No existence check on @BonusTypeID - if the ID does not exist, the UPDATE affects 0 rows silently (no error)
- ParentID FK still enforced - passing an invalid @ParentID causes FK violation (FK_BBNT_BBNT on BackOffice.BonusType)
- Returns @@ERROR as the proc return value (0=no error, non-zero=SQL error code) - NOT @@ROWCOUNT
- Columns NOT updated: HideFromAffwiz, DisplayName, IsDepositRelated (these retain their existing values)
- No transaction - single-statement UPDATE is atomic

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BonusTypeID | INTEGER | NO | - | VERIFIED | PK of the bonus type to update. If no row exists with this ID, the UPDATE silently affects 0 rows (no error returned). |
| 2 | @ParentID | INTEGER | NO | - | VERIFIED | New department-level parent BonusTypeID. Must reference an existing BonusTypeID (FK_BBNT_BBNT enforced). Use to reclassify the type under a different department root (e.g., move from 3=Custom to 8=Accounting/Ops). |
| 3 | @Name | VARCHAR(50) | NO | - | VERIFIED | New internal name for BackOffice staff identification. Overwrites the existing Name. Indexed (BBNT_NAME). Not the customer-facing label (DisplayName is not updated by this procedure). |
| 4 | @Configuration | XML | YES | - | CODE-BACKED | New XML configuration for parameterized bonus types. Pass NULL for standard types. Only BonusTypeID=2 uses non-NULL configuration in production. |
| 5 | @IsWithdrawable | BIT | NO | - | CODE-BACKED | Updated withdrawability flag. Currently 0 (false) for all active types in production. Overwritten unconditionally. |
| 6 | @IsActive | BIT | NO | - | CODE-BACKED | New active status. Pass 0 to deactivate a deprecated bonus type (prevents new grants of this type). Pass 1 to re-activate. Overwritten unconditionally. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | RETURN | INT | NO | - | CODE-BACKED | @@ERROR value after the UPDATE - 0 = success, non-zero = SQL error code. Callers must check RETURN_VALUE to detect failures. Unlike BonusAdd, no result set is returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BonusTypeID | BackOffice.BonusType | MODIFIER | UPDATE target - modifies the existing bonus type record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called by BackOffice admins to modify bonus type properties |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusEdit (procedure)
+-- BackOffice.BonusType (table) [UPDATE target; FK_BBNT_BBNT enforced on @ParentID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | UPDATE target; @ParentID FK still enforced |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Calls to modify bonus type properties (rename, deactivate, reclassify) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| FK_BBNT_BBNT (on table) | Referential Integrity | @ParentID must reference a valid BonusTypeID or FK violation occurs |
| Silent no-op on missing ID | Design | If @BonusTypeID does not exist, UPDATE affects 0 rows and @@ERROR=0 (no error signaled) |
| Partial field coverage | Design | HideFromAffwiz, DisplayName, IsDepositRelated are NOT updated - callers must use other means if these fields need changing |
| RETURN @@ERROR | Design | Returns SQL error code, not row count. 0=success, non-zero=error. |

---

## 8. Sample Queries

### 8.1 Deactivate a deprecated bonus type

```sql
DECLARE @rc INT
EXEC @rc = BackOffice.BonusEdit
    @BonusTypeID = 17,          -- 17 = Refill - Negative Balance (deprecated)
    @ParentID = 8,              -- keep under Accounting / Ops
    @Name = 'Refill - Negative Balance',
    @Configuration = NULL,
    @IsWithdrawable = 0,
    @IsActive = 0               -- deactivate
IF @rc <> 0
    PRINT 'BonusEdit failed with error: ' + CAST(@rc AS VARCHAR)
```

### 8.2 Rename an existing bonus type

```sql
EXEC BackOffice.BonusEdit
    @BonusTypeID = 13,          -- 13 = Satisfaction Bonus (under 8=Accounting/Ops)
    @ParentID = 8,
    @Name = 'Customer Satisfaction Credit',
    @Configuration = NULL,
    @IsWithdrawable = 0,
    @IsActive = 1
```

### 8.3 Verify the update was applied

```sql
SELECT BonusTypeID, ParentID, Name, IsActive, HideFromAffwiz, DisplayName
FROM BackOffice.BonusType WITH (NOLOCK)
WHERE BonusTypeID = 13
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BonusEdit.sql*
