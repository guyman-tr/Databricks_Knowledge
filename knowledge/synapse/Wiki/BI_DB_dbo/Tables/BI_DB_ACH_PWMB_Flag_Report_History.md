# BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History

> AML/compliance flag report history tracking customers who use ACH (FundingTypeID=29) or PWMB (FundingTypeID=32) payment methods and have been flagged for suspicious multi-country IP activity or other compliance concerns. Date-partitioned historical log (ReportDate-clustered) storing per-customer compliance metrics: multi-IP geolocation data, KYC details, funding behaviour, and flag counts. Currently **empty (0 rows as of 2026-04-23)** — no active writer SP in SSDT; not registered in OpsDB. A backup from Nov 2024 confirms the table was previously populated. Schema change history: RealCID was `bigint` pre-backup, now `int`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — AML/compliance flag report history (ACH/PWMB customers) |
| **Production Source** | Unknown — no Generic Pipeline, no SSDT SP, no OpsDB registration |
| **Refresh** | None active — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ReportDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Objects** | DWH_dbo.Dim_FundingType (ACH=29, PWMB=32), SP_AML_BI_Alerts_New, SP_ChargebackReport |

---

## 1. Business Meaning

`BI_DB_ACH_PWMB_Flag_Report_History` is a compliance reporting table tracking customers flagged for suspicious activity who use **ACH** (Automated Clearing House, US bank-to-bank transfer) or **PWMB** (a distinct bank transfer method, FundingTypeID=32) payment channels. These are US-centric payment methods subject to NYDFS/FINRA regulatory scrutiny.

The table stores compliance flag reports by date, capturing:
- **Multi-country IP geolocation signals**: when a customer's logins span multiple countries, which is an AML trigger (related to GEO005 alert type in `SP_AML_BI_Alerts_New`)
- **KYC attributes**: verified phone country, registration country, phone verification date
- **Behavioural risk indicators**: same-day account openings, total connected accounts, depositor status
- **Compliance state**: number of flags, first-reported date, pending compliance officer review amount

The historical log design (ReportDate-clustered) allows compliance teams to track how customer risk profiles evolve over time across report generations.

**ACH vs PWMB**: In eToro's payment framework, ACH (FundingTypeID=29) and PWMB (FundingTypeID=32) follow similar but distinct SLA rules and AML monitoring patterns. PWMB was originally treated as equivalent to ACH (2019: "ACH logic now also applies to PWMB") but was later given separate SLA definitions (2020: "completely separate PWMB from ACH with new SLA definitions").

**Why the table is empty**: The source feeding this compliance report is unknown. A backup from 2024-11-17 confirms prior data existed. The table may have been truncated after a schema change (RealCID bigint → int).

---

## 2. Business Logic

### 2.1 Multi-Country IP Detection

**What**: Customers whose login IPs span multiple countries are flagged for geolocation-based AML review.

**Columns Involved**: `FirstMultiIPDaily`, `LastMultiIPDaily`, `TotalDaysMultiCountry`, `FirstMultiIPDayCountries`, `LastMultiIPDayCountries`, `OnlyNonUSLogins60Days`

**Rules**:
- `FirstMultiIPDaily` and `LastMultiIPDaily` are stored as bigint — likely YYYYMMDD integer format matching DWH DateID convention (e.g., 20240215 = Feb 15, 2024)
- `TotalDaysMultiCountry` = count of days with logins from 2+ countries
- `FirstMultiIPDayCountries` and `LastMultiIPDayCountries` = comma-separated country codes for the first and last observed multi-country day
- `OnlyNonUSLogins60Days` = 1 if all logins in the past 60 days were from non-US IPs — relevant for NYDFS/FINRA customers whose physical presence appears non-US
- Related AML alert: GEO005 in `SP_AML_BI_Alerts_New` (61-day login window, proxies excluded)

### 2.2 Compliance Flag Accumulation

**What**: Customers accumulate compliance flags based on multiple AML/KYC criteria.

**Columns Involved**: `NumberOfFlags`, `FirstReported`, `ReportDate`

**Rules**:
- `NumberOfFlags` = total flags triggered for the customer across all rule types
- `FirstReported` = date when the customer was first included in a compliance flag report
- `ReportDate` = date this specific report snapshot was generated (clustered index key)
- A single customer can appear on multiple ReportDates as their profile evolves

### 2.3 ACH/PWMB Payment Context

**What**: The report targets customers who use specific US bank transfer payment methods.

