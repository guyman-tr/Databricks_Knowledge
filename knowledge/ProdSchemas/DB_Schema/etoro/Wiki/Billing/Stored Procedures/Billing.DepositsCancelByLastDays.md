# Billing.DepositsCancelByLastDays

> Batch-cancels stale "Processing" deposits for a specific funding type that have not been modified in at least @LastDays days - a cleanup job SP for clearing deposits stuck in intermediate processing state.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit (PaymentStatusID 5->6) + INSERT History.DepositAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositsCancelByLastDays` cancels deposits that have been stuck in Processing status (PaymentStatusID=5) for too long. This is a maintenance/cleanup SP used by scheduled jobs or operations staff to clear out stale deposits for a specific payment method after the applicable processing window has expired.

The @RecordLimit parameter (default 1000) acts as a safety cap to prevent a single execution from cancelling too many deposits at once, making it suitable for incremental cleanup. The oldest deposits (by ModificationDate) are processed first, prioritizing the most stale records.

Unlike `Billing.DepositPendingCancel` which targets Pending (13) deposits by date range, this SP targets Processing (5) deposits by age (last @LastDays days since modification).

---

## 2. Business Logic

### 2.1 Stale Processing Deposit Selection

**What**: Identifies Processing deposits older than @LastDays for the specified funding type.

**Columns/Parameters Involved**: `@FundingTypeID`, `@LastDays`, `@RecordLimit`, `Billing.Deposit.PaymentStatusID`

**Rules**:
- Filter: `PaymentStatusID = 5 (Processing)` AND `FundingTypeID = @FundingTypeID` AND `ModificationDate < DATEADD(DAY, -@LastDays, GETUTCDATE())`.
- `TOP (@RecordLimit)` with `ORDER BY ModificationDate ASC, DepositID ASC` - processes oldest first, caps batch size.
- FundingTypeID resolved via INNER JOIN to Billing.Funding.
- Results stored in temp table `#TargetDeposits (DepositID PRIMARY KEY)`.

### 2.2 Cancellation

**What**: Transitions all collected deposits to Cancelled status.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentStatusID`, `ModificationDate`

**Rules**:
- `SET PaymentStatusID = 6 (Cancelled), ModificationDate = @ModificationDate` for all DepositIDs in #TargetDeposits.
- `@ModificationDate = GETUTCDATE()` captured at start - all rows share the same timestamp.

### 2.3 Audit Trail

**What**: Inserts a cancellation action for each cancelled deposit.

**Rules**:
- `PaymentActionStatusID = 3 (Closed)`, `PaymentActionTypeID = 7 (Cancel)`, `PaymentStatusID = 6 (Cancelled)`.
- No transaction wrapping the UPDATE + INSERT - these two steps run without atomicity guarantee. If the INSERT fails after the UPDATE, deposits would be Cancelled without an audit record.

```
@FundingTypeID + @LastDays + @RecordLimit
  -> SELECT TOP @RecordLimit oldest Processing deposits -> #TargetDeposits
  -> UPDATE Billing.Deposit SET PaymentStatusID=6 for all in #TargetDeposits
  -> INSERT History.DepositAction (ActionStatus=3, ActionType=7, Status=6) for all
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method to target. Only deposits whose Billing.Funding.FundingTypeID matches this value are eligible. Allows selective cleanup per payment method. |
| 2 | @ManagerID | INT | NO | - | CODE-BACKED | Manager ID written to History.DepositAction.ManagerID for each cancellation audit row. Identifies who or what system invoked the cleanup. |
| 3 | @LastDays | INT | NO | - | CODE-BACKED | Minimum age in days (based on ModificationDate). Only deposits with `ModificationDate < NOW - @LastDays` are selected. E.g., @LastDays=7 cancels deposits stuck in Processing for more than 7 days. |
| 4 | @RecordLimit | INT | NO | 1000 | CODE-BACKED | Maximum number of deposits to cancel in one execution. Safety cap to prevent runaway batch. Default 1000. Oldest deposits (by ModificationDate ASC) are processed first when more records exist than the limit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Billing.Funding | JOIN | Resolves FundingTypeID filter from deposit's FundingID. |
| DepositID filter | Billing.Deposit | READ + MODIFIER (UPDATE) | Reads PaymentStatusID=5 + age filter; updates to PaymentStatusID=6. |
| DepositID | History.DepositAction | WRITER (INSERT) | Creates cancellation audit records. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job or manual ops | @FundingTypeID | EXEC | Scheduled cleanup of stale Processing deposits per payment method. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositsCancelByLastDays (procedure)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- History.DepositAction (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Filter + UPDATE target. |
| Billing.Funding | Table | INNER JOIN to resolve FundingTypeID. |
| History.DepositAction | Table (cross-schema) | INSERT cancellation audit records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled cleanup jobs | Job | EXEC with specific FundingTypeID and age threshold. |

---

## 7. Technical Details

**Hardcoded status values**: PaymentStatusID filter=5 (Processing), PaymentStatusID target=6 (Cancelled), PaymentActionStatusID=3 (Closed), PaymentActionTypeID=7 (Cancel).

**No transaction**: The UPDATE and INSERT are not wrapped in BEGIN TRANSACTION/COMMIT. A failure mid-way could leave deposits Cancelled without audit records. Compare with `Billing.DepositPendingCancel` which has transaction wrapping.

---

## 8. Sample Queries

### 8.1 Cancel stale Processing deposits for Plaid (FundingTypeID=29) older than 7 days

```sql
EXEC [Billing].[DepositsCancelByLastDays]
    @FundingTypeID = 29,
    @ManagerID = 0,
    @LastDays = 7,
    @RecordLimit = 500;
```

### 8.2 Preview which deposits would be cancelled

```sql
SELECT TOP 100 d.DepositID, d.CID, d.PaymentStatusID, d.ModificationDate, d.Amount
FROM [Billing].[Deposit] d WITH (NOLOCK)
INNER JOIN [Billing].[Funding] f WITH (NOLOCK) ON f.FundingID = d.FundingID
WHERE d.PaymentStatusID = 5
  AND f.FundingTypeID = 29
  AND d.ModificationDate < DATEADD(DAY, -7, GETUTCDATE())
ORDER BY d.ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositsCancelByLastDays | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositsCancelByLastDays.sql*
