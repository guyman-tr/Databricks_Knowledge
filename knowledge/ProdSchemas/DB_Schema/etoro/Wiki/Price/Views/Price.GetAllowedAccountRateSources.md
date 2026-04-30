# Price.GetAllowedAccountRateSources

> View that lists which AccountRateSourceIDs are eligible to price each instrument - a two-column projection of the liquidity account-to-instrument eligibility mapping, used to validate or enumerate allowed price feed sources per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + AccountRateSourceID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetAllowedAccountRateSources answers: "Which rate sources (AccountRateSourceIDs) are authorized to supply prices for a given instrument?" It is a two-column projection of the Price.LiquidityAccountToInstrument eligibility mapping, with the LiquidityAccountID replaced by the account's AccountRateSourceID from Trade.LiquidityAccounts.

This view exists to expose the rate-source-to-instrument eligibility layer without exposing LiquidityAccountID details. Consumers that only need to know "is rate source X allowed for instrument Y?" use this view rather than joining LiquidityAccountToInstrument to LiquidityAccounts themselves. The result is the allowed set: an instrument not present in this view for a given AccountRateSourceID means that source is not configured to price it.

Data characteristics: 13,901 rows covering 6,339 instruments and 27 distinct rate sources. The row count is identical to Price.LiquidityAccountToInstrument because each liquidity account carries exactly one AccountRateSourceID (1:1 account-to-ratesource), so projecting from account to rate source produces no duplicates. An instrument like EUR/USD (ID=1) has 5 eligible rate sources (1, 13, 21, 102, 196), providing pricing redundancy. This view joins Trade.LiquidityAccounts directly (unlike GetAccountRateSourceMapping which uses GetLiquidityAccounts with IsActive=1), so it includes ALL accounts - active or inactive.

---

## 2. Business Logic

### 2.1 Rate Source Eligibility per Instrument

**What**: Each row is an allowed pairing: AccountRateSourceID X is permitted to provide prices for InstrumentID Y.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`

**Rules**:
- Multiple AccountRateSourceIDs per InstrumentID: an instrument is typically covered by 2-5 rate sources, enabling fallback routing.
- All accounts (active and inactive) are included - no IsActive filter. This is the full configured eligibility, not the currently-active subset.
- AccountRateSourceID derives from Trade.LiquidityAccounts.AccountRateSourceID, not from Price.AccountRateSource directly. The JOIN translates LiquidityAccountID into AccountRateSourceID.
- 27 distinct AccountRateSourceIDs correspond to 27 configured liquidity accounts.

**Comparison with GetAccountRateSourceMapping**:
```
GetAccountRateSourceMapping:
  - 3 columns (AccountRateSourceID, InstrumentID, LiquidityAccountID)
  - Joins Trade.GetLiquidityAccounts (IsActive=1 only)
  - Exposes the account identity alongside source and instrument

GetAllowedAccountRateSources (this view):
  - 2 columns (InstrumentID, AccountRateSourceID)
  - Joins Trade.LiquidityAccounts (all accounts)
  - Rate-source-centric: "is source X allowed for instrument Y?"
```

### 2.2 Source Coverage Density

**What**: Each instrument is covered by multiple rate sources to ensure pricing availability.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`

**Rules**:
- 6,339 instruments / 13,901 rows = average 2.19 sources per instrument.
- Major instruments (EUR/USD, GBP/USD, etc.) have 5+ sources; exotic/niche instruments may have only 1.
- AccountRateSourceIDs seen for instrument 1 (EUR/USD): 1 (Simulation Non Stocks), 13 (Xignite variant), 21 (ZBFX), 102 (QuantHouse), 196 (Bloomberg RAW).

---

## 3. Data Overview

| InstrumentID | AccountRateSourceID | Meaning |
|---|---|---|
| 1 | 1 | EUR/USD is eligible to receive prices from rate source 1 (Simulation Non Stocks). Used in demo/simulation mode. |
| 1 | 13 | EUR/USD is also eligible from rate source 13 (Xignite variant). Market data vendor fallback. |
| 1 | 21 | EUR/USD covered by rate source 21 (ZBFX). Direct broker price feed. |
| 1 | 102 | EUR/USD covered by rate source 102 (QuantHouse MBO). Institutional data feed. |
| 1 | 196 | EUR/USD covered by rate source 196 (Bloomberg RAW). Bloomberg direct feed. Five sources for EUR/USD - the most critical forex pair receives maximum redundancy. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Price.LiquidityAccountToInstrument. Identifies the tradeable instrument (forex pair, stock, crypto, index, commodity). FK to Trade.Instrument. Multiple rows per InstrumentID (one per eligible rate source). |
| 2 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier sourced from Trade.LiquidityAccounts.AccountRateSourceID (the account's assigned feed). FK to Price.AccountRateSource. Identifies which named price data provider (Bloomberg, ZBFX, Xignite, Simulation, etc.) is eligible for this instrument. See Price.AccountRateSource for the full registry of source names and categories. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup (via LiquidityAccountToInstrument) | Identifies the instrument being priced |
| AccountRateSourceID | Price.AccountRateSource | Lookup (via LiquidityAccounts) | Resolves to named rate source (Bloomberg, ZBFX, etc.) |
| LiquidityAccountID | Price.LiquidityAccountToInstrument | Direct JOIN source | Eligibility row |
| LiquidityAccountID | Trade.LiquidityAccounts | JOIN | Provides AccountRateSourceID per account |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetAllowedAccountRateSources (view)
├── Price.LiquidityAccountToInstrument (table)
└── Trade.LiquidityAccounts (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityAccountToInstrument | Table | FROM - provides (LiquidityAccountID, InstrumentID) row set |
| Trade.LiquidityAccounts | Table | INNER JOIN on LiquidityAccountID - provides AccountRateSourceID (all accounts, no IsActive filter) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. No active-only filter (unlike GetAccountRateSourceMapping).

---

## 8. Sample Queries

### 8.1 Find all allowed rate sources for a specific instrument

```sql
SELECT InstrumentID, AccountRateSourceID
FROM Price.GetAllowedAccountRateSources WITH (NOLOCK)
WHERE InstrumentID = 1  -- EUR/USD
ORDER BY AccountRateSourceID;
```

### 8.2 Count coverage per instrument (find under-covered instruments)

```sql
SELECT InstrumentID, COUNT(*) AS AllowedSourceCount
FROM Price.GetAllowedAccountRateSources WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(*) = 1
ORDER BY InstrumentID;
```

### 8.3 Join to AccountRateSource for source names

```sql
SELECT
    GAARS.InstrumentID,
    GAARS.AccountRateSourceID,
    ARS.Name AS RateSourceName
FROM Price.GetAllowedAccountRateSources GAARS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GAARS.AccountRateSourceID
WHERE GAARS.InstrumentID = 1
ORDER BY GAARS.AccountRateSourceID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetAllowedAccountRateSources | Type: View | Source: etoro/etoro/Price/Views/Price.GetAllowedAccountRateSources.sql*
