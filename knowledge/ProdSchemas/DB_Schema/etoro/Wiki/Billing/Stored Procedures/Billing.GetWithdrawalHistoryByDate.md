# Billing.GetWithdrawalHistoryByDate

> Returns a customer's withdrawal history since @FromDate (optionally filtered by @WithdrawID) with approval metadata: most recent non-default approval reason, approval date, and rejection count - part of the PaymentHistoryAPI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FromDate (+ optional @WithdrawID); returns one row per withdrawal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawalHistoryByDate is part of the PaymentHistoryAPI. It returns a customer's withdrawal requests since a given date, enriched with approval workflow metadata from BackOffice.WithdrawApproval. The caller uses this to display the customer's withdrawal history in their account dashboard or for support queries.

Two CTEs assemble the approval metadata:
1. **WithdrawApprovalReasonId**: Finds the most recent approval action with a reason other than 7 (reason 7 appears to be the "no specific reason" or "pending" sentinel). This surfaces the actual reason a withdrawal was rejected or requires action.
2. **WithdrawalApprovalDate**: Aggregates all approval actions per withdrawal - the last action date (`maxOccurred`) and count of rejections (`cnt` = actions where Approved=0).

`OPTION (RECOMPILE)` forces per-call plan recompilation to handle the optional @WithdrawID parameter pattern (`ISNULL(@WithdrawID, 0) = 0 OR ...`) without plan cache pollution from parameter sniffing.

Created: Idan Feilhardt, 30 Jul 2014.

---

## 2. Business Logic

### 2.1 Most Recent Non-Default Approval Reason (CTE 1)

**What**: Finds the most recent WithdrawApprovalReasonID (excluding reason 7) for each withdrawal.

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval.WithdrawID`, `BackOffice.WithdrawApproval.WithdrawApprovalReasonID`, `BackOffice.WithdrawApproval.Occurred`

**Rules**:
- `ROW_NUMBER() OVER(PARTITION BY WithdrawID ORDER BY Occurred DESC)` ranks actions newest-first
- `WHERE WithdrawApprovalReasonID != 7` - excludes reason 7 (sentinel for "no specific reason")
- Main query joins with `wari.rn = 1` to get the newest non-7 reason
- `ISNULL(wari.WithdrawApprovalReasonID, 7)` in the main SELECT: defaults to 7 if no non-7 reason exists (all actions were reason 7, or no actions at all)

### 2.2 Approval Summary Aggregation (CTE 2)

**What**: Aggregates approval actions to get the last action date and rejection count.

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval.Approved`, `BackOffice.WithdrawApproval.Occurred`, `WithdrawalApprovalDate.cnt`, `WithdrawalApprovalDate.maxOccurred`

**Rules**:
- `MAX(Occurred)` AS `maxOccurred` - most recent approval action date for this withdrawal
- `SUM(IIF(Approved=0, 1, 0))` AS `cnt` - count of rejection events (Approved=0 = rejected)
- `NullIf(wad.cnt, 0)` in main SELECT: returns NULL instead of 0 for withdrawals with no rejections
- Uses WITH (NOLOCK) on WithdrawApproval in CTE 2 (not in CTE 1 - potential inconsistency)

### 2.3 Optional WithdrawID Filter

**What**: Allows the procedure to return either all withdrawals for a CID or a single specific withdrawal.

**Columns/Parameters Involved**: `@WithdrawID`, `Billing.Withdraw.WithdrawID`

