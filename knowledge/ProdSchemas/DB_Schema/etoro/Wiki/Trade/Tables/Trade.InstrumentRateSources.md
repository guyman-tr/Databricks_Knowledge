# Trade.InstrumentRateSources

> Maps instruments to their price rate sources (liquidity accounts) used for price feeds and rate allocation across the trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentRateSourceID (INT, CLUSTERED PK) |
| **Partition** | Yes - ON [MAIN] |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.InstrumentRateSources defines which liquidity accounts supply price rate data for each instrument. Each row maps one instrument to one liquidity account, optionally scoped by PriceServerID, with a Priority that controls selection order when multiple rate sources exist. The table answers: "Where does the system get live prices for instrument X?" - routing price requests to the correct external feeds via Trade.LiquidityAccounts.

This table exists because eToro aggregates prices from multiple liquidity providers and price servers. Without it, the system could not determine which account feeds which instrument, or how to prioritize when multiple sources exist for the same instrument. Trade.GetInstrumentRateSources exposes this data enriched with LiquidityAccountName and LiquidityProviderName. Price subsystems use it to allocate rate sources; Trade.InstrumentRateSourceAdd, InstrumentRateSourceEdit, and InstrumentRateSourceDelete manage the mappings.

Data flows: rows are created by Trade.InstrumentRateSourceAdd (calls Internal.GetInstrumentRateSourceID for ID allocation), updated by Trade.InstrumentRateSourceEdit (Priority changes), and deleted by Trade.InstrumentRateSourceDelete. Trade.GetInstrumentRateSources (view) joins InstrumentRateSources with GetLiquidityAccounts and LiquidityProviders to expose human-readable names. Note: In this environment the table had 0 rows; the Price schema has a parallel Price.InstrumentRateSources used by CheckValidInstruments with AccountRateSourceID.

---

## 2. Business Logic

### 2.1 Instrument-to-Account Mapping

**What**: Each row assigns one liquidity account as a rate source for one instrument, with optional PriceServerID scoping and Priority ordering.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `PriceServerID`, `Priority`

**Rules**:
- InstrumentID must exist in Trade.Instrument (FK_TRIN_TIRS)
- LiquidityAccountID must exist in Trade.LiquidityAccounts (FK_TRLA_TIRS)
- Trade.InstrumentRateSourceAdd checks for existing row by (InstrumentID, LiquidityAccountID, PriceServerID); if exists, calls InstrumentRateSourceEdit for Priority update instead of INSERT
- Priority controls which source is preferred when multiple sources exist for the same instrument
- PriceServerID can be NULL - used to scope rate sources to specific price servers

**Diagram**:
```
Trade.Instrument (InstrumentID)
       |
       v
Trade.InstrumentRateSources (InstrumentID, LiquidityAccountID, PriceServerID, Priority)
       |
       v
Trade.LiquidityAccounts (LiquidityAccountID -> Username, Provider, AccountRateSourceID)
```

### 2.2 Rate Source Selection Flow

**What**: When the platform needs a rate for an instrument, it queries InstrumentRateSources to find candidate liquidity accounts, then uses Priority to pick the preferred source.

**Columns/Parameters Involved**: `Priority`

**Rules**:
- Lower Priority values typically indicate higher preference (or vice versa depending on consumer logic)
- Trade.GetInstrumentRateSources exposes full mapping for UI and back-office
- Consumers (Price subsystem, rate aggregation) JOIN this table to resolve InstrumentID -> LiquidityAccountID

---

## 3. Data Overview

| InstrumentRateSourceID | InstrumentID | LiquidityAccountID | PriceServerID | Priority | Meaning |
|-----------------------|--------------|-------------------|---------------|----------|---------|
| (No rows) | - | - | - | - | Table structure exists; live data unavailable in this environment. Price.InstrumentRateSources (different schema) may hold equivalent mappings with AccountRateSourceID. |

