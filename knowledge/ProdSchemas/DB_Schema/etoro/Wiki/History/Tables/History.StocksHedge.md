# History.StocksHedge

> Legacy audit log of stock hedging operations from May 2012 to March 2014, recording each batch hedge event - the instrument, price range, hedge execution timing, and source of the hedge decision.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HedgeOperationID (NONCLUSTERED PK + UNIQUE CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK + UNIQUE CLUSTERED on HedgeOperationID) |

---

## 1. Business Meaning

This table is a **legacy audit log** of stock hedging operations from eToro's early stocks trading system (May 2012 through March 2014). Each row represents one hedge batch operation: a hedge run for a specific stock instrument that covered a range of hedge transactions (`MinHedgeID` to `MaxHedgeID`).

eToro's early stocks trading system maintained hedge exposure in batches. When positions accumulated, the system (or an operator) would trigger a hedging operation against a provider. `StockHedgeSourceID` identifies whether the hedge was triggered manually, by the Auto FAPI system, or by the Auto Closing Rate system.

The table has **18,821 rows** covering 2012-2014. It has no active writers and is a frozen historical archive. The last entry is from March 21, 2014, after which the stocks hedging infrastructure was replaced with the current system.

FK: `StockHedgeSourceID` -> `Dictionary.StockHedgeSource` (0=Unknown, 1=Manual, 2=Auto FAPI, 3=Auto Closing Rate).

---

## 2. Business Logic

### 2.1 Hedge Batch Operation

**What**: Each row records one batch hedging operation covering a range of individual hedge transactions.

**Columns/Parameters Involved**: `HedgeOperationID`, `InstrumentID`, `MinHedgeID`, `MaxHedgeID`, `IsComplete`, `StartHedge`, `EndHedge`

**Rules**:
- `MinHedgeID` to `MaxHedgeID` define the range of individual hedge transactions included in this batch
- `IsComplete=1` when the hedge batch fully executed; `IsComplete=0` if it was interrupted or failed
- `StartHedge` = when the hedge batch began; `EndHedge` = when it completed
- `StockHedgeSourceID=3` (Auto Closing Rate) is the dominant pattern in later data

### 2.2 Price Capture at Hedge Execution

**What**: The prices at which the hedge was executed are captured for audit.

**Columns/Parameters Involved**: `Ask`, `Bid`, `SpreadAsk`, `SpreadBid`, `BidUnAdjusted`, `AskUnAdjusted`, `ConversionRate`

**Rules**:
- `Ask` and `Bid`: execution prices (money type)
- `SpreadAsk` / `SpreadBid`: spread-adjusted prices applied
- `BidUnAdjusted` / `AskUnAdjusted` / `SpreadBidUnAdjusted` / `SpreadAskUnAdjusted`: pre-adjustment prices for audit
- `ConversionRate`: currency conversion rate applied at time of hedge

---

## 3. Data Overview

| HedgeOperationID | InstrumentID | MinHedgeID | MaxHedgeID | IsComplete | StartHedge | EndHedge | Ask | Bid | StockHedgeSourceID |
|---|---|---|---|---|---|---|---|---|---|
| 21881 | 1153 | 10581 | 10587 | true | 2014-03-21 19:45 | 2014-03-21 20:31 | 50.92 | 50.92 | 3 (Auto Closing Rate) |
| 21880 | 1149 | 10581 | 10587 | true | 2014-03-21 19:45 | 2014-03-21 20:31 | 83.06 | 83.06 | 3 (Auto Closing Rate) |

