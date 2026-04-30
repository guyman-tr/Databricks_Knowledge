# Billing.ConversionFee

> Temporal (system-versioned) base table of FX conversion fees per currency; each row defines the flat deposit and cashout fee in the local currency unit for a non-USD payment currency, with History.ConversionFee automatically maintained by SQL Server.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | CurrencyID (PRIMARY KEY CLUSTERED) |
| **Row Count** | 28 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 - PK CLUSTERED on CurrencyID |
| **Special** | SYSTEM_VERSIONING = ON -> History.ConversionFee |

---

## 1. Business Meaning

`Billing.ConversionFee` stores the base FX (foreign exchange) conversion fee for each non-USD currency that eToro supports for deposits and cashouts. When a customer deposits or withdraws in a currency other than USD (eToro's base currency), eToro charges a conversion fee to cover the FX spread cost. This table defines those fees.

One row per supported currency. The `DepositFee` and `CashoutFee` values are in the **smallest unit of that currency** (e.g., EUR cents, GBP pence, CLP pesos, COP pesos). The fee is therefore the flat amount charged for the currency conversion on each transaction.

The table follows a two-tier override pattern:
1. **Base rate** (this table): `Billing.ConversionFee` - applies to all customers by default
2. **Player-level override**: `Billing.ConversionFeeOverride` - per-player-level, per-funding-type override; if found, used instead of the base rate

The SP `Billing.GetExchangeRatesForCustomerFunding_v4` implements this logic: it first checks `ConversionFeeOverride` for a matching player-level record; if none found, falls back to `ConversionFee`.

`InstrumentID` links each currency to its corresponding forex instrument in `Trade.Instrument` (e.g., EUR -> EUR/USD instrument), used to retrieve the current bid/ask exchange rate for the conversion calculation.

The table is **SYSTEM_VERSIONED** (SQL Server 2016+ temporal tables): all changes are automatically tracked in `History.ConversionFee` with system-managed `ValidFrom`/`ValidTo` datetime2 columns.

---

## 2. Business Logic

### 2.1 Fee Lookup for Deposits and Cashouts

**What**: When a transaction in a non-USD currency is initiated, the system retrieves the applicable conversion fee for the customer's player level and currency.

**Columns Involved**: `CurrencyID`, `DepositFee`, `CashoutFee`, `InstrumentID`

**Lookup chain** (from `GetExchangeRatesForCustomerFunding_v4`):
```
1. Try Billing.ConversionFeeOverride WHERE FundingTypeID=@FundingTypeID
   AND CurrencyID=@CurrencyID AND PlayerLevelID=@PlayerLevelID
   -> If found: use override fees

2. Fallback: Billing.ConversionFee WHERE CurrencyID=@CurrencyID
   -> Use base fees
```

**Fee unit**: `DepositFee` and `CashoutFee` are integers in the **local currency's smallest denomination unit**:
- EUR/GBP/AUD/CHF: 150 = 1.50 (€/$1.50/etc.)
- CNY: 400 = 4.00 CNY
- VND: 71,000 = 71,000 VND (~$3 USD)
- CLP: 2,310,000 = 2,310,000 CLP (~$2.50 USD)
- COP: 13,000,000 = 13,000,000 COP (~$3 USD)

All fees approximate ~$1.50-3.00 USD equivalent.

### 2.2 Percentage-Based Fees (Planned)

`DepositFeePercentage` and `CashoutFeePercentage` (decimal(18,2)) are NULL for all current rows. These columns support a future percentage-based fee model (already queried in `GetExchangeRatesForCustomerFunding_v4` and `DepositTypeConversionFeeOverride`). A special case: for recurring investment deposits (`TransactionTypeID=5`), the percentage may be fetched from `DepositTypeConversionFeeOverride`.

### 2.3 Temporal Versioning

All modifications to this table are automatically versioned:
- SQL Server tracks `ValidFrom` and `ValidTo` as system-managed `datetime2(7)` columns
- Current rows: ValidTo = 9999-12-31 (system default for active rows)
- Historical rows: stored in `History.ConversionFee` with actual ValidTo timestamps
- All 28 rows were last modified on 2024-05-02 (a bulk fee update event)

### 2.4 Trace Column

`Trace` is a computed column that captures the session context at the time of any DML operation:
```
{"HostName": "...","AppName": "...","SUserName": "...","SPID": "...","DBName": "...","ObjectName": "..."}
```
This provides an automatic audit trail of which application/user/procedure modified a fee row, supplementing the temporal history.

---

## 3. Data Overview

| CurrencyID | Currency | InstrumentID | DepositFee | CashoutFee |
|-----------|---------|-------------|-----------|-----------|
| 2 | EUR | 1 | 150 | 150 |
| 3 | GBP | 2 | 150 | 150 |
| 5 | AUD | 7 | 150 | 150 |
| 6 | CHF | 6 | 140 | 150 |
| 38 | CNY | 45 | 400 | 400 |
| 39 | NOK | 57 | 1,600 | 1,600 |
| 40 | SEK | 58 | 1,600 | 1,600 |
| 42 | MXN | 63 | 6,000 | 6,000 |
| 43 | SGD | 64 | 410 | 410 |
| 44 | PLN | 73 | 650 | 650 |
| 45 | HUF | 69 | 550 | 550 |
| 46 | DKK | 75 | 1,000 | 1,000 |
| 77-90 | Asian/MidEast pairs | 77-90 | varies | varies |
| 346-349 | Gulf currencies | 346-349 | 7,800-7,900 | same |
| 444 | BRL | 429 | 15,555 | 15,555 |
| 452 | CLP | 427 | 2,310,000 | 2,310,000 |
| 453 | COP | 426 | 13,000,000 | 13,000,000 |
| 488 | KRW | 428 | 390,000 | 390,000 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | CODE-BACKED | Primary key. The currency for which this fee applies. FK to `Dictionary.Currency` implicitly. CurrencyID=1 (USD) has no entry - USD is eToro's base currency requiring no conversion. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The forex trading instrument for this currency pair (e.g., EUR/USD=1, GBP/USD=2, AUD/USD=7). References `Trade.Instrument` implicitly. Used by the exchange rate SP to retrieve current bid/ask rates for the conversion. |
| 3 | DepositFee | int | NO | - | CODE-BACKED | Flat deposit conversion fee in the local currency's smallest unit (cents, pence, subunits, etc.). Applied when a customer makes a deposit in this currency and eToro converts to USD. |
| 4 | CashoutFee | int | NO | - | CODE-BACKED | Flat cashout conversion fee in the local currency's smallest unit. Applied when a customer withdraws in this currency and eToro converts from USD. CHF has asymmetric fees (DepositFee=140, CashoutFee=150). |
| 5 | ModificationDate | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of the last modification to this fee row. Defaults to GETUTCDATE() on insert. All rows = 2024-05-02 (bulk fee update). Distinct from temporal ValidFrom (which is system-managed). |
| 6 | Trace | AS computed | YES | - | CODE-BACKED | Auto-captured session context at DML time: `{"HostName":"...","AppName":"...","SUserName":"...","SPID":"...","DBName":"...","ObjectName":"..."}`. Provides lightweight audit trail of who changed the fee. |
| 7 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | System-managed temporal column. UTC timestamp when this row version became current. Automatically set by SQL Server on INSERT/UPDATE. |
| 8 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | System-managed temporal column. UTC timestamp when this row version was superseded. Current rows: 9999-12-31. Set to NOW when updated or deleted; historical row moved to History.ConversionFee. |
| 9 | DepositFeePercentage | decimal(18,2) | YES | NULL | CODE-BACKED | Percentage-based deposit fee (e.g., 1.50 = 1.5%). Currently NULL for all rows - reserved for future percentage-based fee model. Already queried by GetExchangeRatesForCustomerFunding_v4. |
| 10 | CashoutFeePercentage | decimal(18,2) | YES | NULL | CODE-BACKED | Percentage-based cashout fee. Currently NULL for all rows - future use. |
| 11 | ConversionFeeID | int | NO | IDENTITY(100000,1) | CODE-BACKED | Secondary identity column (NOT the PK). Auto-generated starting at 100,000. Provides a stable row identifier separate from the CurrencyID PK, used in override and audit references. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Implicit | Currency for which the fee applies |
| InstrumentID | Trade.Instrument | Implicit | Forex pair instrument for exchange rate lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ConversionFee | CurrencyID | Temporal | SQL Server system-versioning history table |
| Billing.ConversionFeeOverride | CurrencyID | FK (implicit) | Per-player-level overrides referencing this base table |
| Billing.GetExchangeRatesForCustomerFunding | CurrencyID | Read | Retrieves fee for customer exchange rate calculation |
| Billing.GetExchangeRatesForCustomerFunding_v2 | CurrencyID | Read | V2 variant |
| Billing.GetExchangeRatesForCustomerFunding_v3 | CurrencyID | Read | V3 variant |
| Billing.GetExchangeRatesForCustomerFunding_v4 | CurrencyID | Read | V4 variant - current; implements override/fallback pattern |
| Billing.GetExchangeRatesBaseTable | CurrencyID | Read | Retrieves base exchange rate table |
| Billing.ExchangeRatesByPlayerLevelGet | CurrencyID | Read | Player-level specific exchange rates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ConversionFee (temporal)
  -> Dictionary.Currency (CurrencyID - implicit)
  -> Trade.Instrument (InstrumentID - implicit)
  -> History.ConversionFee (system-versioned history - auto-maintained by SQL Server)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | CurrencyID semantic reference |
| Trade.Instrument | Table | InstrumentID for forex pair bid/ask rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ConversionFee | Table | Temporal history (auto-maintained) |
| Billing.ConversionFeeOverride | Table | Base fee reference for override table |
| Billing.GetExchangeRatesForCustomerFunding_v4 | Stored Procedure | Fallback fee lookup when no player-level override exists |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BillingConversionRate_TPL | CLUSTERED PK | CurrencyID ASC | - | - | FILLFACTOR=95; DATA_COMPRESSION=none |

### 7.2 Constraints and Defaults

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingConversionRate_TPL | PRIMARY KEY CLUSTERED | One row per currency |
| SYSTEM_VERSIONING = ON | Temporal | All changes tracked in History.ConversionFee |
| PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo) | Temporal columns | System-managed row versioning |
| DF_BillingConversionFee_ModificationDate_TPL | DEFAULT GETUTCDATE() | ModificationDate defaults to current UTC |

