# BackOffice.JUNK_BonusDelete

> Deletes a bonus type by ID, but only if it is not linked to any campaign and has never been used in credit history. Raises error 60023 if either guard fails.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BonusTypeID; deletes from BackOffice.BonusType with safety guards |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`JUNK_BonusDelete` is a guarded deletion procedure for removing bonus type definitions from `BackOffice.BonusType`. The `JUNK_` prefix indicates this procedure is considered deprecated or non-production ("junk") - it was likely used during an earlier phase of the bonus management system and retained for reference or occasional manual use.

Despite the JUNK prefix, the procedure enforces two important data integrity rules before deleting:
1. The bonus type must not be referenced by any active campaign (`BackOffice.CampaignToBonusType`)
2. The bonus type must never have been applied in credit history (`History.Credit`)

If either rule is violated, the procedure raises error number 60023 with a descriptive message and returns without deleting. This prevents orphaning of campaign-bonus linkages and breaking of historical credit records.

The business context: bonus types define the classification of promotional credits given to customers (e.g., welcome bonus, reactivation bonus). These are referenced from marketing campaigns and from the actual credit grants in History.Credit. Deleting a bonus type in use would corrupt these references.

---

## 2. Business Logic

### 2.1 Safety Guard: Campaign Linkage Check

**What**: Prevents deletion if the bonus type is still assigned to at least one campaign.

**Columns/Parameters Involved**: `@BonusTypeID`, `BackOffice.CampaignToBonusType.BonusTypeID`

**Rules**:
- `IF EXISTS (SELECT * FROM BackOffice.CampaignToBonusType WHERE BonusTypeID = @BonusTypeID)`
- If TRUE: `RAISERROR(60023, 16, 1, 'bonus', @BonusTypeID, 'the bonus linked to campaign')` then `RETURN 60023`
- The error message communicates: "this bonus is still linked to a campaign and cannot be deleted"

### 2.2 Safety Guard: Historical Credit Usage Check

**What**: Prevents deletion if the bonus type has ever been granted to a customer in credit history.

**Columns/Parameters Involved**: `@BonusTypeID`, `History.Credit.BonusTypeID`

**Rules**:
- `IF EXISTS (SELECT * FROM History.Credit WHERE BonusTypeID = @BonusTypeID)`
- If TRUE: `RAISERROR(60023, 16, 1, 'bonus', @BonusTypeID, 'the bonus was used')` then `RETURN 60023`
- The error message communicates: "this bonus has been issued to customers and cannot be deleted"

### 2.3 Deletion

**What**: Deletes the bonus type record if both guards pass.

**Rules**:
- `DELETE FROM BackOffice.BonusType WHERE BonusTypeID = @BonusTypeID`
- `RETURN @@ERROR` - returns 0 on success, SQL error code on failure

**Diagram**:
```
@BonusTypeID
  |
  v
EXISTS in CampaignToBonusType? -> YES -> RAISERROR(60023) + RETURN 60023
  |
  NO
  |
  v
EXISTS in History.Credit?      -> YES -> RAISERROR(60023) + RETURN 60023
  |
  NO
  |
  v
DELETE FROM BackOffice.BonusType
RETURN @@ERROR
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BonusTypeID | INTEGER | NO | - | CODE-BACKED | ID of the bonus type to delete from `BackOffice.BonusType`. Must not be referenced by `BackOffice.CampaignToBonusType` or `History.Credit` - both are checked before deletion proceeds. |

**Output**: No result set. Returns an INT via RETURN statement: 0 = success, 60023 = guard violation (bonus in use), other non-zero = SQL error.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BonusTypeID | BackOffice.CampaignToBonusType | Guard check (EXISTS) | Prevents delete if bonus is still linked to a campaign |
| @BonusTypeID | History.Credit | Guard check (EXISTS) | Prevents delete if bonus was ever used in credit history |
| @BonusTypeID | BackOffice.BonusType | Writer (DELETE) | Deletes the bonus type record if guards pass |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_BonusDelete (procedure)
├── BackOffice.CampaignToBonusType (table) [EXISTS guard]
├── History.Credit (table) [EXISTS guard]
└── BackOffice.BonusType (table) [DELETE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | EXISTS guard: is bonus linked to any campaign? |
| History.Credit | Table | EXISTS guard: has bonus ever been granted to a customer? |
| BackOffice.BonusType | Table | DELETE target if both guards pass |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | JUNK - deprecated, called manually if needed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| RAISERROR(60023, 16, 1, ...) | Error code | Custom error 60023 = "object in use, cannot delete". Severity 16 = user error. |
| RETURN @@ERROR | Return convention | Returns 0 on success; non-zero on SQL error. Callers must check RETURN value. |
| No TRY/CATCH | Design | Errors propagate to caller; caller is responsible for handling the RETURN 60023 |
| JUNK_ prefix | Naming convention | Marks procedure as deprecated / not actively maintained |

---

## 8. Sample Queries

### 8.1 Delete a bonus type (caller must handle return code)

```sql
DECLARE @ReturnCode INT;
EXEC @ReturnCode = [BackOffice].[JUNK_BonusDelete] @BonusTypeID = 42;

IF @ReturnCode = 60023
    PRINT 'Cannot delete: bonus is in use (linked to campaign or used in credit history)'
ELSE IF @ReturnCode = 0
    PRINT 'Bonus type deleted successfully'
ELSE
    PRINT 'Unexpected error: ' + CAST(@ReturnCode AS VARCHAR);
```

### 8.2 Check if a bonus type is safe to delete

```sql
SELECT
    bt.BonusTypeID,
    bt.BonusTypeName,
    CASE WHEN EXISTS (SELECT 1 FROM BackOffice.CampaignToBonusType cbt WHERE cbt.BonusTypeID = bt.BonusTypeID)
         THEN 'Linked to campaign' ELSE 'No campaign link' END AS CampaignStatus,
    CASE WHEN EXISTS (SELECT 1 FROM History.Credit hc WHERE hc.BonusTypeID = bt.BonusTypeID)
         THEN 'Used in credit history' ELSE 'Never used' END AS UsageStatus
FROM BackOffice.BonusType bt WITH (NOLOCK)
WHERE bt.BonusTypeID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_BonusDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.JUNK_BonusDelete.sql*
