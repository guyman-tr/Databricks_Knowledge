# BackOffice.GetWithdrawIds_DROP

> DEPRECATED - Returns a list of WithdrawIDs for a customer filtered by status. Marked _DROP for deletion. Superseded by BackOffice.GetWithdrawalsByCID which provides this functionality plus full withdrawal details.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @StatusIDs TVP (BackOffice.IDs); returns Billing.Withdraw.WithdrawID only |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawIds_DROP` is a deprecated stored procedure that returns the WithdrawIDs belonging to a customer that match a set of cashout statuses. The `_DROP` suffix in the name is a convention marking the procedure for deletion - it should not be used in new development and active callers should be migrated to `BackOffice.GetWithdrawalsByCID`.

Created in MIMOPS-5246. The procedure performs a simple filtered SELECT returning only primary keys (WithdrawIDs), not the full withdrawal records. This narrow return type suggests it was used to feed into further processing or lookups rather than direct display.

---

## 2. Business Logic

### 2.1 Status Filter via TVP

**What**: Returns WithdrawIDs matching the specified cashout statuses.

**Columns/Parameters Involved**: `@StatusIDs`, `BW.CashoutStatusID`

**Rules**:
- SELECT BW.WithdrawID FROM Billing.Withdraw WHERE BW.CID = @CID AND CashoutStatusID IN (SELECT ID FROM @StatusIDs)
- @StatusIDs uses BackOffice.IDs UDT (column: ID) - same UDT as GetWithdrawalsByCID
- Unlike GetWithdrawalsByCID, no branching for empty TVP - if @StatusIDs is empty, IN clause returns no rows
- No optional parameters - both @CID and @StatusIDs are required for meaningful results

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve withdrawal IDs for. Required. |
| 2 | @StatusIDs | BackOffice.IDs (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter of CashoutStatusID values to filter on. Uses BackOffice.IDs UDT (column: ID). Empty TVP returns no rows (no branching logic unlike GetWithdrawalsByCID). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (Billing.Withdraw.WithdrawID). Only field returned - no other withdrawal data. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BW.CID = @CID | Billing.Withdraw | Read | Customer's withdrawal records |
| BW.CashoutStatusID | @StatusIDs (BackOffice.IDs) | IN subquery | Status filter |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Deprecated - no active callers expected) | @CID | Application | Previously used to fetch withdrawal ID lists for downstream processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawIds_DROP (procedure) [DEPRECATED]
├── Billing.Withdraw (table)
└── BackOffice.IDs (user defined type - TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT WithdrawID with CID + status filter |
| BackOffice.IDs | User Defined Type | @StatusIDs TVP type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Deprecated - marked for deletion. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| _DROP naming convention | Lifecycle | The `_DROP` suffix is a team convention marking this procedure for deletion. Do not use in new development. Migrate any remaining callers to BackOffice.GetWithdrawalsByCID. |
| Empty TVP returns 0 rows | Behavior | Unlike GetWithdrawalsByCID which branches to return all statuses when @StatusIDs is empty, this procedure returns nothing for empty TVP (IN (SELECT ID FROM @StatusIDs) = IN (empty set) = false). |
| ID-only output | Design | Returns only WithdrawID, not full withdrawal data. Callers needing data must issue additional queries per ID. GetWithdrawalsByCID should be preferred as it returns full data in one call. |

---

## 8. Sample Queries

### 8.1 Get pending withdrawal IDs for a customer (CashoutStatusID 1 and 2)
```sql
DECLARE @StatusIDs BackOffice.IDs
INSERT INTO @StatusIDs VALUES (1), (2)
EXEC [BackOffice].[GetWithdrawIds_DROP]
    @CID = 123456,
    @StatusIDs = @StatusIDs
-- NOTE: This procedure is deprecated. Use GetWithdrawalsByCID instead.
```

### 8.2 Replacement using GetWithdrawalsByCID
```sql
DECLARE @StatusIDs BackOffice.IDs
INSERT INTO @StatusIDs VALUES (1), (2)
EXEC [BackOffice].[GetWithdrawalsByCID]
    @CustomerID = 123456,
    @WithdrawalID = NULL,
    @FromDate = NULL,
    @StatusIDs = @StatusIDs
-- Returns full withdrawal data including WithdrawID and 17 other columns
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-5246 | Jira (DDL comment) | Original creation ticket |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPS-5246 from DDL comment) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawIds_DROP | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawIds_DROP.sql*