**Columns Involved**: `FundingType`

**Rules**:
- `FundingType` = name from `DWH_dbo.Dim_FundingType` (ACH = FundingTypeID 29, PWMB = FundingTypeID 32)
- ACH and PWMB are both US bank transfer channels subject to structuring detection (AML_NY001: >=2 transactions >=10K in 72h; AML_NY002: >=3 in 24h)
- Customers with these payment methods are subject to NYDFS/FINRA regulatory oversight
- `TotalPendingCOForUser` represents the total value (money type) pending compliance officer review for this customer

### 2.4 KYC Verification Status

**What**: Phone verification is a key KYC checkpoint tracked in this report.

**Columns Involved**: `VerifiedPhoneCounty`, `RegCountry`, `PhoneVerificationDate`, `PhoneNumber`

**Rules**:
- `VerifiedPhoneCounty` stores the country of the verified phone (note: column name has "County" — a spelling anomaly for "Country")
- Mismatch between `VerifiedPhoneCounty` and `RegCountry` may be an additional compliance signal
- `PhoneVerificationDate` = when the phone was verified via KYC process
- `PhoneNumber` stored as bigint — numeric phone number without formatting

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on ReportDate. Designed for date-range queries over compliance report history. Given the table is currently empty, no current query optimizations are relevant.

**Warning**: The table is currently empty. Any query returns 0 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers flagged on a specific date | `WHERE ReportDate = '2024-01-01'` — clustered index efficient |
| Customers with increasing flags | Join self on RealCID, compare NumberOfFlags across dates |
| Multi-country IP flags for US customers | `WHERE Regulation LIKE '%NYDFS%' AND OnlyNonUSLogins60Days = 1` |
| First-time flagged customers | `WHERE ReportDate = FirstReported` |
| PWMB vs ACH breakdown | `GROUP BY FundingType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_FundingType | `ON FundingType = ft.Name` | FundingTypeID and full payment method details |
| DWH_dbo.Dim_Customer / Dim_CID | `ON RealCID = c.RealCID` | Customer profile details |

### 3.4 Gotchas

- **Table is currently empty** — 0 rows as of 2026-04-23. Historical data was truncated circa Nov 2024.
- **VerifiedPhoneCounty spelling** — the column is spelled "County" not "Country" — this is a legacy naming error. Column stores country (not county/subdivision).
- **BigInt date columns** — `FirstMultiIPDaily` and `LastMultiIPDaily` are bigint, not date. Likely YYYYMMDD integer format. Cast as: `CAST(FirstMultiIPDaily AS VARCHAR(8))` then parse with `CONVERT(DATE, ...)`.
- **RealCID type change** — was bigint in Nov 2024 backup, now int. Range-check if RealCID values ever exceeded 2,147,483,647.
- **Regulation string** — regulatory jurisdiction stored as nvarchar(1000). Likely multi-value in some rows (e.g., "NYDFS+FINRA").
- **TotalPendingCOForUser** — money type. CO semantics unclear (Compliance Officer vs. Client Order). Verify with compliance team.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, related SP code, and AML/compliance domain context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Real (non-demo) customer identifier. Schema change Nov 2024: previously bigint, changed to int. (Tier 3 — CID pattern + SSDT DDL change history) |
| 2 | Regulation | nvarchar(1000) | YES | Regulatory jurisdiction governing this customer (e.g., "NYDFS+FINRA", "ASIC"). Determines applicable AML/compliance rules. (Tier 3 — SP_AML_BI_Alerts_New regulation grouping) |
| 3 | Age | int | YES | Customer age at the time of report generation. Used in age-based compliance rules (YOUNG001/YOUNG_ETM001: deposits >= $50K, Age <= 22). (Tier 3 — SP_AML_BI_Alerts_New YOUNG alert context) |
| 4 | LastMultiIPDaily | bigint | YES | Date of last observed multi-country IP login, stored as YYYYMMDD integer (bigint). Cast to date for range queries. (Tier 3 — column name + DWH DateID convention) |
| 5 | FirstMultiIPDaily | bigint | YES | Date of first observed multi-country IP login, stored as YYYYMMDD integer (bigint). Marks start of geo-flagging history. (Tier 3 — column name + DWH DateID convention) |
| 6 | TotalDaysMultiCountry | int | YES | Total number of days the customer logged in from IPs in multiple countries. Core metric for GEO005 AML alert. (Tier 3 — column name + SP_AML_BI_Alerts_New GEO005 context) |
| 7 | VerifiedPhoneCounty | nvarchar(1000) | YES | Country of the customer's verified phone number (column is misspelled as "County" — refers to country). KYC verification signal. Mismatch with RegCountry may indicate AML risk. (Tier 3 — column name + KYC domain; note: "County" is a typo for "Country") |
| 8 | RegCountry | nvarchar(1000) | YES | Country where the customer registered their eToro account. Used for jurisdiction assignment and geo-mismatch compliance checks. (Tier 3 — column name + KYC/compliance domain) |
| 9 | PhoneVerificationDate | datetime | YES | Timestamp when the customer's phone number was verified through the KYC process. (Tier 3 — column name + KYC domain) |
| 10 | PhoneNumber | bigint | YES | Customer phone number stored as bigint (numeric, no formatting). Used for KYC identity correlation. (Tier 3 — column name + KYC domain) |
| 11 | FundingType | nvarchar(1000) | YES | Payment method name — specifically ACH (FundingTypeID=29) or PWMB (FundingTypeID=32). References DWH_dbo.Dim_FundingType.Name. (Tier 3 — SP_ChargebackReport + SP_Operations_Monthly_KPIs_FullData — FundingTypeID 29=ACH, 32=PWMB) |
| 12 | TotalAccountsConnected | int | YES | Count of other accounts linked to this customer (social graph, payment accounts, family accounts). Anomalously high values are a compliance signal. (Tier 3 — column name + AML compliance domain) |
| 13 | Opened_New_SameDay | int | YES | Count of new eToro accounts opened on the same day as this customer. Coordinated same-day registrations are a fraud/AML signal. (Tier 3 — column name + AML fraud domain) |
| 14 | PlayerStatusID | nvarchar(1000) | YES | Customer account status (e.g., Active, Dormant, Blocked). Despite the name, stores the status label (not an integer ID). (Tier 3 — column name + CRM domain) |
| 15 | IsDepositor | int | YES | Binary flag: 1 = customer has made at least one approved deposit, 0 = no deposit history. (Tier 3 — column name + standard eToro depositor segmentation) |
| 16 | NumberOfFlags | int | YES | Total count of compliance/AML flags triggered for this customer across all applicable rule types. (Tier 3 — column name + AML compliance domain) |
| 17 | ReportDate | date | YES | Date this compliance flag report was generated. Clustered index key — date-range queries over compliance history are efficient. (Tier 3 — column name + reporting domain) |
| 18 | FirstReported | date | YES | Date when this customer first appeared in a compliance flag report. Marks the start of ongoing compliance monitoring. (Tier 3 — column name + AML compliance domain) |
| 19 | TotalPendingCOForUser | money | YES | Total value (in USD equivalent) pending compliance officer review for this customer. CO = Compliance Officer or Client Order — semantics require domain expert confirmation. (Tier 4 — column name; CO abbreviation ambiguous) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. (Tier 5 — propagation) |
| 21 | OnlyNonUSLogins60Days | int | YES | Flag: 1 if all of the customer's logins in the past 60 days originated from non-US IP addresses. Compliance relevance for NYDFS/FINRA customers (OB16US geo-mismatch alert context). (Tier 3 — column name + SP_AML_BI_Alerts_New GEO005/OB16US alert context) |
| 22 | FirstMultiIPDayCountries | varchar(1000) | YES | Comma-separated list of country codes observed on the first day the customer logged in from multiple countries. Geo-evidence for compliance review. (Tier 3 — column name + multi-country IP detection domain) |
| 23 | LastMultiIPDayCountries | varchar(1000) | YES | Comma-separated list of country codes observed on the most recent day the customer logged in from multiple countries. (Tier 3 — column name + multi-country IP detection domain) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Unknown (compliance system) | CID | Passthrough |
| Regulation | Unknown (compliance system) | Regulation | Passthrough |
| Age | Unknown | — | Customer age at report time |
| FirstMultiIPDaily / LastMultiIPDaily | IP geo-detection system | Date | YYYYMMDD bigint |
| TotalDaysMultiCountry | IP geo-detection system | — | Count of multi-country days |
| VerifiedPhoneCounty | KYC system | PhoneCountry | Passthrough |
| RegCountry | CRM/KYC system | Country | Passthrough |
| PhoneVerificationDate | KYC system | VerificationDate | Passthrough |
| PhoneNumber | KYC system | PhoneNumber | Passthrough |
| FundingType | DWH_dbo.Dim_FundingType | Name | Passthrough (ACH/PWMB) |
| TotalAccountsConnected | Compliance system | — | Account graph count |
| Opened_New_SameDay | Compliance system | — | Same-day registration count |
| PlayerStatusID | CRM system | PlayerStatus | Passthrough (label) |
| IsDepositor | DWH_dbo.Fact_BillingDeposit | — | Binary derived flag |
| NumberOfFlags | Compliance system | — | Flag count |
| ReportDate | Compliance system | ReportDate | Trading/report date |
| FirstReported | Compliance system | FirstDate | First flag date |
| TotalPendingCOForUser | Unknown | — | Pending CO value |
| OnlyNonUSLogins60Days | IP geo-detection | — | 60-day non-US login flag |
| FirstMultiIPDayCountries | IP geo-detection | — | Comma-separated countries |
| LastMultiIPDayCountries | IP geo-detection | — | Comma-separated countries |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Unknown AML/compliance reporting system (external report generator)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History (0 rows — EMPTY as of 2026-04-23)
  |-- No active UC pipeline --|

Schema history:
  BI_DB_ACH_PWMB_Flag_Report_History_Backup_20241117 (bigint RealCID, data preserved 2024-11-17)
  → Current table: RealCID downcast to int (Nov/Dec 2024 schema change)

Related AML context (NOT writers of this table — read from Dim_FundingType):
  SP_AML_BI_Alerts_New → uses PWMB/ACH FundingType in AML_NY001/NY002 structuring alerts
  SP_ChargebackReport → ACH (ID=29) / PWMB (ID=32) SLA tracking
  SP_Operations_Monthly_KPIs_FullData → ACH/PWMB cashout KPI tracking
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| FundingType | DWH_dbo.Dim_FundingType | Payment method reference (ACH=FundingTypeID 29, PWMB=FundingTypeID 32) |
| RealCID | DWH_dbo.Dim_Customer or Dim_CID | Customer profile (registration country, KYC status) |
| Regulation | AML compliance domain | Regulatory jurisdiction (NYDFS+FINRA, ASIC, etc.) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views that directly reference this table. However, `SP_AML_BI_Alerts_New` and `SP_ChargebackReport` operate on the same ACH/PWMB customer domain (via Dim_FundingType, not via this table directly).

---

## 7. Sample Queries

### Latest compliance flags by funding type (when populated)

```sql
SELECT
    FundingType,
    Regulation,
    COUNT(DISTINCT RealCID) AS flagged_customers,
    AVG(CAST(NumberOfFlags AS FLOAT)) AS avg_flags,
    MAX(ReportDate) AS latest_report
