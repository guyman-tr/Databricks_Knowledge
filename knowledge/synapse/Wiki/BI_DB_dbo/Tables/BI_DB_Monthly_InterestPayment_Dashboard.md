# BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard

> 10.8M-row monthly interest payment dashboard table tracking customer-level interest accruals with tax details, regulation, demographics, and account type enrichment across 27 months (Jan 2024 – Mar 2026). Each row represents one customer's monthly interest payment record with PII fields for Tableau reporting. Refreshed monthly by SP_Monthly_InterestPayment_Dashboard via DELETE+INSERT on the prior month.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Interest.Trade.InterestMonthly via BI_DB_InterestMonthly + BI_DB_InterestDaily + Dim_Customer + Dim_Regulation + Dim_Country + Dim_AccountType + UserApiDB tax fields via SP_Monthly_InterestPayment_Dashboard |
| **Refresh** | Monthly (DELETE+INSERT by MonthOfInterest = prior month's first day) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (MonthOfInterest ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | Not exported to Unity Catalog |

---

## 1. Business Meaning

This table is a materialized Tableau report dataset for the Interest Payments Dashboard. It denormalizes monthly interest payment data with customer PII, regulation, country/region, account type, and tax identification details into a single wide table optimized for direct Tableau consumption.

The column naming convention with `_Custom_SQL_Query1`, `_Custom_SQL_Query2`, and `_Dim_*` suffixes reveals its origin as a Tableau Custom SQL workbook that was later materialized into a Synapse table for performance. Several columns are duplicates (e.g., `CID`, `RealCID_Custom_SQL_Query1`, `CID_Custom_SQL_Query2`, `CID_Custom_SQL_Query1_1`, `CID_Custom_SQL_Query1_2` all contain the same customer ID) — these are Tableau join artifacts preserved for backwards compatibility.

Key characteristics:
- **Grain**: One row per customer (CID) per month (MonthOfInterest)
- **10.8M rows** across 27 months (Jan 2024 – Mar 2026), ~400K rows/month
- **StatusID = 3 always** — only completed/approved interest records
- **Regulations**: CySEC (68%), FCA (27%), FSA Seychelles (2.2%), ASIC & GAML (1.9%)
- **Account types**: Private (99.5%), Corporate (0.5%), Joint Account, SMSF, Affiliate, Employee
- **Tax handling**: TaxPercentage varies by regulation (0% CySEC, 20% FCA). FinalTaxedlnterest = MonthlyAccumulatedInterest × (1 − TaxPercentage/100)
- **PII fields**: FirstName, LastName, City, Address, Zip, BuildingNumber are MASKED WITH (FUNCTION = 'default()')
- Author: Adi Meidan (2024-04-03), changed by Lior Ben Dor (date parameter)

---

## 2. Business Logic

### 2.1 Interest Calculation Source

**What**: Monthly interest amounts sourced from BI_DB_InterestMonthly, which itself sources from Interest.Trade.InterestMonthly production system.
**Columns Involved**: MonthlyAccumulatedInterest, TaxPercentage, FinalTaxedlnterest
**Rules**:
- Gross interest: MonthlyAccumulatedInterest (in USD)
- Tax rate: TaxPercentage (0% for CySEC, 20% for FCA, varies by regulation)
- Net interest: FinalTaxedlnterest ≈ MonthlyAccumulatedInterest × (1 − TaxPercentage/100)
- Only StatusID=3 (completed) records included

### 2.2 Account Type Resolution

**What**: AccountTypeID resolved from BI_DB_InterestDaily using MAX aggregation per CID+month.
**Columns Involved**: AccountTypeID, Name_Dim_AccountType
**Rules**:
- MAX(AccountTypeID) used when a customer has multiple daily records with different account types in a month
- Joined to Dim_AccountType for descriptive name
- 9 account types: Private (99.5%), Corporate, Joint Account, SMSF, Affiliate Private/Corporate, Funded Employee, Administrated, Analyst

### 2.3 Tax Information Enrichment

**What**: Customer tax identification and requirement data from UserApiDB.
**Columns Involved**: TaxCountry_Custom_SQL_Query1, TaxID, Type, TaxRequirement_Custom_SQL_Query1
**Rules**:
- Tax info from External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6
- TaxCountry resolved via Dim_Country on cex.CountryId
- TaxID = ExtendedUserField.Value (the actual tax identifier)
- Type = ExtendedUserValueType.Name (tax value type)
- TaxRequirement = ExtendedUserValueType.Name via CountryTaxType + MandatoryType + NationalPinValueTypeToReportType chain (excluding NationalPinReportTypeID=3)

### 2.4 Tableau Artifact Columns

**What**: Duplicate CID columns and suffixed column names from Tableau Custom SQL migration.
**Columns Involved**: RealCID_Custom_SQL_Query1, CID_Custom_SQL_Query2, CID_Custom_SQL_Query1_1, CID_Custom_SQL_Query1_2
**Rules**:
- All four contain the same value as CID
- Preserved for Tableau workbook backwards compatibility — removing them would break existing dashboards

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED INDEX on MonthOfInterest. Filter on MonthOfInterest for index seeks. JOINs on CID are co-located with other HASH(CID) tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total interest paid by regulation for a month | `SELECT Name, SUM(FinalTaxedlnterest) FROM ... WHERE MonthOfInterest='2026-03-01' GROUP BY Name` |
| Customers with highest interest | `SELECT TOP 100 CID, MonthlyAccumulatedInterest FROM ... WHERE MonthOfInterest='2026-03-01' ORDER BY MonthlyAccumulatedInterest DESC` |
| Tax breakdown by country | `SELECT Country, AVG(TaxPercentage), SUM(FinalTaxedlnterest) FROM ... GROUP BY Country` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_InterestMonthly | CID + MonthOfInterest | Additional interest details |
| DWH_dbo.Dim_Customer | RealCID = CID | Extended customer attributes |

### 3.4 Gotchas

- **FinalTaxedlnterest** — column name has lowercase 'l' instead of uppercase 'I' (typo from source: "Taxed**l**nterest" not "Taxed**I**nterest"). Baked into DDL and upstream BI_DB_InterestMonthly.
- **Duplicate CID columns** — 5 columns contain the same CID value. Use `CID` for queries; ignore `*_Custom_SQL_Query*` variants.
- **PII masking** — FirstName, LastName, Name_Custom_SQL_Query1, City, Address, Zip, BuildingNumber are masked with `default()`. Unmasked access requires UNMASK permission.
- **StatusID is always 3** — no analytical value; every row has the same status.
- **INNER JOIN on #interest_daily** — customers with interest but no daily records for the month are excluded. This is a data completeness gate.
- **UC not migrated** — this table is not exported to Unity Catalog.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | Propagation canonical | Standard ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — unique identifier for a customer account in the eToro platform. FK to DWH_dbo.Dim_Customer.RealCID. Grain key alongside MonthOfInterest. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 2 | RegulationID | int | YES | Regulatory entity ID governing this customer. FK to DWH_dbo.Dim_Regulation. Values observed: 1=CySEC, 2=FCA, 4=ASIC, 9=Seychelles, 10=ASIC-new, 11=FSRA, 13=other. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 3 | StatusID | int | YES | Interest calculation status. Always 3 in this table (completed/approved). SP filters to StatusID=3 before inserting. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 4 | MonthOfInterest | date | YES | First day of the month for which interest was calculated (e.g., 2026-03-01). Clustered index column — filter on this for efficient queries. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 5 | MonthlyAccumulatedInterest | float | YES | Gross accumulated interest for this CID for this month, before tax deduction. In USD. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 6 | TaxPercentage | float | YES | Withholding tax percentage applied to the interest. Varies by regulation: 0.00% for CySEC (RegulationID=1), 20.00% for FCA (RegulationID=2). (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 7 | FinalTaxedlnterest | numeric(12,2) | YES | Net interest after tax deduction. Approximately MonthlyAccumulatedInterest x (1 - TaxPercentage/100). Note: column name has lowercase 'l' not uppercase 'I' (typo in source). (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 8 | ValidFrom | datetime2(7) | YES | Timestamp from the Interest system indicating when this interest record was finalized/approved. Source system timestamp, not a DWH ETL timestamp. (Tier 2 — SP_InterestMonthly, from Interest.Trade.InterestMonthly) |
| 9 | ID | int | YES | Dim_Regulation surrogate ID. Joined on RegulationID=DWHRegulationID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 10 | Name | varchar(50) | YES | Regulation name from Dim_Regulation. Values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, ASIC, MAS. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 11 | DWHRegulationID | int | YES | DWH regulation mapping ID from Dim_Regulation. Same value as RegulationID (joined on this key). (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 12 | StatusID_Dim_Regulation | int | YES | Status of the regulation record in Dim_Regulation. Not the interest StatusID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 13 | InsertDate | datetime2(7) | YES | Insert date of the Dim_Regulation record. Not an ETL timestamp for this table. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 14 | ClusterRegulationID | int | YES | Cluster regulation grouping ID from Dim_Regulation. Used for regulatory cluster reporting. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 15 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Same value as CID (joined on dc.RealCID=i.CID). (Tier 1 — Customer.CustomerStatic) |
| 16 | Country | varchar(50) | YES | Country name from Dim_Country. Resolved via Dim_Customer.CountryID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 17 | Region | varchar(50) | YES | Marketing region name from Dim_Country.MarketingRegionManualName. Values: CEE, Spain, Italian, UK, French, etc. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 18 | Desk | varchar(50) | YES | Operations desk assignment from Dim_Country. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 19 | RealCID_Custom_SQL_Query1 | int | YES | Duplicate of CID. Tableau Custom SQL artifact — originally a separate query's CID join column. Always equals CID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 20 | FirstName | varchar(max) | YES | Legal first name in Unicode. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 21 | LastName | varchar(max) | YES | Legal last name in Unicode. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 22 | MiddleName | varchar(max) | YES | Middle name in Unicode. Added 2018. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 23 | Name_Custom_SQL_Query1 | varchar(max) | YES | Full name: FirstName + ' ' + LastName. MASKED WITH default(). Concatenation from Dim_Customer fields. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 24 | UserName | varchar(max) | YES | Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 25 | BirthDate | date | YES | Customer date of birth. Used in KYC age verification. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 26 | City | varchar(100) | YES | City in Unicode. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 27 | Address | varchar(max) | YES | Street address in Unicode. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 28 | Zip | varchar(100) | YES | Postal code. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 29 | AccountTypeID | int | YES | Account type ID. MAX(AccountTypeID) per CID+month from BI_DB_InterestDaily. FK to Dim_AccountType. 9 types: Private, Corporate, Joint Account, SMSF, Affiliate Private/Corporate, Funded Employee, Administrated, Analyst. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 30 | BuildingNumber | nvarchar(30) | YES | Building/apartment number. Separate from Address for structured address storage. MASKED WITH default(). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 31 | Gender | varchar(20) | YES | Gender: M, F, or U (Unknown). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 32 | CID_Custom_SQL_Query2 | int | YES | Duplicate of CID. Tableau Custom SQL artifact from the InterestDaily join. Always equals CID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 33 | Date | date | YES | First day of month derived from BI_DB_InterestDaily.DayOfInterest via DATEFROMPARTS(YEAR,MONTH,1). Same value as MonthOfInterest. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 34 | AccountTypeID_Custom_SQL_Query2 | int | YES | Duplicate of AccountTypeID. Tableau Custom SQL artifact. Same value as AccountTypeID (#29). (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 35 | AccountTypeID_Dim_AccountType | int | YES | Dim_AccountType.AccountTypeID. Same value as AccountTypeID — joined on this key. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 36 | Name_Dim_AccountType | varchar(100) | YES | Account type name from Dim_AccountType. Private, Corporate, Joint Account, SMSF, etc. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 37 | DWHAccountTypeID | int | YES | DWH account type mapping ID from Dim_AccountType. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 38 | StatusID_Dim_AccountType | int | YES | Status of the Dim_AccountType record. Not the interest StatusID. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 39 | InsertDate_Dim_AccountType | date | YES | Insert date of the Dim_AccountType record. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 40 | CID_Custom_SQL_Query1_1 | int | YES | Duplicate of CID. Tableau Custom SQL artifact from the tax info join. NULL when no tax record exists for the customer (LEFT JOIN). (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 41 | TaxCountry_Custom_SQL_Query1 | varchar(100) | YES | Tax country name. Resolved from Dim_Country via ExtendedUserField.CountryId (FieldId=6 tax registration). May differ from Country (#16) — Country is residence, TaxCountry is tax jurisdiction. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 42 | TaxID | nvarchar(4000) | YES | Customer tax identification number (e.g., national ID, SSN equivalent). From UserApiDB.Customer.ExtendedUserField.Value WHERE FieldId=6. PII. NULL when not provided. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 43 | Type | varchar(100) | YES | Tax value type name from Dictionary.ExtendedUserValueType. Classifies the type of TaxID provided. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 44 | CID_Custom_SQL_Query1_2 | int | YES | Duplicate of CID. Tableau Custom SQL artifact from the tax requirement join. NULL when no tax requirement record exists (LEFT JOIN). (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 45 | TaxRequirement_Custom_SQL_Query1 | nvarchar(4000) | YES | Tax requirement type name. Resolved via CountryTaxType + MandatoryType + NationalPinValueTypeToReportType chain (excluding NationalPinReportTypeID=3). Indicates the regulatory tax reporting obligation for this customer's country. (Tier 2 — SP_Monthly_InterestPayment_Dashboard) |
| 46 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — SP_Monthly_InterestPayment_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID – ValidFrom (8 cols) | Interest.Trade.InterestMonthly | Various | Passthrough via BI_DB_InterestMonthly |
| ID – ClusterRegulationID (6 cols) | Dim_Regulation | Various | Lookup join on RegulationID=DWHRegulationID |
| RealCID, FirstName–Gender (12 cols) | Customer.CustomerStatic | Various | Passthrough via Dim_Customer |
| Country, Region, Desk | Dim_Country | Name, MarketingRegionManualName, Desk | Lookup join via Dim_Customer.CountryID |
| AccountTypeID + Dim_AccountType cols | BI_DB_InterestDaily + Dim_AccountType | Various | MAX aggregation + lookup |
| TaxCountry, TaxID, Type, TaxRequirement | UserApiDB.Customer.ExtendedUserField | Various | Multi-table join chain (FieldId=6) |
| UpdateDate | ETL | GETDATE() | Generated |

### 5.2 ETL Pipeline

```
Interest.Trade.InterestMonthly (production)
  |-- Generic Pipeline (Bronze) ---|
  v
BI_DB_dbo.BI_DB_InterestMonthly (monthly interest accruals)
  + BI_DB_dbo.BI_DB_InterestDaily (AccountTypeID via MAX)
  + DWH_dbo.Dim_Regulation (regulation attributes)
  + DWH_dbo.Dim_Customer (PII, demographics)
  + DWH_dbo.Dim_Country (country, region, desk)
  + DWH_dbo.Dim_AccountType (account type)
  + External_UserApiDB (tax info: FieldId=6)
  |-- SP_Monthly_InterestPayment_Dashboard @Date ---|
  v
BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard (10.8M rows)
  UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID / RealCID | DWH_dbo.Dim_Customer | Customer identity |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory entity |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account classification |
| Country | DWH_dbo.Dim_Country (Name) | Country of residence |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo or DWH_dbo. This is a terminal Tableau dashboard table.

---

## 7. Sample Queries

### 7.1 Monthly Interest by Regulation

```sql
SELECT
    MonthOfInterest,
    Name AS Regulation,
    COUNT(*) AS Customers,
    SUM(MonthlyAccumulatedInterest) AS GrossInterest,
    SUM(FinalTaxedlnterest) AS NetInterest
FROM [BI_DB_dbo].[BI_DB_Monthly_InterestPayment_Dashboard]
WHERE MonthOfInterest >= '2026-01-01'
GROUP BY MonthOfInterest, Name
ORDER BY MonthOfInterest DESC, GrossInterest DESC
```

### 7.2 Tax Impact Analysis by Country

```sql
SELECT
    Country,
    AVG(TaxPercentage) AS AvgTaxPct,
    SUM(MonthlyAccumulatedInterest) AS GrossInterest,
    SUM(FinalTaxedlnterest) AS NetInterest,
    SUM(MonthlyAccumulatedInterest) - SUM(FinalTaxedlnterest) AS TaxWithheld
FROM [BI_DB_dbo].[BI_DB_Monthly_InterestPayment_Dashboard]
WHERE MonthOfInterest = '2026-03-01'
GROUP BY Country
ORDER BY TaxWithheld DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search access denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 9 T1, 36 T2, 0 T3, 0 T4, 1 T5 | Elements: 46/46, Logic: 7/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard | Type: Table | Production Source: Interest.Trade.InterestMonthly via BI_DB_InterestMonthly*
