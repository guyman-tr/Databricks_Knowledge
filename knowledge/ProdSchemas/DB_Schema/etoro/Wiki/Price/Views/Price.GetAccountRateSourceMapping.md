# Price.GetAccountRateSourceMapping

> Read-only view that maps each active liquidity account's assigned rate source to the instruments it is eligible to price - the primary lookup used by the pricing engine to resolve which AccountRateSourceID feeds prices for a given instrument via which liquidity account.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | AccountRateSourceID + InstrumentID + LiquidityAccountID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetAccountRateSourceMapping answers: "For each active liquidity account, what rate source does it carry, and for which instruments is it eligible?" Each row is a triple: a rate source (AccountRateSourceID), an instrument (InstrumentID), and the active liquidity account that bridges them (LiquidityAccountID). This is the core routing lookup used by the eToro pricing engine to find valid price feeds for an instrument.

The view exists because Trade.LiquidityAccounts holds the AccountRateSourceID (the feed type), and Price.LiquidityAccountToInstrument holds the instrument coverage per account, but neither table alone answers "which rate source can price this instrument?" The JOIN here combines both: it reads the instrument-to-account eligibility from LiquidityAccountToInstrument and enriches each row with the AccountRateSourceID from the matched active liquidity account in Trade.GetLiquidityAccounts. The JOIN to GetLiquidityAccounts also serves as an IsActive=1 filter - inactive accounts are silently excluded.

Data flows: Price.LiquidityAccountToInstrument drives the row set (all instrument-account pairs); Trade.GetLiquidityAccounts provides the AccountRateSourceID and enforces active-only scope. The result is used by downstream configuration views and pricing operations tooling that need to know which named price sources (Bloomberg, ZBFX, Simulation, etc.) are assigned to each instrument.

---

## 2. Business Logic

### 2.1 Active-Account Filter via GetLiquidityAccounts JOIN

**What**: The INNER JOIN to Trade.GetLiquidityAccounts implicitly filters to active accounts only (GetLiquidityAccounts contains WHERE IsActive=1 on its base table).

**Columns/Parameters Involved**: `LiquidityAccountID`

**Rules**:
- Any LiquidityAccountID in LiquidityAccountToInstrument that does NOT appear in GetLiquidityAccounts (i.e., IsActive=0) is excluded from results.
- No explicit WHERE clause in this view; the active-only scope is inherited from the sub-view.
- This means the view always reflects the current live routing - deactivated accounts disappear automatically.

**Diagram**:
```
Price.LiquidityAccountToInstrument   Trade.GetLiquidityAccounts
  (LiquidityAccountID, InstrumentID)   (IsActive=1 only)
            |                                  |
            +-------- INNER JOIN on --------- +
                      LiquidityAccountID
                           |
                           v
         Price.GetAccountRateSourceMapping
           AccountRateSourceID (from GetLiquidityAccounts)
           InstrumentID        (from LiquidityAccountToInstrument)
           LiquidityAccountID  (from LiquidityAccountToInstrument)
```

### 2.2 Rate Source to Instrument Resolution

**What**: The view bridges the gap between "which instruments can this account price?" (LiquidityAccountToInstrument) and "which rate source does this account carry?" (LiquidityAccounts.AccountRateSourceID), producing the full triple used by the pricing engine configuration layer.

**Columns/Parameters Involved**: `AccountRateSourceID`, `InstrumentID`, `LiquidityAccountID`

**Rules**:
- One row per (AccountRateSourceID, InstrumentID, LiquidityAccountID) combination.
- Multiple rows per InstrumentID are expected: an instrument covered by 2+ active accounts will appear 2+ times, with different LiquidityAccountIDs and potentially different AccountRateSourceIDs.
- AccountRateSourceID=1 (Simulation Non Stocks, from LiquidityAccountID=1) will appear for all instruments covered by account 1.
- AccountRateSourceID=21 (ZBFX, from LiquidityAccountID=7) will appear for all instruments covered by account 7.

---

## 3. Data Overview

