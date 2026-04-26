# Lineage: BI_DB_dbo.BI_DB_AML_Gatsby_Alerts

**Writer SP**: SP_AML_Gatsby_Alerts  
**Load Pattern**: DELETE WHERE AlertDate = @Date + INSERT (accumulating, date-partitioned)  
**Frequency**: Daily  
**Parameter**: `@Date DATE`

---

## Source Tables

| Source | Role | Columns Used |
|--------|------|--------------|
| `BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity` | APEX SOD cash transactions (deposits and withdrawals) | RegisteredRepCode, AccountNumber, ACATSControlNumber, ProcessDate, Amount, OfficeCode, PayTypeCode, EnteredBy |
| `BI_DB_staging.STG_Sodreconciliation_apex_EXT872_TradeActivity` | APEX SOD trade activity | AccountNumber, OrderId, ProcessDate, OfficeCode, MarketCode |
| `BI_DB_dbo.External_Sodreconciliation_apex_EXT1034_NewAccountFinancialInformation` | APEX account details | AccountNumber, CodeDescription, AccountName1 (→FullName), DateOfBirth |
| `BI_DB_dbo.External_USABroker_Apex_Options` | APEX ↔ eToro ID mapping | GCID, OptionsApexID |
| `DWH_dbo.Dim_Customer` | CID resolution from GCID | GCID, RealCID (→ CID) |

---

## Population Filters (Base Cash Activity)

```
OfficeCode = '4GS'                     -- Gatsby/APEX office code
PayTypeCode = 'C' (deposits) / 'D' (withdrawals)
EnteredBy IN ('ACH', 'WRD')           -- wire/ACH only, excludes other entry methods
RegisteredRepCode IN ('GAT', 'UK1')   -- USA or UK accounts only (excludes house accounts)
ProcessDate <= @Date                   -- historical up to run date
```

---

## Alert Rules (6 Active + 1 Sentinel)

| Rule ID | Alert Type | Time Window | Condition |
|---------|-----------|-------------|-----------|
| DC10US-1A | 20+ deposits in 14 days > $50K with no trades | 14 days | deposit_count ≥ 20, deposit_sum > $50K first time; no trades in same window |
| DC10US-1B | 20+ deposits in 14 days > $50K + 5+ withdrawals | 14 days | deposit_count ≥ 20, deposit_sum > $50K first time; 5+ withdrawals in same window |
| DC5US | 10+ deposits in 48 hours > $25K with no trades | 48 hours | deposit_count ≥ 10, deposit_sum > $25K first time; no trades |
| DC25US | 3+ individual deposits $9K–$9.9K within 10 days, none ≥$10K | 10 days | Smurfing/CTR avoidance pattern |
| DC2US | First time yearly deposits exceed $250K | Calendar year | first date exceeding $250K is @Date |
| DC26US | 10+ deposits in 48 hours > $25K + 2+ withdrawals all < $10K | 48 hours | deposit_count ≥ 10, deposit_sum > $25K; 2+ withdrawals each < $10K |
| Dummy Line | Sentinel — always inserted | — | Confirms SP ran for @Date even when no alerts fired |

---

## Column-Level Lineage

| Column | Source | Derivation |
|--------|--------|------------|
| AlertDate | `@Date` parameter | Hardcoded per rule block |
| ProcessDate | EXT869_CashActivity.ProcessDate | MAX per AccountNumber in alert window |
| CodeDescription | EXT1034.CodeDescription | LEFT JOIN on AccountNumber; 'Dummy Line' for sentinel |
| AlertType | Hardcoded per rule | Human-readable rule label |
| Region | Computed | 'USA' if RegisteredRepCode='GAT'; 'UK' if RegisteredRepCode='UK1' |
| AccountNumber | EXT869_CashActivity.AccountNumber | Passthrough; 'Dummy Line' for sentinel |
| Rule_Checked | Hardcoded per rule | Short rule code (DC10US-1A, DC5US, etc.) |
| FullName | EXT1034.AccountName1 | LEFT JOIN on AccountNumber; 'Dummy Line' for sentinel |
| DateOfBirth | EXT1034.DateOfBirth | LEFT JOIN on AccountNumber; GETDATE() for sentinel (invalid DOB) |
| GCID | External_USABroker_Apex_Options.GCID | LEFT JOIN via OptionsApexID = AccountNumber; 1111 for sentinel |
| CID | Dim_Customer.RealCID | JOIN via GCID; 1111 for sentinel |
| UpdateDate | GETDATE() | ETL timestamp |
