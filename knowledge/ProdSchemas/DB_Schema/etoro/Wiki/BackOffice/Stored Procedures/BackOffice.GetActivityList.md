# BackOffice.GetActivityList

> Returns the complete financial activity timeline for a customer - all cash credits, debits, and position-linked events within a date range, formatted for BackOffice display.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer identifier; returns result set of financial activity rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetActivityList` produces a human-readable financial statement for a single customer, covering all credit/debit events recorded in `History.CreditWithFee` within a configurable time window (defaults to the last 3 months). Each row represents one financial event - a deposit, withdrawal, position open/close, dividend, compensation, bonus, or fee - enriched with contextual labels, the responsible manager's name, and whether associated positions were CFD or real stock.

This procedure is the backbone of the "Activity" tab in the BackOffice customer view. Operations staff use it to understand what happened to a customer's balance over time: which transactions came in, which went out, which manager performed actions, and which specific entities (DepositID, WithdrawID, PositionID, MirrorID) are involved.

The data flows from `History.CreditWithFee` (the permanent financial ledger) through multiple lookup enrichments: `Dictionary.CreditType` for human labels, `BackOffice.Manager` for staff attribution, `BackOffice.BonusType` and `BackOffice.CompensationReason` for BackOffice-initiated entries, and `History.Position` via OUTER APPLY to classify associated positions as CFD or Real.

---

## 2. Business Logic

### 2.1 Transaction Type Labeling and Dividend Subclassification

**What**: Each activity row is assigned a TransactionType label derived from Dictionary.CreditType.Name, with special handling for dividend transactions (CreditTypeID=19).

**Columns/Parameters Involved**: `HCDT.CreditTypeID`, `HCDT.MirrorDividendID`, `DCTP.Name`

**Rules**:
- For CreditTypeID != 19: TransactionType = CreditType.Name (e.g., "Deposit", "Cashout", "Open Position")
- For CreditTypeID = 19 (Mirror balance to account / Dividend):
  - MirrorDividendID = 0 -> TransactionType = "Mirror balance to account (Manual)"
  - MirrorDividendID > 0 -> TransactionType = "Mirror balance to account (Copy Dividend)"
  - MirrorDividendID NULL -> TransactionType = "Mirror balance to account" (no suffix)
- CreditTypeID 32 (Reverse Deposit) and 33 (Cashout Rollback) were added in Aug/Sep 2022 (MIMOPS-3211).

**Diagram**:
```
CreditTypeID = 19 (Mirror balance to account)?
    YES ->
        MirrorDividendID = 0   -> "(Manual)"
        MirrorDividendID > 0   -> "(Copy Dividend)"
        MirrorDividendID NULL  -> ""
    NO  -> CreditType.Name as-is
