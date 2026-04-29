# BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard

> Daily TRUNCATE+INSERT AML/CTF (Anti-Money Laundering / Counter-Terrorism Financing) monitoring snapshot. One row per fully-verified depositor whose KYC profile has a connection to any of 20 high-risk/terrorism-monitored countries. Combines customer identity, regulation, screening status, AML sub-entity classification, equity, deposit/cashout totals, and eMoney account presence for compliance dashboard consumption. 270,341 rows as of 2024-12-28.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation + DWH_dbo.Dim_PlayerStatus + DWH_dbo.Dim_PlayerLevel + DWH_dbo.Dim_ScreeningStatus + DWH_dbo.V_Liabilities + DWH_dbo.Fact_CustomerAction + eMoney_dbo.eMoney_Dim_Account + BI_DB_dbo.BI_DB_AML_SubEntity_Categorization + BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake |
| **Refresh** | Daily (TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 270,341 (sampled 2024-12-28) |
| **UC Target** | Not confirmed |
| **ETL Procedure** | BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard |

---

## 1. Business Meaning

`BI_DB_AML_Terror_Monitor_Dashboard` is the daily AML and counter-terrorism financing (CTF) monitoring table. Each row represents one fully-verified, active depositor whose KYC profile shows a connection — via KYC country, citizenship, place of birth, or registration IP — to one or more of 20 high-risk or terrorism-monitored country IDs (CountryIDs: 3, 15, 63, 97, 98, 99, 105, 109, 113, 123, 138, 155, 167, 179, 198, 209, 210, 217, 229, 235).

The table is fully rebuilt daily by `SP_AML_Terror_Monitor_Dashboard`. The population is restricted to:
- `IsValidCustomer = 1` (standard customer, not Popular Investor / label 26/30 / CountryID=250)
- `IsDepositor = 1`
- `VerificationLevelID = 3` (fully KYC-verified)
- `PlayerStatusID IN (1=Normal, 5=Warning)` — active accounts only

For each qualifying customer, the SP denormalizes regulation, country names, player status, club, screening outcome, AML entity assignments, current equity (yesterday's balance), lifetime deposits, lifetime cashouts, and eMoney account status into a single flat row for compliance dashboard consumption.

As of 2024-12-28: FCA accounts dominate (107K, 40%), followed by CySEC (44K, 16%), ASIC & GAML (41K, 15%), FSRA (36K, 13%), FSA Seychelles (32K, 12%). Screening is predominantly clean (NoMatch = 99.9%). Risk scoring: Medium (87%), High (12%), Low (<1%).

### Business Usage

- **AML/CTF Compliance Dashboards**: Primary feed for terrorism-risk monitoring dashboards used by the compliance team.
- **AML Reports**: Consumed by `SP_M_AML_Report` for periodic regulatory reporting.
- **Risk Scoring**: Combined with external risk classification (`RiskScoreName`) for enhanced due diligence workflows.

---

## 2. Business Logic

### 2.1 Population Filter (High-Risk Country Connection)

The SP uses a 4-way OR filter to capture customers with any KYC link to monitored countries:

```sql
WHERE dc.IsValidCustomer = 1
AND dc.IsDepositor = 1
AND dc.VerificationLevelID = 3
AND dps.PlayerStatusID IN (1, 5)  -- Normal, Warning
AND (
  dc.CountryID IN (109,217,167,15,155,123,97,179,105,63,138,3,235,98,99,113,198,229,210,209)
  OR dc.CitizenshipCountryID IN (...)
  OR dc.POBCountryID IN (...)
  OR dc.CountryIDByIP IN (...)
)
```

This means a customer in the UK (FCA, not a high-risk country) can appear if their citizenship or place of birth is in a monitored country (e.g., Iran, Syria, Lebanon).

### 2.2 Equity Computation

```sql
ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0) AS Equity
```

Sourced from `DWH_dbo.V_Liabilities` at `DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)` (yesterday). This equals the customer's total balance: real funds (Liabilities) plus the credit-capped promotional portion (ActualNWA). NULL is replaced with 0 via ISNULL.

### 2.3 Total Deposits and Cashouts

Lifetime aggregations from `DWH_dbo.Fact_CustomerAction`:
- `Total_Deposits = SUM(Amount) WHERE ActionTypeID = 7` (Deposit events)
- `Total_CO = SUM(Amount) WHERE ActionTypeID = 8` (Cashout events)

Both are in USD, no date filter — full lifetime history.

### 2.4 Has_eMoney_Account Flag

```sql
CASE WHEN mm.CID IS NULL THEN 0 ELSE 1 END AS Has_eMoney_Account
```

Where `mm` is the subset of `eMoney_dbo.eMoney_Dim_Account` where `IsValidETM = 1`, `IsTestAccount = 0`, and `CurrencyBalanceStatusID <> 4` (not Blocked). If a matching CID is found, the flag is 1; otherwise 0.

### 2.5 AML Entity Assignment

The three AML entity columns (`AMLEntity`, `AMLSubEntity`, `AMLSubEntity_2`) are passed through from `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization` via a LEFT JOIN on CID. They represent separate decomposed entity assignments from the AML sub-entity categorization pipeline:

- **AMLEntity**: Primary entity (observed: 'eToro_Gibraltar' — customers with crypto wallets in non-Germany countries under CySEC/FCA/ASIC/FSA Seychelles/ASIC&GAML)
- **AMLSubEntity**: Secondary entity (observed: 'eToro_Money_UK' and 'eToro_Germany')
- **AMLSubEntity_2**: Tertiary entity (observed: 'eToro_Money_Malta')

NULL in all three columns for customers not qualifying for any AML sub-entity (241,726 rows = 89% of population).

### 2.6 Full Rebuild Daily

The table is TRUNCATE + INSERT every day. There is no incremental logic. `UpdateDate = GETDATE()` is identical for all rows within a given day's run (confirmed: all 270,341 rows have UpdateDate = '2024-12-28 04:47:13.517').

---

## 3. Distribution & Performance

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Row count | 270,341 (one per CID) |
| Key join column | CID |

ROUND_ROBIN + HEAP is appropriate for a TRUNCATE+INSERT staging/reporting table with no repeated point lookups. Queries joining on CID will cause data movement; consider filtering heavily before joining to large distributed tables.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description quoted verbatim from upstream wiki |
| **Tier 2** | Derived from SP_AML_Terror_Monitor_Dashboard ETL code |
| **Tier 3** | Inferred from data patterns; no upstream wiki located |

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Resolved from DWH_dbo.Dim_Regulation via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 3 | KYC_Country | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryID (customer's KYC country of residence). (Tier 1 — Dictionary.Country) |
| 4 | CitizenshipCountry | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CitizenshipCountryID. NULL if CitizenshipCountryID is NULL. (Tier 1 — Dictionary.Country) |
| 5 | POBCountry | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.POBCountryID (place of birth). NULL if POBCountryID is NULL. (Tier 1 — Dictionary.Country) |
| 6 | CountryByIP_Residency | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved from DWH_dbo.Dim_Country via Dim_Customer.CountryIDByIP (country detected from registration IP). NULL if CountryIDByIP is NULL. (Tier 1 — Dictionary.Country) |
| 7 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Only Normal (ID=1) and Warning (ID=5) appear in this table due to the SP population filter. (Tier 1 — Dictionary.PlayerStatus) |
| 8 | Club | varchar(250) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Resolved from DWH_dbo.Dim_PlayerLevel via Dim_Customer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 9 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 10 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 11 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer) |
| 12 | FirstDepositAmount | money | YES | Amount of first deposit (in USD). Updated from FTDAmountInUsd. Passthrough from DWH_dbo.Dim_Customer. (Tier 1 — Dim_Customer, Tier 2 in source: SP_Dim_Customer) |
| 13 | ScreeningStatus | varchar(250) | YES | Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. Resolved from DWH_dbo.Dim_ScreeningStatus via Dim_Customer.ScreeningStatusID (LEFT JOIN — NULL if no screening record). Live values: NoMatch (99.9%), PendingInvestigation (0.07%), PEP (0.01%). (Tier 1 — ScreeningService.Dictionary.ScreeningStatus) |
| 14 | RiskScoreName | varchar(250) | YES | Customer risk score label from `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake` (LEFT JOIN on CID). No upstream wiki located for this object. Live data values: Medium (87.4%), High (12.3%), Low (0.2%), NULL (0.2%). Likely derived from an external risk scoring model or data lake integration. (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake, unresolved) |
| 15 | Equity | money | YES | Customer total balance as of yesterday: `ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0)` from DWH_dbo.V_Liabilities at DateID = yesterday (CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)). Equals real funds (Liabilities) plus credit-capped promotional portion (ActualNWA). NULL if no V_Liabilities row exists for yesterday (LEFT JOIN). (Tier 2 — SP_AML_Terror_Monitor_Dashboard) |
| 16 | Total_Deposits | money | YES | Lifetime total deposit amount in USD: `SUM(fca.Amount) WHERE fca.ActionTypeID = 7` (Deposit events) from DWH_dbo.Fact_CustomerAction. No date filter — full history. NULL if no deposit events exist for the customer. (Tier 2 — SP_AML_Terror_Monitor_Dashboard) |
| 17 | Total_CO | money | YES | Lifetime total cashout (withdrawal) amount in USD: `SUM(fca.Amount) WHERE fca.ActionTypeID = 8` (Cashout events) from DWH_dbo.Fact_CustomerAction. No date filter — full history. NULL if no cashout events exist. (Tier 2 — SP_AML_Terror_Monitor_Dashboard) |
| 18 | Has_eMoney_Account | int | YES | Flag: 1 if the customer has a valid, non-blocked eToro Money account in eMoney_dbo.eMoney_Dim_Account (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID≠4); 0 otherwise. ETL-computed: `CASE WHEN eMoney CID IS NULL THEN 0 ELSE 1 END`. (Tier 2 — SP_AML_Terror_Monitor_Dashboard) |
| 19 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at TRUNCATE+INSERT time. Identical for all rows within a given day's run. Not a business timestamp — reflects ETL execution time, not data change time. (Tier 2 — SP_AML_Terror_Monitor_Dashboard) |
| 20 | AMLEntity | varchar(250) | YES | Primary AML legal entity assignment for this customer, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLEntity (LEFT JOIN on CID). In this population (high-risk country connection), only 'eToro_Gibraltar' is observed (28,615 rows = customers with crypto wallets outside Germany under CySEC/FCA/ASIC/ASIC&GAML/FSA Seychelles). NULL for customers not qualifying for any primary AML entity (89% of population). (Tier 1 — BI_DB_AML_SubEntity_Categorization) |
| 21 | AMLSubEntity | varchar(250) | YES | Secondary AML legal entity assignment, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLSubEntity (LEFT JOIN on CID). Observed values: 'eToro_Money_UK' (6,566 rows — CySEC/FCA customers with UK eToro Money account), 'eToro_Germany' (6,191 rows — CySEC-regulated Germany residents with crypto wallet or positions). NULL when no secondary entity qualifies. (Tier 1 — BI_DB_AML_SubEntity_Categorization) |
| 22 | AMLSubEntity_2 | varchar(250) | YES | Tertiary AML legal entity assignment, passthrough from BI_DB_dbo.BI_DB_AML_SubEntity_Categorization.AMLSubEntity_2 (LEFT JOIN on CID). Observed values: 'eToro_Money_Malta' (509 rows — CySEC customers with EU IBAN eToro Money account, fully verified, in EEA country). NULL when no tertiary entity qualifies. (Tier 1 — BI_DB_AML_SubEntity_Categorization) |

---

## 5. Lineage

See `BI_DB_AML_Terror_Monitor_Dashboard.lineage.md` for full column-level lineage table.

### ETL Pipeline

```
DWH_dbo.Dim_Customer (population + customer attributes)
DWH_dbo.Dim_Regulation (regulation name)
DWH_dbo.Dim_PlayerStatus (player status name + population filter: IN (1,5))
DWH_dbo.Dim_PlayerLevel (club name)
DWH_dbo.Dim_Country (×4: KYC, citizenship, POB, IP country names)
DWH_dbo.Dim_ScreeningStatus (screening status name)
BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake (risk score)
BI_DB_dbo.BI_DB_AML_SubEntity_Categorization (AML entity assignments)
DWH_dbo.V_Liabilities (yesterday equity)
DWH_dbo.Fact_CustomerAction (lifetime deposits + cashouts)
eMoney_dbo.eMoney_Dim_Account (eMoney account flag)
  |
  ├── Step 01: #pop — population + denormalized attributes
  ├── Step 02: #equity — yesterday's balance from V_Liabilities
  ├── Step 03: #deposits — SUM of deposits from Fact_CustomerAction
  ├── Step 04: #CO — SUM of cashouts from Fact_CustomerAction
  ├── Step 05: #eMoney + #eMoney2 — eMoney flag
  ├── Step 06: #final — JOIN all temp tables
  └── Step 07: TRUNCATE + INSERT → BI_DB_AML_Terror_Monitor_Dashboard
```

### Production Sources

| Object | Purpose |
|--------|---------|
| Customer.CustomerStatic (via DWH staging) | CID, RegisteredReal, CountryID, CitizenshipCountryID, POBCountryID, CountryIDByIP |
| BackOffice.Customer (via DWH staging) | HasWallet, RegulationID, PlayerStatusID, PlayerLevelID, ScreeningStatusID |
| CustomerFinanceDB.Customer.FirstTimeDeposits | FirstDepositDate, FirstDepositAmount (via Dim_Customer ETL) |
| Dictionary.Regulation | Regulation name (via Dim_Regulation) |
| Dictionary.PlayerStatus | PlayerStatus name (via Dim_PlayerStatus) |
| Dictionary.PlayerLevel | Club name (via Dim_PlayerLevel) |
| Dictionary.Country | Country names (via Dim_Country) |
| ScreeningService.Dictionary.ScreeningStatus | ScreeningStatus name (via Dim_ScreeningStatus) |

---

## 6. Relationships

### 6.1 References To

| Column | Related Object | Join Condition |
|--------|---------------|----------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Source of most attributes |
| Regulation | DWH_dbo.Dim_Regulation | RegulationID = DWHRegulationID |
| KYC_Country | DWH_dbo.Dim_Country | CountryID = DWHCountryID |
| CitizenshipCountry | DWH_dbo.Dim_Country | CitizenshipCountryID = DWHCountryID |
| POBCountry | DWH_dbo.Dim_Country | POBCountryID = DWHCountryID |
| CountryByIP_Residency | DWH_dbo.Dim_Country | CountryIDByIP = DWHCountryID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | PlayerStatusID (filtered IN 1,5) |
| Club | DWH_dbo.Dim_PlayerLevel | PlayerLevelID |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | ScreeningStatusID |
| RiskScoreName | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | CID |
| AMLEntity, AMLSubEntity, AMLSubEntity_2 | BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | CID |
| Equity | DWH_dbo.V_Liabilities | CID, DateID=yesterday |
| Total_Deposits, Total_CO | DWH_dbo.Fact_CustomerAction | RealCID, ActionTypeID IN (7,8) |
| Has_eMoney_Account | eMoney_dbo.eMoney_Dim_Account | CID |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| BI_DB_dbo.SP_M_AML_Report | Reads this table for monthly AML reporting |
| AML/CTF compliance dashboards | Direct table reads for terror monitoring dashboard |

---

## 7. Sample Queries

### Customer AML profile lookup

```sql
SELECT CID, Regulation, KYC_Country, CitizenshipCountry, POBCountry,
       CountryByIP_Residency, PlayerStatus, Club,
       ScreeningStatus, RiskScoreName,
       Equity, Total_Deposits, Total_CO,
       Has_eMoney_Account, HasWallet,
       AMLEntity, AMLSubEntity, AMLSubEntity_2
FROM [BI_DB_dbo].[BI_DB_AML_Terror_Monitor_Dashboard]
WHERE CID = 12345;
```

### High-risk screening outcomes

```sql
SELECT ScreeningStatus, COUNT(*) AS cnt
FROM [BI_DB_dbo].[BI_DB_AML_Terror_Monitor_Dashboard]
WHERE ScreeningStatus NOT IN ('NoMatch', 'Unknown')
GROUP BY ScreeningStatus
ORDER BY cnt DESC;
```

### AML entity distribution

```sql
SELECT 
    COALESCE(AMLEntity, 'None') AS AMLEntity,
    COALESCE(AMLSubEntity, 'None') AS AMLSubEntity,
    COALESCE(AMLSubEntity_2, 'None') AS AMLSubEntity_2,
    COUNT(*) AS customer_count
FROM [BI_DB_dbo].[BI_DB_AML_Terror_Monitor_Dashboard]
GROUP BY AMLEntity, AMLSubEntity, AMLSubEntity_2
ORDER BY customer_count DESC;
```

### High-risk customers with high equity

```sql
SELECT CID, Regulation, KYC_Country, RiskScoreName, 
       Equity, Total_Deposits, ScreeningStatus
FROM [BI_DB_dbo].[BI_DB_AML_Terror_Monitor_Dashboard]
WHERE RiskScoreName = 'High'
  AND Equity > 50000
ORDER BY Equity DESC;
```

---

## 8. Atlassian Knowledge Sources

Phase 10 (Jira/Confluence) skipped — Atlassian MCP not used in this session. Compliance context for AML/CTF monitoring is captured in the SP source code and upstream wikis.

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14 (P10 Jira skipped)*
*Tiers: 16 T1, 5 T2, 1 T3, 0 T4 | Elements: 22/22*
*Object: BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard | Type: Table | Production Source: DWH_dbo.Dim_Customer + 11 upstream objects via SP_AML_Terror_Monitor_Dashboard*