FROM [BI_DB_dbo].[BI_DB_ACH_PWMB_Flag_Report_History]
GROUP BY FundingType, Regulation
ORDER BY flagged_customers DESC;
-- Returns 0 rows as of 2026-04-23
```

### Multi-country IP risk profile

```sql
SELECT
    RealCID,
    RegCountry,
    VerifiedPhoneCounty,
    TotalDaysMultiCountry,
    FirstMultiIPDayCountries,
    LastMultiIPDayCountries,
    OnlyNonUSLogins60Days
FROM [BI_DB_dbo].[BI_DB_ACH_PWMB_Flag_Report_History]
WHERE ReportDate = (SELECT MAX(ReportDate) FROM [BI_DB_dbo].[BI_DB_ACH_PWMB_Flag_Report_History])
ORDER BY TotalDaysMultiCountry DESC;
```

### Check table state

```sql
SELECT
    COUNT(*) AS row_count,
    MIN(ReportDate) AS earliest_report,
    MAX(ReportDate) AS latest_report,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_DB_ACH_PWMB_Flag_Report_History];
-- Returns 0 rows as of 2026-04-23
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found directly. Related AML alert rules are documented in `SP_AML_BI_Alerts_New` change history (author: Pavlina Masoura, 2024–2026).

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 5/14 (P3/P5/P6-live/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 21 T3, 1 T4, 1 T5 | Elements: 23/23 | Object: BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History | Type: Table | Production Source: Unknown (AML/compliance system — discontinued)*
*Note: Table is currently empty (0 rows). Compliance flag history for ACH/PWMB (US bank transfer) customers with multi-country IP activity. Backup from Nov 2024 confirms prior data. Schema change: RealCID bigint → int. Quality 6.5 — penalized for empty table, no writer SP, and TotalPendingCOForUser Tier 4 ambiguity.*
