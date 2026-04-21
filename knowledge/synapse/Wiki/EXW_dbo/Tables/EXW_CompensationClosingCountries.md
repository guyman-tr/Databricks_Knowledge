# EXW_dbo.EXW_CompensationClosingCountries

> Regulatory compensation reference table — 140,638 rows tracking 59,207 wallet users whose crypto holdings were subject to country-closure or AML-driven compensation events. Each row records one wallet-crypto pair for a specific regulatory project, with the compensation amount, exchange rate, and closure details used to resolve user balances during regulatory exits.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Google Sheets (Fivetran): aml_reasons_compensated_users, wallet_aml_us_compensations, wallet_closureandreimbursementseea_cysec_2025; legacy country-closure data from prior ETL |
| **Refresh** | On-demand — SP_EXW_CompensationClosingCountries (no date parameter); UPSERT pattern (INSERT new + UPDATE existing); deduplication at end |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only regulatory reference |

---

## 1. Business Meaning

EXW_CompensationClosingCountries is the central registry of wallet users who were compensated as part of regulatory country-closure or AML-driven wallet termination events. With 140,638 rows covering 59,207 users, it stores one record per GCID × CryptoId × Project, capturing the crypto balance at time of compensation, the exchange rate used, and the closure date.

The table covers two categories of events:
1. **Country closures** (compliance events): Large-scale regulatory exits from specific jurisdictions where eToro was required to close wallet accounts — e.g., FrenchTerr (51,101 rows, 11,520 users), Germany_Tangany_AirDrop (47,021 rows, 31,123 users), Russia (17,421 rows), Netherlands (8,034 rows). These were loaded via legacy ETL processes and are not updated by the current SP.
2. **AML compensations** (individual enforcement): Users compensated due to anti-money-laundering enforcement actions. Currently loaded via Fivetran from Google Sheets: AML (2,664 rows, 2,311 users), AML_US (470 rows, 377 users), AML_EEA (217 rows, 187 users).

This table has two critical downstream roles:
- **AMLClosureEvent trigger**: SP_EXW_FinanceReportsBalancesNew uses it to set AMLClosureEvent=1 for users who appear in this table (condition 4 in the 4-way CASE)
- **Reimbursement pipeline input**: SP_EXW_CompensationClosingCountries itself (after populating this table) uses it to rebuild EXW_ReimbursementFollowUp and EXW_ReimbursementSumTable

---

## 2. Business Logic

### 2.1 Project Taxonomy

**What**: The Project column categorizes why a user appears in this table. 18 distinct project values are currently present.

**Columns Involved**: Project, AMLStatus, DateClosure, CompensationDate

**Project categories**:
- Legacy country-closure projects (loaded by prior ETL, not current SP):
  - FrenchTerr — French Territories closure
  - Germany_Tangany_AirDrop — Germany Tangany platform migration (airdrop-based)
  - Germany_Tangany_Cash_Compensation / Germany_Tangany_Cash_Compensation2 — Germany cash compensation tranches
  - Russia ALL regulations / Russia ASIC+ASIC GAML / Russia_Sanctions — Russia regulatory exit by regulation tier
  - Netherlands — Netherlands closure
  - GroupAB — Group A/B closure event
  - Philippines — Philippines closure
  - XtokensClosure / XtokensClosureFixMissing — xToken-specific closure events
  - SSN Closure -US — US SSN-based closure
  - Angola,Eritrea,Rwanda,Senegal — African market closure
  - Manual Adjustment — manual correction entries (2 rows)
- AML compensation projects (loaded by current SP via Fivetran Google Sheets):
  - AML — EU AML enforcement
  - AML_US — US AML enforcement
  - AML_EEA — EEA/CySEC 2025 closure and reimbursement

### 2.2 UPSERT Pattern

**What**: The SP uses an INSERT-if-not-exists + UPDATE-if-exists pattern to avoid duplicates while refreshing changed data.

**Columns Involved**: GCID, CryptoId, USD_FinalBalance, Project

**Rules**:
- INSERT: Only if no matching row exists (LEFT JOIN on GCID + CryptoId + ROUND(USD_FinalBalance,8) + Project)
- UPDATE: Refresh Rate, RateDate, FinalBalance, USD_FinalBalance, Country, CountryID, CompensationDate, Regulation, RegulationID, UpdateDate, Reason, AMLStatus, DateClosure where GCID + CryptoId + Project match
- Final dedup: ROW_NUMBER OVER all columns removes exact duplicates, keeping one row per unique combination

### 2.3 AMLStatus — Downstream Filter

