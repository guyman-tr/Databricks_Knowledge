# Billing.GetExchangeRatesForCustomer

> Returns customer-specific exchange rates with fee overrides by resolving the customer's player level and delegating to Billing.ExchangeRatesByPlayerLevelGet - a thin CID-to-player-level adapter after a major refactor in 2022.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns exchange rate rows for @CID by resolving PlayerLevelID and calling ExchangeRatesByPlayerLevelGet |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetExchangeRatesForCustomer` returns the exchange rates applicable to a specific customer, accounting for their player level (Silver/Gold/Platinum/etc.) and optionally their country. Player-level customers may receive preferential exchange rates or fee overrides.

**Key history**: This SP underwent a major performance refactor in October 2022 (PAYIL-5173, Shay Oren). The original implementation contained complex cursor-based logic to apply `Billing.ConversionFeeOverride` entries layered on top of `Billing.ConversionFee`, with nested cursors iterating over funding types and currencies. This was entirely replaced with a single call to `Billing.ExchangeRatesByPlayerLevelGet`. The old code is preserved as a large commented-out block (lines 27-180).

The current implementation is a thin adapter: it resolves `@CID -> PlayerLevelID` via `Customer.CustomerStatic`, then delegates all computation to `Billing.ExchangeRatesByPlayerLevelGet`.

**Change history**:
- 03/09/2020 Shay Oren: Added ExchangeFeeMultiplier
- 17/07/2022 Yair T: Added CountryID filter from ConversionFeeOverride - PAYSOLB-1018
- 26/10/2022 Shay Oren: Revised for performance - now calls ExchangeRatesByPlayerLevelGet - PAYIL-5173

---

## 2. Business Logic

### 2.1 CID to PlayerLevel Resolution

**What**: Converts the caller's CID to a PlayerLevelID for the rate lookup.

**Columns/Parameters Involved**: `@CID`, `Customer.CustomerStatic.PlayerLevelID`, `@PlayerLevelID (internal)`

**Rules**:
- `SELECT @PlayerLevelID = PlayerLevelID FROM Customer.CustomerStatic WHERE CID = @CID`
- No fallback if CID doesn't exist - @PlayerLevelID remains NULL and is passed to ExchangeRatesByPlayerLevelGet as NULL

### 2.2 Delegation to ExchangeRatesByPlayerLevelGet

**What**: The full rate computation with player-level overrides is delegated to the dedicated SP.

**Rules**:
- `EXECUTE [Billing].[ExchangeRatesByPlayerLevelGet] @PlayerLevelID = @PlayerLevelID, @CountryID = @CountryID`
- All output columns are determined by ExchangeRatesByPlayerLevelGet (documented in Batch 14)
- @CountryID defaults to NULL if not provided - ExchangeRatesByPlayerLevelGet handles the NULL case

**Diagram**:
```
@CID + @CountryID
  |
  -> Customer.CustomerStatic -> PlayerLevelID
  |
  v
  Billing.ExchangeRatesByPlayerLevelGet(@PlayerLevelID, @CountryID)
  -> Returns full exchange rate dataset with player-level fee overrides
```

---

## 3. Data Overview

N/A for stored procedure (output delegated to ExchangeRatesByPlayerLevelGet).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Resolved to PlayerLevelID via Customer.CustomerStatic for the rate lookup. |
| 2 | @CountryID | INT | YES | NULL | CODE-BACKED | Optional customer country ID. Passed to ExchangeRatesByPlayerLevelGet for country-specific rate overrides (added PAYSOLB-1018). NULL = use non-country-specific rates. |
| 3 | (output columns) | various | - | - | CODE-BACKED | All output columns are returned by Billing.ExchangeRatesByPlayerLevelGet. See ExchangeRatesByPlayerLevelGet documentation (Batch 14) for full column definitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic.CID | Lookup | Resolves to PlayerLevelID |
| @PlayerLevelID + @CountryID | Billing.ExchangeRatesByPlayerLevelGet | EXEC delegation | All rate computation delegated here |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit/exchange rate service | Direct execution | Operational | No GRANT EXECUTE found in SSDT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesForCustomer (procedure)
├── Customer.CustomerStatic (table) [for CID -> PlayerLevelID]
└── Billing.ExchangeRatesByPlayerLevelGet (procedure) [full rate computation]
    ├── Billing.ConversionFee
    ├── Billing.ConversionFeeOverride
    ├── Trade.Instrument [cross-schema]
    ├── Trade.ProviderToInstrument [cross-schema]
    └── Trade.CurrencyPrice [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Resolves @CID to PlayerLevelID |
| Billing.ExchangeRatesByPlayerLevelGet | Stored Procedure | EXEC delegation - performs all rate computation with player-level overrides |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit service / exchange rate services | Service | Customer-specific rate lookup during deposit flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Commented-out old code | History | Lines 27-180 contain the original cursor-based implementation; preserved for reference but not executed. The code used nested CURSOR loops over FundingType and Currency to apply ConversionFeeOverride. |
| PAYIL-5173 refactor | Performance | Old implementation was cursor-based and slow; replacement delegates to ExchangeRatesByPlayerLevelGet which uses set-based operations |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |
| NULL @PlayerLevelID pass-through | Edge case | If @CID doesn't exist in CustomerStatic, @PlayerLevelID is NULL - ExchangeRatesByPlayerLevelGet must handle NULL gracefully |

---

## 8. Sample Queries

### 8.1 Get exchange rates for a customer

```sql
EXEC Billing.GetExchangeRatesForCustomer @CID = 12345;
```

### 8.2 Get exchange rates with country override

```sql
EXEC Billing.GetExchangeRatesForCustomer @CID = 12345, @CountryID = 70;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Exchange rate migration - Deposit Service (Confluence) | Confluence | Context for the deposit service exchange rate architecture and the migration that led to this SP's delegation pattern |
| Billing Service Database Readonly Separation (Confluence) | Confluence | Context for the read-separated SP architecture |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.3/10 (Elements: 7/10, Logic: 8/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence (search results) + 0 Jira | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesForCustomer | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesForCustomer.sql*
