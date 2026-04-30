# Trade.GetClosedPositionsFromTimestamp

> Retrieves a paginated batch of closed positions from the active position history within a specified time window, used by the Position Adapter Service for downstream processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns closed position rows from History.Position_Active |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves closed trading positions that fell within a specific time range, returning key financial and trade attributes for each position. It serves as a data extraction endpoint for the Position Adapter Service, which consumes closed position data for reconciliation, analytics, or downstream event processing.

The procedure exists to provide a controlled, paginated mechanism for external services to consume closed position data without placing excessive load on the database. Without it, services would need to directly query the large History.Position_Active table, potentially causing performance issues.

Data flows outward from this procedure: the History.Position_Active table (populated by the position close lifecycle) is the source, and the PositionAdapterService is the consumer. The procedure reads from the history table using timestamp-based windowing and a last-processed PositionID exclusion to avoid duplicate processing.

---

## 2. Business Logic

### 2.1 Timestamp-Based Pagination

**What**: Paginated extraction of closed positions using a sliding time window with duplicate exclusion.

**Columns/Parameters Involved**: `@BulkSize`, `@MinimumTimestampThreshold`, `@MaximumTimestampThreshold`, `@LastPositionID`

**Rules**:
- Returns at most `@BulkSize` rows per call, ordered by `CloseOccurred ASC`
- Only includes positions closed at or after `@MinimumTimestampThreshold` (converted from VARCHAR using style 105 - dd-MM-yyyy format) and before `@MaximumTimestampThreshold`
- Excludes the position identified by `@LastPositionID` to prevent re-processing the last row from a previous batch
- The caller advances the window by updating the thresholds and last PositionID between calls

**Diagram**:
```
Time window:  [MinTimestamp --------> MaxTimestamp)
               |                        |
               >= (inclusive)           < (exclusive)

  Batch N:  [pos1, pos2, ..., posN]  (TOP @BulkSize, ORDER BY CloseOccurred)
  Batch N+1: @LastPositionID = posN.PositionID, advance MinTimestamp
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkSize | INT | NO | - | CODE-BACKED | Maximum number of closed position rows to return in a single call. Controls pagination batch size for the consuming service. |
| 2 | @MinimumTimestampThreshold | VARCHAR(23) | NO | - | CODE-BACKED | Lower bound (inclusive) of the CloseOccurred time window. Passed as a string and converted to DATETIME2 using style 105 (dd-MM-yyyy). Determines the earliest close time to include. |
| 3 | @MaximumTimestampThreshold | DATETIME2 | NO | - | CODE-BACKED | Upper bound (exclusive) of the CloseOccurred time window. Positions closed before this timestamp are included. |
| 4 | @LastPositionID | BIGINT | NO | - | CODE-BACKED | PositionID of the last row returned in the previous batch. Excluded from results to prevent duplicate processing when paginating within the same time window. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique identifier for the closed trading position. PK of the History.Position_Active table. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument traded in this position. FK to instrument reference data (e.g., stocks, indices, commodities, crypto). |
| 3 | CID | INT | YES | - | CODE-BACKED | Customer ID - identifies the trader who owned this position. |
| 4 | HedgeServerID | INT | YES | - | CODE-BACKED | Identifies which hedge server handled the risk management for this position. |
| 5 | CloseOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was actually closed (execution time). Used as the primary sort and filter column for pagination. |
| 6 | Amount | MONEY | NO | - | CODE-BACKED | Monetary amount invested in the position. |
| 7 | AmountInUnitsDecimal | DECIMAL(16,6) | YES | - | CODE-BACKED | Position size expressed in units of the instrument (e.g., number of shares, units of currency). |
| 8 | InitForexRate | dtPrice | NO | - | CODE-BACKED | The forex conversion rate at position open time, used for PnL calculation in the customer's account currency. |
| 9 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy/Long position, 0 = Sell/Short position. |
| 10 | IsComputeForHedge | BIT | - | - | NAME-INFERRED | Flag indicating whether this position should be included in hedge computation calculations. |
| 11 | IsSettled | BIT | - | - | CODE-BACKED | Legacy flag for real stock ownership: 1 = real stock position (customer owns actual shares), 0 = CFD position (contract for difference). Predates SettlementTypeID. |
| 12 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier applied to the position (e.g., 1 = no leverage, 5 = 5x leverage). Real stock positions typically use leverage 1. |
| 13 | MirrorID | BIGINT | - | - | CODE-BACKED | Links this position to its copy-trading parent. 0 = manual trade (no copy relationship). Non-zero = copied from another trader's position. Also known as CopyParentPositionId in application code. |
| 14 | LimitRate | dtPrice | NO | - | CODE-BACKED | Take-profit price level set for the position. When the market reaches this rate, the position closes automatically for profit. |
| 15 | StopRate | dtPrice | NO | - | CODE-BACKED | Stop-loss price level set for the position. When the market reaches this rate, the position closes automatically to limit losses. |
| 16 | UnitMargin | - | - | - | NAME-INFERRED | Margin amount per unit for the position. Used in margin requirement calculations. |
| 17 | SpreadedCommission | INT | NO | - | NAME-INFERRED | Commission amount factored into the spread. Stored as an integer value representing basis points or a scaled amount. |
| 18 | CommissionOnClose | MONEY | NO | - | CODE-BACKED | Commission fee charged when the position was closed. |
| 19 | FullCommissionOnClose | MONEY | - | - | NAME-INFERRED | Full commission on close before any discounts or adjustments. |
| 20 | NetProfit | MONEY | NO | - | CODE-BACKED | Net profit or loss from the position after all fees and commissions. Positive = profit, negative = loss. Calculated by an external PnL calculation engine. |
| 21 | EndForexRate | dtPrice | NO | - | CODE-BACKED | The forex conversion rate at position close time, used for final PnL conversion to account currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position_Active | Read | Reads closed position data from the active position history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PositionAdapterService | GRANT EXECUTE | Permission | The Position Adapter Service has execute permission on this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClosedPositionsFromTimestamp (procedure)
└── History.Position_Active (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position_Active | Table | Read with NOLOCK - source of all closed position data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PositionAdapterService | DB User/Service | Granted EXECUTE permission; consumes closed position data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the latest 100 closed positions from the last hour

```sql
EXEC Trade.GetClosedPositionsFromTimestamp
    @BulkSize = 100,
    @MinimumTimestampThreshold = '16-03-2026',
    @MaximumTimestampThreshold = '2026-03-16T23:59:59',
    @LastPositionID = 0;
```

### 8.2 Resume pagination from a known last position

```sql
EXEC Trade.GetClosedPositionsFromTimestamp
    @BulkSize = 500,
    @MinimumTimestampThreshold = '15-03-2026',
    @MaximumTimestampThreshold = '2026-03-16T00:00:00',
    @LastPositionID = 987654321;
```

### 8.3 Query the source table directly with instrument name resolution

```sql
SELECT TOP 10
    hp.PositionID,
    hp.CID,
    hp.InstrumentID,
    hp.CloseOccurred,
    hp.NetProfit,
    hp.IsBuy,
    hp.Leverage
FROM History.Position_Active hp WITH (NOLOCK)
WHERE hp.CloseOccurred >= '2026-03-15'
ORDER BY hp.CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetClosedPositionsFromTimestamp | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetClosedPositionsFromTimestamp.sql*
