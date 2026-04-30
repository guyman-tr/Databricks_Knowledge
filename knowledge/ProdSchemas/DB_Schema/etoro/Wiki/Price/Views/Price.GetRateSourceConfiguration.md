# Price.GetRateSourceConfiguration

> View that resolves the full PCS-to-instrument rate source mapping - for each instrument with a price server, shows which AccountRateSourceIDs are reachable via PCS-assigned liquidity accounts.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | PriceServerID + AccountRateSourceID + InstrumentID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetRateSourceConfiguration answers: "For each instrument, which PCS-assigned rate sources can provide prices, and via which price server?" It builds the full routing chain PCS -> LiquidityAccount -> Instrument -> AccountRateSourceID, then RIGHT JOINs Trade.Instrument to ensure all instruments with a PriceServerID appear - even those not reachable via any PCS account (they would have NULL AccountRateSourceID).

The view bridges the PCS assignment system (PCSToLiquidityAccount) with the instrument coverage layer (LiquidityAccountToInstrument). The RIGHT JOIN design is deliberate: an instrument should always appear in this view if it has a PriceServerID, giving the pricing engine a complete inventory of instruments alongside their available PCS-routed rate sources. An instrument row with NULL AccountRateSourceID signals a gap - the instrument has a price server but no PCS-managed feed.

Data: 11,010 rows across 10,484 unique instruments. The 526 extra rows (11,010 - 10,484) come from instruments covered by multiple PCS-assigned accounts (e.g., EUR/USD has 2 rows: ZBFX via ARS=21 and QuantHouse MBO via ARS=102, both via PriceServerID=1). WHERE PriceServerID IS NOT NULL filters out instruments lacking a price server assignment.

---

## 2. Business Logic

### 2.1 RIGHT JOIN Pattern - All Instruments Included

**What**: The RIGHT JOIN to Trade.Instrument ensures ALL instruments with PriceServerID appear, regardless of PCS account coverage.

**Columns/Parameters Involved**: `PriceServerID`, `AccountRateSourceID`, `InstrumentID`

**Rules**:
- Instruments WITH a PCS-routed account: AccountRateSourceID is populated, PriceServerID comes from Trade.Instrument
- Instruments WITHOUT any PCS-routed account: AccountRateSourceID=NULL (gap alert)
- WHERE PriceServerID IS NOT NULL: instruments with NULL PriceServerID in Trade.Instrument are excluded entirely
- An instrument can appear multiple times (once per PCS-assigned account that covers it)

**JOIN chain**:
```
PCSToLiquidityAccount (PCSID -> LiquidityAccountID)
  -> LiquidityAccountToInstrument (LiquidityAccountID -> InstrumentID)
  -> LiquidityAccounts (LiquidityAccountID -> AccountRateSourceID)
  RIGHT JOIN Trade.Instrument (all instruments, driving set)
  WHERE PriceServerID IS NOT NULL
```

### 2.2 Multi-Source Instruments

**What**: An instrument covered by multiple PCS-assigned accounts generates multiple rows, one per AccountRateSourceID.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`

**Rules**:
- EUR/USD (ID=1): 2 rows - ARS=21 (ZBFX Price1) and ARS=102 (QuantHouse MBO), both via PriceServerID=1
- GBP/USD (ID=2): 2 rows - same ARS combination via PriceServerID=3
- Multiple rows = multiple feed sources available for this instrument via PCS routing

---

## 3. Data Overview

| PriceServerID | AccountRateSourceID | InstrumentID | Meaning |
|---|---|---|---|
| 1 | 21 | 1 | EUR/USD priced via price server 1 using ZBFX Price1 (ARS=21) through a PCS-assigned account. |
| 1 | 102 | 1 | EUR/USD also reachable via QuantHouse MBO (ARS=102) through another PCS-assigned account on server 1. Two sources = redundancy. |
| 3 | 21 | 2 | GBP/USD on price server 3, ZBFX source. Different server from EUR/USD. |
| 3 | 102 | 2 | GBP/USD also via QuantHouse MBO on server 3. Same dual-source pattern. |
| 1 | 21 | 3 | Instrument 3 on price server 1 via ZBFX. Single source in this sample. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceServerID | int | YES | - | CODE-BACKED | Price server identifier from Trade.Instrument. Identifies which price server handles this instrument. NULL only for instruments excluded by WHERE clause. Values observed: 1, 2, 3 (different server partitions). |
| 2 | AccountRateSourceID | int | YES | - | CODE-BACKED | Rate source identifier from Trade.LiquidityAccounts. NULL when no PCS-assigned account covers this instrument (RIGHT JOIN gap). When populated, identifies the named feed (ZBFX=21, QuantHouse MBO=102, etc.) reachable via PCS routing for this instrument. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. Driving column from the RIGHT JOIN to Trade.Instrument. Always populated (WHERE PriceServerID IS NOT NULL ensures non-null). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountRateSourceID (via accounts) | Price.PCSToLiquidityAccount | INNER JOIN | PCS-to-account assignment chain |
| InstrumentID | Price.LiquidityAccountToInstrument | INNER JOIN | Account-to-instrument coverage |
| AccountRateSourceID | Trade.LiquidityAccounts | INNER JOIN | Rate source of the coverage account |
| InstrumentID + PriceServerID | Trade.Instrument | RIGHT JOIN (driving) | All instruments with price server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetRateSourceConfiguration (view)
├── Price.PCSToLiquidityAccount (table)
├── Price.LiquidityAccountToInstrument (table)
├── Trade.LiquidityAccounts (table)
└── Trade.Instrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PCSToLiquidityAccount | Table | INNER JOIN (PTLA) - PCS-to-account assignments |
| Price.LiquidityAccountToInstrument | Table | INNER JOIN (LATI) - account-to-instrument coverage |
| Trade.LiquidityAccounts | Table | INNER JOIN (TLA) - account's AccountRateSourceID |
| Trade.Instrument | Table | RIGHT JOIN (TI) driving set; provides PriceServerID; WHERE PriceServerID IS NOT NULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. RIGHT JOIN means AccountRateSourceID can be NULL. WHERE PriceServerID IS NOT NULL applied after RIGHT JOIN.

---

## 8. Sample Queries

### 8.1 Get rate source configuration for a specific instrument

```sql
SELECT PriceServerID, AccountRateSourceID, InstrumentID
FROM Price.GetRateSourceConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY AccountRateSourceID;
```

### 8.2 Find instruments with no PCS-routed rate source (coverage gaps)

```sql
SELECT InstrumentID, PriceServerID
FROM Price.GetRateSourceConfiguration WITH (NOLOCK)
WHERE AccountRateSourceID IS NULL
ORDER BY InstrumentID;
```

### 8.3 Instruments per price server with source names

```sql
SELECT
    GRSC.PriceServerID,
    GRSC.InstrumentID,
    ARS.Name AS RateSourceName
FROM Price.GetRateSourceConfiguration GRSC WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GRSC.AccountRateSourceID
WHERE GRSC.PriceServerID = 1
ORDER BY GRSC.InstrumentID, ARS.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetRateSourceConfiguration | Type: View | Source: etoro/etoro/Price/Views/Price.GetRateSourceConfiguration.sql*