**Selection criteria**: Live query returned 0 rows. Structure and usage documented from DDL, procedures, and dependency docs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentRateSourceID | int | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetInstrumentRateSourceID when creating via Trade.InstrumentRateSourceAdd. Unique per row. |
| 2 | PriceServerID | int | YES | - | CODE-BACKED | Optional price server scoping. Identifies which price server this mapping applies to. NULL = applies to all servers or default. Used in InstrumentRateSourceAdd duplicate check. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The tradeable instrument that receives rate data from this liquidity account. |
| 4 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts. The liquidity account that supplies price feeds for this instrument. See Trade.LiquidityAccounts for account types (Price vs Execution). |
| 5 | Priority | int | YES | - | CODE-BACKED | Ordering/priority when multiple rate sources exist for the same instrument. Updated by Trade.InstrumentRateSourceEdit. Lower values typically mean higher preference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Instrument receiving rate data (FK_TRIN_TIRS). |
| LiquidityAccountID | Trade.LiquidityAccounts | FK | Account supplying price feed (FK_TRLA_TIRS). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentRateSources | FROM | Reader | View joins InstrumentRateSources with GetLiquidityAccounts and LiquidityProviders for enriched display. |
| Trade.InstrumentRateSourceAdd | INSERT | Writer | Creates rows; uses InstrumentRateSourceEdit when duplicate (InstrumentID, LiquidityAccountID, PriceServerID) exists. |
| Trade.InstrumentRateSourceEdit | UPDATE | Modifier | Updates Priority for existing rows. |
| Trade.InstrumentRateSourceDelete | DELETE | Deleter | Removes rows by InstrumentRateSourceID. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentRateSources (table)
├── Trade.Instrument (table)
│     └── Dictionary.Currency (table)
└── Trade.LiquidityAccounts (table)
      ├── Trade.LiquidityProviders (table)
      ├── Dictionary.LiquidityAccountType (table)
      └── Price.AccountRateSource (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID |
| Trade.LiquidityAccounts | Table | FK LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentRateSources | View | FROM - exposes mapping with account/provider names |
| Trade.InstrumentRateSourceAdd | Procedure | INSERT, SELECT for duplicate check |
| Trade.InstrumentRateSourceEdit | Procedure | UPDATE Priority |
| Trade.InstrumentRateSourceDelete | Procedure | DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TIRS | CLUSTERED | InstrumentRateSourceID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TIRS | PK | InstrumentRateSourceID primary key |
| FK_TRIN_TIRS | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_TRLA_TIRS | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

---

## 8. Sample Queries

### 8.1 List instrument rate sources with account and provider names
```sql
SELECT TIRS.InstrumentRateSourceID,
       TIRS.InstrumentID,
       TIRS.LiquidityAccountID,
       TIRS.PriceServerID,
       TIRS.Priority,
       TRLA.LiquidityAccountName,
       TRLP.LiquidityProviderName
  FROM Trade.InstrumentRateSources TIRS WITH (NOLOCK)
  LEFT JOIN Trade.GetLiquidityAccounts TRLA WITH (NOLOCK)
    ON TRLA.LiquidityAccountID = TIRS.LiquidityAccountID
  LEFT JOIN Trade.LiquidityProviders TRLP WITH (NOLOCK)
    ON TRLP.LiquidityProviderID = TRLA.LiquidityProviderID
 ORDER BY TIRS.InstrumentID, TIRS.Priority
```

### 8.2 Use the GetInstrumentRateSources view
```sql
SELECT InstrumentRateSourceID,
       InstrumentID,
       LiquidityAccountID,
       LiquidityAccountName,
       LiquidityProviderName,
       PriceServerID,
       Priority
  FROM Trade.GetInstrumentRateSources WITH (NOLOCK)
 ORDER BY InstrumentID, Priority
```

### 8.3 Find rate sources for a specific instrument
```sql
SELECT TIRS.InstrumentRateSourceID,
       TIRS.LiquidityAccountID,
       LA.LiquidityAccountName,
       TIRS.PriceServerID,
       TIRS.Priority
  FROM Trade.InstrumentRateSources TIRS WITH (NOLOCK)
  JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
    ON LA.LiquidityAccountID = TIRS.LiquidityAccountID
 WHERE TIRS.InstrumentID = 1
 ORDER BY TIRS.Priority
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.InstrumentRateSources | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentRateSources.sql*