```

### 2.2 Contextual Details Field by Transaction Category

**What**: The "Details" column surfaces the most relevant linked entity ID depending on transaction type, giving BackOffice staff a direct reference to the source record.

**Columns/Parameters Involved**: `HCDT.CreditTypeID`, `HCDT.DepositID`, `HCDT.WithdrawID`, `HCDT.PositionID`, `HCDT.MirrorID`, `HCDT.Description`, `BOCR.Name`, `BOBT.Name`

**Rules**:
- CreditTypeID IN (1=Deposit, 11=Chargeback, 12=Refund, 16=Refund As ChargeBack, 32=Reverse Deposit) -> "DepositID : {DepositID}"
- CreditTypeID IN (2=Cashout, 8=Reverse cashout, 9=Cashout request, 15=Cashout Fee, 33=Cashout Rollback) -> "Withdraw Id: {WithdrawID}"
- CreditTypeID IN (3=Open Position, 4=Close Position, 13=Edit Stop Loss, 22=Mirror Hierarchical Close, 23=Hierarchical Open, 24=Close by recovery, 25=Open by recovery) -> "Position Id: {PositionID}"
- CreditTypeID IN (18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror) -> "Mirror Id: {MirrorID}"
- CreditTypeID = 6 (Compensation) -> "Compensation Reason: {CompensationReason.Name}"
- CreditTypeID = 7 (Bonus) -> "Credit Type: {BonusType.Name}"
- CreditTypeID = 14 (End Of Week Fee) or default -> History.CreditWithFee.Description

### 2.3 Manager Attribution and User-Initiated Events

**What**: The PerfomedBy (sic) column identifies who performed the action - a BackOffice manager or the customer themselves.

**Columns/Parameters Involved**: `HCDT.ManagerID`, `BMNG.FirstName`, `BMNG.LastName`

**Rules**:
- LEFT JOIN BackOffice.Manager ON ManagerID != 0: ManagerID = 0 is a sentinel for "no manager" (customer or system initiated)
- If manager found: PerfomedBy = "FirstName LastName" (trimmed)
- If no manager (ManagerID=0 or NULL): PerfomedBy = "Initiated By User" (added 2024-02-20 per KateM)

### 2.4 CFD vs Real Classification for Position-Linked Events

**What**: For transactions linked to positions, indicates whether the position was a CFD or a real stock holding.

**Columns/Parameters Involved**: `HCDT.PositionID`, `History.Position.IsSettled`

**Rules**:
- OUTER APPLY to History.Position WHERE PositionID matches AND CID matches
- IsSettled = 0 -> "CFD"
- IsSettled = 1 -> "Real"
- No matching position (non-position transactions) -> "" (empty string)
- Uses temp table with NC index on PositionID for efficient OUTER APPLY lookup.

### 2.5 Date Range Defaults

**What**: @FromDate and @ToDate default to a 3-month rolling window.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `HCDT.Occurred`

**Rules**:
- @FromDate NULL -> DATEADD(MONTH, -3, GETUTCDATE())
- @ToDate NULL -> GETUTCDATE()
- Filter applied as: HCDT.Occurred BETWEEN @FromDate AND @ToDate (inclusive)
- 3-month default added in Jan 2021 (MIMOPS-3219) to prevent unbounded queries.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer Identifier. All returned rows belong to this customer (filters History.CreditWithFee.CID and History.Position.CID). |
| 2 | @FromDate | DATETIME | YES | NULL (3 months ago) | CODE-BACKED | Start of activity window (inclusive). When NULL, defaults to DATEADD(MONTH,-3,GETUTCDATE()). Pass explicit date to extend or narrow the window. |
| 3 | @ToDate | DATETIME | YES | NULL (now) | CODE-BACKED | End of activity window (inclusive). When NULL, defaults to GETUTCDATE(). Pass explicit date for historical snapshots. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer Identifier repeated in output for reference. Same as @CID. |
| 5 | CreditID | INT | NO | - | CODE-BACKED | Primary key of the History.CreditWithFee record. Uniquely identifies this financial event in the ledger. |
| 6 | TransactionType | VARCHAR | NO | - | CODE-BACKED | Human-readable label for the event type, combining Dictionary.CreditType.Name with dividend subclassification. E.g., "Deposit", "Cashout", "Close Position", "Mirror balance to account (Copy Dividend)". |
| 7 | Payment | DECIMAL(16,2) | YES | - | CODE-BACKED | Monetary payment amount for this event, in account currency. CAST from History.CreditWithFee.Payment. Positive = credit to account; negative = debit. |
| 8 | Available Cash | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's available (liquid) cash balance at the moment of this event. From History.CreditWithFee.Credit, cast to DECIMAL(16,2). Running balance snapshot. |
| 9 | PerfomedBy | NVARCHAR | YES | - | CODE-BACKED | Who performed the action: BackOffice manager "FirstName LastName" (from BackOffice.Manager), or "Initiated By User" if ManagerID=0/NULL (customer-initiated or system event). Note: column name has intentional typo from original implementation. |
| 10 | Occurred At | DATETIME | NO | - | CODE-BACKED | Timestamp when the financial event occurred (UTC). Alias of History.CreditWithFee.Occurred. Results ordered DESC by this column. |
| 11 | TotalCashChange | DECIMAL(16,2) | YES | - | CODE-BACKED | Net change to total cash (available + non-available) for this event. From History.CreditWithFee.TotalCashChange. |
| 12 | RealizedEquity | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's realized equity (closed position P&L cumulative) at the moment of this event. From History.CreditWithFee.RealizedEquity. |
| 13 | Bonus Credit (NWA) | DECIMAL(16,2) | YES | - | CODE-BACKED | Bonus credit component (Non-Withdrawable Amount) for this event. From History.CreditWithFee.BonusCredit. Non-zero for bonus and compensation transactions. |
| 14 | Details | VARCHAR | YES | - | CODE-BACKED | Contextual reference: "DepositID: {id}" for deposits/chargebacks/refunds; "Withdraw Id: {id}" for cashouts/fees; "Position Id: {id}" for position events; "Mirror Id: {id}" for mirror events; "Compensation Reason: {name}" for type 6; "Credit Type: {bonusname}" for type 7; History.CreditWithFee.Description for others. |
| 15 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the financial event occurred (UTC). Same value as "Occurred At" - present as a raw column used for ORDER BY. Duplicate of column 10. |
| 16 | PositionID | BIGINT | YES | - | CODE-BACKED | Position identifier linked to this event. Cast to BIGINT from History.CreditWithFee.PositionID. NULL or 0 for non-position events. Used to JOIN to History.Position for "Is Real" classification. |
| 17 | Is Real | VARCHAR | YES | - | CODE-BACKED | Whether the associated position was real stock or CFD: "Real" (History.Position.IsSettled=1), "CFD" (IsSettled=0), or "" (no linked position - deposits, withdrawals, mirror events, fees). Populated via OUTER APPLY to History.Position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / HCDT.CID | History.CreditWithFee | Primary data source | Reads all financial events for the customer in the date range. |
| HCDT.CreditTypeID | Dictionary.CreditType | Lookup (INNER JOIN) | Resolves credit type integer to human-readable Name for TransactionType column. |
| HCDT.BonusTypeID | BackOffice.BonusType | Lookup (LEFT JOIN) | Resolves bonus type for CreditTypeID=7 Details label. |
| HCDT.CompensationReasonID | BackOffice.CompensationReason | Lookup (LEFT JOIN) | Resolves compensation reason for CreditTypeID=6 Details label. |
| HCDT.ManagerID | BackOffice.Manager | Lookup (LEFT JOIN) | Resolves manager ID to first/last name for PerfomedBy column (excludes ManagerID=0). |
| PositionID | History.Position | Lookup (OUTER APPLY) | Reads IsSettled to classify position as CFD or Real. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BOManagementServiceUser (service account grants only - no SQL procedure callers found in repository).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetActivityList (procedure)
├── History.CreditWithFee (table)
├── Dictionary.CreditType (table)
├── BackOffice.BonusType (table)
├── BackOffice.CompensationReason (table)
├── BackOffice.Manager (table)
└── History.Position (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditWithFee | Table | Main data source - all financial events filtered by CID and date range. |
| Dictionary.CreditType | Table | INNER JOIN on CreditTypeID to get transaction type name. |
| BackOffice.BonusType | Table | LEFT JOIN on BonusTypeID for Details label on bonus entries. |
| BackOffice.CompensationReason | Table | LEFT JOIN on CompensationReasonID for Details label on compensation entries. |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID (excluding 0) for PerfomedBy field. |
| History.Position | Table | OUTER APPLY on PositionID+CID to get IsSettled for CFD/Real classification. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | No procedures in the repository call this procedure. Invoked by BOManagementService (external service account). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Internal temp table `#t` is created with a NONCLUSTERED INDEX `#ix_1` on `PositionID` to optimize the OUTER APPLY lookup against History.Position. SET NOCOUNT is not explicitly set; results include row counts.

