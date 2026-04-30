# History.BillingCurrencyPerFundingTypeOverrides

> SQL Server temporal history table for Billing.CurrencyPerFundingTypeOverrides: records all past states of which currencies are available (and which is the default) for each payment method (funding type) in each country. Automatically maintained by SYSTEM_VERSIONING. 6,025 history rows covering 250 countries, 12 funding types, and 27 currencies.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, FundingTypeID, CurrencyID) - no PK constraint |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.BillingCurrencyPerFundingTypeOverrides is the SQL Server temporal system-versioning history table for `Billing.CurrencyPerFundingTypeOverrides`. It automatically captures every INSERT, UPDATE, and DELETE applied to the currency-per-funding-type override configuration, preserving the full history of which currencies were available for which payment methods in which countries.

`Billing.CurrencyPerFundingTypeOverrides` defines the supported currency options for each payment method (funding type) per country. For a given combination of country + funding type (e.g., Israel + CreditCard), the table lists all currencies the customer may use, marking one as the default (`IsDefault=1`) and providing a priority ranking (`Rank`) when multiple currencies are available. This drives the payment method configuration displayed to customers when they deposit or withdraw.

**Business significance**: This is a core payment configuration table. When eToro expands to new markets, adds or removes payment method support, or adjusts which currencies are accepted per payment method, these changes land here. The MIMO alerts system monitors changes via `MIMOAlerts.GetSupportedCountryMOPCurrencyConfigurationChanges`.

**Scale**: 6,025 history rows vs. 2,527 live rows. The high history/live ratio (2.4x) reflects significant configuration activity - many countries' funding type currency configurations have been changed multiple times. Data spans from a 1900-01-01 sentinel (initial bulk load rows) through February 2026.

**Funding type coverage** (top 5 by history volume):
- FundingTypeID=1 (CreditCard): 1,671 history rows, 250 countries
- FundingTypeID=3 (PayPal): 737 history rows, 187 countries
- FundingTypeID=8 (MoneyBookers/Skrill): 720 history rows, 181 countries
- FundingTypeID=2 (WireTransfer): 141 history rows, 10 countries
- FundingTypeID=35 (newer method): 38 history rows, 14 countries

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any INSERT, UPDATE, or DELETE to Billing.CurrencyPerFundingTypeOverrides.

**Rules**:
- INSERT into source: row becomes active at ValidFrom=NOW; no immediate history row
- UPDATE to source: old row moved to history with ValidTo=NOW; new row active with ValidFrom=NOW
- DELETE from source: deleted row moved to history with ValidTo=NOW
- History rows are immutable once written
- ValidFrom/ValidTo use UTC (datetime2(7))
- The 1900-01-01 ValidFrom values in history represent rows created during an initial bulk load/migration before proper temporal timestamps were established - these should be treated as "origin/initial state" markers

### 2.2 Currency Override Semantics

**What**: Each row defines a single valid currency for a given country + funding type combination.

**Rules**:
- Composite key: (CountryID, FundingTypeID, CurrencyID) - one row per country/method/currency triplet
- `IsDefault=1`: exactly one row per (CountryID, FundingTypeID) should be the default currency
- `Rank`: ordering when multiple currencies exist for the same country/funding-type (DEFAULT=1 in source)
- "Override" implies these are exceptions to a base currency configuration - specific country/funding-type combinations that differ from the standard currency rules
- `MIMOAlerts.GetSupportedCountryMOPCurrencyConfigurationChanges` monitors this table for changes to alert the MIMO system

### 2.3 Funding Type Distribution

| FundingTypeID | Name | History Rows | Countries |
|---|---|---|---|
| 1 | CreditCard | 1,671 | 250 |
| 3 | PayPal | 737 | 187 |
| 8 | MoneyBookers/Skrill | 720 | 181 |
| 2 | WireTransfer | 141 | 10 |
| 35 | (newer method) | 38 | 14 |
| 36-39 | (newer methods) | 14 total | various |

---

## 3. Data Overview

6,025 history rows. 2,527 live rows. 250 distinct countries, 12 funding types, 27 currencies in history. Oldest ValidFrom: 1900-01-01 (sentinel for initial load rows). Newest ValidTo: 2026-02-03.