---

## 8. Sample Queries

### 8.1 View all current conversion fees with currency names

```sql
SELECT
    cf.CurrencyID,
    c.Name AS CurrencyName,
    cf.InstrumentID,
    cf.DepositFee,
    cf.CashoutFee,
    cf.DepositFeePercentage,
    cf.CashoutFeePercentage,
    cf.ModificationDate
FROM Billing.ConversionFee cf WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = cf.CurrencyID
ORDER BY cf.CurrencyID
```

### 8.2 View historical fee changes (using temporal history)

```sql
SELECT
    cf.CurrencyID,
    c.Name AS CurrencyName,
    cf.DepositFee,
    cf.CashoutFee,
    cf.ValidFrom,
    cf.ValidTo
FROM History.ConversionFee cf
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = cf.CurrencyID
ORDER BY cf.CurrencyID, cf.ValidFrom
```

### 8.3 Find fees for a customer transaction

```sql
-- Simulate GetExchangeRatesForCustomerFunding fallback pattern
DECLARE @CurrencyID INT = 2  -- EUR
DECLARE @FundingTypeID INT = 1  -- CreditCard
DECLARE @PlayerLevelID INT = 1

-- Try override first
SELECT 'Override' AS Source, DepositFee, CashoutFee
FROM Billing.ConversionFeeOverride WITH (NOLOCK)
WHERE CurrencyID = @CurrencyID
  AND FundingTypeID = @FundingTypeID
  AND PlayerLevelID = @PlayerLevelID

-- Fallback to base
SELECT 'Base' AS Source, DepositFee, CashoutFee
FROM Billing.ConversionFee WITH (NOLOCK)
WHERE CurrencyID = @CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ConversionFee | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ConversionFee.sql*
