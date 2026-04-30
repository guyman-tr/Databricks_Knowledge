# Trade.GetCustomerManualOpenPositions

> Retrieves all manually opened (non-copy-trade) open positions for a given customer, returning instrument details, direction, size, open rate, and leverage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer ID filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomerManualOpenPositions returns a summary of all open positions that a customer opened manually - that is, positions the customer placed directly rather than positions created through the CopyTrader feature. Each row contains the instrument name, position direction (buy/sell), size in units, the rate at which it was opened, the open date, leverage, and the position amount in the account's denomination currency.

This procedure exists to provide a lightweight snapshot of a customer's self-directed trading activity, excluding copy-trade positions. This distinction matters because manual positions represent the customer's own trading decisions, while copy positions are managed by the copied trader's actions. The BI team (PROD\BIadmins) has VIEW DEFINITION permission, suggesting this is used for analytics or reporting on customer self-directed activity.

The data flows from Trade.Position (a view over Trade.PositionTbl INNER JOIN Trade.PositionTreeInfo, filtered to StatusID=1 open positions) joined with Trade.InstrumentMetaData for instrument display names. The MirrorID=0 filter excludes all copy-trade positions, since MirrorID links a position to its parent copy-trade relationship (0 = no mirror/copy linkage).

---

## 2. Business Logic

### 2.1 Manual Position Filter

**What**: Distinguishes manually opened positions from copy-trade positions using the MirrorID column.

**Columns/Parameters Involved**: `MirrorID`, `@CID`

**Rules**:
- MirrorID = 0 means the position was opened by the customer directly (manual trade), not copied from another trader
- MirrorID > 0 links to the copy-trade mirror relationship (excluded by this procedure)
- Combined with Trade.Position's built-in StatusID = 1 filter, this returns only currently open manual positions

**Diagram**:
```
Customer Positions (CID = @CID)
  |
  +-- MirrorID = 0 --> Manual positions (INCLUDED)
  |
  +-- MirrorID > 0 --> Copy-trade positions (EXCLUDED)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID to retrieve positions for. FK to Customer.Customer. Filters Trade.Position.CID to return only this customer's positions. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument being traded. FK to Trade.Instrument. Sourced from Trade.Position.InstrumentID. |
| 2 | InstrumentName | nvarchar | YES | - | CODE-BACKED | Human-readable instrument display name (e.g., "AAPL", "BTC/USD"). Aliased from Trade.InstrumentMetaData.SymbolFull. Unique per instrument. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier for the open position. PK of Trade.PositionTbl, surfaced through Trade.Position view. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | Position direction: 1 = Buy/Long, 0 = Sell/Short. Determines PnL calculation sign. |
| 5 | Units | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. Aliased from Trade.Position.AmountInUnitsDecimal. For stocks, this is the number of shares; for CFDs, the notional unit count. |
| 6 | OpenRate | float | YES | - | CODE-BACKED | The instrument price at which the position was opened. Aliased from Trade.Position.InitForexRate. Used as the reference price for PnL calculation. |
| 7 | OpenDate | datetime | YES | - | CODE-BACKED | Timestamp when the position was opened. Aliased from Trade.Position.InitDateTime. |
| 8 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied to the position (1, 2, 5, 10, etc.). Leverage=1 for real stock positions; higher values for CFD/leveraged trades. |
| 9 | PositionAmount | money | NO | - | CODE-BACKED | Position size in the account's denomination currency. Aliased from Trade.Position.Amount. Represents the customer's invested capital before leverage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / p.CID | Customer.Customer | FK | Customer whose manual positions are retrieved |
| p.InstrumentID | Trade.Instrument | JOIN | Instrument traded, joined to InstrumentMetaData for display name |
| p.* | Trade.Position (view) | FROM | Primary data source - open positions view (PositionTbl + PositionTreeInfo, StatusID=1) |
| m.* | Trade.InstrumentMetaData | JOIN | Instrument metadata table providing SymbolFull as InstrumentName |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Permission granted to PROD\BIadmins for reporting/analytics access.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerManualOpenPositions (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | FROM - primary data source for open positions |
| Trade.InstrumentMetaData | Table | INNER JOIN on InstrumentID for instrument display name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered; accessed via BI reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all manual open positions for a customer

```sql
EXEC Trade.GetCustomerManualOpenPositions @CID = 12345;
```

### 8.2 Equivalent inline query with additional PnL context

```sql
SELECT  p.InstrumentID,
        m.SymbolFull AS InstrumentName,
        p.PositionID,
        p.IsBuy,
        p.AmountInUnitsDecimal AS Units,
        p.InitForexRate AS OpenRate,
        p.InitDateTime AS OpenDate,
        p.Leverage,
        p.Amount AS PositionAmount,
        p.NetProfit
FROM    Trade.Position p WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData m WITH (NOLOCK)
        ON p.InstrumentID = m.InstrumentID
WHERE   p.CID = 12345
        AND p.MirrorID = 0;
```

### 8.3 Count manual vs copy positions per customer

```sql
SELECT  p.CID,
        SUM(CASE WHEN p.MirrorID = 0 THEN 1 ELSE 0 END) AS ManualPositions,
        SUM(CASE WHEN p.MirrorID > 0 THEN 1 ELSE 0 END) AS CopyPositions
FROM    Trade.Position p WITH (NOLOCK)
WHERE   p.CID = 12345
GROUP BY p.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerManualOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerManualOpenPositions.sql*