**What**: The AMLStatus column is used by the reimbursement pipeline to filter active compensation records.

**Columns Involved**: AMLStatus, Project

**Rules**:
- For AML* projects, only rows where LOWER(AMLStatus) IN ('compensated','reimbursed','completed') are included in EXW_ReimbursementFollowUp
- For non-AML projects, all rows are included regardless of AMLStatus
- This filter prevents "pending" or "in-progress" AML cases from appearing in the follow-up report

### 2.4 NBSP Sanitization

**What**: Google Sheets sometimes contains non-breaking space characters (CHAR(160)) in numeric fields, causing CAST failures.

**Columns Involved**: CID, GCID (for AML_US and AML_EEA)

**Rules**:
- SP uses `CAST(CAST(REPLACE(value, CHAR(160), '') AS FLOAT) AS INT)` to sanitize before casting
- Applied to CID and GCID in AML_US and AML_EEA inserts (where Google Sheets formatting is less controlled)
- AML insert uses simpler direct CAST — presumably cleaner source sheet

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) distribution — joins on GCID (e.g., to EXW_DimUser, EXW_FinanceReportsBalancesNew) will be colocated. HEAP — no index; filter by Project or GCID to avoid full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All users compensated under AML | `WHERE Project IN ('AML', 'AML_US', 'AML_EEA') AND LOWER(AMLStatus) IN ('compensated','reimbursed','completed')` |
| Users for a specific project | `WHERE Project = 'Germany_Tangany_AirDrop'` |
| Total USD compensated by project | `SELECT Project, SUM(USD_FinalBalance) FROM ... GROUP BY Project` |
| Is a specific user in this table? | `WHERE GCID = @gcid` |
| Legacy vs AML breakdown | `SELECT CASE WHEN Project LIKE 'AML%' THEN 'AML' ELSE 'CountryClosure' END ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_FinanceReportsBalancesNew | GCID = GCID | Check AMLClosureEvent — whether user in this table |
| EXW_dbo.EXW_ReimbursementFollowUp | GCID = GCID | Track reimbursement completion status |
| EXW_dbo.EXW_DimUser | GCID = GCID | User demographic enrichment |

### 3.4 Gotchas

- **No GCID uniqueness**: One user may have multiple rows (one per CryptoId, one per Project). Always GROUP BY GCID if computing user counts
- **ReportFromDate and ReportId are NULL for all AML* rows**: These columns are hardcoded NULL in the current SP; only legacy project rows may have values
- **Project has a typo in SP**: The source alias is `Poject` (missing an 'r') in the SP code — this is a known SP defect that doesn't affect output (the alias maps correctly to the Project column in the INSERT list)
- **Legacy rows are NOT updated by current SP**: Country-closure projects (FrenchTerr, Germany, Russia, etc.) are static historical records. Only AML* rows are refreshed on each SP run
- **AMLStatus filter for reimbursement**: Don't use all rows from this table for reimbursement analysis — always apply the AML status filter (LOWER(AMLStatus) IN ('compensated','reimbursed','completed')) for AML* projects
- **NBSP in Google Sheets**: CID and GCID from AML_US and AML_EEA source sheets may contain non-breaking spaces — the SP sanitizes these but raw Fivetran tables may not

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from SP code analysis — ETL-computed, from Fivetran/Google Sheets (no upstream wiki), or lookup-enriched |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best guess — no code or wiki evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Platform customer ID (RealCID equivalent). Sourced from Google Sheet column `cid`; sanitized for non-breaking space characters before CAST to INT. May be NULL for rows where the source sheet omits CID. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 2 | GCID | int | NULL | Wallet customer identifier. Sourced from Google Sheet column `gcid`; sanitized for NBSP then CAST to INT. Distribution key. Used for AMLClosureEvent check in SP_EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 3 | Rate | numeric(38,8) | NULL | Exchange rate (crypto-to-USD) used at time of compensation. Sourced from Google Sheet column `exchange_rate`. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 4 | RateDate | date | NULL | Date of the exchange rate used for compensation calculation. Sourced from Google Sheet column `exchange_date`. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 5 | CryptoName | varchar(50) | NULL | Human-readable name of the cryptocurrency compensated (e.g., BTC, ETH, XRP). Sourced from Google Sheet column `crypto`. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 6 | CryptoId | int | NULL | Cryptocurrency identifier. Sourced from Google Sheet column `crypto_id`; ISNUMERIC guard applied for AML_US/AML_EEA sheets. NULL if source value is non-numeric. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 7 | FinalBalance | numeric(38,8) | NULL | Crypto balance at time of compensation, in native crypto units. Sourced from Google Sheet column `units`; CAST as FLOAT. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 8 | USD_FinalBalance | numeric(38,8) | NULL | USD value of compensation: FinalBalance × Rate at RateDate. Sourced from Google Sheet column `compensation_amount_usd`; CAST as FLOAT. Used as uniqueness key in UPSERT logic (ROUND to 8 decimal places). (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 9 | WalletId | uniqueidentifier | NULL | Customer's wallet GUID for the compensated CryptoId. Lookup from EXW_Wallet.EXW_CustomerWalletsView.Id by GCID + CryptoId. NULL if no matching wallet found. (Tier 2 — SP_EXW_CompensationClosingCountries via EXW_Wallet.EXW_CustomerWalletsView) |
| 10 | Address | varchar(max) | NULL | Blockchain address of the customer's wallet for the compensated crypto. Lookup from EXW_Wallet.EXW_CustomerWalletsView.Address by GCID + CryptoId. NULL if no wallet found. (Tier 2 — SP_EXW_CompensationClosingCountries via EXW_Wallet.EXW_CustomerWalletsView) |
| 11 | Country | varchar(100) | NULL | Country name of the user at time of compensation. Sourced from Google Sheet column `country`. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 12 | CountryID | int | NULL | Country identifier. Sourced from Google Sheet column `country_id`; CAST to INT. FK to DWH_dbo.Dim_Country. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 13 | ReportFromDate | date | NULL | Start date of the balance report period used in legacy compensation calculations. NULL for all AML*, AML_US, and AML_EEA rows (hardcoded by current SP). May have date values for legacy country-closure project rows. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 14 | ReportId | int | NULL | Report identifier from legacy balance report runs. NULL for all AML*, AML_US, and AML_EEA rows (hardcoded by current SP). May have values for legacy country-closure project rows. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 15 | Project | varchar(100) | NULL | Regulatory compensation project identifier. Discriminates the reason for user inclusion. Current SP produces: 'AML', 'AML_US', 'AML_EEA'. 15 additional legacy values: FrenchTerr, Germany_Tangany_AirDrop, Germany_Tangany_Cash_Compensation, Germany_Tangany_Cash_Compensation2, Russia ALL regulations..., Russia ASIC+ASIC GAML, Russia_Sanctions, Netherlands, GroupAB, Philippines, XtokensClosure, XtokensClosureFixMissing, SSN Closure -US, Angola/Eritrea/Rwanda/Senegal, Manual Adjustment. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 16 | CompensationDate | date | NULL | Date the compensation was calculated or recorded. Sourced from Google Sheet column `compensation_date`. Used as the join key in EXW_ReimbursementFollowUp (CompensationDate = EXW_WalletEntity.Date). (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 17 | Regulation | varchar(100) | NULL | Regulation name at time of compensation (e.g., CySEC, FCA, FinCEN). Sourced from Google Sheet column `regulation`. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 18 | RegulationID | int | NULL | Regulation identifier. Sourced from Google Sheet column `regulation_id`; ISNUMERIC guard applied for AML_US/AML_EEA. FK to DWH_dbo.Dim_Regulation. NULL if source is non-numeric. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 19 | UpdateDate | datetime | NULL | Timestamp of the most recent INSERT or UPDATE of this row. Set to GETDATE() by the SP. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 20 | Reason | varchar(512) | NULL | Textual reason for the compensation or closure. Sourced from `reason` column for AML/AML_US; from `sub_reason` column for AML_EEA. May differ in granularity across project types. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 21 | AMLStatus | varchar(max) | NULL | Status of the AML enforcement action. Sourced from Google Sheet column `status`. Key values used by downstream SP: 'compensated', 'reimbursed', 'completed' (active records); other values indicate in-progress or excluded cases. NULL for legacy non-AML project rows. (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |
| 22 | DateClosure | date | NULL | Date the user's wallet was formally closed as part of this regulatory event. Sourced from Google Sheet column `date_of_closure`; CAST(DATE). (Tier 2 — SP_EXW_CompensationClosingCountries via Fivetran) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, GCID | Google Sheets (Fivetran external tables) | cid, gcid | CAST INT with NBSP sanitization |
| Rate, RateDate | Google Sheets | exchange_rate, exchange_date | Passthrough |
| CryptoName, CryptoId | Google Sheets | crypto, crypto_id | Passthrough / CAST INT |
| FinalBalance, USD_FinalBalance | Google Sheets | units, compensation_amount_usd | CAST FLOAT |
| WalletId, Address | EXW_Wallet.EXW_CustomerWalletsView | Id, Address | JOIN by GCID + CryptoId |
| Country, CountryID | Google Sheets | country, country_id | Passthrough / CAST INT |
| Project | ETL-computed | — | Hardcoded: 'AML', 'AML_US', 'AML_EEA' |
| CompensationDate, DateClosure | Google Sheets | compensation_date, date_of_closure | CAST DATE |
| Regulation, RegulationID | Google Sheets | regulation, regulation_id | Passthrough / CAST INT |
| Reason | Google Sheets | reason or sub_reason | Per project type |
| AMLStatus | Google Sheets | status | Passthrough |
| UpdateDate | ETL-computed | — | GETDATE() |
| ReportFromDate, ReportId | ETL-computed | — | Hardcoded NULL (AML*); values from legacy ETL (other projects) |

### 5.2 ETL Pipeline

```
Google Sheets (Fivetran → BI_DB_dbo External Tables)
  aml_reasons_compensated_users         → Project='AML'
  wallet_aml_us_compensations           → Project='AML_US'
  wallet_closureandreimbursementseea... → Project='AML_EEA'
    |
    | SP_EXW_CompensationClosingCountries (on-demand, no @d)
    | UPSERT (INSERT new + UPDATE existing) + Dedup
    v