| AccountRateSourceID | InstrumentID | LiquidityAccountID | Meaning |
|---|---|---|---|
| 1 | 1 | 1 | Instrument 1 (EUR/USD) can receive prices from AccountRateSource 1 (Simulation Non Stocks) via liquidity account 1. |
| 1 | 2 | 1 | Instrument 2 (GBP/USD) is covered by the same simulation feed. Account 1 services multiple instruments. |
| 1 | 3 | 1 | Instrument 3 covered by account 1 / rate source 1. Typical bulk-mapping row. |
| 21 | 1 | 7 | Instrument 1 (EUR/USD) is ALSO covered by rate source 21 (ZBFX) via account 7. Multiple sources per instrument provide redundancy. |
| 21 | 2 | 7 | Instrument 2 (GBP/USD) covered by account 7 / rate source 21 as secondary source. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier assigned to this liquidity account. Sourced from Trade.GetLiquidityAccounts.AccountRateSourceID (which reads Trade.LiquidityAccounts.AccountRateSourceID). FK to Price.AccountRateSource. Values: -1=US special, 0=Do not use!, 1-6=Simulation feeds, 9001-9006=FIX protocol, 20-24=broker feeds (Goldman, ZBFX...), 196-197=Bloomberg. See Price.AccountRateSource for full registry. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Price.LiquidityAccountToInstrument. Identifies the tradeable instrument (forex pair, stock, crypto, etc.) this account-source pair can price. FK to Trade.Instrument. |
| 3 | LiquidityAccountID | int | NO | - | CODE-BACKED | Active liquidity account identifier from Price.LiquidityAccountToInstrument (aliased as LATI). Must exist in Trade.GetLiquidityAccounts (IsActive=1). Links AccountRateSourceID to InstrumentID. FK to Trade.LiquidityAccounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountRateSourceID | Price.AccountRateSource | Lookup (via LiquidityAccounts) | Rate source name resolution; AccountRateSourceID identifies the feed type |
| InstrumentID | Trade.Instrument | Lookup (via LiquidityAccountToInstrument) | Tradeable instrument covered by this rate source |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (via GetLiquidityAccounts, IsActive=1 only) | Active liquidity account carrying this rate source |
| LiquidityAccountID | Price.LiquidityAccountToInstrument | Direct JOIN source | Instrument eligibility mapping |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetAccountRateSourceMapping (view)
├── Price.LiquidityAccountToInstrument (table)
└── Trade.GetLiquidityAccounts (view)
      ├── Trade.LiquidityAccounts (table)
      └── Price.AccountRateSource (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityAccountToInstrument | Table | FROM - provides (LiquidityAccountID, InstrumentID) pairs as the driving row set |
| Trade.GetLiquidityAccounts | View | INNER JOIN on LiquidityAccountID - provides AccountRateSourceID and enforces IsActive=1 filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. No WITH CHECK OPTION.

---

## 8. Sample Queries

### 8.1 Find all rate sources eligible to price a specific instrument

```sql
SELECT AccountRateSourceID, LiquidityAccountID
FROM Price.GetAccountRateSourceMapping WITH (NOLOCK)
WHERE InstrumentID = 1  -- EUR/USD
ORDER BY AccountRateSourceID;
```

### 8.2 Count instruments covered per rate source

```sql
SELECT AccountRateSourceID, COUNT(DISTINCT InstrumentID) AS InstrumentCount
FROM Price.GetAccountRateSourceMapping WITH (NOLOCK)
GROUP BY AccountRateSourceID
ORDER BY InstrumentCount DESC;
```

### 8.3 Join to AccountRateSource for human-readable source names

```sql
SELECT
    GARSM.AccountRateSourceID,
    ARS.Name AS RateSourceName,
    GARSM.InstrumentID,
    GARSM.LiquidityAccountID
FROM Price.GetAccountRateSourceMapping GARSM WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GARSM.AccountRateSourceID
WHERE GARSM.InstrumentID = 1
ORDER BY GARSM.LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetAccountRateSourceMapping | Type: View | Source: etoro/etoro/Price/Views/Price.GetAccountRateSourceMapping.sql*
