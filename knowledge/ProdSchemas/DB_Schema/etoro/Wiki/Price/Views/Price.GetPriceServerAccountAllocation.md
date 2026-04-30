# Price.GetPriceServerAccountAllocation

> View that maps each price server to its assigned liquidity accounts with their rate source IDs, exposing the price server to feed routing allocation used by the pricing engine.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | PriceServerID + LiquidityAccountID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetPriceServerAccountAllocation answers: "Which liquidity accounts is each price server responsible for, and what rate source does each account carry?" It joins Price.PriceServerToLiquidityAccount with Trade.LiquidityAccounts to add AccountRateSourceID alongside the server-to-account assignment.

The view exists so the pricing engine can determine, for a given PriceServerID, which liquidity accounts it manages and what rate sources those accounts represent. This is the server-level routing table: a price server needs to know its assigned accounts to know which price feeds it must subscribe to and process. Adding AccountRateSourceID completes the chain from server -> account -> rate source.

Current state: Price.PriceServerToLiquidityAccount is empty (0 rows), so this view returns 0 rows. The price server assignment system is provisioned but not populated. (Note: PriceServerID values are observed in live data from Trade.Instrument - values 1, 3 seen for EUR/USD and GBP/USD - but no server-to-account assignments are configured in this table yet.)

---

## 2. Business Logic

### 2.1 Price Server to Rate Source Resolution

**What**: Joins the server-to-account assignment with the account's rate source to fully describe each server's feed subscriptions.

**Columns/Parameters Involved**: `PriceServerID`, `LiquidityAccountID`, `AccountRateSourceID`

**Rules**:
- PriceServerID: externally defined (no FK in PriceServerToLiquidityAccount); matches PriceServerID in Trade.Instrument
- INNER JOIN to Trade.LiquidityAccounts: accounts not in LiquidityAccounts are excluded; provides AccountRateSourceID
- One price server can appear multiple times (one row per assigned liquidity account)
- AccountRateSourceID identifies the named feed (ZBFX, Bloomberg, Simulation, etc.) the account carries

**Pricing routing chain**:
```
Trade.Instrument.PriceServerID
  -> Price.GetPriceServerAccountAllocation (this view)
       -> PriceServerID + LiquidityAccountID pairs
       -> AccountRateSourceID (rate source the account carries)
  -> Pricing engine subscribes to AccountRateSourceID feeds for these instruments
```

---

## 3. Data Overview

*The view currently returns 0 rows - Price.PriceServerToLiquidityAccount is empty. No price server to account assignments are configured.*

*When populated, rows would appear as:*

| PriceServerID | LiquidityAccountID | AccountRateSourceID | Meaning |
|---|---|---|---|
| 1 | 7 | 21 | Price server 1 is assigned account 7 (ZBFX Price1, ARS=21). Server 1 handles EUR/USD, NZD/USD etc. |
| 3 | 7 | 21 | Price server 3 is also assigned account 7. Server 3 handles GBP/USD. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceServerID | int | NO | - | CODE-BACKED | Price server instance identifier from Price.PriceServerToLiquidityAccount. Matches PriceServerID in Trade.Instrument - the server responsible for computing prices for instruments with this ID. No FK constraint in base table; managed externally. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity account assigned to this price server. From Price.PriceServerToLiquidityAccount. FK to Trade.LiquidityAccounts. The account provides the price feed subscription for this server. |
| 3 | AccountRateSourceID | int | YES | - | CODE-BACKED | Rate source carried by the liquidity account, from Trade.LiquidityAccounts.AccountRateSourceID. FK to Price.AccountRateSource. Identifies the named feed (e.g., ZBFX=21, Bloomberg=196) that this price server subscribes to via this account. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PriceServerID + LiquidityAccountID | Price.PriceServerToLiquidityAccount | FROM source | Server-to-account assignment pairs |
| LiquidityAccountID + AccountRateSourceID | Trade.LiquidityAccounts | INNER JOIN | Provides AccountRateSourceID per account |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetPriceServerAccountAllocation (view)
├── Price.PriceServerToLiquidityAccount (table)
└── Trade.LiquidityAccounts (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PriceServerToLiquidityAccount | Table | FROM (PSLA alias) - price server to account assignments |
| Trade.LiquidityAccounts | Table | JOIN on LiquidityAccountID (LA alias) - provides AccountRateSourceID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. INNER JOIN - accounts not in Trade.LiquidityAccounts excluded. Currently returns 0 rows.

---

## 8. Sample Queries

### 8.1 Get all accounts assigned to a specific price server

```sql
SELECT PriceServerID, LiquidityAccountID, AccountRateSourceID
FROM Price.GetPriceServerAccountAllocation WITH (NOLOCK)
WHERE PriceServerID = 1
ORDER BY LiquidityAccountID;
```

### 8.2 Get server assignments with rate source names

```sql
SELECT
    GPSAA.PriceServerID,
    GPSAA.LiquidityAccountID,
    ARS.Name AS RateSourceName
FROM Price.GetPriceServerAccountAllocation GPSAA WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GPSAA.AccountRateSourceID
ORDER BY GPSAA.PriceServerID, GPSAA.LiquidityAccountID;
```

### 8.3 Count accounts per price server

```sql
SELECT PriceServerID, COUNT(*) AS AccountCount
FROM Price.GetPriceServerAccountAllocation WITH (NOLOCK)
GROUP BY PriceServerID
ORDER BY PriceServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetPriceServerAccountAllocation | Type: View | Source: etoro/etoro/Price/Views/Price.GetPriceServerAccountAllocation.sql*