Total: 18,821 rows | May 2012 - March 2014 | 4 distinct hedge sources

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeOperationID | int | NO | - | CODE-BACKED | Primary key. Both NONCLUSTERED PK and UNIQUE CLUSTERED index defined (unusual - both enforce uniqueness on the same column; clustered index is the physical ordering). Uniquely identifies each hedge batch operation. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The stock instrument this hedge batch covers. Implicit FK to Trade.Instrument. |
| 3 | MinHedgeID | int | NO | - | VERIFIED | The lowest individual hedge transaction ID in this batch. Together with MaxHedgeID defines the range of hedge transactions covered. |
| 4 | MaxHedgeID | int | NO | - | VERIFIED | The highest individual hedge transaction ID in this batch. |
| 5 | IsComplete | bit | NO | - | CODE-BACKED | 1 when the hedge batch completed successfully. 0 if the hedge was initiated but did not complete (failed or still in progress). |
| 6 | StartHedge | datetime | NO | - | CODE-BACKED | UTC timestamp when the hedge batch operation began. |
| 7 | EndHedge | datetime | NO | - | CODE-BACKED | UTC timestamp when the hedge batch operation completed. Duration = EndHedge - StartHedge (typically 30-60 minutes). |
| 8 | Ask | money | NO | - | VERIFIED | The ask price at which the hedge was executed. |
| 9 | Bid | money | NO | - | VERIFIED | The bid price at which the hedge was executed. In the sample data Ask=Bid (symmetric pricing). |
| 10 | SpreadAsk | money | NO | - | CODE-BACKED | The spread-adjusted ask price used for the hedge. |
| 11 | SpreadBid | money | NO | - | CODE-BACKED | The spread-adjusted bid price used for the hedge. |
| 12 | PriceRateID | bigint | NO | - | CODE-BACKED | Reference to the price rate record used for this hedge operation. Links to the pricing system. |
| 13 | BidUnAdjusted | money | YES | - | CODE-BACKED | The pre-spread-adjustment bid price. NULL for older records. |
| 14 | AskUnAdjusted | money | YES | - | CODE-BACKED | The pre-spread-adjustment ask price. NULL for older records. |
| 15 | SpreadBidUnAdjusted | money | YES | - | CODE-BACKED | The unadjusted spread bid. NULL for older records. |
| 16 | SpreadAskUnAdjusted | money | YES | - | CODE-BACKED | The unadjusted spread ask. NULL for older records. |
| 17 | ConversionRate | money | YES | - | CODE-BACKED | Currency conversion rate applied at time of the hedge. NULL for older records. |
| 18 | StockHedgeSourceID | int | NO | 0 | VERIFIED | Identifies what triggered this hedge operation. FK to Dictionary.StockHedgeSource: 0=Unknown, 1=Manual (operator-initiated), 2=Auto FAPI (automated via FAPI system), 3=Auto Closing Rate (automated based on closing rate). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | The stock instrument being hedged. |
| StockHedgeSourceID | Dictionary.StockHedgeSource | FK | 0=Unknown, 1=Manual, 2=Auto FAPI, 3=Auto Closing Rate. |

### 5.2 Referenced By (other objects point to this)

No active writers or readers in current codebase. Static legacy archive.

---

## 6. Dependencies

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.StockHedgeSource | Table | FK on StockHedgeSourceID - validates hedge source values. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StocksHedge | NONCLUSTERED PK | HedgeOperationID ASC | - | - | Active |
| PK_History_Stocks_Hedge | UNIQUE CLUSTERED | HedgeOperationID ASC | - | - | Active |

Note: Both PK and CLUSTERED index are on HedgeOperationID - unusual dual-index pattern on the same column.

---

## 8. Sample Queries

### 8.1 View recent hedge operations
```sql
SELECT
    HedgeOperationID,
    InstrumentID,
    MinHedgeID,
    MaxHedgeID,
    IsComplete,
    StartHedge,
    EndHedge,
    Ask,
    Bid,
    StockHedgeSourceID
FROM [History].[StocksHedge] WITH (NOLOCK)
ORDER BY StartHedge DESC
```

### 8.2 Find incomplete hedge operations
```sql
SELECT HedgeOperationID, InstrumentID, StartHedge, EndHedge
FROM [History].[StocksHedge] WITH (NOLOCK)
WHERE IsComplete = 0
ORDER BY StartHedge ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.StocksHedge | Type: Table | Source: etoro/etoro/History/Tables/History.StocksHedge.sql*
