# Trade.MirrorsStopLossToBeCompensatedByPercentageDiff

> Identifies mirrors that closed due to Mirror Stop Loss (MSL) but whose actual close amount fell below the MSL threshold by more than the allowed tolerance, generating a compensation candidate report ordered by shortfall (largest first).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate + @AllowedDiffPercentage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MirrorsStopLossToBeCompensatedByPercentageDiff is a compensation-identification report for eToro's CopyTrader. When a mirror triggers its Mirror Stop Loss (MSL), the customer expects to receive back the MSL-configured amount. In practice, due to market slippage or execution delays, the actual close amount (Trade.Mirror.Amount at close time) may be less than the MSL threshold (MirrorSL). This procedure finds mirrors where that shortfall exceeds a configurable tolerance percentage.

For example, if a mirror had MirrorSL=1000 (expected payout at stop-loss) and actually closed at Amount=940 with @AllowedDiffPercentage=3%, the allowed tolerance is 30 (3% of 1000). Since 1000-940=60 > 30, this mirror qualifies as a compensation candidate. The report shows the shortfall (Compensation), total customer investment, and contact details for remediation.

Data flows: executed ad-hoc by BI/operations teams (PROD_BIadmins has permission). No SP callers - pure reporting query.

---

## 2. Business Logic

### 2.1 MSL-Triggered Close Identification

**What**: Filters History.Mirror to rows representing MSL-triggered mirror closures within the specified date range.

**Columns/Parameters Involved**: `History.Mirror.MirrorOperationID`, `History.Mirror.CloseMirrorActionType`, `History.Mirror.ModificationDate`, `@StartDate`, `@EndDate`

**Rules**:
- MirrorOperationID=2: mirror close (close-type history entry from Dictionary.MirrorOperation).
- CloseMirrorActionType=1: MSL-triggered close (from Dictionary.CloseMirrorActionType; 1=MirrorStopLoss).
- ModificationDate >= @StartDate AND <= @EndDate: date range filter (@EndDate defaults to GETUTCDATE() if NULL).
- Only rows that are both a "close" operation AND specifically MSL-triggered qualify.

**Diagram**:
```
History.Mirror
  WHERE MirrorOperationID = 2         (Close)
    AND CloseMirrorActionType = 1      (MSL-triggered)
    AND ModificationDate IN [Start, End]
    AND Amount < MirrorSL - (AllowedDiffPercentage/100 * MirrorSL)
```

### 2.2 Tolerance-Based Shortfall Filter

**What**: Excludes mirrors whose close amount was within the acceptable tolerance of the MSL level.

**Columns/Parameters Involved**: `History.Mirror.Amount`, `History.Mirror.MirrorSL`, `@AllowedDiffPercentage`

**Rules**:
- CalculatedAllowedDiff = (AllowedDiffPercentage/100) * MirrorSL: absolute tolerance in dollars.
- CalculatedAllowedFinalMinAmount = MirrorSL - CalculatedAllowedDiff: minimum acceptable close amount.
- Include only WHERE Amount < CalculatedAllowedFinalMinAmount (shortfall exceeds tolerance).
- Compensation = MirrorSL - Amount: the actual dollar shortfall for each mirror.
- Result ordered by Compensation DESC: largest shortfalls first for prioritized remediation.

### 2.3 Investment Summary Columns

**What**: Calculates per-mirror investment lifecycle summary for context.

**Columns/Parameters Involved**: `History.Mirror.InitialInvestment`, `History.Mirror.DepositSummary`, `History.Mirror.WithdrawalSummary`

**Rules**:
- TotalInvestment = InitialInvestment + DepositSummary - WithdrawalSummary: lifetime net investment in the mirror.
- NetInvestment = TotalInvestment - Compensation: what the customer effectively ended up with after the MSL shortfall.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Start of the date range (inclusive) for History.Mirror.ModificationDate. Filters MSL-close events from this date onward. |
| 2 | @EndDate | datetime | YES | GETUTCDATE() | CODE-BACKED | End of the date range (inclusive) for History.Mirror.ModificationDate. Defaults to the current UTC timestamp if NULL. |
| 3 | @AllowedDiffPercentage | decimal(16,8) | NO | - | CODE-BACKED | Acceptable slippage percentage (e.g., 3.0 = 3%). Used to compute the tolerance band around the MSL level. Only mirrors with actual close below MirrorSL*(1 - AllowedDiffPercentage/100) are included. Passed back in the result set for reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID, CID | History.Mirror | Read | NOLOCK; filtered for MirrorOperationID=2, CloseMirrorActionType=1 - MSL close events |
| CID | Customer.Customer | JOIN/Read | NOLOCK; provides UserName and Email for the copier |
| MirrorOperationID=2 | Dictionary.MirrorOperation | Reference | 2=Mirror Close |
| CloseMirrorActionType=1 | Dictionary.CloseMirrorActionType | Reference | 1=MirrorStopLoss (MSL-triggered) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Ad-hoc compensation reporting query; called by BI/operations teams. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MirrorsStopLossToBeCompensatedByPercentageDiff (procedure)
├── History.Mirror (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | NOLOCK SELECT; source of mirror close events with MirrorSL, Amount, financial summary columns |
| Customer.Customer | Table | INNER JOIN NOLOCK; provides UserName and Email for copier contact details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Reporting procedure; result set consumed by BI/operations teams. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No transaction needed - read-only SELECT. TRY/CATCH with bare THROW (errors propagate to caller). Both History.Mirror and Customer.Customer read with NOLOCK hints.

---

## 8. Sample Queries

### 8.1 Find mirrors with 3% tolerance over last 30 days

```sql
EXEC Trade.MirrorsStopLossToBeCompensatedByPercentageDiff
    @StartDate = DATEADD(DAY, -30, GETUTCDATE()),
    @EndDate = NULL,
    @AllowedDiffPercentage = 3.0;
```

### 8.2 Directly query MSL close shortfalls without tolerance filter

```sql
SELECT hm.CID, hm.MirrorID, hm.MirrorSL, hm.Amount,
       hm.MirrorSL - hm.Amount AS Shortfall,
       hm.ModificationDate AS MirrorCloseDate
FROM History.Mirror AS hm WITH (NOLOCK)
WHERE hm.MirrorOperationID = 2
  AND hm.CloseMirrorActionType = 1
  AND hm.ModificationDate >= <StartDate>
  AND hm.Amount < hm.MirrorSL
ORDER BY Shortfall DESC;
```

### 8.3 Verify CloseMirrorActionType=1 is MSL

```sql
SELECT CloseMirrorActionTypeID, Name
FROM Dictionary.CloseMirrorActionType WITH (NOLOCK)
WHERE CloseMirrorActionTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MirrorsStopLossToBeCompensatedByPercentageDiff | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MirrorsStopLossToBeCompensatedByPercentageDiff.sql*