EXW_dbo.EXW_CompensationClosingCountries (140K rows — Synapse)
  (+ 15 legacy project values from prior ETL / manual load — not updated by current SP)
    |
    +-- SP_EXW_FinanceReportsBalancesNew → AMLClosureEvent condition 4
    +-- SP_EXW_CompensationClosingCountries → EXW_ReimbursementFollowUp (TRUNCATE + INSERT)
    +-- SP_EXW_CompensationClosingCountries → EXW_ReimbursementSumTable (TRUNCATE + INSERT)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | User wallet dimension |
| GCID + CryptoId | EXW_Wallet.EXW_CustomerWalletsView | Wallet address lookup |
| CountryID | DWH_dbo.Dim_Country | Country name reference |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name reference |

### 6.2 Referenced By

| Source Object | Join Column | Description |
|--------------|-------------|-------------|
| EXW_dbo.EXW_FinanceReportsBalancesNew | GCID | AMLClosureEvent condition 4: user in this table + SelectedValue=0 |
| EXW_dbo.EXW_ReimbursementFollowUp | GCID + CryptoId + CompensationDate | Reimbursement tracking (rebuilt by same SP) |
| EXW_dbo.EXW_ReimbursementSumTable | — | Summary aggregation (rebuilt by same SP) |

---

