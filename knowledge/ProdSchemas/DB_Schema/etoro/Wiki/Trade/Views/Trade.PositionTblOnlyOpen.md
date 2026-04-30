# Trade.PositionTblOnlyOpen

> Filtered view of Trade.PositionTbl exposing only open positions (StatusID=1) with raw columns and WITH (NOLOCK), created for Async-Close scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.PositionTblOnlyOpen provides direct access to open positions only from Trade.PositionTbl. Unlike Trade.Position which JOINs to PositionTreeInfo and filters open positions, this view exposes the raw PositionTbl schema with a simple WHERE StatusID = 1. Each row is an open position with all columns from PositionTbl including close-related fields (EndForexRate, EndDateTime, etc.) which are NULL for open positions. The view uses WITH (NOLOCK) for read-uncommitted isolation.

This view was created for Async-Close scenarios (Dec 2018) where consumers need fast access to open positions without the overhead of joining to tree info. It also includes a computed column: SettlementTypeID = ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)) to provide a fallback for legacy positions where SettlementTypeID may be NULL.

The view serves BI, monitoring, and async-close logic that needs the full PositionTbl structure for open positions only, with built-in dirty reads for high-throughput read scenarios.

---

## 2. Business Logic

Direct filter on Trade.PositionTbl WHERE StatusID = 1 (open). All PositionTbl columns pass through. Computed: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)) AS SettlementTypeID. Uses WITH (NOLOCK). Close-related columns (EndForexRate, EndDateTime, etc.) are NULL for open positions by definition.

---

## 3. Data Overview

N/A - output mirrors Trade.PositionTbl filtered by StatusID=1. See [Trade.PositionTbl](../Tables/Trade.PositionTbl.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Unique position identifier. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 3 | ForexResultID | int | YES | - | CODE-BACKED | Forex conversion result reference. |
| 4 | CurrencyID | int | YES | - | CODE-BACKED | Denomination currency. |
| 5 | ProviderID | int | YES | - | CODE-BACKED | Provider identifier. |
| 6 | GameServerID | int | YES | - | CODE-BACKED | Game/sim server. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. |
| 8 | HedgeID | bigint | YES | - | CODE-BACKED | Hedge position reference. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server. |
| 10 | OrderID | bigint | YES | - | CODE-BACKED | Opening order. |
| 11 | Leverage | int | YES | - | CODE-BACKED | Position leverage. |
| 12 | Amount | decimal | YES | - | CODE-BACKED | Position amount. |
| 13 | AmountInUnitsDecimal | decimal | YES | - | CODE-BACKED | Size in units. |
| 14 | UnitMargin | decimal | YES | - | CODE-BACKED | Unit margin. |
| 15 | LotCountDecimal | decimal | YES | - | CODE-BACKED | Lot count. |
| 16 | NetProfit | decimal | YES | - | CODE-BACKED | NULL for open. |
| 17 | InitForexRate | decimal | YES | - | CODE-BACKED | Open rate. |
| 18 | InitDateTime | datetime | YES | - | CODE-BACKED | Open timestamp. |
| 19 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)). 0=CFD, 1=Real. |
| 20 | StatusID | tinyint | NO | - | CODE-BACKED | Always 1 (open) in this view. |
| 21 | (other PositionTbl columns) | (varies) | (varies) | - | CODE-BACKED | EndForexRate, EndDateTime, ActionType, CloseOccurred, etc. NULL for open. See PositionTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Instrument of the position |
| CID | (Customer) | Implicit FK | Position owner |
| ProviderID | (Provider) | Implicit FK | Provider |
| HedgeServerID | (HedgeServer) | Implicit FK | Hedge server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTblOnlyOpen (view)
    |
    +-- Trade.PositionTbl (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | FROM - source table, filtered WHERE StatusID=1, WITH (NOLOCK) |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All open positions for a customer

```sql
SELECT PositionID, InstrumentID, Amount, Leverage, InitDateTime
FROM Trade.PositionTblOnlyOpen WITH (NOLOCK)
WHERE CID = @CID;
```

### 8.2 Open positions by instrument

```sql
SELECT InstrumentID, COUNT(*) AS Cnt, SUM(Amount) AS TotalAmount
FROM Trade.PositionTblOnlyOpen WITH (NOLOCK)
GROUP BY InstrumentID;
```

### 8.3 Open positions on a hedge server

```sql
SELECT PositionID, CID, InstrumentID, HedgeServerID, Amount
FROM Trade.PositionTblOnlyOpen WITH (NOLOCK)
WHERE HedgeServerID = @HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionTblOnlyOpen | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionTblOnlyOpen.sql*
