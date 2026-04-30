# BackOffice.JUNK_GetCustomerAggregations

> **DEPRECATED (JUNK prefix)** - Legacy comprehensive customer profile view combining identity, all-time profit, game history, instrument preferences, and position win/loss counts into a single row per customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID - one row per customer (requires all join conditions met) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_GetCustomerAggregations` is a legacy "customer 360" view (JUNK prefix = deprecated) that assembled a comprehensive per-customer profile by joining six different sources into a single row per customer. It was designed to give BackOffice staff a one-stop view of a customer's complete trading and gaming history summary.

The view combines:
- Customer identity (CID, UserName from Customer.Customer)
- All-time P&L (TotalProfit in cents, from CustomerAllTimeAggregatedData)
- Most popular game type (from GetMostPopularGamePerCustomer)
- First game played and first bet amount (from GetFirstGameInfoPerCustomer)
- Instruments traded at first session (from GetInstrumentPopularityPerCustomer, Place=1)
- Win/loss position counts (computed from History.Position)

The use of INNER JOINs across all six sources means only customers who have data in ALL sources appear in the results. Customers without game history, instrument popularity data, or History.Position records are excluded. The JUNK prefix and absence of consumers indicate this was abandoned, likely superseded by BI dashboards or CRM tools.

The History.Position join (EtoroArchive) makes this view expensive and inaccessible via current MCP credentials.

---

## 2. Business Logic

### 2.1 Multi-Source Customer Profile Assembly

**What**: Joins six data sources per customer to create a consolidated analytics profile.

**Columns/Parameters Involved**: All output columns

**Rules**:
- All joins are implicit INNER JOINs via WHERE clauses - a customer must have records in ALL six sources to appear
- `BISP.Place = 1`: restricts instrument data to the customer's earliest trading session (the "first instruments" they ever traded)
- `BFGI.OrderNumber = 1`: restricts to the customer's first game only
- GROUP BY includes all single-valued columns; aggregate counts are per (CID, UserName, allother_scalars)

### 2.2 Win/Loss Position Counting

**What**: Counts profitable vs non-profitable historical positions per customer directly from History.Position.

**Columns/Parameters Involved**: `ProfitPositionCount`, `NonProfitPositionCount`

**Rules**:
- `ProfitPositionCount = ABS(SUM(CASE WHEN SIGN(CAST(NetProfit*100 AS INT)) = 1 THEN 1 ELSE 0 END))`
- `NonProfitPositionCount = ABS(SUM(CASE WHEN SIGN(CAST(NetProfit*100 AS INT)) != 1 THEN 1 ELSE 0 END))`
- `SIGN(NetProfit*100)=1` means NetProfit > 0 (profitable position)
- `SIGN != 1` catches both zero-profit (SIGN=0) and losing (SIGN=-1) positions
- `ABS()` wrapper is redundant (COUNT cannot be negative) - legacy defensive coding
- NetProfit multiplied by 100 before SIGN to avoid floating-point zero issues

---

## 3. Data Overview

*Live data not available - joins History.Position (EtoroArchive) and GetInstrumentPopularityPerCustomer (also EtoroArchive). Not sampled due to JUNK/legacy status and EtoroArchive access restriction.*

| CID | UserName | TotalProfit | MostPopularGame | TotalGames | FirstBetAmount | FirstGamePlayed | Instruments | ProfitPositionCount | NonProfitPositionCount | TotalPositionCount |
|-----|----------|-------------|-----------------|------------|----------------|-----------------|-------------|--------------------|-----------------------|-------------------|
| (example) | john123 | -5000 | eToro Trading | 3 | 100 | 2020-01-15 | BTC,ETH | 12 | 35 | 47 |

*TotalProfit=-5000 means -$50.00. FirstBetAmount in cents convention.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer identifier. Primary key for this profile row. A customer only appears if they have records in all six joined data sources simultaneously. |
| 2 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer's eToro username. From Customer.Customer.UserName. |
| 3 | TotalProfit | INT (computed) | YES | - | CODE-BACKED | Customer's all-time realized profit/loss in cents. Computed as `CAST(BackOffice.CustomerAllTimeAggregatedData.TotalProfit*100 AS INTEGER)`. Divide by 100 for dollar value. Negative = net loss over trading lifetime. |
| 4 | MostPopularGame | NVARCHAR | YES | - | CODE-BACKED | Name of the game type the customer has played most. From BackOffice.GetMostPopularGamePerCustomer.MostPopularGame (CLR-concatenated if tied). See [BackOffice.GetMostPopularGamePerCustomer](BackOffice.GetMostPopularGamePerCustomer.md). |
| 5 | TotalGames | INT | YES | - | CODE-BACKED | Total number of games played for the customer's most popular game type. From BackOffice.GetMostPopularGamePerCustomer.TotalGames. |
| 6 | FirstBetAmount | DECIMAL | YES | - | CODE-BACKED | Amount wagered in the customer's first game session. From BackOffice.GetFirstGameInfoPerCustomer.FirstBetAmount (OrderNumber=1). |
| 7 | FirstGamePlayed | DATETIME | YES | - | CODE-BACKED | Timestamp of the customer's first game session. From BackOffice.GetFirstGameInfoPerCustomer.FirstGamePlayed (OrderNumber=1). |
| 8 | Instruments | NVARCHAR | YES | - | CODE-BACKED | Comma-separated list of instruments traded in the customer's earliest trading session (Place=1 from BackOffice.GetInstrumentPopularityPerCustomer). Represents the instruments at the customer's very first InitDateTime slot. See [BackOffice.GetInstrumentPopularityPerCustomer](BackOffice.GetInstrumentPopularityPerCustomer.md). |
| 9 | ProfitPositionCount | INT (computed) | YES | - | VERIFIED | Count of the customer's historical positions where NetProfit > 0. Computed via `SUM(CASE WHEN SIGN(NetProfit*100)=1 THEN 1 ELSE 0 END)` over History.Position. Represents the number of winning trades in the customer's lifetime. |
| 10 | NonProfitPositionCount | INT (computed) | YES | - | VERIFIED | Count of the customer's historical positions where NetProfit <= 0 (zero or negative). Computed via `SUM(CASE WHEN SIGN(NetProfit*100)!=1 THEN 1 ELSE 0 END)`. Includes break-even positions as "non-profitable". |
| 11 | TotalPositionCount | INT | YES | - | CODE-BACKED | Total number of positions in the customer's all-time record. From BackOffice.CustomerAllTimeAggregatedData.TotalPositionCount. Should equal ProfitPositionCount + NonProfitPositionCount (within rounding). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, UserName | Customer.Customer | Source (cross-schema, NOLOCK) | Customer identity data. |
| TotalProfit, TotalPositionCount | BackOffice.CustomerAllTimeAggregatedData | Source (NOLOCK) | All-time trading aggregates. |
| MostPopularGame, TotalGames | BackOffice.GetMostPopularGamePerCustomer | Source (implicit INNER JOIN) | Most-played game type per customer. |
| Instruments | BackOffice.GetInstrumentPopularityPerCustomer | Source (filter: Place=1) | Instruments from the customer's earliest trading session. |
| FirstBetAmount, FirstGamePlayed | BackOffice.GetFirstGameInfoPerCustomer | Source (filter: OrderNumber=1) | First game event for the customer. |
| ProfitPositionCount, NonProfitPositionCount | History.Position | Source (cross-schema, NOLOCK) | Historical positions for win/loss counting. |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetCustomerAggregations (view) [DEPRECATED]
├── Customer.Customer (cross-schema table)
├── BackOffice.CustomerAllTimeAggregatedData (view)
│     └── BackOffice.CustomerAllTimeAggregatedData_1 (table)
├── BackOffice.GetMostPopularGamePerCustomer (view)
│     ├── BackOffice.GetGamePopularityPerCustomer (view)
│     └── Dictionary.GameType (table)
├── BackOffice.GetInstrumentPopularityPerCustomer (view)
│     └── History.GetPositionInfo (cross-schema)
├── BackOffice.GetFirstGameInfoPerCustomer (view)
│     └── History.ForexResult (cross-schema)
└── History.Position (cross-schema table - EtoroArchive)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Cross-schema Table | FROM clause (alias CCST, NOLOCK) - customer identity |
| BackOffice.CustomerAllTimeAggregatedData | View | FROM clause (alias BCAG, NOLOCK) - all-time trading aggregates |
| BackOffice.GetMostPopularGamePerCustomer | View | FROM clause (alias BMPG) - most popular game |
| BackOffice.GetInstrumentPopularityPerCustomer | View | FROM clause (alias BISP, Place=1 filter) - first trading session instruments |
| BackOffice.GetFirstGameInfoPerCustomer | View | FROM clause (alias BFGI, OrderNumber=1 filter) - first game details |
| History.Position | Cross-schema Table | FROM clause (alias HPOS, NOLOCK, EtoroArchive) - position win/loss counting |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: All six joins are implicit INNER JOINs - only customers with records in ALL six sources appear. This is a very restrictive join that would produce a small result set relative to the total customer base. The History.Position join to EtoroArchive makes this view inaccessible from the current environment.

---

## 8. Sample Queries

### 8.1 Get the customer profile for a specific customer

```sql
SELECT *
FROM BackOffice.JUNK_GetCustomerAggregations WITH (NOLOCK)
WHERE CID = 123456
```

### 8.2 Find customers with more wins than losses

```sql
SELECT CID, UserName, ProfitPositionCount, NonProfitPositionCount,
       TotalProfit / 100.0 AS TotalProfitUSD
FROM BackOffice.JUNK_GetCustomerAggregations WITH (NOLOCK)
WHERE ProfitPositionCount > NonProfitPositionCount
ORDER BY TotalProfit DESC
```

### 8.3 Analyze most popular first instruments

```sql
SELECT Instruments, COUNT(*) AS CustomerCount,
       AVG(TotalProfit) / 100.0 AS AvgProfitUSD
FROM BackOffice.JUNK_GetCustomerAggregations WITH (NOLOCK)
GROUP BY Instruments
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetCustomerAggregations | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_GetCustomerAggregations.sql*
