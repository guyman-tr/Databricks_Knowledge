# Price.GetMarkupInstrumentAccounts

> View that enriches the markup pricing configuration table with PriceServerID and AccountRateSourceID, exposing the full pricing chain for instruments configured for markup-based pricing.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetMarkupInstrumentAccounts answers: "For instruments using markup-based pricing, what is the full configuration chain - instrument, price server, liquidity account, rate source, and deviation tolerance?" It enriches Price.MarkupInstrumentAccounts with two infrastructure identifiers from cross-schema tables: PriceServerID (from Trade.Instrument) and AccountRateSourceID (from Trade.LiquidityAccounts).

A markup pricing model derives displayed prices from a reference price provided by a specific liquidity account, with a MaxDiffPercentage tolerance controlling how far the derived price can deviate from the reference. This view resolves the full chain needed to implement that model: which price server handles the instrument, which account provides the reference, and what the tolerance is.

Current state: Price.MarkupInstrumentAccounts contains 0 rows, so this view returns 0 rows. The markup pricing system is provisioned but not actively configured.

---

## 2. Business Logic

### 2.1 Markup Pricing Chain Resolution

**What**: Joins three objects to expose the full pricing chain for each markup-configured instrument.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `PriceServerID`, `AccountRateSourceID`, `MaxDiffPercentage`

**Rules**:
- One row per InstrumentID (PK on MarkupInstrumentAccounts enforces one account per instrument)
- INNER JOIN to Trade.Instrument: adds PriceServerID for routing; excludes instruments not in Trade.Instrument
- INNER JOIN to Trade.LiquidityAccounts: adds AccountRateSourceID of the reference account; excludes if account missing
- MaxDiffPercentage is the deviation threshold: prices deviating beyond this percentage from the reference trigger flagging or rejection

**Pricing chain**:
```
InstrumentID
  -> PriceServerID (Trade.Instrument)        - which price server handles this instrument
  -> LiquidityAccountID (MarkupInstrumentAccounts) - reference account for markup basis
  -> AccountRateSourceID (Trade.LiquidityAccounts) - rate source of the reference account
  -> MaxDiffPercentage (MarkupInstrumentAccounts)  - allowed deviation from reference
```

---

## 3. Data Overview

*The view currently returns 0 rows - Price.MarkupInstrumentAccounts is empty. No markup instrument configurations are active.*

*When populated, rows would appear as:*

| InstrumentID | LiquidityAccountID | PriceServerID | AccountRateSourceID | MaxDiffPercentage | Meaning |
|---|---|---|---|---|---|
| 1 | 7 | 1 | 21 | 0.500000 | EUR/USD uses account 7 (ZBFX) as markup reference via rate source 21, via price server 1. Max deviation 0.5%. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Price.MarkupInstrumentAccounts. One row per instrument (PK enforces). Must exist in Trade.Instrument (INNER JOIN). |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity account providing the reference price for markup computation. From Price.MarkupInstrumentAccounts. FK to Trade.LiquidityAccounts. |
| 3 | PriceServerID | int | YES | - | CODE-BACKED | Price server identifier from Trade.Instrument. Identifies which price server partition handles this instrument's pricing. |
| 4 | AccountRateSourceID | int | YES | - | CODE-BACKED | Rate source of the reference liquidity account, from Trade.LiquidityAccounts.AccountRateSourceID. Identifies the named feed (Bloomberg, ZBFX, etc.) providing the markup reference price. |
| 5 | MaxDiffPercentage | decimal(18,6) | NO | - | CODE-BACKED | Maximum allowed deviation (in percentage) between the markup-derived price and the reference price from the liquidity account. Example: 0.500000 = 0.5% tolerance. Prices exceeding this threshold may be flagged or rejected by the pricing engine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + PriceServerID | Trade.Instrument | INNER JOIN | Provides PriceServerID and validates instrument |
| LiquidityAccountID + AccountRateSourceID | Trade.LiquidityAccounts | INNER JOIN | Resolves rate source of the reference account |
| InstrumentID + LiquidityAccountID + MaxDiffPercentage | Price.MarkupInstrumentAccounts | FROM source | Core markup configuration |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetMarkupInstrumentAccounts (view)
├── Price.MarkupInstrumentAccounts (table)
├── Trade.Instrument (table)
└── Trade.LiquidityAccounts (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.MarkupInstrumentAccounts | Table | FROM (t1 alias) - markup config (InstrumentID, LiquidityAccountID, MaxDiffPercentage) |
| Trade.Instrument | Table | INNER JOIN on InstrumentID (t2 alias) - provides PriceServerID |
| Trade.LiquidityAccounts | Table | INNER JOIN on LiquidityAccountID (t3 alias) - provides AccountRateSourceID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. All INNER JOINs - instruments not in Trade.Instrument or accounts not in Trade.LiquidityAccounts are excluded. Currently returns 0 rows.

---

## 8. Sample Queries

### 8.1 Get markup configuration for a specific instrument

```sql
SELECT InstrumentID, LiquidityAccountID, PriceServerID, AccountRateSourceID, MaxDiffPercentage
FROM Price.GetMarkupInstrumentAccounts WITH (NOLOCK)
WHERE InstrumentID = 1;
```

### 8.2 List all markup-configured instruments with source names

```sql
SELECT
    GMIA.InstrumentID,
    GMIA.LiquidityAccountID,
    GMIA.PriceServerID,
    ARS.Name AS RateSourceName,
    GMIA.MaxDiffPercentage
FROM Price.GetMarkupInstrumentAccounts GMIA WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GMIA.AccountRateSourceID
ORDER BY GMIA.InstrumentID;
```

### 8.3 Find instruments with tight deviation tolerance

```sql
SELECT InstrumentID, LiquidityAccountID, MaxDiffPercentage
FROM Price.GetMarkupInstrumentAccounts WITH (NOLOCK)
WHERE MaxDiffPercentage < 0.100000
ORDER BY MaxDiffPercentage;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetMarkupInstrumentAccounts | Type: View | Source: etoro/etoro/Price/Views/Price.GetMarkupInstrumentAccounts.sql*
