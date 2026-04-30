# Price.PriceServerToLiquidityAccount

> Configuration table that maps price server IDs to the liquidity accounts they are responsible for, enabling the pricing engine to resolve which rate source feeds each price server uses.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (PriceServerID, LiquidityAccountID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

PriceServerToLiquidityAccount maps each price server (referenced as `PriceServerID` in `Trade.Instrument`) to one or more liquidity accounts. A price server is a process instance responsible for computing prices for a set of instruments; its assigned liquidity accounts determine which market data feeds it sources prices from. This table is the server-to-account assignment registry.

The primary consumer is `Price.GetPriceServerAccountAllocation`, a view that enriches this mapping with the `AccountRateSourceID` from `Trade.LiquidityAccounts`, enabling callers to resolve the full chain: price server -> liquidity account -> rate source. This is analogous to `Price.PCSToLiquidityAccount`, which maps PCS (Price Calculation Service) instances to accounts, but `PriceServerToLiquidityAccount` maps price server instances specifically.

The table is currently empty (0 rows) and has no temporal versioning or audit columns - it is a simple assignment table with only two data columns (both forming the composite PK). PriceServerID has no FK constraint; price server IDs are defined externally.

---

## 2. Business Logic

### 2.1 Price Server to Account Assignment

**What**: Declares which liquidity accounts a given price server is responsible for processing.

**Columns/Parameters Involved**: `PriceServerID`, `LiquidityAccountID`

**Rules**:
- Composite PK (PriceServerID, LiquidityAccountID) prevents duplicate assignments
- One PriceServerID can be assigned to multiple LiquidityAccountIDs (one-to-many)
- PriceServerID has no FK constraint - managed externally
- LiquidityAccountID FK-validated against Trade.LiquidityAccounts

### 2.2 Rate Source Resolution via GetPriceServerAccountAllocation

**What**: The view enriches the mapping with the rate source identifier needed for pricing.

**Columns/Parameters Involved**: `PriceServerID`, `LiquidityAccountID`

**Rules**:
- `GetPriceServerAccountAllocation` INNER JOINs this table with Trade.LiquidityAccounts to add AccountRateSourceID
- Output: `PriceServerID, LiquidityAccountID, AccountRateSourceID`
- Used by downstream pricing systems to route price computation to the correct feed

---

## 3. Data Overview

The table is currently empty (0 rows). No price server to account assignments are configured.

*When populated, rows would appear as:*

| PriceServerID | LiquidityAccountID | Meaning |
|---|---|---|
| 1 | 21 | Price server 1 is assigned to LiquidityAccount 21 (FD/EtoroAll feed) |
| 2 | 103 | Price server 2 is assigned to LiquidityAccount 103 |
| 2 | 7 | Price server 2 also handles LiquidityAccount 7 (serves multiple accounts) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceServerID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. The price server instance identifier. References the same PriceServerID found in Trade.Instrument (each instrument is assigned to a price server). No FK constraint - price server lifecycle is managed externally. |
| 2 | LiquidityAccountID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Trade.LiquidityAccounts. The liquidity account assigned to this price server. Each liquidity account has an AccountRateSourceID that identifies the market data feed. (Trade.LiquidityAccounts) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (unnamed) | The liquidity account assigned to this price server |
| PriceServerID | Trade.Instrument (indirect) | Logical (no FK) | PriceServerID is referenced in Trade.Instrument - price servers are logically tied to the instruments they price |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetPriceServerAccountAllocation | PriceServerID, LiquidityAccountID | READER | Returns all mappings enriched with AccountRateSourceID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.PriceServerToLiquidityAccount (table)
|- Trade.LiquidityAccounts (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK target - LiquidityAccountID must reference a valid liquidity account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetPriceServerAccountAllocation | View | Base table - returns assignments enriched with AccountRateSourceID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceServerToLiquidityAccount | CLUSTERED PK | PriceServerID ASC, LiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PriceServerToLiquidityAccount | PRIMARY KEY | One assignment per (price server, liquidity account) pair |
| FK (unnamed) | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

---

## 8. Sample Queries

### 8.1 View all price server assignments with account names

```sql
SELECT
    PSLA.PriceServerID,
    PSLA.LiquidityAccountID,
    LA.LiquidityAccountName,
    LA.AccountRateSourceID
FROM Price.PriceServerToLiquidityAccount PSLA WITH (NOLOCK)
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
    ON LA.LiquidityAccountID = PSLA.LiquidityAccountID
ORDER BY PSLA.PriceServerID;
```

### 8.2 Use the enriched view for full allocation detail

```sql
SELECT PriceServerID, LiquidityAccountID, AccountRateSourceID
FROM Price.GetPriceServerAccountAllocation WITH (NOLOCK)
ORDER BY PriceServerID, LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PriceServerToLiquidityAccount | Type: Table | Source: etoro/etoro/Price/Tables/Price.PriceServerToLiquidityAccount.sql*