---

## 8. Sample Queries

### 8.1 Get last 3 months of activity for a customer (default window)
```sql
EXEC BackOffice.GetActivityList @CID = 12345678;
```

### 8.2 Get activity for a specific date range
```sql
EXEC BackOffice.GetActivityList
    @CID = 12345678,
    @FromDate = '2025-01-01',
    @ToDate = '2025-03-31';
```

### 8.3 Equivalent inline query to understand the raw data
```sql
SELECT TOP 20
    HCDT.CID,
    HCDT.CreditID,
    DCTP.Name AS TransactionType,
    HCDT.Payment,
    HCDT.Credit AS AvailableCash,
    ISNULL(BMNG.FirstName + ' ' + BMNG.LastName, 'Initiated By User') AS PerformedBy,
    HCDT.Occurred,
    HCDT.TotalCashChange
FROM History.CreditWithFee HCDT WITH (NOLOCK)
JOIN Dictionary.CreditType DCTP WITH (NOLOCK)
    ON HCDT.CreditTypeID = DCTP.CreditTypeID
LEFT JOIN BackOffice.Manager BMNG WITH (NOLOCK)
    ON BMNG.ManagerID = HCDT.ManagerID AND BMNG.ManagerID != 0
WHERE HCDT.CID = 12345678
ORDER BY HCDT.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2637 | Jira | Original "GetActivityList" redesign - procedure was transformed from a legacy BackOffice query by Ran Sh. in Oct 2020. |
| MIMOPS-3211 | Jira | Added @FromDate and @ToDate parameters (Jan 2021, Shay O.) enabling date-range filtering instead of returning all history. |
| MIMOPS-3219 | Jira | Capped default date range to 3 months to prevent unbounded queries impacting performance (Jan 2021, Shay O.). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 3 Jira (inline refs) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetActivityList | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetActivityList.sql*
