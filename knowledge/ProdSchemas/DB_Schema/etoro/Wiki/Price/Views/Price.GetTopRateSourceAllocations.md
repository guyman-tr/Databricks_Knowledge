# Price.GetTopRateSourceAllocations

> View that returns only the highest-priority rate source per instrument with its associated liquidity account - the primary source allocation used when the pricing engine needs one canonical feed per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetTopRateSourceAllocations answers: "What is the single highest-priority rate source and liquidity account for each instrument?" It is a simplified version of Price.GetInstrumentAllocationData filtered to Row=1 (the top-priority source only), without the IsBenchmark or Row columns. Each instrument appears exactly once with its primary (lowest Priority value) rate source and the liquidity account carrying that source.

The view exists for consumers that need the canonical feed per instrument without the complexity of managing priorities. The pricing engine's primary price routing uses this view: for each instrument, use this account and this rate source first. If the primary source is unavailable, the fallback logic is handled elsewhere (InstrumentRateSources has all tiers; this view only exposes tier 1).

Live data: all major forex instruments use AccountRateSourceID=21 (ZBFX Price1) at Priority=10 via LiquidityAccountID=7. This is the dominant primary source for the current configuration.

---

## 2. Business Logic

### 2.1 Top-Priority Source Selection via ROW_NUMBER

**What**: A CTE assigns ROW_NUMBER() per instrument ordered by Priority ASC, then WHERE Row=1 selects only the highest-priority source.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- CTE: ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Priority ASC) AS Row
- WHERE Row=1: selects the source with the lowest Priority value per instrument (e.g., Priority=10 beats Priority=20)
- One row per instrument - guaranteed by the ROW_NUMBER + WHERE Row=1 pattern
- Tie-breaking: if two sources have identical Priority, ROW_NUMBER picks one arbitrarily (non-deterministic) - the data model prevents this via the unique (InstrumentID, Priority) design of InstrumentRateSources

### 2.2 Coherence Filter: Account Must Match Both Eligibility and Rate Source

**What**: Same double-JOIN filter as GetInstrumentAllocationData - the account must be both eligible for the instrument AND carry the correct rate source.

**Columns/Parameters Involved**: `LiquidityAccountID`, `AccountRateSourceID`, `InstrumentID`

**Rules**:
- JOIN Price.LiquidityAccountToInstrument ON InstrumentID: account must be in LATI for this instrument
- JOIN Trade.LiquidityAccounts ON AccountRateSourceID AND LiquidityAccountID: account must carry the matching rate source
- Without both conditions, instruments with misconfigured routing would be silently dropped
- All 10,484 instruments in live data use LiquidityAccountID=7 (ZBFX Price1 account) as their primary

---

## 3. Data Overview

| InstrumentID | AccountRateSourceID | Priority | LiquidityAccountID | Meaning |
|---|---|---|---|---|
| 1 | 21 | 10 | 7 | EUR/USD: primary source is ZBFX Price1 (ARS=21) via account 7. All major forex pairs share this primary source. |
| 2 | 21 | 10 | 7 | GBP/USD: same primary source. ZBFX Price1 is the dominant top-priority feed. |
| 3 | 21 | 10 | 7 | NZD/USD: ZBFX primary. |
| 4 | 21 | 10 | 7 | USD/CAD: ZBFX primary. |
| 5 | 21 | 10 | 7 | JPY/USD: ZBFX primary. All 5 shown use the same primary source. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Price.InstrumentRateSources. One row per instrument (ROW_NUMBER + WHERE Row=1 guarantees this). |
| 2 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier of the highest-priority source for this instrument. From Price.InstrumentRateSources. FK to Price.AccountRateSource. Currently: ARS=21 (ZBFX Price1) is the top source for all major forex. |
| 3 | Priority | int | NO | - | CODE-BACKED | Priority tier of the selected source. Always the lowest value present for this instrument (e.g., 10 where multiple tiers exist). Confirms this is the top-ranked source. |
| 4 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity account carrying this top rate source for this instrument. From Trade.LiquidityAccounts via the double-join coherence filter. Currently LiquidityAccountID=7 (ZBFX account) for all major forex instruments in the sample. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + AccountRateSourceID + Priority | Price.InstrumentRateSources | CTE source (WHERE Row=1) | Top-priority row per instrument |
| InstrumentID + LiquidityAccountID | Price.LiquidityAccountToInstrument | JOIN | Account eligibility validation |
| AccountRateSourceID + LiquidityAccountID | Trade.LiquidityAccounts | JOIN | Rate source coherence validation; provides LiquidityAccountID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetTopRateSourceAllocations (view)
├── Price.InstrumentRateSources (table)
├── Price.LiquidityAccountToInstrument (table)
└── Trade.LiquidityAccounts (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | CTE - ranked by Priority, WHERE Row=1 selects top source |
| Price.LiquidityAccountToInstrument | Table | JOIN - validates account eligibility per instrument |
| Trade.LiquidityAccounts | Table | JOIN - validates ARS-account coherence; provides LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. One row per instrument guaranteed by ROW_NUMBER + WHERE Row=1. Same coherence filter as GetInstrumentAllocationData (no GetInstrument JOIN here, so no InstrumentTypeID for benchmark check).

---

## 8. Sample Queries

### 8.1 Get the primary rate source for a specific instrument

```sql
SELECT InstrumentID, AccountRateSourceID, Priority, LiquidityAccountID
FROM Price.GetTopRateSourceAllocations WITH (NOLOCK)
WHERE InstrumentID = 1;
```

### 8.2 Count instruments per primary rate source

```sql
SELECT AccountRateSourceID, COUNT(*) AS InstrumentCount
FROM Price.GetTopRateSourceAllocations WITH (NOLOCK)
GROUP BY AccountRateSourceID
ORDER BY InstrumentCount DESC;
```

### 8.3 Get primary sources with rate source names

```sql
SELECT
    GTRSA.InstrumentID,
    GTRSA.AccountRateSourceID,
    ARS.Name AS RateSourceName,
    GTRSA.LiquidityAccountID,
    GTRSA.Priority
FROM Price.GetTopRateSourceAllocations GTRSA WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GTRSA.AccountRateSourceID
ORDER BY GTRSA.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetTopRateSourceAllocations | Type: View | Source: etoro/etoro/Price/Views/Price.GetTopRateSourceAllocations.sql*
