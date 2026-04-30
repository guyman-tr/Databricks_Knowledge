# History.MirrorSLCloseFail

> Failure audit log for Mirror Stop Loss (MSL) close attempts - records every unsuccessful attempt to force-close a copy relationship when the stop-loss threshold was breached, capturing the error message and account state snapshot for reconciliation and debugging.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | MirrorStopLossCloseFailID (int IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (NONCLUSTERED PK on MirrorStopLossCloseFailID) |

---

## 1. Business Meaning

History.MirrorSLCloseFail is the failure companion to History.MirrorSLCloseLog. Together, these two tables form a complete success/failure audit trail for Mirror Stop Loss (MSL) enforcement.

When a copier's copy portfolio (Mirror) suffers losses that push the account value to or below the stop-loss threshold (MirrorSL), the MSL engine triggers a forced close of the copy relationship. If that close attempt succeeds, a row is written to History.MirrorSLCloseLog. If it fails (due to a database error, business rule violation, or race condition), a row is written here instead, capturing the error message and the account state at the moment of the failed attempt.

Written exclusively by `History.LogMirrorSLCloseFail`, which is called by the MSL engine application code when a close attempt fails. With 0 rows in the test environment, failures are rare in this system.

The companion success table (History.MirrorSLCloseLog) has ~28,000 rows, indicating this is an actively used system with occasional failures requiring investigation.

---

## 2. Business Logic

### 2.1 MSL Close Failure - Error Capture Pattern

**What**: When the MSL engine attempts to close a copy relationship and fails, it calls `History.LogMirrorSLCloseFail` with the full context of what was attempted and what error occurred. The account snapshot (MirrorSL, MirrorAmount, InvestedAmount, NetProfit) is captured at the moment of the failure for post-mortem reconciliation.

**Columns/Parameters Involved**: `MirrorID`, `ErrorMessage`, `ErrorOccurred`, `CloseTrigger`, `MirrorSL`, `MirrorAmount`, `InvestedAmount`, `NetProfit`

**Rules**:
- A row here means the MSL close did NOT complete - the copy relationship and positions may still be open
- ErrorMessage can be up to varchar(max) - captures the full exception text from the MSL engine
- CloseTrigger identifies which MSL evaluation path detected the breach (same enum as History.MirrorSLCloseLog)
- RatesList captures the market rates at time of the failed attempt - critical for post-failure reconciliation
- PositionIDs captures the positions that were targeted for close but could not be closed

### 2.2 Success/Failure Pair Pattern

**What**: Every MSL close attempt ends in either History.MirrorSLCloseLog (success) or History.MirrorSLCloseFail (failure). These two tables together give complete coverage of all MSL enforcement events.

**Rules**:
- Same account snapshot columns: MirrorSL, MirrorAmount, InvestedAmount, NetProfit, CloseTrigger, RatesList, StockOrdersAmount, PositionIDs
- Success (MirrorSLCloseLog): CloseOccurred = when the close was completed
- Failure (MirrorSLCloseFail): ErrorOccurred = when the error was detected + ErrorMessage = what failed
- After a failure, the MSL engine may retry - if the retry succeeds, there will be a failure row here AND a success row in MirrorSLCloseLog for the same MirrorID

---

## 3. Data Overview

No data in test environment (0 rows). Failures are rare - the MSL close process is designed to be reliable. In production, rows represent failed forced-close attempts requiring operations investigation.

| MirrorStopLossCloseFailID | MirrorID | MirrorSL | MirrorAmount | InvestedAmount | NetProfit | ErrorOccurred | ErrorMessage | CloseTrigger |
|---|---|---|---|---|---|---|---|---|
| (example) | 456789 | 5000.00 | 45000.00 | 1200.00 | -42000.00 | 2024-08-12 03:45:22 | "Deadlock victim during position close" | 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorStopLossCloseFailID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. NONCLUSTERED PK - no clustered index defined (table on HISTORY filegroup). Distinct ID sequence from History.MirrorSLCloseLog (separate IDENTITY sequences). |
| 2 | MirrorID | int | NO | - | CODE-BACKED | The copy-trade mirror relationship where the stop-loss close attempt failed. References Trade.Mirror.MirrorID (no FK enforced). Primary lookup key for investigating specific mirror failures. |
| 3 | MirrorSL | money | NO | - | CODE-BACKED | The mirror stop-loss threshold amount (in account currency) that was breached, triggering the close attempt. money type (decimal(19,4)). The MSL engine compares the current portfolio value against this threshold to determine when to force-close. |
| 4 | MirrorAmount | money | NO | - | CODE-BACKED | The total copy amount allocated to this mirror at time of the failed close attempt. Part of the financial snapshot for reconciliation. In the MSL formula: MSLReturnedMoney = MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount. |
| 5 | InvestedAmount | money | NO | - | CODE-BACKED | The currently invested portion of the copy amount (funds deployed in open positions) at time of the failed close. Separate from MirrorAmount (total allocated) - the difference represents uninvested cash within the copy portfolio. |
| 6 | NetProfit | money | NO | - | CODE-BACKED | The net P&L (realized + unrealized) of the copy portfolio at time of the failed close. For MSL triggers, this value is typically large and negative (stop-loss fires when the portfolio has suffered significant losses). |
| 7 | ErrorOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the close attempt failed and this record was logged. Not auto-defaulted - supplied by the calling MSL engine code. |
| 8 | ErrorMessage | varchar(max) | YES | - | CODE-BACKED | The full error description from the failed close attempt. Can be very long (max) - captures the complete exception text for debugging. NULL if no error message was captured. |
| 9 | CloseTrigger | tinyint | NO | - | CODE-BACKED | Identifies which MSL evaluation pathway triggered this close attempt. Same enum as History.MirrorSLCloseLog.CloseTrigger. Common values in the success table: 0=93% (scheduled periodic check), 4=3.7%, 1=2.1%, 7=0.9%. Exact enum values defined in MSL engine application code. |
| 10 | RatesList | varchar(max) | YES | - | CODE-BACKED | Semicolon-delimited list of market rates for each position at time of the failed close attempt. Critical for post-failure reconciliation - allows reconstructing what the portfolio was worth when the close was attempted. |
| 11 | StockOrdersAmount | money | NO | 0 | CODE-BACKED | The portion of the portfolio value represented by stock (real equity) orders. DEFAULT 0 - hardcoded in History.LogMirrorSLCloseFail (always inserted as 0, ignoring the @StockOrdersAmount parameter which is not in the procedure signature). Legacy column maintained for schema consistency with History.MirrorSLCloseLog. |
| 12 | PositionIDs | varchar(max) | YES | - | CODE-BACKED | Semicolon-delimited list of position IDs that were targeted for close in the failed attempt. Allows tracing exactly which positions were involved and whether they were subsequently closed after the failure was resolved. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Implicit | References the copy relationship where the stop-loss close failed. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LogMirrorSLCloseFail | (INSERT) | Writer | The ONLY writer - called by MSL engine when a close attempt fails |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorSLCloseFail (table)
  - No code-level dependencies (leaf table)
  - Written by History.LogMirrorSLCloseFail (procedure)
  - Failure counterpart to History.MirrorSLCloseLog
```

### 6.1 Objects This Depends On

No dependencies. Free-standing failure log.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LogMirrorSLCloseFail | Stored Procedure | Sole writer - inserts one row per failed MSL close attempt |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorSLCloseFail_MirrorStopLossCloseFailID | NONCLUSTERED | MirrorStopLossCloseFailID ASC | - | - | Active |

Note: No clustered index - heap table. On [HISTORY] filegroup. TEXTIMAGE_ON [HISTORY] for the varchar(max) columns.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorSLCloseFail_MirrorStopLossCloseFailID | PRIMARY KEY | NONCLUSTERED PK on MirrorStopLossCloseFailID |
| DF__MirrorSLCloseFail_StockOrdersAmount | DEFAULT | StockOrdersAmount = 0 |

---

## 8. Sample Queries

### 8.1 Get all MSL close failures for a specific mirror

```sql
SELECT
    MirrorStopLossCloseFailID,
    MirrorID,
    MirrorSL,
    MirrorAmount + InvestedAmount + NetProfit + StockOrdersAmount AS PortfolioValueAtFailure,
    ErrorOccurred,
    ErrorMessage,
    CloseTrigger,
    LEFT(PositionIDs, 200) AS PositionIDsSample
FROM [History].[MirrorSLCloseFail] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
ORDER BY ErrorOccurred ASC
```

### 8.2 Cross-check failures against subsequent successes (retry analysis)

```sql
-- Mirrors that had both a failure and a success (MSL engine retried successfully)
SELECT
    f.MirrorID,
    f.ErrorOccurred AS FailureAt,
    f.ErrorMessage,
    s.CloseOccurred AS SuccessAt,
    DATEDIFF(SECOND, f.ErrorOccurred, s.CloseOccurred) AS SecondsBetweenFailAndSuccess
FROM [History].[MirrorSLCloseFail] f WITH (NOLOCK)
JOIN [History].[MirrorSLCloseLog] s WITH (NOLOCK) ON s.MirrorID = f.MirrorID
ORDER BY f.ErrorOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.LogMirrorSLCloseFail) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MirrorSLCloseFail | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorSLCloseFail.sql*