**Rules**:
- `AND (ISNULL(@WithdrawID, 0) = 0 OR BWDR.WithdrawID = @WithdrawID)`
- When @WithdrawID is NULL (default): all withdrawals matching CID + date filter
- When @WithdrawID is specified: only that specific withdrawal
- `OPTION (RECOMPILE)` forces plan recompile to avoid parameter sniffing issues with this optional filter

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Billing.Withdraw to this customer's withdrawals. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Lower bound for RequestDate (exclusive: `>`). Withdrawals requested after this date are returned. |
| 3 | @WithdrawID | INT | YES | NULL | CODE-BACKED | Optional filter. If specified, returns only that specific withdrawal. If NULL, returns all qualifying withdrawals for the CID since @FromDate. |
| - | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal request from Billing.Withdraw. |
| - | OperationType | VARCHAR | NO | 'Withdraw' | CODE-BACKED | Hardcoded literal 'Withdraw'. Allows callers to distinguish withdrawal rows in unified payment history result sets. |
| - | RequestDate | DATETIME | YES | - | CODE-BACKED | Date the withdrawal was requested by the customer. From Billing.Withdraw.RequestDate. |
| - | Amount | DECIMAL | YES | - | CODE-BACKED | Withdrawal amount requested. From Billing.Withdraw.Amount. |
| - | CashoutStatusID | INT | YES | - | CODE-BACKED | Current status of the cashout process. From Billing.Withdraw.CashoutStatusID. |
| - | Fee | DECIMAL | YES | - | CODE-BACKED | Fee charged for the withdrawal. From Billing.Withdraw.Fee. |
| - | ManagerID | INT | YES | - | CODE-BACKED | ID of the manager who last acted on the withdrawal approval. From Billing.Withdraw (via approval join). |
| - | Approved | BIT | YES | - | CODE-BACKED | Current approval status of the withdrawal. From Billing.Withdraw. |
| - | CountWithdrawApprovals | INT | YES | - | CODE-BACKED | Count of rejection events (Approved=0) from BackOffice.WithdrawApproval. NULL if no rejections (NullIf(cnt, 0)). |
| - | WithdrawApprovalReasonID | INT | NO | 7 | CODE-BACKED | Most recent non-default approval reason ID. From BackOffice.WithdrawApproval excluding reason 7. Defaults to 7 if no specific reason recorded. Reason 7 = pending/no specific reason. |
| - | WithdrawalApprovalDate | DATETIME | YES | - | CODE-BACKED | Date of the most recent approval action from BackOffice.WithdrawApproval (MAX Occurred). NULL if no approval actions exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, WithdrawID, RequestDate, Amount, CashoutStatusID, Fee, ManagerID, Approved | Billing.Withdraw | SELECT | Source of withdrawal records; filtered by CID + RequestDate + optional WithdrawID |
| WithdrawID, WithdrawApprovalReasonID, Occurred, Approved | BackOffice.WithdrawApproval | CTE (twice) | CTE 1: most recent non-7 reason; CTE 2: last date + rejection count |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PaymentHistoryAPI | @CID, @FromDate | EXEC | Customer-facing withdrawal history for account dashboard and support |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawalHistoryByDate (procedure)
+-- Billing.Withdraw (table) [withdrawal records]
+-- BackOffice.WithdrawApproval (table) [approval reason + date + rejection count]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Source of withdrawal data; filtered by CID, RequestDate, optional WithdrawID |
| BackOffice.WithdrawApproval | Table | Two CTEs: most recent approval reason (excluding 7) + aggregate approval date and rejection count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PaymentHistoryAPI | External | Customer withdrawal history endpoint (referenced in DDL comment) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Performance | Forces per-call recompile to handle optional @WithdrawID parameter without parameter sniffing cache issues |
| WithdrawApprovalReasonID=7 sentinel | Business rule | Reason 7 is treated as the default/no-reason state; excluded from CTE 1 to surface meaningful reasons |
| NOLOCK inconsistency | Technical | CTE 2 uses NOLOCK on WithdrawApproval; CTE 1 does NOT - minor inconsistency in read isolation |
| RequestDate > @FromDate | Design | Exclusive lower bound (not >=); withdrawals on exactly @FromDate are excluded |

---

## 8. Sample Queries

### 8.1 Get all withdrawals for a customer since a date

```sql
EXEC [Billing].[GetWithdrawalHistoryByDate]
    @CID = 12345,
    @FromDate = '2026-01-01',
    @WithdrawID = NULL
-- Returns all withdrawals since 2026-01-01 with approval metadata
```

### 8.2 Get a specific withdrawal with its approval history

```sql
EXEC [Billing].[GetWithdrawalHistoryByDate]
    @CID = 12345,
    @FromDate = '2020-01-01',  -- far past to ensure match
    @WithdrawID = 999          -- specific withdrawal
```

### 8.3 Check pending withdrawals with rejections

```sql
SELECT w.WithdrawID, w.RequestDate, w.Amount, wa.cnt AS RejectionCount
FROM [Billing].[Withdraw] w WITH (NOLOCK)
LEFT JOIN (
    SELECT WithdrawID, SUM(IIF(Approved=0,1,0)) AS cnt
    FROM [BackOffice].[WithdrawApproval] WITH (NOLOCK)
    GROUP BY WithdrawID
) wa ON wa.WithdrawID = w.WithdrawID
WHERE w.CID = 12345
  AND wa.cnt > 0
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "MIMOPSB-929- Approval dependencies on etoro db" (/spaces/MG) - references withdrawal approval workflow and BackOffice.WithdrawApproval dependencies relevant to this procedure.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (MIMOPSB-929) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawalHistoryByDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawalHistoryByDate.sql*
