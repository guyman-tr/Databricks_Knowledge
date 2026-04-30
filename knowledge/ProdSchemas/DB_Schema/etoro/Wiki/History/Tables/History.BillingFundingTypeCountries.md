# History.BillingFundingTypeCountries

> SQL Server temporal history table for Billing.FundingTypeCountries: records all past states of which payment methods (funding types) are available in which countries, with priority ranking. 30 history rows covering 11 funding types across 9 countries. Automatically maintained by SYSTEM_VERSIONING.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, CountryID) - no PK constraint |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.BillingFundingTypeCountries is the SQL Server temporal system-versioning history table for `Billing.FundingTypeCountries`. It automatically captures every INSERT, UPDATE, and DELETE applied to the payment method country availability configuration.

`Billing.FundingTypeCountries` defines which payment methods (funding types) are available in each country and their priority order. Each row represents one (payment method, country) availability rule with a `Rank` field controlling the display order when multiple payment methods are available. When eToro adds a new payment method to a country, adjusts a method's priority, or removes it from a market, this configuration changes and the old state is preserved here.

**Business significance**: This table directly controls which payment options customers see when depositing or withdrawing. Changes here affect the customer-facing payment method selection UI. The MIMO alerts system monitors configuration changes via `MIMOAlerts.GetSupportedCountryMOPConfigurationChanges`.

**Scale**: Only 30 history rows vs. 1,276 live rows (history/live ratio = 0.023). This indicates very stable configuration - the payment method/country availability matrix has had minimal changes since temporal versioning was activated. The OldestChange of 1900-01-01 is a sentinel from the initial bulk load.

**Known funding types** in history (11 total): CreditCard (1), WireTransfer (2), PayPal (3), BankDraft (4), NetellerOnePay (7), MoneyBookers/Skrill (8), MoneyGram (9), ACH (29), eToroMoney (33), GCCInstantBankTransfer (43), MoneyFarm (44).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any INSERT, UPDATE, or DELETE to Billing.FundingTypeCountries.

**Rules**:
- INSERT into source: row becomes active at ValidFrom=NOW; no immediate history row
- UPDATE to source: old row moved to history with ValidTo=NOW; new row active with ValidFrom=NOW
- DELETE from source: deleted row moved to history with ValidTo=NOW
- ValidFrom/ValidTo use UTC (datetime2(7))
- 1900-01-01 sentinel in history = initial bulk-load rows before temporal timestamps established

### 2.2 Country-Funding Configuration Semantics

**What**: Each row authorizes one payment method for one country with a priority rank.

**Rules**:
- Composite key: (FundingTypeID, CountryID) - one row per method/country combination
- `Rank` (tinyint, 0-7): priority ordering for payment methods available in a country. Lower rank = higher priority in display
- FK from source to Dictionary.Country - enforces valid country codes
- No FK to Dictionary.FundingType in source DDL (checked) - FundingTypeID is unconstrained
- 1,276 live rows with only 30 history rows = very few changes since inception

### 2.3 Funding Type Coverage

| FundingTypeID | Name | History Rows | Countries | Rank Range |
|---|---|---|---|---|
| 1 | CreditCard | 7 | 3 | 0-6 |
| 8 | MoneyBookers/Skrill | 6 | 2 | 2-7 |
| 2 | WireTransfer | 4 | 3 | 4-6 |
| 3 | PayPal | 2 | 2 | 1-2 |
| 33 | eToroMoney | 2 | 1 | 1-2 |
| 44 | MoneyFarm | 2 | 1 | 1-6 |
| 7 | NetellerOnePay | 2 | 1 | 5-6 |
| 43 | GCCInstantBankTransfer | 2 | 1 | 5-6 |
| 29 | ACH | 1 | 1 | 3 |
| 4 | BankDraft | 1 | 1 | 6 |
| 9 | MoneyGram | 1 | 1 | 7 |

---

## 3. Data Overview

30 history rows (1900-01-01 sentinel to 2026-03-09). 1,276 live rows. 11 funding types, 9 countries in history data. Rank range: 0 (highest priority) to 7 (lowest priority).

| FundingTypeID | CountryID | Rank | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 1 (CreditCard) | (any) | 0 | 1900-01-01 | (later) | CreditCard at highest rank (0) for this country - initial bulk-load state |
| 8 (Skrill) | (any) | 7 | (any) | 9999 (live) | Skrill at lowest priority (rank 7) for this country |
| (any) | (any) | (any) | 2024-xx | 2026-03-09 | A configuration change recorded March 2026 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. Part of composite key. 11 distinct values in history. Known values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 4=BankDraft, 7=NetellerOnePay, 8=MoneyBookers/Skrill, 9=MoneyGram, 29=ACH, 33=eToroMoney, 43=GCCInstantBankTransfer, 44=MoneyFarm. References Dictionary.FundingType (no FK in source DDL). |
| 2 | CountryID | int | NO | - | CODE-BACKED | Country where this payment method is available. Part of composite key. FK in source to Dictionary.Country. 9 distinct values in history. |
| 3 | Rank | tinyint | NO | - | CODE-BACKED | Priority ordering for payment method selection in this country. Range 0-7 in history. Lower = higher priority. Controls the display order of payment options in the eToro deposit/withdrawal UI. |
| 4 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON connection context captured via computed column at time of change. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Identifies who changed the availability configuration. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this availability rule became active. Set by SQL Server temporal. 1900-01-01 in oldest history rows indicates initial bulk-load before temporal was activated. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this rule was superseded. Set by SQL Server temporal. Clustered index leading key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table. Source table Billing.FundingTypeCountries has FK: CountryID -> Dictionary.Country.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically. |
| MIMOAlerts.GetSupportedCountryMOPConfigurationChanges | Reader | Change detection | Monitors for changes in payment method country availability for MIMO alerts. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingFundingTypeCountries (temporal history table)
  - automatically maintained by: Billing.FundingTypeCountries (source table)
  - monitored by: MIMOAlerts.GetSupportedCountryMOPConfigurationChanges
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Writes historical rows from Billing.FundingTypeCountries changes automatically |
| MIMOAlerts.GetSupportedCountryMOPConfigurationChanges | Stored Procedure | Reads history for payment method configuration change detection |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingFundingTypeCountries | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Standard temporal clustering on (ValidTo, ValidFrom). PAGE compression. On PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. |

---

## 8. Sample Queries

### 8.1 History of availability changes for a specific country
```sql
SELECT
    h.FundingTypeID,
    ft.[Name] AS FundingType,
    h.CountryID,
    h.Rank,
    h.ValidFrom,
    h.ValidTo,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingFundingTypeCountries h WITH (NOLOCK)
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON h.FundingTypeID = ft.FundingTypeID
WHERE h.CountryID = @CountryID
ORDER BY h.FundingTypeID, h.ValidFrom ASC;
```

### 8.2 Point-in-time payment method availability (temporal syntax)
```sql
-- What payment methods were available in which countries on a specific date?
SELECT *
FROM Billing.FundingTypeCountries
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00';
```

### 8.3 Recent configuration changes
```sql
SELECT TOP 20
    h.FundingTypeID,
    ft.[Name] AS FundingType,
    h.CountryID,
    h.Rank,
    h.ValidFrom AS ChangeTime,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingFundingTypeCountries h WITH (NOLOCK)
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON h.FundingTypeID = ft.FundingTypeID
WHERE h.ValidFrom > '1900-01-02'
ORDER BY h.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly referencing this table.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingFundingTypeCountries | Type: Table | Source: etoro/etoro/History/Tables/History.BillingFundingTypeCountries.sql*
