# Billing.DepositBCK_FixMatchingTool

> Historical backup table from a December 2011 one-time deposit matching fix - preserves DepositIDs and before/after timestamps for deposits that were deleted and re-inserted to correct matching errors.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no indexes) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

`Billing.DepositBCK_FixMatchingTool` is a historical backup/audit table created during a one-time data correction operation in December 2011. The "BCK" suffix indicates it was a backup before destructive changes; "FixMatchingTool" indicates it was produced by a tool that fixed deposit-to-payment matching errors.

The table records the 5,879 DepositIDs that went through the fix operation, along with two timestamps that bracket each fix: `ModificationDate_DEL` (when the original deposit was deleted) and `ModificationDate_Ins` (typically 1-2 seconds later, when the corrected deposit was re-inserted). The consistent 1-2 second gap between DEL and Ins timestamps confirms this was an automated batch delete-then-reinsert operation.

All data is from 2011 (DepositIDs up to 718,669). The table has no code consumers and no constraints - it is purely a historical audit artifact. It has not received new rows in over 14 years and is not relevant to current operations.

---

## 2. Business Logic

No business logic. This is a static audit snapshot from 2011. No procedures read or write to it.

### 2.1 Fix Operation Pattern (Historical)

**What**: The table preserved DepositIDs before a delete-and-reinsert fix cycle to enable rollback verification.

**Columns/Parameters Involved**: `DepositID`, `ModificationDate_DEL`, `ModificationDate_Ins`

**Rules** (historical, inferred from data):
- Each row represents one deposit processed by the FixMatchingTool.
- `ModificationDate_DEL`: timestamp when the deposit was deleted from `Billing.Deposit` during the fix.
- `ModificationDate_Ins`: timestamp when the corrected deposit was re-inserted (consistently 1-2 seconds after DEL).
- The fix ran in batches from May through December 2011, with the bulk of activity in December 2011.
- No deduplication or ordering enforced (no PK, no UNIQUE constraint).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 5,879 |
| ModificationDate_DEL range | 2011-12-07 to 2011-12-24 |
| ModificationDate_Ins range | 2011-05-31 to 2011-12-24 |
| Max DepositID seen | 718,669 |
| DEL-to-Ins gap | ~1-2 seconds (automated operation) |

All data is from 2011. No new rows since December 2011.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | int | YES | - | CODE-BACKED | Identifier of the deposit that was processed by the matching fix. Implicit reference to Billing.Deposit.DepositID (no FK constraint). All IDs are from early eToro history (up to 718,669). NULL-allowed but no NULL rows observed. |
| 2 | ModificationDate_DEL | datetime | YES | - | CODE-BACKED | UTC timestamp when the original deposit record was deleted from Billing.Deposit during the fix operation. Ranges from 2011-12-07 to 2011-12-24. NULL-allowed but no NULL rows observed. |
| 3 | ModificationDate_Ins | datetime | YES | - | CODE-BACKED | UTC timestamp when the corrected deposit was re-inserted into Billing.Deposit after the fix. Consistently 1-2 seconds after ModificationDate_DEL, confirming an automated delete-reinsert pattern. Ranges from 2011-05-31 to 2011-12-24 (the earlier May dates likely reflect the original deposit insert dates in some rows). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit (historical) | Records DepositIDs from Billing.Deposit that were processed by the fix. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

No current code consumers. This table is not referenced by any stored procedure, view, or function in the Billing schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints, no computed columns).

### 6.2 Objects That Depend On This

None.

---

## 7. Technical Details

### 7.1 Indexes

None. No PK, no clustered index, no nonclustered indexes.

### 7.2 Constraints

None. All columns are nullable. No PK, no UNIQUE, no DEFAULT, no CHECK constraints.

---

## 8. Sample Queries

### 8.1 View most recent fix operations

```sql
SELECT TOP 10 DepositID, ModificationDate_DEL, ModificationDate_Ins,
    DATEDIFF(MILLISECOND, ModificationDate_DEL, ModificationDate_Ins) AS DelToInsMs
FROM [Billing].[DepositBCK_FixMatchingTool] WITH (NOLOCK)
ORDER BY ModificationDate_DEL DESC;
```

### 8.2 Check if a specific DepositID was part of the fix

```sql
SELECT DepositID, ModificationDate_DEL, ModificationDate_Ins
FROM [Billing].[DepositBCK_FixMatchingTool] WITH (NOLOCK)
WHERE DepositID = @DepositID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 8/10, Logic: 5/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositBCK_FixMatchingTool | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DepositBCK_FixMatchingTool.sql*
