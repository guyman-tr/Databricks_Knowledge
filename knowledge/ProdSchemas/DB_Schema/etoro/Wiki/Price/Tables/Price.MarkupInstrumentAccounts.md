# Price.MarkupInstrumentAccounts

> Configuration table that maps each instrument to a liquidity account and a maximum price deviation percentage for markup pricing, defining which account provides the markup basis and the acceptable spread tolerance for that instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

MarkupInstrumentAccounts defines markup pricing configuration on a per-instrument basis. A "markup" pricing model is one where an instrument's displayed price is derived by adding a spread or markup on top of a reference price sourced from a specific liquidity account. This table records, for each instrument: which liquidity account provides the reference price (`LiquidityAccountID`) and the maximum tolerated deviation between the markup price and the reference (`MaxDiffPercentage`).

The `Price.GetMarkupInstrumentAccounts` view enriches this table with the `PriceServerID` from `Trade.Instrument` and the `AccountRateSourceID` from `Trade.LiquidityAccounts`, enabling downstream systems to fully resolve the pricing chain: instrument -> price server -> liquidity account -> rate source -> markup tolerance.

The table currently holds 0 rows, meaning no markup pricing configurations are active. It uses a single-column PK on InstrumentID, enforcing one liquidity account and one tolerance per instrument. There is no temporal auditing or computed columns - changes are tracked only via standard DML audit means.

---

## 2. Business Logic

### 2.1 One Markup Account per Instrument

**What**: Each instrument can be assigned to exactly one liquidity account for markup-based pricing with one maximum deviation percentage.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `MaxDiffPercentage`

**Rules**:
- PK on InstrumentID enforces one-to-one: an instrument can have at most one markup account mapping
- LiquidityAccountID is NOT NULL and FK-validated against Trade.LiquidityAccounts
- MaxDiffPercentage is decimal(18,6) NOT NULL - supports highly precise percentage values (e.g., 0.250000 = 0.25%)
- No procedures currently write to this table - population must be via direct DML or a management procedure not yet present

### 2.2 Markup Pricing View Enrichment

**What**: `Price.GetMarkupInstrumentAccounts` surfaces the markup config alongside the pricing infrastructure identifiers needed to route prices.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `MaxDiffPercentage`

**Rules**:
- View joins this table with Trade.Instrument (adds PriceServerID) and Trade.LiquidityAccounts (adds AccountRateSourceID)
- Output: `InstrumentID, LiquidityAccountID, PriceServerID, AccountRateSourceID, MaxDiffPercentage`
- INNER JOIN used (not LEFT JOIN) - instruments not in this table are excluded from the view result

---

## 3. Data Overview

The table is currently empty (0 rows). No markup instrument account configurations are active.

*When populated, rows would appear as:*

| InstrumentID | LiquidityAccountID | MaxDiffPercentage | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 21 | 0.500000 | EUR/USD uses LiquidityAccount 21 for markup basis; deviation above 0.5% is flagged or rejected |
| 5 | 103 | 0.250000 | Instrument 5 uses LiquidityAccount 103; tighter tolerance of 0.25% |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. FK to Trade.Instrument. The trading instrument for which markup pricing is configured. One row per instrument enforced by single-column PK. (Trade.Instrument) |
| 2 | LiquidityAccountID | int | NOT NULL | - | VERIFIED | FK to Trade.LiquidityAccounts. The liquidity account that provides the reference price used as the basis for markup pricing for this instrument. The associated AccountRateSourceID in Trade.LiquidityAccounts identifies the rate source feed. (Trade.LiquidityAccounts) |
| 3 | MaxDiffPercentage | decimal(18,6) | NOT NULL | - | NAME-INFERRED | The maximum allowable percentage deviation between the markup-derived price and the reference price from the liquidity account. Prevents the markup from drifting too far from the underlying feed. Exact enforcement logic depends on consuming code (no active procedures found). Expressed as a percentage value (e.g., 0.5 = 0.5%). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_MarkupInstrumentAccounts_InstrumentID) | The instrument for which markup pricing is configured |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_MarkupInstrumentAccounts_LiquidityAccountID) | The liquidity account providing the reference price for markup calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetMarkupInstrumentAccounts | InstrumentID, LiquidityAccountID | READER | Returns all markup configurations enriched with PriceServerID and AccountRateSourceID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.MarkupInstrumentAccounts (table)
|- Trade.Instrument (table, FK target - leaf)
|- Trade.LiquidityAccounts (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Trade.LiquidityAccounts | Table | FK target - LiquidityAccountID must reference a valid liquidity account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetMarkupInstrumentAccounts | View | Base table - INNER JOINs this table to enrich with PriceServerID and AccountRateSourceID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarkupInstrumentAccounts | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MarkupInstrumentAccounts | PRIMARY KEY | One markup account per instrument (InstrumentID) |
| FK_MarkupInstrumentAccounts_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_MarkupInstrumentAccounts_LiquidityAccountID | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

---

## 8. Sample Queries

### 8.1 View all markup configurations with names

```sql
SELECT
    MIA.InstrumentID,
    I.InstrumentName,
    MIA.LiquidityAccountID,
    LA.LiquidityAccountName,
    MIA.MaxDiffPercentage
FROM Price.MarkupInstrumentAccounts MIA WITH (NOLOCK)
JOIN Trade.Instrument I WITH (NOLOCK)
    ON I.InstrumentID = MIA.InstrumentID
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
    ON LA.LiquidityAccountID = MIA.LiquidityAccountID
ORDER BY MIA.InstrumentID;
```

### 8.2 Use the enriched view to get full pricing chain

```sql
SELECT
    InstrumentID,
    LiquidityAccountID,
    PriceServerID,
    AccountRateSourceID,
    MaxDiffPercentage
FROM Price.GetMarkupInstrumentAccounts WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.3 Find instruments whose tolerance exceeds a threshold

```sql
SELECT
    MIA.InstrumentID,
    MIA.LiquidityAccountID,
    MIA.MaxDiffPercentage
FROM Price.MarkupInstrumentAccounts MIA WITH (NOLOCK)
WHERE MIA.MaxDiffPercentage > 1.0  -- more than 1% tolerance
ORDER BY MIA.MaxDiffPercentage DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.MarkupInstrumentAccounts | Type: Table | Source: etoro/etoro/Price/Tables/Price.MarkupInstrumentAccounts.sql*