| CountryID | FundingTypeID | CurrencyID | IsDefault | Rank | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|
| (any) | 1 (CreditCard) | (USD?) | 1 | 1 | 1900-01-01 | (later) | Initial CreditCard currency configuration for this country at system inception. |
| (any) | 3 (PayPal) | (EUR?) | 1 | 1 | 2022-xx-xx | 9999-12-31 (live) | Current default PayPal currency for this country. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Customer's country. Part of the composite key. 250 distinct values in history. References Dictionary.Country (implicit - no FK on history table). |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. Part of composite key. 12 distinct values in history. Known values: 1=CreditCard (largest), 2=WireTransfer, 3=PayPal, 6=Neteller, 8=MoneyBookers/Skrill, plus newer types (35-39). References Dictionary.FundingType. |
| 3 | CurrencyID | int | NO | - | CODE-BACKED | The currency available for this country + funding type combination. Part of composite key. 27 distinct currencies in history. References Dictionary.Currency (implicit). |
| 4 | IsDefault | bit | NO | - | CODE-BACKED | 1=this currency is the default selection for this country/funding-type combination; 0=alternative currency option. Only one row per (CountryID, FundingTypeID) should have IsDefault=1. |
| 5 | Rank | int | YES | 1 | CODE-BACKED | Priority ordering when multiple currencies are available for the same country + funding type. Lower rank = higher priority. Default=1 in source table. NULL in history if the DEFAULT constraint did not apply (e.g., bulk-loaded rows). |
| 6 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON connection context captured at DML time via computed column. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Identifies who changed the configuration. Computed in source; stored as data in history snapshot. |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration row became active. Set by SQL Server temporal. 1900-01-01 sentinel values indicate rows created during initial bulk-load before temporal timestamps were established. |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row was superseded. Set by SQL Server temporal. Clustered index leading key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table. Source table Billing.CurrencyPerFundingTypeOverrides has implicit references to Dictionary.Country, Dictionary.FundingType, Dictionary.Currency.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically. |
| MIMOAlerts.GetSupportedCountryMOPCurrencyConfigurationChanges | Reader | Change detection | Monitors configuration changes to alert the MIMO system of currency support updates. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingCurrencyPerFundingTypeOverrides (temporal history table)
  - automatically maintained by: Billing.CurrencyPerFundingTypeOverrides (source table)
  - monitored by: MIMOAlerts.GetSupportedCountryMOPCurrencyConfigurationChanges
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Writes historical rows from Billing.CurrencyPerFundingTypeOverrides changes automatically |
| MIMOAlerts.GetSupportedCountryMOPCurrencyConfigurationChanges | Stored Procedure | Reads history to detect and report configuration changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingCurrencyPerFundingTypeOverrides | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Standard temporal clustering on (ValidTo, ValidFrom). PAGE compression. On PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. |

---

## 8. Sample Queries

### 8.1 History of currency changes for a specific country + funding type
```sql
SELECT
    h.CountryID,
    h.FundingTypeID,
    h.CurrencyID,
    h.IsDefault,
    h.Rank,
    h.ValidFrom,
    h.ValidTo,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingCurrencyPerFundingTypeOverrides h WITH (NOLOCK)
WHERE h.CountryID = @CountryID
  AND h.FundingTypeID = 1  -- CreditCard
ORDER BY h.ValidFrom ASC;
```

### 8.2 Point-in-time configuration (temporal syntax)
```sql
-- What currency configuration was active on a specific date?
SELECT *
FROM Billing.CurrencyPerFundingTypeOverrides
FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00';
```

### 8.3 Most recently changed configurations
```sql
SELECT TOP 20
    h.CountryID,
    h.FundingTypeID,
    h.CurrencyID,
    h.IsDefault,
    h.ValidFrom AS ChangedAt,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingCurrencyPerFundingTypeOverrides h WITH (NOLOCK)
WHERE h.ValidFrom > '1900-01-02'
ORDER BY h.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly referencing this table.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingCurrencyPerFundingTypeOverrides | Type: Table | Source: etoro/etoro/History/Tables/History.BillingCurrencyPerFundingTypeOverrides.sql*