## 7. Sample Queries

### 7.1 All active AML-compensated users with their crypto balances

```sql
SELECT
    GCID,
    CID,
    Project,
    CryptoName,
    FinalBalance,
    USD_FinalBalance,
    AMLStatus,
    CompensationDate,
    DateClosure
FROM EXW_dbo.EXW_CompensationClosingCountries
WHERE Project IN ('AML', 'AML_US', 'AML_EEA')
  AND LOWER(AMLStatus) IN ('compensated', 'reimbursed', 'completed')
ORDER BY CompensationDate DESC;
```

### 7.2 Total compensation by project

```sql
SELECT
    Project,
    COUNT(DISTINCT GCID) AS Users,
    COUNT(*) AS Rows,
    SUM(USD_FinalBalance) AS TotalUSDCompensated
FROM EXW_dbo.EXW_CompensationClosingCountries
GROUP BY Project
ORDER BY TotalUSDCompensated DESC;
```

### 7.3 Check if specific users are in the compensation registry (for AMLClosureEvent audit)

```sql
SELECT
    f.GCID,
    f.AMLClosureEvent,
    c.Project,
    c.USD_FinalBalance,
    c.AMLStatus
FROM EXW_dbo.EXW_FinanceReportsBalancesNew f
LEFT JOIN EXW_dbo.EXW_CompensationClosingCountries c ON f.GCID = c.GCID
WHERE f.BalanceDateID = (SELECT MAX(BalanceDateID) FROM EXW_dbo.EXW_FinanceReportsBalancesNew)
  AND f.AMLClosureEvent = 1
  AND c.Project IN ('AML', 'AML_US', 'AML_EEA');
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found. SP header includes link to Google Sheet for AML compensation data. SP modified by Inessa Kontorovich 2025-07-27 to add EU AML (AML_EEA) part. SP is not date-parameterized — runs as full UPSERT on all source sheets.

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 9/10, Sources: 7/10*
*Object: EXW_dbo.EXW_CompensationClosingCountries | Type: Table | Production Source: Google Sheets via Fivetran (BI_DB_dbo External Tables)*
