# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_QSR_Balance_New`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_QSR_Balance_New.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_QSR_Balance_New]
(
	[Quarter] [int] NULL,
	[ReportCurrency] [varchar](100) NULL,
	[Rate] [money] NULL,
	[CID] [int] NULL,
	[IsCreditReportValidCB] [varchar](100) NULL,
	[Regulation] [varchar](100) NULL,
	[PlayerStatus] [varchar](100) NULL,
	[Country] [varchar](100) NULL,
	[CountryFormatted] [varchar](100) NULL,
	[IsEtoroBVI] [varchar](100) NULL,
	[ClientBalanceEnd] [money] NULL,
	[RealizedPnL] [money] NULL,
	[UnrealizedEnd] [money] NULL,
	[ClientBalanceEndRealCrypto] [money] NULL,
	[ClientBalanceEnd_CFD] [money] NULL,
	[RealizedCFD] [money] NULL,
	[UnrealizedCFDEnd] [money] NULL,
	[LiabilitiesStocksSustainable] [money] NULL,
	[LiabilitiesStocksNonSustainable] [money] NULL,
	[LiabilitiesStocksRealSustainable] [money] NULL,
	[LiabilitiesStocksRealNonSustainable] [money] NULL,
	[TotalStockLiabilities] [money] NULL,
	[IsZeroBalance] [varchar](100) NULL,
	[IsNegativeBalance] [varchar](100) NULL,
	[HasSustainableEquityEOP] [varchar](100) NULL,
	[UpdateDate] [datetime] NULL,
	[MifidCategory] [varchar](100) NULL,
	[RealizedPnLRealCrypto] [money] NULL,
	[RealizedPnLRealStocks] [money] NULL,
	[UnrealizedRealCryptoEnd] [money] NULL,
	[UnrealizedRealCryptoChange] [money] NULL,
	[UnrealizedRealStocksEnd] [money] NULL,
	[UnrealizedRealStocksChange] [money] NULL,
	[RealizedCFDWithBugPre2021Q2] [money] NULL,
	[StockMargin] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Quarter] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 13 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_SnapshotCustomer` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotCustomer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md`

# DWH_dbo.Fact_SnapshotCustomer

> Daily SCD Type 2 snapshot of every eToro customer's current state — the central customer-attribute table powering regulatory reporting, risk, and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Ext_FSC_Real_Customer_Customer (CC), Ext_FSC_BackOffice_Customer (BO), Ext_FSC_BackOffice_RegulationChangeLog, Ext_FSC_Customer_FirstTimeDeposits, Ext_FSC_PhoneCustomer, Ext_FSC_StocksLending, Ext_Dim_Customer_CustomerIdentification_DLT |
| **Refresh** | Daily via MERGE (SP_Fact_SnapshotCustomer), orchestrated by SP_Fact_SnapshotCustomer_DL_To_Synapse |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI(RealCID ASC) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked; matches `_generic_pipeline_mapping.json` generic_id=1115, `business_group` DWH). Unmasked PII export: `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`. |
| **UC Format** | delta |
| **UC Partitioned By** | N/A (view is unpartitioned) |
| **UC Table Type** | Two UC targets: `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked) + `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked) |

---

## 1. Business Meaning

Fact_SnapshotCustomer is the central customer state table in the DWH. For every eToro customer (RealCID), it holds one row per distinct attribute state within a year, recording which attributes were active between FromDate and ToDate (encoded together in `DateRangeID`). The pattern is SCD Type 2 by year: each year's rows are closed as attribute changes occur, and a new open row is created with the updated state. At year-end, all open rows are closed and reopened with the new year's date range.

As of 2026-03-19: **406M+ total rows**, **46.4M distinct customers**, data from **2007-08-22 to present**. 302M rows are "currently open" (ToDate = year-end). 11.9% of current open rows represent depositors; 98.0% are valid customers (IsValidCustomer=1).

The SP loads data from 6 source systems via staging Ext_FSC tables pre-populated by SP_Fact_SnapshotCustomer_DL_To_Synapse. The core CC (Customer Core) source provides demographics and status; the BO (Back Office) source provides risk/compliance attributes. RegulationID is taken from RegulationChangeLog — **not** from Back Office — because regulation changes take effect end-of-day.

8 legacy columns (DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist) are present in the DDL but NOT populated by the current SP. They carry DEFAULT (0) values.

---

## 2. Business Logic

### 2.1 SCD Type 2 Pattern — DateRangeID

**What**: Each customer-state row has a DateRangeID encoding both the open date (FromDate) and close date (ToDate) as a 12-digit bigint.

**Columns Involved**: `DateRangeID`, `RealCID`

**Rules**:
- DateRangeID = `YYYYMMDD` (open date, 8 chars) + `MMDDD` (year-end month+day, 4 chars) → e.g., `202603101231` = opened 2026-03-10, closes 2026-12-31
- When an attribute changes, the SP updates DateRangeID of the existing row to close it (right 4 chars become yesterday's MMDD), then inserts a new row with today's open date + year-end
- To get the **most current row** per customer: `RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'`
- On January 1st: all prior year's open rows are closed (12-31) and re-opened for the new year
- The `Dim_Range` dimension table stores FromDateID + ToDateID for each DateRangeID

### 2.2 IsValidCustomer — Segment Flag

**What**: Computed flag indicating whether a customer is a "valid" retail customer for analytics (excludes demo, blocked countries, excluded labels).

**Columns Involved**: `IsValidCustomer`, `PlayerLevelID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsValidCustomer = 1 IF:
  PlayerLevelID <> 4 (not demo)
  AND LabelID NOT IN (30, 26) (not internal/excluded label)
  AND CountryID <> 250 (not blocked country)
ELSE 0
```
Pre-2020-03-14 rule additionally excluded AccountTypeID=9.

### 2.3 IsCreditReportValidCB — Credit Reporting Flag

**What**: Flag indicating whether a customer is eligible for credit report validation (CB = CreditBureau context).

**Columns Involved**: `IsCreditReportValidCB`, `PlayerLevelID`, `AccountTypeID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsCreditReportValidCB = 1 IF:
  NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)  (not non-real demo)
  AND LabelID NOT IN (26, 30)
  AND NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243))
ELSE 0
```

### 2.4 RegulationID — End-of-Day Rule

**What**: A customer's regulatory jurisdiction is taken from RegulationChangeLog (end-of-day change), NOT from the back-office system (immediate change), because regulation changes take effect at end of day for business/legal reasons.

**Columns Involved**: `RegulationID`, sourced from `Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID`

### 2.5 GDPR Erasure Masking

**What**: When a GDPR deletion request is processed, the UserName in Customer Core gets a `DelUserName` prefix. The SP detects this and masks Email, City, Address, Zip, and PhoneNumber in Fact_SnapshotCustomer.

**Columns Involved**: `Email`, `City`, `Address`, `Zip`, `PhoneNumber`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution + CCI makes per-customer aggregations and filters on RealCID highly efficient — queries that filter or join on RealCID benefit from colocation. The NCI on RealCID provides efficient point-lookup for single customers.

**Warning**: With 406M rows, full table scans are expensive. Always filter by DateRangeID or a specific year range when possible.

### 3.1b UC (Databricks) Storage

**In Databricks**, the data is accessed via `V_Fact_SnapshotCustomer_FromDateID` (generic_id=1115), not directly. Two UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` — full PII (gated access)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` — Email/City/Address/Zip masked

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current state for all customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Current state for one customer | `WHERE RealCID = @cid AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Customer state on a specific date | `WHERE RealCID = @cid AND LEFT(CAST(DateRangeID AS VARCHAR(12)),8) <= @date AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) >= RIGHT(@date, 4)` |
| Count of depositors | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsDepositor = 1` |
| Valid retail customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsValidCustomer = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name/region |
| DWH_dbo.Dim_Label | ON f.LabelID = dl.LabelID | Brand/label name |
| DWH_dbo.Dim_Language | ON f.LanguageID = dl.LanguageID | Customer language |
| DWH_dbo.Dim_VerificationLevel | ON f.VerificationLevelID = dv.VerificationLevelID | KYC verification status |
| DWH_dbo.Dim_PlayerStatus | ON f.PlayerStatusID = dp.PlayerStatusID | Account lifecycle status |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_AccountStatus | ON f.AccountStatusID = das.AccountStatusID | Account enabled/disabled |
| DWH_dbo.Dim_Range | ON f.DateRangeID = dr.DateRangeID | Decode FromDateID + ToDateID |
| DWH_dbo.Fact_Guru_Copiers | ON f.RealCID = fg.RealCID | Copy-trading activity |

### 3.4 Gotchas

- **DateRangeID is NOT a date** — it is a 12-digit bigint encoding (FromDate)(ToDate MMDD). Always extract with LEFT(...,8) for FromDate and RIGHT(...,4) for ToDate MMDD.
- **Most-current-row filter**: `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` gets the currently open row, but after year-end closure this may temporarily return 0 rows. Use `MAX(DateRangeID)` per RealCID as a safer alternative.
- **Legacy columns with 0 defaults**: DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist are all DEFAULT 0 and NOT populated by the current SP. Do not rely on them.
- **PII masking**: Email, City, Address, Zip are dynamically masked (`MASKED WITH (FUNCTION = 'default()')`). Users without `UNMASK` permission see NULL. PhoneNumber is NOT masked at DDL level but is GDPR-erased via the SP for deleted users.
- **WeekendFeePrecentage** (note: typo in column name — "Precentage" instead of "Percentage") — use as-is.
- **AccountStatusID distribution**: 1=93.2% (Active), 0=6.1% (unknown/default), 2=0.9% (Inactive). Only 3 distinct values observed.
- **Not exported directly to UC** — join via `V_Fact_SnapshotCustomer_FromDateID` in UC.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 2 | RealCID | int | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 3 | DemoCID | int | YES | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 4 | CustomerChangeTypeID | tinyint | YES | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=Insert, 2=Update). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 5 | CurentValue | int | YES | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 6 | PreviousValue | int | YES | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 7 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 8 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 9 | LanguageID | int | YES | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | VerificationLevelID | int | YES | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | DocsOK | smallint | YES | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 12 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | Bankruptcy | smallint | YES | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 16 | CommunicationLanguageID | int | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | PremiumAccount | smallint | YES | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 18 | Evangelist | smallint | YES | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 19 | GuruStatusID | smallint | YES | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 20 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 21 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | DateRangeID | bigint | YES | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | PendingClosureStatusID | tinyint | YES | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | DocumentStatusID | int | YES | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | IsEmailVerified | int | YES | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | DesignatedRegulationID | int | YES | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | EvMatchStatus | int | YES | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | RegionID | int | YES | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | PlayerStatusReasonID | int | YES | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | Email | nvarchar(50) | YES | Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | City | nvarchar(50) | YES | Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Address | nvarchar(100) | YES | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | Zip | nvarchar(50) | YES | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | PhoneNumber | varchar(30) | YES | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneVerificationDateID | varchar(8) | YES | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | WeekendFeePrecentage | int | YES | Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | DltStatusID | int | YES | DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | DltID | nvarchar(100) | YES | DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | EquiLendID | varchar(4000) | YES | EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | StocksLendingStatusID | int | YES | Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source System | Source Object | Source Column | Transform |
|---------------|--------------|---------------|---------------|-----------|
| RealCID | Customer Core (CC) | Ext_FSC_Real_Customer_Customer | CID | Passthrough |
| GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) |
| CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) |
| LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) |
| LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) |
| PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) |
| CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) |
| AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) |
| PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) |
| IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) |
| PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) |
| RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) |
| PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) |
| PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) |
| WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) |
| AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) |
| Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking |
| City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking |
| Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking |
| Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking |
| VerificationLevelID | Back Office (BO) | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) |
| RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) |
| RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) |
| GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) |
| AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) |
| AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) |
| DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) |
| SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) |
| MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) |
| DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) |
| EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) |
| RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) — end-of-day |
| IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID exists in FTD table |
| PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') |
| IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 |
| PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 |
| DltStatusID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| DltID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending |
| StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending |
| DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) |
| IsValidCustomer | ETL-computed | N/A | N/A | CASE on PlayerLevelID, LabelID, CountryID |
| IsCreditReportValidCB | ETL-computed | N/A | N/A | CASE on PlayerLevelID, AccountTypeID, LabelID, CountryID |
| UpdateDate | ETL-computed | N/A | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → Ext_FSC_BackOffice_Customer
  → Ext_FSC_BackOffice_RegulationChangeLog

FTD System → CustomerFinanceDB_Customer_FirstTimeDeposits
  → Ext_FSC_Customer_FirstTimeDeposits

Phone Verification → ContactVerification_Phone_Customer
  → Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → Ext_Dim_Customer_CustomerIdentification_DLT

Stocks Lending → ComplianceStateDB_Compliance_StocksLending
  → Ext_FSC_StocksLending

[All above via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  → SP_Fact_SnapshotCustomer(@dt) [MERGE + DateRange update]
  → DWH_dbo.Fact_SnapshotCustomer
```

| Step | Object | Description |
|------|--------|-------------|
| Source Load | SP_Fact_SnapshotCustomer_DL_To_Synapse | Loads 6 Ext_FSC staging tables from DL, then calls inner SP |
| ETL | SP_Fact_SnapshotCustomer (Author: Boris Slutski, 2018-03-11) | MERGE: close existing rows + INSERT new rows + Dim_Range update |
| Target | DWH_dbo.Fact_SnapshotCustomer | DWH customer snapshot table |
| UC Export | V_Fact_SnapshotCustomer_FromDateID (generic_id=1115) | Daily Merge to UC (two targets: PII + masked) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country name/region |
| LabelID | DWH_dbo.Dim_Label | Brand/label name |
| LanguageID | DWH_dbo.Dim_Language | Language name |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC tier |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account lifecycle status |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Real vs demo tier |
| RiskStatusID | DWH_dbo.Dim_RiskStatus | Risk status |
| RiskClassificationID | DWH_dbo.Dim_RiskClassification | Risk classification |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Popular Investor status |
| RegulationID / DesignatedRegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| AccountStatusID | DWH_dbo.Dim_AccountStatus | Account enabled/disabled |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type |
| DocumentStatusID | DWH_dbo.Dim_DocumentStatus | KYC document status |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons | Status reason code |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | eVerify match status |
| PendingClosureStatusID | DWH_dbo.Dim_PendingClosureStatus | Closure status |
| DateRangeID | DWH_dbo.Dim_Range | SCD2 date range decode |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Guru_Copiers | RealCID | SP_Fact_Guru_Copiers joins FSC for guru/copier state |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | All columns | Databricks export view (generic_id=1115) |
| DWH_dbo.V_Fact_SnapshotCustomer | All columns | Alternative view (not in generic mapping) |
| DWH_dbo.Dim_Range | DateRangeID | SP inserts new DateRangeIDs into Dim_Range |

---

## 7. Sample Queries

### 7.1 Current customer state for a single customer

```sql
SELECT
    f.RealCID,
    f.GCID,
    f.AccountStatusID,
    f.PlayerStatusID,
    f.CountryID,
    f.RegulationID,
    f.IsDepositor,
    f.IsValidCustomer,
    f.DateRangeID,
    LEFT(CAST(f.DateRangeID AS VARCHAR(12)), 8) AS FromDateYYYYMMDD
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
WHERE f.RealCID = 12345678
  AND RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231';
```

### 7.2 Count of valid retail depositors by country (current snapshot)

```sql
SELECT
    dc.CountryName,
    COUNT(DISTINCT f.RealCID) AS depositor_count
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
JOIN [DWH_dbo].[Dim_Country] dc ON f.CountryID = dc.CountryID
WHERE RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231'
  AND f.IsDepositor = 1
  AND f.IsValidCustomer = 1
GROUP BY dc.CountryName
ORDER BY depositor_count DESC;
```

### 7.3 Customers who changed regulation during 2025 (history)

```sql
SELECT
    f.RealCID,
    f.Regula

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Range` — synapse
- **Resolved as**: `DWH_dbo.Dim_Range`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`

# DWH_dbo.Dim_Range

> DWH-internal date range helper table mapping (FromDate, ToDate) pairs as composite keys, used by Snapshot analytics to efficiently join year-to-date and multi-period equity/customer snapshots.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-internal (generated by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer) |
| **Refresh** | Daily - INSERT-only accumulation by Snapshot SPs |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time.

This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted.

As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side.

---

## 2. Business Logic

### 2.1 DateRangeID Encoding

**What**: DateRangeID is a deterministic composite key encoding both FromDate and MMDD(ToDate) into a single 12-digit BigInt.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- Formula: `DateRangeID = CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`
- Example: FromDateID=20070101, ToDateID=20071231 -> DateRangeID=200701011231
- Decoding FromDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 8))`
- Decoding ToDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 4) + RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4))`
- The YEAR component of ToDateID is always the SAME as the YEAR of FromDateID (only MMDD of ToDate is stored in the last 4 digits)

**Diagram**:
```
DateRangeID (12-digit BigInt):
  [ YYYY | MM | DD | MM | DD ]
  [  From Year  | From MMDD  | To MMDD ]
   |___________|             |________|
   Chars 1-8 = FromDateID    Chars 9-12 = MMDD(ToDate)

  ToDateID = YYYY(FromDate) + MMDD(ToDate)
  -> Year-end range example:
     FromDate=2020-03-15, ToDate=2020-12-31
     DateRangeID = 202003151231
     ToDateID    = 20201231
```

### 2.2 Snapshot Range Pattern

**What**: Dim_Range is the bridge between individual customer dates and fiscal/calendar year-end periods in Snapshot reports.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- The primary use case is "from customer registration/event date to year-end": FromDate = customer's start date, ToDate = December 31 of that year
- The SPs also generate non-year-end ranges when snapshots require partial-period measurements
- The table grows daily as new snapshot dates are processed
- No deduplication needed - DateRangeID uniqueness is enforced by the NOT EXISTS check in both SPs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a composite CLUSTERED INDEX on (DateRangeID, FromDateID, ToDateID) and three Non-Clustered Indexes: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, and IX_Dim_Range_FromDateID_ToDateID. The NCI indexes are unusual for Synapse (which typically uses only CCI) and suggest heavy range-based lookups by the Snapshot SPs. Always filter on FromDateID or ToDateID directly to leverage these indexes.

Note: PRIMARY KEY (DateRangeID) is declared NOT ENFORCED - Synapse does not validate uniqueness but the ETL SPs maintain it via NOT EXISTS guards.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` is Parquet. With 1.3M rows, consider filtering on FromDateID for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the DateRangeID for a specific (from, to) pair | `SELECT DateRangeID FROM DWH_dbo.Dim_Range WHERE FromDateID = @from AND ToDateID = @to` |
| Find all ranges starting from a given date | `WHERE FromDateID = @date` (uses IX_Dim_Range_FromDateID) |
| Look up range details from a DateRangeID | `SELECT FromDateID, ToDateID FROM DWH_dbo.Dim_Range WHERE DateRangeID = @id` |
| Check how many ranges exist for a year | `WHERE FromDateID BETWEEN @year*10000+101 AND @year*10000+1231` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotEquity | DateRangeID | Resolve snapshot equity date ranges |
| DWH_dbo.Fact_SnapshotCustomer | DateRangeID | Resolve snapshot customer date ranges |
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | View-level access to snapshot equity with resolved ranges |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridging |

### 3.4 Gotchas

- **ToDate YEAR = FromDate YEAR**: The DateRangeID encoding only stores MMDD of ToDate. The year of ToDate is derived from FromDate's year. This means all ranges in this table are within-year ranges - cross-year ranges cannot be represented.
- **INSERT-only, no TRUNCATE**: Both writer SPs use NOT EXISTS guards, making the table append-only. Rows are never deleted. If a DateRangeID is erroneously created, it persists forever.
- **Primary key NOT ENFORCED**: Synapse does not verify uniqueness of DateRangeID. Trust the ETL logic, not the constraint.
- **DateRangeID is a STRING-derived number**: Always treat DateRangeID as a derived key, not a business ID. Decode using LEFT/RIGHT string operations if needed.
- **1.3M rows for a dim table**: Larger than typical dimensions. REPLICATE is appropriate given daily Snapshot SP joins from all distributions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3b - DDL structure | `(Tier 3b - DDL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateRangeID | bigint | NO | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 2 | FromDateID | int | NO | Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 3 | ToDateID | int | NO | End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateRangeID | DWH-internal (computed) | - | ETL-computed: CONCAT(YYYYMMDD(@date), MMDD(@largedate)) |
| FromDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 8) |
| ToDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 4) + RIGHT(DateRangeID, 4) |
| UpdateDate | - | - | ETL-computed: GETDATE() at insert time |

### 5.2 ETL Pipeline

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT new DateRangeIDs --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
```

| Step | Object | Description |
|------|--------|-------------|
| Writer 1 | SP_Fact_SnapshotEquity | INSERTs new (FromDate, ToDate) pairs from #outputdata temp table (Action='UPDATE') |
| Writer 2 | SP_Fact_SnapshotCustomer | INSERTs new (FromDate, ToDate) pairs from #outputdata and #UpdatedRanges temp tables |
| Guard | NOT EXISTS check | Both SPs use NOT EXISTS to prevent duplicate DateRangeIDs |
| Target | DWH_dbo.Dim_Range | Append-only. 1.3M rows as of 2026-03-10 |
| Export | Generic Pipeline (daily) | Exports to dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - DateRangeID, FromDateID, and ToDateID are DWH-internal keys with no external FK targets.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | Snapshot equity view with date range context |
| DWH_dbo.V_Fact_SnapshotEquity_FromDateID | DateRangeID / FromDateID | Snapshot equity filtered by customer registration date |
| DWH_dbo.V_Fact_SnapshotCustomer | DateRangeID | Snapshot customer view with date range context |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | DateRangeID / FromDateID | Snapshot customer filtered by registration date |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridge view |

---

## 7. Sample Queries

### 7.1 Decode a DateRangeID back to its components
```sql
SELECT
    DateRangeID,
    FromDateID,
    ToDateID,
    -- Verify encoding formula
    CONVERT(BIGINT,
        LEFT(CONVERT(VARCHAR(12), DateRangeID), 4)
        + RIGHT(CONVERT(VARCHAR(12), DateRangeID), 4)
    ) AS ToDateID_decoded
FROM [DWH_dbo].[Dim_Range]
WHERE DateRangeID = 200701011231
```

### 7.2 Find all year-end ranges (FromDate to Dec 31 of same year)
```sql
SELECT DateRangeID, FromDateID, ToDateID
FROM [DWH_dbo].[Dim_Range]
WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'
ORDER BY FromDateID DESC
```

### 7.3 Count ranges per year
```sql
SELECT
    LEFT(CAST(FromDateID AS VARCHAR(8)), 4) AS FromYear,
    COUNT(*) AS range_count
FROM [DWH_dbo].[Dim_Range]
GROUP BY LEFT(CAST(FromDateID AS VARCHAR(8)), 4)
ORDER BY FromYear DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 3 T2, 1 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Range | Type: Table | Production Source: DWH-internal (SP_Fact_SnapshotEquity + SP_Fact_SnapshotCustomer)*


### Upstream `DWH_dbo.Dim_Regulation` — synapse
- **Resolved as**: `DWH_dbo.Dim_Regulation`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md`

# DWH_dbo.Dim_Regulation

> Lookup table defining the 15 regulatory jurisdictions under which eToro operates globally, with DWH-specific grouping (ClusterRegulationID) for analytics aggregation.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Regulation |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity holding the corresponding license. This classification drives multi-jurisdiction compliance - it determines which rules apply to each customer, what instruments they can trade, what leverage limits are enforced, and how their funds are segregated. (Tier 1 - upstream wiki, Dictionary.Regulation)

RegulationID is one of the most frequently joined columns in the DWH. It is assigned to users at registration (CustomerStatic.RegulationID) and propagated through every subsequent operation - deposits, trading, copy-trading, and compliance reporting. V_Dim_Customer joins Dim_Regulation to resolve the regulation name for every customer.

**DWH vs Production differences**: The DWH strips 6 columns from production (IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID) and adds 3 DWH-specific columns (DWHRegulationID = ID alias, StatusID = hardcoded 1, ClusterRegulationID = grouping logic). Analysts needing US/non-US split or jurisdiction names should reference the upstream wiki or query production via the Bronze layer.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_Regulation. All 15 rows have StatusID=1 (Active). No sentinel row.

---

## 2. Business Logic

### 2.1 ClusterRegulationID Grouping

**What**: The ETL groups certain regulations into a single cluster (ID=1) for analytics aggregation.

**Columns Involved**: `ClusterRegulationID`, `ID`

**Rules**:
- IDs 0 (None), 1 (CySEC), 5 (BVI) -> ClusterRegulationID=1 (grouped as "CySEC/BVI/None" cluster)
- All other IDs -> ClusterRegulationID = ID (each regulation is its own cluster)

**Rationale**: BVI (5) is the non-US fallback regulation for users in jurisdictions without a specific eToro entity. CySEC (1) is the primary EU regulation. None (0) is the sentinel for unassigned users. Grouping them under cluster 1 allows DWH analytics to treat these three as a single reporting unit.

```
ClusterRegulationID mapping:
  ID=0 (None)    -> Cluster 1
  ID=1 (CySEC)   -> Cluster 1
  ID=5 (BVI)     -> Cluster 1
  All others     -> Cluster = ID (FCA=2, NFA=3, ASIC=4, eToroUS=6, ...)
```

### 2.2 DWH Column Gaps vs Production

**What**: The DWH drops 6 production columns that are needed for full compliance analysis.

**Columns Dropped**:
- `IsUSA` - US/non-US jurisdiction flag (critical for instrument availability branching)
- `JurisdictionName` - eToro legal entity name (e.g., "eToro EU", "eToro UK")
- `BankID` - FK to Dictionary.Bank (custodian banking partner)
- `RegulationLongName` - Full formal name (e.g., "Cyprus Securities Exchange Commission")
- `RegulationShortName` - Abbreviated code for compact display
- `DefaultRegulationID` - Self-reference fallback (non-US->BVI, US->eToroUS)

**Impact**: DWH analytics that need US vs non-US split must either hardcode the IDs (6, 7, 8, 12, 14 are US) or join to the Bronze layer. See Section 3.4 Gotchas.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ID. With 15 rows, REPLICATE is optimal. Join on ID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RegulationID to name in customer data | `LEFT JOIN DWH_dbo.Dim_Regulation r ON r.ID = cs.RegulationID` |
| Group analytics by regulation cluster | `GROUP BY r.ClusterRegulationID` |
| US vs non-US split (without IsUSA) | `WHERE r.ID IN (6, 7, 8, 12, 14)` for US; else non-US |
| Full customer record with regulation | Use `DWH_dbo.V_Dim_Customer` (pre-joins Dim_Regulation) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.CustomerStatic / V_Dim_Customer | ON r.ID = cs.RegulationID | Resolve regulation name per customer |
| DWH_dbo.V_Dim_Customer | Dim_Regulation already joined (INNER JOIN on RegulationID) | Use view instead of re-joining |

### 3.4 Gotchas

- **IsUSA not in DWH**: Production Dictionary.Regulation.IsUSA (US=1, non-US=0) is dropped by ETL. DWH analysts must hardcode: US regulations = IDs 6, 7, 8, 12, 14.
- **DWHRegulationID = ID**: These two columns always have the same value. DWHRegulationID is an ETL alias and appears redundant. Prefer ID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **Cluster 1 includes 3 regulations**: ClusterRegulationID=1 covers None (0), CySEC (1), and BVI (5). Aggregating by ClusterRegulationID will merge these three.
- **V_Dim_Customer uses INNER JOIN**: V_Dim_Customer has `INNER JOIN Dim_Regulation ON ID = RegulationID`. Customers with NULL RegulationID would be excluded.
- **Production has 6 more columns**: If you need IsUSA, JurisdictionName, or DefaultRegulationID, use the Bronze/staging layer or etoro.Dictionary.Regulation directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.Regulation)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | DWHRegulationID | tinyint | YES | ETL-computed alias of ID - always equals ID. `[ID] as [DWHRegulationID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field not present in production. Use ID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL (`1 as [StatusID]`). Not present in production Dictionary.Regulation. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate since table is TRUNCATE+INSERTed daily. Not present in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | ClusterRegulationID | tinyint | YES | ETL-computed grouping: `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None (0), CySEC (1), and BVI (5) into cluster 1. All other regulations map to their own ID. Used for analytics aggregation where BVI/CySEC/None are treated as a single reporting unit. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.Regulation | ID | passthrough |
| Name | etoro.Dictionary.Regulation | Name | passthrough |
| DWHRegulationID | - | - | ETL-computed: [ID] aliased as DWHRegulationID |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| ClusterRegulationID | - | - | ETL-computed: CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END |

**Lost from production** (dropped by ETL):

| Production Column | Type | Reason Dropped |
|-------------------|------|----------------|
| IsUSA | tinyint | Not carried to DWH; hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | varchar(30) | Not carried to DWH |
| BankID | int | Not carried to DWH |
| RegulationLongName | varchar(100) | Not carried to DWH |
| RegulationShortName | varchar(50) | Not carried to DWH |
| DefaultRegulationID | int | Not carried to DWH |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.Regulation.md (quality 9.2, 15 rows documented)

### 5.2 ETL Pipeline

```
etoro.Dictionary.Regulation -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Regulation -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_Regulation
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Regulation | 15 current rows (IDs 0-14) |
| Staging | DWH_staging.etoro_Dictionary_Regulation | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRegulationID, StatusID, InsertDate, UpdateDate, ClusterRegulationID. Drops 6 production columns. |
| Target | DWH_dbo.Dim_Regulation | 15 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - production FKs (BankID, DefaultRegulationID) are dropped by ETL.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | ID (INNER JOIN on RegulationID) | Pre-joined customer view resolves regulation name |
| DWH_dbo.CustomerStatic | RegulationID | Every customer assigned a regulation at registration |

---

## 7. Sample Queries

### 7.1 List all regulations with cluster groupings
```sql
SELECT
    ID,
    Name,
    DWHRegulationID,
    ClusterRegulationID,
    StatusID
FROM [DWH_dbo].[Dim_Regulation]
ORDER BY ID
```

### 7.2 US vs non-US regulation breakdown
```sql
SELECT
    CASE WHEN ID IN (6, 7, 8, 12, 14) THEN 'US' ELSE 'Non-US' END AS Region,
    ID,
    Name
FROM [DWH_dbo].[Dim_Regulation]
WHERE ID > 0
ORDER BY Region, ID
```

### 7.3 Customer count by regulation cluster
```sql
SELECT
    r.ClusterRegulationID,
    r.Name AS PrimaryRegulationName,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_Regulation] r ON r.ID = cs.RegulationID
GROUP BY r.ClusterRegulationID, r.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Regulation | Type: Table | Production Source: etoro.Dictionary.Regulation*


### Upstream `DWH_dbo.Dim_MifidCategorization` — synapse
- **Resolved as**: `DWH_dbo.Dim_MifidCategorization`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md`

# DWH_dbo.Dim_MifidCategorization

> 6-row regulatory reference table mapping MifidCategorizationID to the MiFID II customer classification tier -- identifying each customer as Retail, Professional, or Elective Professional under EU MiFID II financial regulation, which determines applicable leverage limits, margin requirements, and investor-protection rules.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.MifidCategorization (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (MifidCategorizationID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (6 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_MifidCategorization` maps the MiFID II customer classification IDs used throughout the eToro platform to human-readable tier names. MiFID II (Markets in Financial Instruments Directive II) is the EU regulatory framework governing retail and professional financial clients. Customer classification determines leverage caps, margin requirements, negative balance protection eligibility, and disclosure obligations.

The 6 rows define the complete classification space:

| ID | Name | Meaning |
|----|------|---------|
| 0 | None | Not classified / not applicable (e.g., US customers not subject to MiFID) |
| 1 | Retail | Standard retail client -- maximum investor protection, lowest leverage limits |
| 2 | Professional | Institutional or experienced investor -- lower protection, higher leverage allowed |
| 3 | Elective professional | Retail client who has applied for professional status (opted-up) |
| 4 | Retail Pending | Retail classification in progress (e.g., registration not yet complete) |
| 5 | Pending | General pending state (categorization in progress) |

ETL: part of `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_MifidCategorization`).

---

## 2. Business Logic

### 2.1 MiFID II Classification Tiers

**What**: Customer accounts are classified into one of these tiers based on their trading experience, financial knowledge, and portfolio size.

**Rules**:
- **Retail (1)**: The default classification. ESMA leverage caps apply (e.g., 30:1 for major forex). Full investor protection: negative balance protection, margin close-out rules.
- **Professional (2)**: Reserved for institutional clients and high-net-worth individuals meeting regulatory criteria. Higher leverage allowed; reduced investor protections.
- **Elective Professional (3)**: A retail client who has voluntarily opted up to professional status after meeting specific criteria (trading frequency, portfolio size, experience). eToro-specific status that lies between 1 and 2.
- **None (0)**: Not subject to MiFID II (e.g., US-regulated accounts under CFTC/NFA rules, or unclassified system accounts).
- **Retail Pending (4) / Pending (5)**: Transitional states during onboarding or reclassification.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get customer MiFID tier by name | `JOIN Dim_MifidCategorization ON MifidCategorizationID; SELECT Name` |
| Find all retail customers | `WHERE MifidCategorizationID = 1` |
| Find professional/elective-professional | `WHERE MifidCategorizationID IN (2, 3)` |
| Exclude unclassified/pending | `WHERE MifidCategorizationID IN (1, 2, 3)` |

### 3.2 Gotchas

- **MifidCategorizationID=0 is NOT a null-sentinel for EU customers**: For EU customers, 0 means "not classified" which may be a data quality issue. NULL is different from 0.
- **UpdateDate is GETDATE() at load**: Does not reflect when the classification definitions last changed in production.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — Dictionary (upstream wiki) | `(Tier 1 — Dictionary.MifidCategorization)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MifidCategorizationID | int | NO | MiFID II client classification tier: 0=None (non-EU), 1=Retail (full protection, default), 2=Professional (reduced protection), 3=Elective Professional (opted-in retail), 4=Retail Pending (under review), 5=Pending (assessment incomplete). Referenced by BackOffice.Customer.MifidCategorizationID (FK, DEFAULT 1) and History.BackOfficeCustomer. Feeds into computed column TradingRiskStatusID. (Tier 1 — Dictionary.MifidCategorization) |
| 2 | Name | varchar | YES | Human-readable classification label. Used in compliance dashboards and regulatory reports. (Tier 1 — Dictionary.MifidCategorization) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| MifidCategorizationID | etoro.Dictionary.MifidCategorization | MifidCategorizationID | passthrough |
| Name | etoro.Dictionary.MifidCategorization | Name | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.MifidCategorization  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_MifidCategorization
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_MifidCategorization  (6 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_MifidCategorization/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | MifidCategorizationID | Customer's MiFID II regulatory classification |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 Count customers by MiFID tier

```sql
SELECT
    mc.MifidCategorizationID,
    mc.Name AS MifidTier,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_MifidCategorization] mc ON f.MifidCategorizationID = mc.MifidCategorizationID
GROUP BY mc.MifidCategorizationID, mc.Name
ORDER BY mc.MifidCategorizationID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 3/3, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_MifidCategorization | Type: Table | Production Source: etoro.Dictionary.MifidCategorization*


### Upstream `DWH_dbo.Dim_PlayerStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md`

# DWH_dbo.Dim_PlayerStatus

> Permission matrix table defining 16 account restriction states (Normal through Block Deposit & Trading) that control which platform capabilities -- trading, deposits, withdrawals, login, social, and copy-trading -- are enabled for each customer.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerStatus defines 16 distinct account restriction states in the eToro platform, each encoding a granular permission matrix controlling what a user can and cannot do. Unlike Dim_AccountStatus (binary open/closed), PlayerStatus provides fine-grained control over trading, deposits, withdrawals, social features, and copy-trading. This enables compliance and fraud teams to surgically restrict specific capabilities without full account lockout.

The data originates from `etoro.Dictionary.PlayerStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override) to the data lake, and `SP_Dictionaries_DL_To_Synapse` loads it via TRUNCATE + INSERT, plus a separate sentinel INSERT for ID=0 (N/A placeholder). The ETL adds 4 computed columns (DWHPlayerStatusID, StatusID, UpdateDate, InsertDate) and **drops 2 production columns** (`CanCopy` and `GetsInterest`).

PlayerStatusID is stored in Dim_Customer and is read by virtually every user-facing operation -- login, trading, funding, social posting, and copy-trading -- to enforce permission checks. The permission flags are queried directly from this table rather than hardcoded in business logic.

---

## 2. Business Logic

### 2.1 Permission Matrix System

**What**: Each player status defines a complete set of boolean permissions that gate platform features.

**Columns Involved**: `IsBlocked`, `CanEditPosition`, `CanOpenPosition`, `CanClosePosition`, `CanDeposit`, `CanRequestWithdraw`, `CanLogin`, `CanChatAndPost`, `CanBeCopied`

**Rules**:
- **Full Block** (IsBlocked=1): IDs 2, 4, 6, 7, 8, 14 -- user cannot log in. All capabilities disabled.
- **Partial Restriction**: IDs 3, 9, 10, 11, 12, 13, 15 -- user can access some features but not others.
- **Full Access**: IDs 1, 5 -- all capabilities enabled. ID=5 (Warning) is identical to Normal in permissions but signals compliance flagging.
- **Close-Only / Wind-Down**: IDs 9 (Trade & MIMO Blocked) and 15 (Block Deposit & Trading) -- user can close existing positions and log in, but cannot open new positions or deposit.

**Diagram**:
```
Access Level Summary:
  ID=1  Normal                -- All capabilities ON
  ID=5  Warning               -- All ON + compliance flag
  ID=3  Chat Blocked          -- All ON except CanChatAndPost
  ID=10 Deposit Blocked       -- All ON except CanDeposit
  ID=12 Copy Block            -- All ON except CanBeCopied (note: DWH lacks CanCopy col)
  ID=9  Trade & MIMO Blocked  -- Close+Login only; no open/deposit/withdraw
  ID=13 Pending Verification  -- Close+Login only
  ID=15 Block Deposit&Trading -- Close+Login+Chat+Copy; no open/deposit
  ID=11 Social Index          -- All ON except CanDeposit + CanRequestWithdraw
  ID=2  Blocked               -- ALL OFF (full lockout, cannot login)
  ID=4  Blocked Upon Request  -- ALL OFF (self-requested lockout)
  ID=6  Under Investigation   -- ALL OFF (compliance hold)
  ID=7  Scalpers Block        -- ALL OFF (trading abuse)
  ID=8  PayPal Investigation  -- ALL OFF (payment fraud)
  ID=14 Failed Verification   -- ALL OFF (KYC failure)
  ID=0  N/A                   -- All OFF (DWH ETL placeholder)
```

### 2.2 Status Transition Patterns

**What**: Common pathways between player statuses driven by compliance, fraud, and user lifecycle events.

**Columns Involved**: `PlayerStatusID`

**Rules**:
- New accounts: 1 (Normal) or 13 (Pending Verification) depending on regulation
- Compliance investigation: 1 -> 6 (Under Investigation) -> 1 (cleared) or 2 (blocked)
- KYC timeout: 13 (Pending) -> 14 (Failed Verification) if docs not submitted
- Self-service closure: 1 -> 4 (Blocked Upon Request)
- Scalping detection: 1 -> 7 (Scalpers Block)
- PayPal fraud: 1 -> 8 (PayPal Investigation)
- Wind-down: 1 -> 9 or 15 (close-only mode for accounts under investigation)

### 2.3 Schema Drift -- Dropped Production Columns

**What**: Two production permission columns are not loaded into DWH.

**Dropped**:
- `CanCopy` (bit, default 1) -- whether user can copy other traders. Status 12 (Copy Block) sets this to 0.
- `GetsInterest` (bit) -- whether overnight fees/credits apply to user's positions. NOT available in DWH.

**Impact**: Analysts cannot determine from DWH whether a given status blocks copy-trading (CanCopy) or overnight interest (GetsInterest). For these, query production or the upstream wiki.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP means no CCI/sort -- for 16 rows this is irrelevant to performance, but row order is arbitrary without ORDER BY. Always join on `PlayerStatusID`. With REPLICATE, JOINs are zero-cost (all nodes have a full copy).

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed. Full scan of 16 rows is trivial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve a PlayerStatusID to a name | JOIN Dim_PlayerStatus ON PlayerStatusID |
| Find customers who cannot trade | JOIN Dim_Customer, filter CanOpenPosition = 0 or IsBlocked = 1 |
| Count customers by restriction category | GROUP BY IsBlocked + CanOpenPosition combination |
| Find wind-down accounts (close-only) | Filter CanClosePosition = 1 AND CanOpenPosition = 0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusID = dps.PlayerStatusID | Resolve status name and permission flags per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusID = dps.PlayerStatusID | View-level status resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusID = dps.PlayerStatusID | Customer status in daily snapshots |

### 3.4 Gotchas

- **HEAP index**: Like Dim_PlayerLevel, this table uses HEAP. No guaranteed row order without ORDER BY.
- **ID=0 sentinel**: All permission bits are 0 for ID=0 (N/A). LEFT JOIN if the fact table may have NULL or missing PlayerStatusID.
- **CanCopy and GetsInterest are MISSING**: These two production columns are not in DWH. Analysts needing copy-block or interest-eligibility logic must use production data.
- **Status 5 (Warning) = same permissions as Status 1 (Normal)**: All permission flags are identical. The only difference is the compliance signal encoded in the ID itself.
- **Status names have trailing spaces**: Live data shows "Blocked" with trailing whitespace for some status names (e.g., Name column for ID=2). Apply RTRIM() in comparisons if matching by name string.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusID | int | NO | Primary key identifying the restriction state. 0=N/A (sentinel), 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. FK from Dim_Customer. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 2 | Name | varchar(50) | NO | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 3 | IsBlocked | bit | NO | Master block flag. 1 for statuses 2, 4, 6, 7, 8, 14 -- ALL capabilities disabled including login. 0 for statuses where individual CanX flags control granular permissions. Checked by login and order entry procedures. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 4 | CanEditPosition | bit | YES | Whether the user can modify existing position parameters (SL/TP/trailing stop). False when IsBlocked=1 and for close-only statuses (9, 13, 15). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 5 | CanOpenPosition | bit | YES | Whether the user can open new trading positions. False when IsBlocked=1 and for close-only statuses (9, 13, 15). True for all active/warning/partial statuses. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 6 | CanClosePosition | bit | YES | Whether the user can close existing positions. True even for most restricted statuses -- regulators require users to be able to exit. Only IsBlocked=1 statuses set this to False. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 7 | CanDeposit | bit | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only statuses (9, 15), status 10 (Deposit Blocked), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 8 | CanRequestWithdraw | bit | YES | Whether the user can request withdrawals. False for full-block statuses (IsBlocked=1), close-only statuses (9, 13, 15), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 9 | CanLogin | bit | YES | Whether the user can authenticate and access the platform. False when IsBlocked=1. True for all partial-restriction statuses -- wind-down users can view their portfolio. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 10 | CanChatAndPost | bit | YES | Whether the user can post to the social feed or chat. False when IsBlocked=1 and for status 3 (Chat Blocked). True for all other statuses including close-only. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 11 | CanBeCopied | bit | YES | Whether other users can start copying this user's trades. False when IsBlocked=1. Used to hide restricted users from the CopyTrader marketplace. Note: CanCopy (whether THIS user can copy others) is NOT loaded into DWH. (Tier 1 - upstream wiki, Dictionary.PlayerStatus) |
| 12 | DWHPlayerStatusID | int | YES | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerStatusID] AS [DWHPlayerStatusID]. 0 for the ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 13 | StatusID | int | YES | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. Standard DWH ETL convention for SP_Dictionaries_DL_To_Synapse-loaded tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 14 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 15 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusID | Dictionary.PlayerStatus | PlayerStatusID | passthrough |
| Name | Dictionary.PlayerStatus | Name | passthrough |
| IsBlocked | Dictionary.PlayerStatus | IsBlocked | passthrough |
| CanEditPosition | Dictionary.PlayerStatus | CanEditPosition | passthrough |
| CanOpenPosition | Dictionary.PlayerStatus | CanOpenPosition | passthrough |
| CanClosePosition | Dictionary.PlayerStatus | CanClosePosition | passthrough |
| CanDeposit | Dictionary.PlayerStatus | CanDeposit | passthrough |
| CanRequestWithdraw | Dictionary.PlayerStatus | CanRequestWithdraw | passthrough |
| CanLogin | Dictionary.PlayerStatus | CanLogin | passthrough |
| CanChatAndPost | Dictionary.PlayerStatus | CanChatAndPost | passthrough |
| CanBeCopied | Dictionary.PlayerStatus | CanBeCopied | passthrough |
| DWHPlayerStatusID | -- | -- | ETL-computed: = PlayerStatusID (redundant surrogate) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |
| InsertDate | -- | -- | ETL-computed: GETDATE() or @ddate for ID=0 |

**Dropped from production**: CanCopy (bit), GetsInterest (bit).

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatus.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatus
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/PlayerStatus/
  -> DWH_staging.etoro_Dictionary_PlayerStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatus | 15 rows, 13 columns (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/PlayerStatus/ | Daily full export via Generic Pipeline |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatus | 11 passthrough cols loaded |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; adds 4 computed cols; drops CanCopy, GetsInterest |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1568) | INSERT VALUES for ID=0 N/A sentinel with all-false permissions |
| Target | DWH_dbo.Dim_PlayerStatus | 16 rows (0-15), 15 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusID | Customer's current account restriction state |
| DWH_dbo.V_Dim_Customer | PlayerStatusID | View-level customer status |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Daily snapshot of customer restriction state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusID | Year-end snapshot status |

---

## 7. Sample Queries

### 7.1 List all statuses with key permission flags

```sql
SELECT PlayerStatusID,
       Name,
       IsBlocked,
       CanOpenPosition,
       CanClosePosition,
       CanDeposit,
       CanLogin
FROM   [DWH_dbo].[Dim_PlayerStatus]
WHERE  PlayerStatusID > 0
ORDER BY PlayerStatusID;
```

### 7.2 Count customers by restriction category

```sql
SELECT  CASE
            WHEN dps.IsBlocked = 1          THEN 'Full Block'
            WHEN dps.CanOpenPosition = 0    THEN 'Close-Only / Restricted'
            WHEN dps.CanDeposit = 0         THEN 'Deposit Blocked'
            ELSE 'Active'
        END               AS RestrictionCategory,
        dps.Name          AS PlayerStatus,
        COUNT(*)          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.PlayerStatusID > 0
GROUP BY dps.IsBlocked, dps.CanOpenPosition, dps.CanDeposit, dps.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find customers in wind-down state (can close, cannot open)

```sql
SELECT  dc.CID,
        dps.Name   AS PlayerStatus
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatus] dps
        ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.CanClosePosition = 1
        AND dps.CanOpenPosition = 0
        AND dps.PlayerStatusID > 0;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 11 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatus | Type: Table | Production Source: etoro.Dictionary.PlayerStatus*


### Upstream `DWH_dbo.Dim_Country` — synapse
- **Resolved as**: `DWH_dbo.Dim_Country`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md`

# DWH_dbo.Dim_Country

> Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes. One of the most-referenced dimension tables in the DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Country (primary) + etoro.Dictionary.MarketingRegion (region label) + Ext_Dim_Country (EU flags) + Ext_Dim_Country_Region_Desk (desk/CFKey) + ComplianceStateDB.Compliance.RegulationCountry (regulation) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, full TRUNCATE+INSERT + 3 UPDATE passes) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (non-clustered PK on CountryID NOT ENFORCED) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Country` is one of the most heavily-referenced dimension tables in the DWH. It defines every country and territory the eToro platform recognizes (251 rows: 250 active countries + 1 "Not available" placeholder at CountryID=0). Each row provides geographic classification, regulatory risk attributes, marketing segmentation, and compliance data for users registered from that country.

When a customer registers, their CountryID determines: which regulatory entity governs them (via RegulationID), what AML/KYC scrutiny level applies (IsHighRiskCountry, RiskGroupID), what marketing desk handles them (Desk), and whether they can receive RAF bonuses (IsEligibleForRAFBonusCountry).

The ETL is multi-step: TRUNCATE+INSERT from etoro.Dictionary.Country (primary, joined to etoro.Dictionary.MarketingRegion for the Region label), then three UPDATE passes that patch in EU classification from Ext_Dim_Country, Desk/CFKey from Ext_Dim_Country_Region_Desk, and RegulationID from ComplianceStateDB.Compliance.RegulationCountry. Several columns present in the upstream Dictionary.Country source are dropped in DWH (IsSettlementRestricted, DefaultCurrencyID, LanguageID, IsActive, PhonePrefix, IsoCode).

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 High-Risk Country Flag (Computed)

**What**: IsHighRiskCountry is derived from RiskGroupID in the ETL, not passed through from source. AML-flagged countries trigger enhanced due diligence.

**Columns Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `CASE WHEN RiskGroupID IN (0, 4) THEN 0 ELSE 1 END` -> IsHighRiskCountry
- RiskGroupID=0 (None): 70 countries -> not high risk
- RiskGroupID=4 (Verified before deposit): 2 countries -> not high risk
- RiskGroupID=1 (High risk country): 100 countries -> high risk
- RiskGroupID=2 (High risk for new clients): 71 countries -> high risk
- RiskGroupID=3 (High risk FATF country): 8 countries -> high risk
- High-risk countries trigger enhanced document verification, manual review of first deposit, and reduced transaction monitoring thresholds

**Diagram**:
```
RiskGroupID -> IsHighRiskCountry
0 (None)                  -> 0  (70 countries)
4 (Verified bfr deposit)  -> 0  (2 countries)
1 (High risk)             -> 1  (100 countries)
2 (High risk new clients) -> 1  (71 countries)
3 (High risk FATF)        -> 1  (8 countries)
```

### 2.2 EU vs. European Country Classification

**What**: Two separate flags distinguish full EU membership from broader European geography.

**Columns Involved**: `EU`, `IsEuropeanCountry`

**Rules**:
- EU=1: 27 countries with full EU membership (legal/treaty member states)
- IsEuropeanCountry=1: 66 countries total (27 EU members + 39 other European countries)
- Source: Ext_Dim_Country (manual extension table), not from etoro.Dictionary.Country
- EU=1 always implies IsEuropeanCountry=1. IsEuropeanCountry=1 does NOT imply EU=1.

### 2.3 Region vs. MarketingRegion

**What**: DWH exposes two separate geographic segmentations. `Region` is marketing-driven; the source geographic `RegionID` is dropped.

**Columns Involved**: `Region`, `MarketingRegionID`, `MarketingRegionManualName`, `Desk`

**Rules**:
- `Region` is loaded from etoro.Dictionary.MarketingRegion.Name (y.Name AS Region in SP). It is the marketing region label.
- `MarketingRegionManualName` is a manual override from Ext_Dim_Country - may differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE).
- `Desk` is a sales/support desk assignment from Ext_Dim_Country_Region_Desk, joined via MarketingRegionID.
- The upstream Dictionary.Country source has a geographic `RegionID` pointing to Dictionary.Region - this is NOT loaded to DWH.
- 22 distinct Region values in DWH (South & Central America=40, Africa=38, ROW=38, French=23, etc.)

### 2.4 Dropped Source Columns (Compliance-Critical)

**What**: Several compliance and localization columns present in the upstream source are NOT loaded to DWH.

**Dropped from etoro.Dictionary.Country**:
- `IsSettlementRestricted`: 21 countries restricted to CFD-only trading (cannot hold REAL assets). Includes United States (SEC/FINRA). CRITICAL for compliance analysts.
- `DefaultCurrencyID`: Trading account default currency (USD/EUR/GBP/AUD/CAD/PLN).
- `LanguageID`: UI language default.
- `IsActive`: Whether country is active on platform.
- `PhonePrefix`: International dialing code.
- `IsoCode`: ISO 3166-1 numeric code.
- `RegionID`: Geographic region FK (DWH replaces with text Region label from MarketingRegion).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE (correct for a 251-row dimension - broadcast to all nodes avoids data movement on JOINs). HEAP means no sorted index. The non-clustered PK on CountryID is NOT ENFORCED - duplicates are theoretically possible but prevented by ETL TRUNCATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (251 rows). Z-ORDER on CountryID optional for join optimization.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode country for a customer | `JOIN DWH_dbo.Dim_Country d ON f.CountryID = d.CountryID` |
| Filter high-risk countries | `WHERE d.IsHighRiskCountry = 1` |
| Filter EU customers | `WHERE d.EU = 1` |
| Group by marketing region | `GROUP BY d.Region` |
| Find regulation for a country | `SELECT RegulationID FROM Dim_Country WHERE CountryID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON c.CountryID = d.CountryID | Decode customer country attributes |
| DWH_dbo.Fact_BillingDeposit | ON f.CountryID = d.CountryID | Country-level deposit analytics |
| DWH_dbo.Dim_CountryBin | ON c.CountryID = d.CountryID | BIN-to-country card mapping |
| DWH_dbo.V_Dim_Customer | ON v.CountryID = d.CountryID | Customer view with country decode |

### 3.4 Gotchas

- CountryID=0 ("Not available") is a real row - use `WHERE CountryID > 0` to exclude the placeholder in population-level queries.
- `IsHighRiskCountry` is RECOMPUTED from `RiskGroupID` by the ETL (not passthrough from source). If source IsHighRiskCountry changes but RiskGroupID stays the same, DWH will not reflect the change.
- `IsSettlementRestricted` is NOT in DWH. This critical compliance flag must be looked up in the source etoro.Dictionary.Country if needed.
- `Region` reflects `MarketingRegion.Name`, not the geographic `Dictionary.Region`. The two segmentations differ (e.g., Albania: geographic region=Europe, marketing Region=ROE).
- `DWHCountryID` always equals `CountryID` (redundant copy from SP: `x.CountryID AS DWHCountryID`). Never use both in GROUP BY.
- `StatusID` is hardcoded to 1 for all rows (including CountryID=0). No meaningful variation.
- `InsertDate` and `UpdateDate` are both set to GETDATE() on each daily reload - they reflect ETL run time, not original insert or data change time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki) |
| 2 | Abbreviation | char(2) | NO | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | LongAbbreviation | char(3) | NO | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). Unique per row. Used in some international reporting standards and Compliance.GetCountryLongAbbreviation (WorldCheck KYC/AML integration). (Tier 1 - Dictionary.Country upstream wiki) |
| 4 | Name | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 5 | IsHighRiskCountry | tinyint | YES | AML/compliance risk flag. 0=standard risk, 1=high risk. RECOMPUTED by SP from RiskGroupID: `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. 179 high-risk countries. Triggers enhanced due diligence and stricter transaction monitoring. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows by SP. Intended to indicate active status. In practice carries no variation. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | DWHCountryID | int | NO | Redundant copy of CountryID (set to `x.CountryID AS DWHCountryID` in SP). Always equals CountryID. Retained for legacy compatibility. Do not use both CountryID and DWHCountryID in the same GROUP BY. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily full reload. Reflects ETL run time, not when country data actually changed. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate) on each daily full reload. Not a true insert timestamp - both dates are refreshed on every reload due to TRUNCATE+INSERT. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 11 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join - NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. (Tier 3 - Ext_Dim_Country live data) |
| 12 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 - Ext_Dim_Country_Region_Desk via SP) |
| 13 | RegulationID | int | YES | Regulatory entity ID governing users from this country. Loaded from ComplianceStateDB.Compliance.RegulationCountry via Ext_Dim_Country_Regulation staging. Left join - NULL if country not in compliance mapping. References the regulatory framework (e.g., CySEC, FCA, ASIC). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse via ComplianceStateDB) |
| 14 | CFKey | int | YES | Clearing/settlement framework key for this country's marketing region. Loaded from Ext_Dim_Country_Region_Desk.CFKey via MarketingRegionID join. Exact business meaning unclear - likely maps to a clearing firm or settlement category. (Tier 3 - Ext_Dim_Country_Region_Desk live data) |
| 15 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 - Dictionary.Country upstream wiki) |
| 16 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. (Tier 1 - Dictionary.Country upstream wiki) |
| 17 | IsEligibleForRAFBonusCountry | int | YES | Whether users from this country can participate in the Refer-A-Friend bonus program. Source: CAST(etoro.Dictionary.Country.IsEligibleForRAFBonusCountry AS int) - type cast from bit to int. 1=eligible (most countries), 0=ineligible (regulatory/fraud restrictions). (Tier 1 - Dictionary.Country upstream wiki) |
| 18 | IsEuropeanCountry | int | YES | Whether this country is geographically European (broader than EU membership). 1=European (66 countries total: 27 EU + 39 others), 0=non-European. Source: Ext_Dim_Country manual extension table. Always >= EU flag. (Tier 3 - Ext_Dim_Country live data) |
| 19 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Ext_Dim_Country live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough (nvarchar(max) -> char(2)) |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough (nvarchar(max) -> char(3)) |
| Name | etoro.Dictionary.Country | Name | passthrough |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed: CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END |
| Region | etoro.Dictionary.MarketingRegion | Name | rename (y.Name AS Region via JOIN on MarketingRegionID) |
| StatusID | - | - | ETL-computed (hardcoded constant 1) |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy (x.CountryID AS DWHCountryID, always = CountryID) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| InsertDate | - | - | ETL-computed (GETDATE()) |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE pass (LEFT JOIN on CountryID) |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE pass via Ext_Dim_Country_Regulation staging |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type cast (CAST(bit AS int)) |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE pass (LEFT JOIN on CountryID) |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE pass (LEFT JOIN on CountryID) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10).

### 5.2 ETL Pipeline

```
etoro.Dictionary.Country (x)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial population: 19 cols partially loaded)
  -> UPDATE from DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> TRUNCATE+INSERT DWH_dbo.Ext_Dim_Country_Regulation from DWH_staging.ComplianceStateDB_Compliance_RegulationCountry
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (fully loaded)
```

Note: The same SP also loads Dim_CountryIPAnonymous in the same transaction.

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Country | Master country reference (251 rows). 16-column source, DWH drops 8 columns. |
| Source | etoro.Dictionary.MarketingRegion | Marketing region labels. Provides Region text and MarketingRegionID. |
| Staging | DWH_staging.etoro_Dictionary_Country | Raw staging: 16 cols, HEAP ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT. Computes IsHighRiskCountry from RiskGroupID. Joins MarketingRegion. Hardcodes StatusID=1. Sets GETDATE() for UpdateDate/InsertDate. |
| Patch 1 | DWH_dbo.Ext_Dim_Country | Manual extension table: EU=1/0, IsEuropeanCountry=1/0, MarketingRegionManualName. LEFT JOIN on CountryID. |
| Patch 2 | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk and CFKey lookup by MarketingRegionID. LEFT JOIN on MarketingRegionID=RegionID. |
| Patch 3 | DWH_dbo.Ext_Dim_Country_Regulation | Regulation staging loaded from ComplianceStateDB.Compliance.RegulationCountry. Then LEFT JOIN on CountryID. |
| Target | DWH_dbo.Dim_Country | Final DWH dimension (251 rows). |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MarketingRegionID | etoro.Dictionary.MarketingRegion | Marketing region segment. Implicit FK (not enforced in Synapse). |
| RiskGroupID | etoro.Dictionary.CountryRiskGroup | Country risk classification. Implicit FK (not enforced in Synapse). |
| RegulationID | ComplianceStateDB (Regulation) | Regulatory entity governing country users. Sourced from ComplianceStateDB. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | CountryID | Customer view JOINs to Dim_Country for country attributes. |
| DWH_dbo.Dim_CountryIP | CountryID | IP-to-country lookup table references Dim_Country via Abbreviation join. |
| DWH_dbo.Dim_CountryIPAnonymous | CountryID | Anonymous proxy IP table; CountryID set via Abbreviation-to-CountryID lookup against Dim_Country. |
| DWH_dbo.SP_Fact_BillingDeposit | CountryID | Billing deposit facts reference Dim_Country for country-level analytics. |
| BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table | CountryID | LTV modeling references country dimension. |
| BI_DB_dbo.SP_Group_LTV_Table | CountryID | Group LTV analytics references country dimension. |

---

## 7. Sample Queries

### 7.1 Decode customer country
```sql
SELECT c.CustomerID, d.Name AS Country, d.Region, d.IsHighRiskCountry
FROM [DWH_dbo].[Dim_Customer] c
JOIN [DWH_dbo].[Dim_Country] d ON c.CountryID = d.CountryID
WHERE d.IsHighRiskCountry = 1;
```

### 7.2 Countries by EU membership
```sql
SELECT CountryID, Name, Abbreviation, EU, IsEuropeanCountry, Region
FROM [DWH_dbo].[Dim_Country]
WHERE EU = 1
ORDER BY Name;
```

### 7.3 Risk group distribution
```sql
SELECT RiskGroupID, IsHighRiskCountry, COUNT(*) AS CountryCount
FROM [DWH_dbo].[Dim_Country]
WHERE CountryID > 0
GROUP BY RiskGroupID, IsHighRiskCountry
ORDER BY RiskGroupID;
```

### 7.4 RAF-ineligible countries by region
```sql
SELECT Region, Name, Abbreviation
FROM [DWH_dbo].[Dim_Country]
WHERE IsEligibleForRAFBonusCountry = 0 AND CountryID > 0
ORDER BY Region, Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, 16 VERIFIED columns).

---

*Generated: 2026-03-19 | Quality: 8.8/10 (4 stars) | Phases: 9/14 (full pipeline, no Atlassian)*
*Tiers: 6 T1, 8 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Country | Type: Table | Production Source: etoro.Dictionary.Country + etoro.Dictionary.MarketingRegion + Ext_Dim_Country + ComplianceStateDB*


### Upstream `DWH_dbo.V_Liabilities` — synapse
- **Resolved as**: `DWH_dbo.V_Liabilities`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md`

# DWH_dbo.V_Liabilities

> Daily customer liabilities view combining equity snapshots (`Fact_SnapshotEquity`) with unrealized PnL (`Fact_CustomerUnrealized_PnL`) to compute **ActualNWA** (credit-capped net worth), **Liabilities** (customer obligations to the platform), **WA_Liabilities** (credit-covered portion), and asset-class breakdowns — the central view for regulatory balance reporting, dormant fee calculations, AML monitoring, and client balance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Source Tables** | Fact_SnapshotEquity (a), V_M2M_Date_DateRange (b), Fact_CustomerUnrealized_PnL (c), Fact_Guru_Copiers (gc — dead join) |
| **Key Identifier** | CID + DateID |
| **Output Columns** | 75 (T1: 63, T2: 12) |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` |
| **Data Scope** | All dates **before today** (`DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)`) |
| **Generated** | 2026-03-22 |

---

## 1. Business Meaning

`V_Liabilities` is the platform's primary view for computing what eToro owes each customer (liabilities) and how much of the customer's balance is "real" vs promotional credit.

**Core formula** — let `NetEquity = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`:
- **ActualNWA** (Non-Withdrawable Amount): The portion of NetEquity covered by BonusCredit. Clamped to `[0, BonusCredit]`. If the customer's NetEquity exceeds their BonusCredit, ActualNWA = BonusCredit. If NetEquity goes negative, ActualNWA = 0.
- **Liabilities**: InProcessCashouts + the portion of NetEquity **above** BonusCredit. This is what eToro owes the customer — real money, not promotional credit.
- **Balance**: Liabilities + ActualNWA = RealizedEquity + PositionPnL (Confluence: "Summary of V-Liabilities")

**Business context** (from Confluence):
- "If clients lose money, their Actual NWA will reflect only what's left. A client has $1000, loses $200 → Actual NWA = $800. When they profit back to $2000 → Actual NWA = $1000 and Liabilities show $1000 bonus credit."
- The view excludes today's date because end-of-day snapshots (FSE + FCUPNL) must both be loaded before the view is meaningful.

**Key consumers**: SP_DDR_Fact_AUM, SP_Client_Balance_New, SP_Client_Balance_Breakdown, SP_Q_AML_EDD_US_Report, SP_Q_AML_FSA_Report, SP_AML_PI_Abuse, SP_AML_BI_Alerts_New_Singapore, SP_CIDFirstDates, SP_CID_DailyPanel_FullData, SP_CID_MonthlyPanel_FullData, SP_MarketingCloudDaily, SP_Copyfunds_SignificantAllocation, SP_Fact_RegulationTransfer, SP_TIN_Gap, SP_BI_DB_W8_Users_Status, SP_BI_DB_CO_Cluster_Daily, SP_IR_Dashboard_Monitor_Checks, SP_OPS_MultipleAccounts, SP_Q_QSR_New.

---

## 2. Business Logic

### 2.1 Join Structure

```
Fact_SnapshotEquity a                   -- daily equity snapshot per CID
  JOIN V_M2M_Date_DateRange b           -- expands DateRangeID → one row per calendar day (DateKey)
    ON a.DateRangeID = b.DateRangeID
  LEFT JOIN Fact_CustomerUnrealized_PnL c  -- daily PnL snapshot per CID
    ON a.CID = c.CID AND b.DateKey = c.DateModified
  LEFT JOIN Fact_Guru_Copiers gc        -- DEAD JOIN: no columns selected (Boris Slutski, 2021-01-11)
    ON a.CID = gc.CID AND b.DateKey = gc.DateID
WHERE b.DateKey < today
```

### 2.2 Computed Column Formulas

All computed columns use a common intermediate value:

```
NetEquity = ISNULL(TotalPositionsAmount, 0) + ISNULL(TotalCash, 0)
          + ISNULL(TotalStockOrders, 0) + ISNULL(PositionPnL, 0)
```

Note: `TotalStockOrders` is a legacy column hardcoded to 0 since 2019 (see Fact_SnapshotEquity wiki). Its presence in the formula is a historical artifact — it does not affect computation.

| Column | Formula |
|--------|---------|
| **ActualNWA** | `CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END` |
| **Liabilities** | `InProcessCashouts + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END` |
| **WA_Liabilities** | `MIN(Liabilities_excl_cashouts, Credit)` — the portion of liabilities coverable by credit |
| **Liabilities_InUsedMargin** | `MAX(Liabilities_excl_cashouts - Credit, 0)` — liabilities exceeding available credit |
| **LiabilitiesStockReal** | `ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0)` |
| **LiabilitiesCryptoReal** | `ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)` |
| **LiabilitiesCrypto_TRS** | `ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0)` |
| **LiabilitiesFuturesReal** | `ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0)` |
| **TotalStockManualPosition** | `TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount` |
| **ManualStockPositionPnL** | `StocksPositionPnL - MirrorStocksPositionPnL` |
| **TotalCryptoManualPosition** | `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount` |
| **TotalCryptoManualPosition_TRS** | `TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS` |

---

## 3. Source Objects

| Object | Schema | Alias | Role |
|--------|--------|-------|------|
| Fact_SnapshotEquity | DWH_dbo | a | Equity balances, cash, positions, AUM, credit |
| V_M2M_Date_DateRange | DWH_dbo | b | Expands DateRangeID to per-day rows (DateKey, FullDate) |
| Fact_CustomerUnrealized_PnL | DWH_dbo | c | Unrealized PnL, NOP, notional, commissions, risk |
| Fact_Guru_Copiers | DWH_dbo | gc | **Dead join** — no columns selected. LEFT JOIN preserved from 2021, can be removed. |

---

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | Fact_SnapshotEquity.CID | Direct | T1 |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | Direct (alias DateKey → DateID) | T1 |
| 3 | FullDate | V_M2M_Date_DateRange.FullDate | Direct | T1 |
| 4 | RealizedEquity | Fact_SnapshotEquity.RealizedEquity | Direct | T1 |
| 5 | TotalPositionsAmount | Fact_SnapshotEquity.TotalPositionsAmount | Direct | T1 |
| 6 | TotalCash | Fact_SnapshotEquity.TotalCash | Direct | T1 |
| 7 | InProcessCashouts | Fact_SnapshotEquity.InProcessCashouts | Direct | T1 |
| 8 | TotalMirrorPositionsAmount | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Direct | T1 |
| 9 | TotalMirrorCash | Fact_SnapshotEquity.TotalMirrorCash | Direct | T1 |
| 10 | TotalStockOrders | Fact_SnapshotEquity.TotalStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 11 | TotalMirrorStockOrders | Fact_SnapshotEquity.TotalMirrorStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 12 | Credit | Fact_SnapshotEquity.Credit | Direct | T1 |
| 13 | AUM | Fact_SnapshotEquity.AUM | Direct | T1 |
| 14 | BonusCredit | Fact_SnapshotEquity.BonusCredit | Direct | T1 |
| 15 | TotalStockPositionAmount | Fact_SnapshotEquity.TotalStockPositionAmount | Direct | T1 |
| 16 | TotalMirrorStockPositionAmount | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Direct | T1 |
| 17 | PositionPnL | Fact_CustomerUnrealized_PnL.PositionPnL | Direct | T1 |
| 18 | CopyPositionPnL | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Direct | T1 |
| 19 | StandardDeviation | Fact_CustomerUnrealized_PnL.StandardDeviation | Direct | T1 |
| 20 | CommissionOnOpen | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Direct | T1 |
| 21 | ActualNWA | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0) | T2 |
| 22 | Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END | T2 |
| 23 | WA_Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MIN(Liabilities_excl_cashouts, Credit) — credit-capped liabilities | T2 |
| 24 | Liabilities_InUsedMargin | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MAX(Liabilities_excl_cashouts - Credit, 0) — liabilities beyond credit | T2 |
| 25 | StocksPositionPnL | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Direct | T1 |
| 26 | TotalStockManualPosition | Fact_SnapshotEquity | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | T2 |
| 27 | ManualStockPositionPnL | Fact_CustomerUnrealized_PnL | StocksPositionPnL - MirrorStocksPositionPnL | T2 |
| 28 | MirrorStocksPositionPnL | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Direct | T1 |
| 29 | CryptoPositionPnL | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Direct | T1 |
| 30 | ManualCryptoPositionPnL | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Direct | T1 |
| 31 | CopyCryptoPositionPnL | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Direct | T1 |
| 32 | TotalCryptoPositionAmount | Fact_SnapshotEquity.TotalCryptoPositionAmount | Direct | T1 |
| 33 | TotalCryptoManualPosition | Fact_SnapshotEquity | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount | T2 |
| 34 | CopyFundAUM | Fact_SnapshotEquity.CopyFundAUM | Direct | T1 |
| 35 | CopyFundPnL | Fact_CustomerUnrealized_PnL.CopyFundPnL | Direct | T1 |
| 36 | NOP | Fact_CustomerUnrealized_PnL.NOP | Direct | T1 |
| 37 | Notional | Fact_CustomerUnrealized_PnL.Notional | Direct | T1 |
| 38 | NOP_Crypto | Fact_CustomerUnrealized_PnL.NOP_Crypto | Direct | T1 |
| 39 | Notional_Crypto | Fact_CustomerUnrealized_PnL.Notional_Crypto | Direct | T1 |
| 40 | NOP_CFD | Fact_CustomerUnrealized_PnL.NOP_CFD | Direct | T1 |
| 41 | Notional_CFD | Fact_CustomerUnrealized_PnL.Notional_CFD | Direct | T1 |
| 42 | NOP_Crypto_CFD | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Direct | T1 |
| 43 | Notional_Crypto_CFD | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Direct | T1 |
| 44 | PositionPnLStocksReal | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Direct | T1 |
| 45 | PositionPnLCryptoReal | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Direct | T1 |
| 46 | TotalRealStocks | Fact_SnapshotEquity.TotalRealStocks | Direct | T1 |
| 47 | TotalRealCrypto | Fact_SnapshotEquity.TotalRealCrypto | Direct | T1 |
| 48 | LiabilitiesStockReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0) | T2 |
| 49 | LiabilitiesCryptoReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0) | T2 |
| 50 | CommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Direct | T1 |
| 51 | CopyCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Direct | T1 |
| 52 | CryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Direct | T1 |
| 53 | FullCommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Direct | T1 |
| 54 | ManualCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Direct | T1 |
| 55 | NOP_Crypto_TRS | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Direct | T1 |
| 56 | Notional_Crypto_TRS | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Direct | T1 |
| 57 | Total_TRSCrypto | Fact_SnapshotEquity.Total_TRSCrypto | Direct | T1 |
| 58 | TotalCryptoPositionAmount_TRS | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Direct | T1 |
| 59 | TotalCryptoManualPosition_TRS | Fact_SnapshotEquity | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS | T2 |
| 60 | LiabilitiesCrypto_TRS | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0) | T2 |
| 61 | MirrorRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL | Direct | T1 |
| 62 | ManualRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL | Direct | T1 |
| 63 | NOP_FuturesReal | Fact_CustomerUnrealized_PnL.NOP_FuturesReal | Direct | T1 |
| 64 | Notional_FuturesReal | Fact_CustomerUnrealized_PnL.Notional_FuturesReal | Direct | T1 |
| 65 | PositionPnLFuturesReal | Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal | Direct | T1 |
| 66 | FullCommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal | Direct | T1 |
| 67 | CommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal | Direct | T1 |
| 68 | TotalMirrorRealFuturesPositionAmount | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Direct | T1 |
| 69 | TotalRealFutures | Fact_SnapshotEquity.TotalRealFutures | Direct | T1 |
| 70 | TotalFuturesProviderMargin | Fact_SnapshotEquity.TotalFuturesProviderMargin | Direct | T1 |
| 71 | LiabilitiesFuturesReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0) | T2 |
| 72 | NOP_StocksMargin | Fact_CustomerUnrealized_PnL.NOP_StocksMargin | Direct | T1 |
| 73 | PositionPnLStocksMargin | Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin | Direct | T1 |
| 74 | TotalStocksMargin | Fact_SnapshotEquity.TotalStocksMargin | Direct | T1 |
| 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Direct | T1 |

---

## 5. Query Advisory

- **Always filter by DateID** — the view contains the full history of daily snapshots. Unfiltered queries are expensive.
- **Balance formula**: `Liabilities + ActualNWA` or equivalently `ISNULL(RealizedEquity,0) + ISNULL(PositionPnL,0)` (Confluence)
- **TotalCash decomposition**: `TotalCash = Credit + TotalMirrorCash` (Confluence)
- **Today's data is excluded** — the WHERE clause filters `DateKey < today`. This is by design; use yesterday's date.
- **LEFT JOIN to FCUPNL**: PnL columns will be NULL for CIDs with no open positions on a given date. Use ISNULL when aggregating.

---

## 6. Relationships

### 6.1 Upstream Sources

| Source | Join Key | Columns Contributed |
|--------|----------|-------------------|
| Fact_SnapshotEquity | CID + DateRangeID → V_M2M_Date_DateRange | Equity, cash, positions, credit, AUM, asset-class amounts (32 columns) |
| Fact_CustomerUnrealized_PnL | CID + DateModified = DateKey | PnL, NOP, notional, commissions, risk (31 columns) |
| V_M2M_Date_DateRange | DateRangeID | DateKey (→ DateID), FullDate |

### 6.2 Downstream Consumers (20+ SPs)

| SP | Schema | Usage Pattern |
|----|--------|---------------|
| SP_DDR_Fact_AUM | BI_DB_dbo | AUM dashboard aggregation |
| SP_Client_Balance_New | BI_DB_dbo | Customer balance reporting |
| SP_Client_Balance_Breakdown | BI_DB_dbo | Detailed balance decomposition |
| SP_Q_AML_EDD_US_Report | BI_DB_dbo | AML enhanced due diligence (US) |
| SP_Q_AML_FSA_Report | BI_DB_dbo | AML FSA regulatory report |
| SP_AML_PI_Abuse | BI_DB_dbo | Popular Investor abuse detection |
| SP_AML_BI_Alerts_New_Singapore | BI_DB_dbo | AML alerts (Singapore) |
| SP_Fact_RegulationTransfer | DWH_dbo | Regulation transfer processing |
| SP_Fact_CustomerUnrealized_PnL | DWH_dbo | Uses equity from FSE for risk weights |
| SP_CIDFirstDates | BI_DB_dbo | First date tracking per CID |
| SP_MarketingCloudDaily | BI_DB_dbo | Marketing data feed |
| SP_Copyfunds_SignificantAllocation | BI_DB_dbo | Copy fund allocation analysis |
| SP_Q_QSR_New | BI_DB_dbo | QSR regulatory report |
| SP_TIN_Gap | BI_DB_dbo | TIN gap analysis |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Daily customer panel |
| SP_CID_MonthlyPanel_FullData | BI_DB_dbo | Monthly customer panel |
| SP_BI_DB_CO_Cluster_Daily | BI_DB_dbo | Cashout clustering |
| SP_BI_DB_W8_Users_Status | BI_DB_dbo | W8 tax form status |
| SP_IR_Dashboard_Monitor_Checks | BI_DB_dbo | IR dashboard monitoring |
| SP_OPS_MultipleAccounts | BI_DB_dbo | Multiple account detection |
| SP_M_Affiliates_FraudMonitoring | BI_DB_dbo | Affiliate fraud monitoring |

---

## 7. Sample Queries

```sql
-- Customer balance for yesterday
SELECT CID, DateID,
       Liabilities + ActualNWA AS Balance,
       Liabilities, ActualNWA, Credit,
       RealizedEquity, PositionPnL
FROM DWH_dbo.V_Liabilities
WHERE DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)
  AND CID = 12345;

-- Platform total liabilities trend (last 7 days)
SELECT DateID,
       SUM(Liabilities) AS TotalLiabilities,
       SUM(ActualNWA) AS TotalNWA,
       SUM(Liabilities) + SUM(ActualNWA) AS TotalBalance,
       COUNT(DISTINCT CID) AS Customers
FROM DWH_dbo.V_Liabilities
WHERE DateID >= CAST(CONVERT(CHAR(8), GETDATE()-8, 112) AS INT)
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Summary of V-Liabilities (Confluence/BI) | Authoritative business definitions: Balance = Liabilities + ActualNWA = RealizedEquity + PositionPnL. BonusCredit examples. TotalCash = Credit + TotalMirrorCash. |
| BI Dictionary (Confluence/BI) | "V_Liabilities: a view that summarizes or exposes customer liabilities, such as negative balances, equity, Position PnL, etc." |
| DDR Tables (Confluence) | "BI_DB_DDR_Fact_AUM is the same as V_Liabilities table (daily snapshot per user)" — notes equivalence for equity/AUM |
| Azure Data Platform Projects (Confluence/BDP) | Lists V_Liabilities as a Gold-tier replicated asset |
| PNL flow (Confluence/BDP) | V_Liabilities as downstream consumer of PnL pipeline |
| Dormant Fee (Confluence/REGTECH) | Uses V_Liabilities.Liabilities and Credit for dormant fee eligibility |
| Credit Line COs (Confluence/OTS) | NWA / Credit Line rules: "Credit Line × 3 = AAA; Equity - AAA = what can be CO" |

---
*Generated: 2026-03-22 | Reviewed: 2026-03-28 (Batch 17) | Quality: 9.2/10 (★★★★★)*
*Tiers: 63 T1, 12 T2, 0 T3, 0 T4 | Phases: 1,5,7,8,10,11 | 75 cols individually documented — no shortcuts*


### Upstream `DWH_dbo.Fact_CustomerAction` — synapse
- **Resolved as**: `DWH_dbo.Fact_CustomerAction`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`

# DWH_dbo.Fact_CustomerAction

> The central customer activity fact table in the Synapse DWH, recording every significant user action — position opens/closes, logins, deposits, cashouts, fees, bonuses, social engagement, copy-trade operations, and more — as one row per event.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | ~11 billion |
| **Production Sources** | `History.Credit` (via `History.ActiveCredit`), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `STS_Audit_UserOperationsData` (logins), `Billing.Login` (cashier logins), `Customer.CustomerStatic` (registrations) |
| **Refresh** | Daily (midnight ETL via SWITCH partition) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + 4 nonclustered |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **UC Format** | Delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | EXTERNAL |

---

## 1. Business Meaning

`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?"

The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema:
1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging
2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging
3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007)
4. **Logins** (ActionTypeID 14): From `STS_Audit_UserOperationsData` (Session Tracking Service) with platform/browser detection
5. **Registrations** (ActionTypeID 41): From `Customer.CustomerStatic`

Because the table unions fundamentally different event types, **most columns are only populated for specific ActionTypeIDs**. Position-related columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are NULL/0 for non-position events. Fee-specific columns (IsFeeDividend, DividendID) are only set for ActionTypeID=35. This is a sparse fact table by design.

The data originates from production systems, flows through the Azure Data Lake and DWH staging tables, and is loaded by `SP_Fact_CustomerAction_DL_To_Synapse` (staging extract) and `SP_Fact_CustomerAction` (transform + load). Post-load, `SP_Fact_CustomerAction_IsParitalCloseParent` marks partial-close parents. The load uses SWITCH partition for daily increments.

---

## 2. Business Logic

### 2.1 ActionTypeID — Event Classification

**What**: Every row is classified by ActionTypeID, which determines what type of customer action occurred and which columns are populated.

**Columns Involved**: `ActionTypeID`, mapped via `DWH_dbo.Dim_ActionType`

**Rules**:

| ActionTypeID | Name | Category | Source |
|---|---|---|---|
| 1 | ManualPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID=0 |
| 2 | CopyPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID>0, OrigParentPositionID>0 |
| 3 | CopyPlusPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID>0 |
| 4 | ManualPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 5 | CopyPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 6 | CopyPlusPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 7 | Deposit | Deposit | History.Credit (CreditTypeID=1) |
| 8 | Cashout | Cashout | History.Credit (CreditTypeID=2) |
| 9 | Bonus | Bonus | History.Credit (CreditTypeID=7) |
| 10 | Cashout request | Cashout request | History.Credit (CreditTypeID=9) |
| 11 | Chargeback | Chargeback | History.Credit (CreditTypeID=11) |
| 12 | Refund | Refund | History.Credit (CreditTypeID=12) |
| 14 | LoggedIn | LoggedIn | STS_Audit_UserOperationsData |
| 15 | Account balance to mirror | Mirror ops | History.Credit (CreditTypeID=18) |
| 16 | Mirror balance to account | Mirror ops | History.Credit (CreditTypeID=19) |
| 17 | Register new mirror | Mirror ops | History.Credit (CreditTypeID=20) |
| 18 | Unregister mirror | Mirror ops | History.Credit (CreditTypeID=21) |
| 19 | Detach position from mirror | DetachPosition | History.Credit |
| 21-26 | Publish Post/Comment/Like, Received Post/Comment/Like | Social engagement | **DEAD DATA** — legacy rows exist but no longer updated. No active ETL. |
| 27 | DepositAttempt | DepositAttempt | History.Credit |
| 28 | DetachedPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 29 | Cashier Loggin | Cashier login | Billing.Login |
| 30 | Processed Cashout | Processed Cashout | History.Credit (CreditTypeID=2 processed) |
| 32 | Edit StopLoss | Edit StopLoss | History.Credit (CreditTypeID=13) |
| 34 | Open Stock Order | Stock order | History.Credit (CreditTypeID=29) |
| 35 | End Of The Week Fee | Fees | History.Credit (CreditTypeID=14) — overnight, weekend, dividend, SDRT, ticket fees |
| 36 | Compensation | Compensation | History.Credit (CreditTypeID=6) |
| 37 | Reverse cashout | Reverse cashout | History.Credit (CreditTypeID=8) |
| 38 | Affiliate Deposit | Deposit | History.Credit |
| 39 | PositionOpenTypeUnknown | PositionOpen | Position open without matching History.Credit (fix at weekly maintenance) |
| 40 | PositionCloseTypeUnknown | PositionClose | Position close without matching History.Credit |
| 41 | Customer Registration | Registration | Customer.CustomerStatic |
| 42 | Cashout Rollback | Chargeback | History.Credit (CreditTypeID=33) |
| 43 | Reverse Deposit | Reverse Deposit | History.Credit (CreditTypeID=32) |
| 44 | InternalDeposit | Deposit | History.Credit (MoveMoneyReasonID=5) |
| 45 | InternalWithdraw | Withdraw | History.Credit (MoveMoneyReasonID=5) |

### 2.2 IsFeeDividend — Fee Sub-Classification

**What**: For ActionTypeID=35 (End of Week Fee), classifies the specific fee type.

**Columns Involved**: `IsFeeDividend`, `Description`

**Rules** (per DSM-1463):
- `1` = Overnight/weekend fee (Description: "Over night fee", "Weekend fee")
- `2` = Dividend payment (Description LIKE '%dividend%')
- `3` = SDRT charge (Description LIKE '%sdrt%')
- `4` = Ticket fees (Description: "OpenTotalFees" or "CloseTotalFees")
- `NULL` = Not ActionTypeID=35

### 2.3 Position-Derived Columns (Shared with Dim_Position)

**What**: ~33 columns in Fact_CustomerAction are copies of the same data from `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay` that also populates `DWH_dbo.Dim_Position`. These columns display the same data under the same column names but are populated independently at ETL time.

**Shared columns**: `PositionID`, `InstrumentID`, `Amount`, `Leverage`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `MirrorID`, `IsSettled`, `InitialUnits`, `IsDiscounted`, `CommissionByUnits`, `FullCommissionByUnits`, `RegulationIDOnOpen`, `ReopenForPositionID`, `IsReOpen`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `OriginalPositionID`, `IsPartialCloseParent`, `IsPartialCloseChild`, `IsAirDrop`, `SettlementTypeID`, `DLTOpen`, `DLTClose`, `OpenMarkupByUnits`, `IsBuy`, `NetProfit`, `RedeemStatus`, `RedeemID`, `IsRedeem`

**Rules**:
- These columns are ONLY populated for position events (ActionTypeID IN 1-6, 28, 39, 40)
- For non-position events, these columns are 0 or NULL
- The ETL joins from staging tables directly — NOT from Dim_Position itself
- Column meanings are identical to Dim_Position (see `Dim_Position.md` for detailed descriptions)

### 2.4 PlatformID — Product/Platform Resolution

**What**: Identifies which product/platform the action originated from. Badly named — it's actually a FK to `Dim_Product.ProductID`, not a standalone platform enum.

**Columns Involved**: `PlatformID`

**Rules**:
- Only populated for ActionTypeID=14 (logins) and 41 (registrations)
- Resolve via JOIN to `DWH_dbo.Dim_Product` — provides Product, Platform, and SubPlatform columns
- Do NOT hard-code value mappings (101=Android, etc.) — always JOIN to Dim_Product

**Query pattern**:
```sql
SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Product dp ON fca.PlatformID = dp.ProductID
WHERE fca.ActionTypeID = 14
```

### 2.6 Reopen Commission Adjustment

**What**: For reopened positions (IsReOpen=1), the commission at close is adjusted.

**Columns Involved**: `CommissionOnClose`, `FullCommissionOnClose`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsReOpen`, `ReopenForPositionID`

**Rules**:
- `CommissionOnClose = new_position.CommissionOnClose - original_position.CommissionOnClose`
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve original values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX + 4 nonclustered indexes (`ActionTypeID+DateID`, `ActionTypeID`, `CompensationReasonID`, `RealCID+DateID`). Always include `RealCID` in WHERE or JOIN for optimal single-distribution queries. The columnstore index enables efficient analytical scans across the ~11B rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as **Delta** (EXTERNAL, ~430 GB, ~7K files), partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). Always include partition columns in WHERE clauses for partition pruning — e.g., `WHERE etr_y = '2025' AND etr_ym = '202503'` will skip scanning irrelevant partitions. Given the table's ~11B rows, partition pruning is critical for any practical query. The partition columns are Databricks-layer additions not present in the Synapse source. Deletion vectors are enabled (`delta.enableDeletionVectors = true`).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All logins for a customer | `WHERE ActionTypeID = 14 AND RealCID = @cid` |
| Position opens in a date range | `WHERE ActionTypeID IN (1,2,3) AND DateID BETWEEN @start AND @end` |
| Revenue (commissions) | `WHERE ActionTypeID IN (1,2,3,4,5,6,28) AND Commission > 0` |
| Deposits for a customer | `WHERE ActionTypeID = 7 AND RealCID = @cid` |
| Overnight fees | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| First-time deposits (FTD) | `WHERE IsFTD = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_ActionType` | `ON fca.ActionTypeID = dat.ActionTypeID` | Action type name and category |
| `DWH_dbo.Dim_Customer` | `ON fca.RealCID = dc.RealCID` | Customer demographics, country |
| `DWH_dbo.Dim_Instrument` | `ON fca.InstrumentID = di.InstrumentID` | Instrument name (position events only) |
| `DWH_dbo.Dim_Position` | `ON fca.PositionID = dp.PositionID` | Full position details (avoid when possible — heavy join on 11B rows) |
| `DWH_dbo.Dim_BonusType` | `ON fca.BonusTypeID = dbt.BonusTypeID` | Bonus type name, IsWithdrawable (bonus events only) |
| `DWH_dbo.Dim_Campaign` | `ON fca.CampaignID = dcm.CampaignID` | Campaign code, description, dates |
| `DWH_dbo.Dim_Country` | `ON fca.CountryIDByIP = dco.CountryID` | Country name from IP geolocation |
| `DWH_dbo.Dim_FundingType` | `ON fca.FundingTypeID = dft.FundingTypeID` | Payment method name (deposit/cashout events) |
| `DWH_dbo.Dim_PaymentStatus` | `ON fca.PaymentStatusID = dps.PaymentStatusID` | Payment status name |
| `DWH_dbo.Dim_Product` | `ON fca.PlatformID = dp.ProductID` | Product, Platform, SubPlatform (logins/registrations only) |
| `DWH_dbo.Dim_Date` | `ON fca.DateID = dd.DateID` | Calendar attributes |
| `DWH_dbo.Dim_Regulation` | `ON fca.RegulationIDOnOpen = dr.ID` | Regulation name |

### 3.4 Gotchas

- **Most columns are only populated for specific ActionTypeIDs.** InstrumentID, Leverage, Commission, IsBuy are all 0/NULL for logins, deposits, social events, etc.
- **11 billion rows** — always filter by ActionTypeID + DateID to avoid full scans
- **IsReal is always 1** in this table — it only contains real-account actions (no demo)
- **Leverage=0 means non-position event**, not "no leverage". For actual position opens, Leverage=1 means no leverage (real ownership)
- **IsBuy NULL** means non-position event. For position events: True=Buy, False=Sell
- **Description is sparse** — only populated for fee events (ActionTypeID=35) and a few others. Contains human-readable strings like "Over night fee", "Payment caused by dividend", "OpenTotalFees"
- **PlatformTypeID** vs **PlatformID**: PlatformTypeID is a legacy field (0=default, 99=STS); PlatformID is a FK to `Dim_Product.ProductID` (badly named — always JOIN to Dim_Product, don't hard-code values)
- **StatusID is nearly always 1** (~11B rows with StatusID=1, ~2M NULL)
- **DemoCID is always 0** (real accounts only)
- **HistoryID is NOT unique** — despite being intended as a key, it contains duplicates. Never use it for JOINs, deduplication, or row identification

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 11 | Amount | decimal(11,2) | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 12 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 13 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 16 | CampaignID | int | NO | Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert) |
| 19 | LoginID | int | NO | Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 21 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned) |
| 26 | DateID | int | NO | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed) |
| 27 | TimeID | int | NO | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed) |
| 28 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21) |
| 31 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | bit | YES | Deprecated/unused column. Always NULL. (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | int | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer's regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | int | YES | Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 57 | IsFTD | int | YES | First-Time Deposit flag: 1 = this is the customer's first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed) |
| 58 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description) |
| 62 | IsAirDrop | int | YES | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | DividendID | int | YES | Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions) |
| 64 | MoveMoneyReasonID | int | YES | Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |
| 66 | DLTOpen | smallint | YES | DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 67 | DLTClose | smallint | YES | DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 69 | Description | varchar(255) | YES | Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 — History.Credit, added 2024-08) |
| 70 | IsBuy | bit | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 71 | CreditID | bigint | YES | Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07) |

---

## 5. Relationships

### 5.1 References To

| Target Object | Join Column | Purpose |
|--------------|-------------|---------|
| DWH_dbo.Dim_ActionType | ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Customer | RealCID | Customer demographics, country, regulation |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument name, type (position events only) |
| DWH_dbo.Dim_Position | PositionID | Full position details (position events only) |
| DWH_dbo.Dim_Product | PlatformID → ProductID | Product, Platform, SubPlatform (badly named FK) |
| DWH_dbo.Dim_Regulation | RegulationIDOnOpen | Regulation name at event time |
| DWH_dbo.Dim_Date | DateID | Calendar attributes |
| DWH_dbo.Dim_BonusType | BonusTypeID | Bonus type name, IsWithdrawable, IsActive |
| DWH_dbo.Dim_Campaign | CampaignID | Campaign code, description, dates, bonus amount |
| DWH_dbo.Dim_Country | CountryIDByIP → CountryID | Country name (IP geolocation) |
| DWH_dbo.Dim_FundingType | FundingTypeID | Payment method name and properties |
| DWH_dbo.Dim_PaymentStatus | PaymentStatusID | Payment status name |
| Dictionary.CreditType | (via CreditID → History.Credit) | Credit type classification |
| Dictionary.MoveMoneyReason | MoveMoneyReasonID | Money movement reason |

### 5.2 Referenced By

| Source Object | Type | Usage |
|--------------|------|-------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | Function | First deposit across platforms |
| BI_DB_dbo.Function_Population_Active_Traders | Function | Active trader population |
| BI_DB_dbo.Function_Population_First_Time_Funded | Function | FTD population |
| BI_DB_dbo.Function_Population_First_Trading_Action | Function | First trading action |
| BI_DB_dbo.Function_Population_OTD_DateRange | Function | OTD date range population |
| BI_DB_dbo.Function_Revenue_Commissions | Function | Commission revenue calculation |
| BI_DB_dbo.Function_Revenue_FullCommissions | Function | Full commission revenue |
| BI_DB_dbo.Function_Revenue_CashoutFee_* | Function | Cashout fee revenue |
| BI_DB_dbo.Function_Revenue_DormantFee | Function | Dormant fee revenue |
| BI_DB_dbo.Function_Revenue_Share_Lending | Function | Share lending revenue |
| BI_DB_dbo.Function_Revenue_TransferCoinFee | Function | Crypto transfer fee revenue |
| BI_DB_dbo.V_C2P_Positions | View | CRM-to-position mapping |
| DWH_dbo.V_FCA_NumOfLogins_mean_1q | View | Average login count (1 quarter) |
| DWH_dbo.SP_Fact_FirstCustomerAction | SP | First action per customer |
| DWH_dbo.Fact_FirstCustomerAction | Table | Derivative table: first action per customer per type |

---

## 6. Dependencies

### 6.1 ETL Pipeline

```
Production Sources:
  History.ActiveCredit + Archive Credit Tables (2007-2022Q1)
    → History.Credit (view, UNION ALL)
      → Generic Pipeline → DWH_staging.Ext_FCA_Real_History_Credit_ForFactAction
  
  Trade.PositionTbl → Trade.OpenPositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Trade_Position
  
  History.Position_Active → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_History_Position
  
  STS_Audit_UserOperationsData (Session Tracking Service)
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Audit_Loggin
  
  Billing.Login → DWH_staging.etoro_Billing_Login
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Cashier_Loggin
  
  Customer.CustomerStatic → DWH_staging.etoro_Customer_CustomerStatic
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Customer_Registration

All staging → SP_Fact_CustomerAction → Ext_FCA_Fact_CustomerAction
  → SP_Fact_CustomerAction_SWITCH → Fact_CustomerAction (SWITCH partition)
  → SP_Fact_CustomerAction_IsParitalCloseParent (post-load update)
```

### 6.2 ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Fact_CustomerAction_DL_To_Synapse | Stage 1: Extract data from lake staging tables into Ext_FCA_* intermediate tables |
| SP_Fact_CustomerAction | Stage 2: Transform and load into Ext_FCA_Fact_C

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Position` — synapse
- **Resolved as**: `DWH_dbo.Dim_Position`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md`

# DWH_dbo.Dim_Position

> Core trading position table containing every opened and closed position on the eToro platform since 2007, with financial metrics (P&L, commissions, forex rates), lifecycle timestamps, social trading relationships (mirrors/copies/copy funds), regulatory context, and 20+ market price and spread columns added incrementally since 2022.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Position (open) + etoro.History.ClosePosition (closed) |
| **Refresh** | Daily (incremental via SP_Dim_Position_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (CloseDateID ASC, PositionID ASC) |
| **Synapse Partitions** | Monthly by CloseDateID, 2007-01-01 through 2026-02-28 (230+ partitions) |
| **Synapse Indexes** | IX_Dim_Position_CID, IX_Dim_Position_CloseDateID, IX_Dim_Position_CloseDateIDOpenDateID, IX_Dim_Position_CloseOccurred_OpenOccurred, IX_Dim_Position_Instrument |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` |
| **UC Format** | Delta |
| **UC Partitioned By** | CloseDateID (monthly) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_Position is the central trading record table in DWH, containing every position (trade) ever opened on the eToro platform. Each row represents a single trading position lifecycle: opened by a customer (CID) on an instrument (InstrumentID), held for some duration, and either still open (CloseDateID=0) or closed with a final NetProfit. The data spans positions from 2007-08-27 to the most recent load date (2026-03-10 as of last ETL run 2026-03-11).

**Position types represented**:
- **Retail positions**: Opened by customers directly in the eToro web/mobile app
- **Mirror/CopyTrading positions**: Opened when a customer copies another trader (MirrorID links to Dim_Mirror); ParentPositionID links to the "master" position
- **Copy Fund positions**: IsCopyFundPosition=1 when the position's root (TreeID) belongs to a fund account (AccountTypeID=9)
- **AirDrop positions**: IsAirDrop=1 for positions created via airdrop events (crypto)
- **ReOpen positions**: IsReOpen=1 for positions reopened after a ReOpen event; ReopenForPositionID points to the original

**Open vs Closed state**:
- Open position: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00'
- Closed position: CloseDateID=YYYYMMDD (e.g., 20260310), CloseOccurred = actual close timestamp

**Data Sources (merged in ETL)**:
- Open positions: `etoro_Trade_OpenPositionEndOfDay` (today's snapshot of all open positions)
- Closed positions: `etoro_History_ClosePositionEndOfDay` (positions that closed on @dt)

**134 columns** covering financial amounts, forex rates at open/close, market prices (spread data), execution IDs, order IDs, hedge types, and fee calculations added through 2025.

---

## 2. Business Logic

### 2.1 Open vs Closed Position States

**What**: The same position row transitions from "open" to "closed" as its lifecycle progresses.

**Columns Involved**: `CloseDateID`, `CloseOccurred`, `NetProfit`, `EndForexRate`, `ClosePositionReasonID`

**Rules**:
- **Open state**: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00.000'. NetProfit holds unrealized P&L (updated daily). EndForexRate=NULL (position not yet closed).
- **Closed state**: CloseDateID=YYYYMMDD int (e.g., 20260310), CloseOccurred=actual datetime. NetProfit holds realized P&L. ClosePositionReasonID explains why it closed.
- **ETL daily cycle**: Each day, rows for positions that opened or closed that day are deleted/updated and re-inserted fresh from staging.
- **CloseDateID=19000101** is a transient internal state used during ETL processing (positions being "reset" before re-insertion); analysts should filter `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed closed positions.
- **OpenDateID and CloseDateID**: Both are YYYYMMDD integers, NOT dates. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.

**Diagram**:
```
Position lifecycle in Dim_Position:
  Day 1 (open):  CloseDateID=0,        CloseOccurred='1900-01-01'  <-- still open
  Day N (close): CloseDateID=YYYYMMDD, CloseOccurred=actual time   <-- closed
  During ETL:    CloseDateID=19000101  <-- transient, skip in queries
```

### 2.2 Social Trading Relationships

**What**: How copy-trading and mirror relationships are encoded.

**Columns Involved**: `MirrorID`, `ParentPositionID`, `OrigParentPositionID`, `TreeID`, `IsCopyFundPosition`

**Rules**:
- **MirrorID**: FK to Dim_Mirror. When a customer copies another trader, all positions generated share the same MirrorID.
- **ParentPositionID**: The position ID of the "master" position being copied. NULL for original/manual positions.
- **OrigParentPositionID**: The original parent (before any reopen/rebalance operations).
- **TreeID**: FK back to Dim_Position.PositionID -- points to the root position of the copy tree. Used to identify CopyFund positions.
- **IsCopyFundPosition=1**: The position belongs to a copy-fund tree (TreeID's CID has AccountTypeID=9).

### 2.3 Financial Metrics and Commissions

**What**: How P&L and commission amounts flow through a position lifecycle.

**Columns Involved**: `Amount`, `NetProfit`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `EndOfWeekFee`, `PnLInDollars`

**Rules**:
- **Amount**: Position notional value in USD at open.
- **NetProfit**: Realized P&L for closed positions; unrealized daily P&L for open positions (updated daily from EndOfDayPnLInDollars).
- **Commission**: Opening commission charged.
- **CommissionOnClose**: Closing commission. Set to 0 for open positions; filled when position closes.
- **FullCommission / FullCommissionOnClose**: Total commissions including all components.
- **EndOfWeekFee**: Overnight fee charged on weekends for leveraged positions. CloseOnEndOfWeek=1 means position auto-closes at weekend.
- **PnLInDollars**: Unrealized daily P&L for open positions (from EndOfDayPnLInDollars staging column); realized at close.

### 2.4 Position Segmentation and Regulation

**What**: Regulatory context and platform categorization at time of open.

**Columns Involved**: `RegulationIDOnOpen`, `PlatformTypeID`, `PositionSegment`

**Rules**:
- **RegulationIDOnOpen**: The regulatory jurisdiction (entity) the customer belonged to at the time of opening. Derived from a JOIN with etoro_History_BackOfficeCustomer at ETL time. 1=UK/FCA, 2=Cyprus/CySEC, etc.
- **PlatformTypeID**: FK to Dim_PlatformType. 1=Web, 2=iOS, 3=Android, 0=Undefined.
- **PositionSegment**: Internal segment classification (smallint).

### 2.5 Volume and Unit Calculations

**What**: ETL-computed unit and volume metrics.

**Columns Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `Volume`, `VolumeOnClose`, `UnitMargin`, `InitialUnits`

**Rules**:
- **AmountInUnitsDecimal**: Position size in instrument units (e.g., shares, crypto coins).
- **LotCountDecimal**: Position size in lots.
- **Volume**: ETL-computed = ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion factor, 0) -- approximates USD equivalent at open.
- **VolumeOnClose**: Similar calculation using EndForexRate at close.
- **UnitMargin**: Margin per unit for leveraged positions.
- **InitialUnits**: Original units before any partial-close or partial-reopen adjustments.

### 2.6 Open/Close Rates and Market Prices

**What**: The forex rates, market prices, and spread data captured at open and close.

**Columns Involved**: `InitForexRate`, `EndForexRate`, `SpreadedPipBid`, `SpreadedPipAsk`, `InitForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate`, `EndForex_*`, `OpenMarket_*`, `CloseMarket_*`

**Rules**:
- **InitForexRate / EndForexRate**: The execution rate at open and close respectively (in instrument's base currency per USD or USD per instrument).
- **InitForex_* columns**: Ask, Bid, spreaded variants, and USD conversion rate at the INIT price rate ID (raw price book). Populated from PriceLog_History_CurrencyPrice_Active.
- **EndForex_***: Same price book data at the END (close) rate.
- **OpenMarket_* / CloseMarket_***: Market prices at the time of market open/close events. Added 2023-03-07 (12 columns).
- **SpreadedPipBid / SpreadedPipAsk**: Bid/ask spread in pips at execution.

### 2.7 Fees and Taxes (Post-2025)

**What**: Tax and fee components added in 2025.

**Columns Involved**: `OpenTotalTaxes`, `CloseTotalTaxes`, `OpenTotalFees`, `CloseTotalFees`, `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpenByUnits`, `EstimateCloseFeeOnOpen`, `Close_PnLInDollars`, `Close_CalculationRate`, `Close_ConversionRate`, `Close_PriceType`, `CurrentCalculationRate`, `CurrentConversionRate`

**Rules**:
- Added 2025-06-25 (Adi Ferber) and 2025-09-08 (Daniel Kaplan).
- These columns will be NULL for positions opened/closed before the ETL addition date.
- `EstimateCloseFeeForCFD/OnOpenByUnits/OnOpen`: Fee estimates for CFD instruments at open.
- `Close_PnLInDollars / Close_CalculationRate / Close_ConversionRate / Close_PriceType`: Close-side P&L metrics with explicit calculation chain.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Partitioning

**HASH (PositionID)**: Rows distributed by PositionID across nodes. Single-position lookups are efficient. JOINs between two HASH(PositionID) tables (e.g., Dim_Position JOIN Dim_PositionChangeLog by PositionID) are co-located and fast.

**Clustered Index (CloseDateID, PositionID)**: Clustered on close date -- date-range queries on closed positions are efficient. Open-position queries (CloseDateID=0) hit a single partition.

**Monthly partitioning**: Partitioned from 2007-01-01 to 2026-02-28 by CloseDateID. Always include a CloseDateID range filter in queries to enable partition elimination. Without it, all 230+ partitions are scanned.

**NOT ENFORCED PK**: The primary key on (PositionID, CloseDateID) is NOT ENFORCED. Synapse does not validate uniqueness. PositionID is logically unique per position, but be aware: duplicate PositionIDs can exist if ETL has a bug.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position`. Partitioned monthly by CloseDateID. Use `WHERE CloseDateID >= 20260101` style filters for partition pruning. Z-ORDER on PositionID within each partition is beneficial for position-lookup workloads.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get closed positions for a date range | WHERE CloseDateID BETWEEN 20260101 AND 20260310 |
| Get all open positions | WHERE CloseDateID = 0 |
| Get a customer's positions | WHERE CID = X AND CloseDateID BETWEEN ... (always include date range!) |
| P&L for closed positions | SUM(NetProfit) WHERE CloseDateID > 0 AND CloseDateID != 19000101 |
| CopyTrading positions only | WHERE MirrorID IS NOT NULL |
| Direct (non-copy) positions | WHERE MirrorID IS NULL AND ParentPositionID IS NULL |
| CopyFund positions only | WHERE IsCopyFundPosition = 1 |
| Long positions only | WHERE IsBuy = 1 |
| Short positions | WHERE IsBuy = 0 |
| By instrument | WHERE InstrumentID = X AND CloseDateID BETWEEN ... |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer info, tier, country |
| DWH_dbo.Dim_Currency | ON CurrencyID | Position base currency |
| DWH_dbo.Dim_Mirror | ON MirrorID | Copy-trading relationship details |
| DWH_dbo.Dim_ClosePositionReason | ON ClosePositionReasonID | Why position was closed |
| DWH_dbo.Dim_Platform | ON PlatformTypeID | Platform used to open |
| DWH_dbo.Dim_Date | ON OpenDateID / CloseDateID | Calendar dimensions |
| DWH_dbo.Dim_PositionChangeLog | ON PositionID | Position lifecycle changes (IsSettled, Amount changes) |

### 3.4 Gotchas

- **NEVER query without CloseDateID filter**: Without a date range filter, Synapse scans all 230+ monthly partitions. Always include `WHERE CloseDateID BETWEEN X AND Y` or `WHERE CloseDateID = 0`.
- **CloseDateID=0 for open, CloseDateID=19000101 during ETL**: Exclude 19000101 in most queries: `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed-closed positions.
- **OpenDateID and CloseDateID are int, not date**: They are in YYYYMMDD format. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.
- **HASH distribution on PositionID**: Very efficient for single-position or position-list queries. Less efficient for large customer-level scans (CID is not the distribution key).
- **NOT ENFORCED PK**: PositionID uniqueness is not enforced by the database. Check for duplicates if needed.
- **134 columns -- many nullable**: Most columns beyond the core set are NULL for older positions predating their addition (2022-2025). Don't assume non-null.
- **Volume = ETL-computed approximation**: Volume (int) is rounded to nearest integer. VolumeOnClose uses EndForexRate which may differ. Not always perfectly accurate.
- **UpdateDate = GETDATE() or GETUTCDATE()**: Mixed -- open positions use GETDATE(), UPDATE path for closing positions uses GETUTCDATE(). Not a reliable "modified since" field.
- **IsPartialCloseParent / IsPartialCloseChild**: 1 if this position was split via partial close. Use OriginalPositionID to trace the original. Generally filter ISNULL(IsPartialCloseChild,0)=0 on OPEN metrics only — NEVER on CLOSE. Some open metrics (e.g., volume) are already pro-rated, so excluding children would be wrong. Apply the filter case-by-case.
- **RegulationIDOnOpen is 0 for unmatched**: If the ETL JOIN with BackOfficeCustomer history finds no regulation at that date, ISNULL defaults to 0.
- **AmountInUnitsDecimal may change**: Position amount can be adjusted (e.g., partial close). Dim_PositionChangeLog tracks historical amount values.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 - MCP live data) |
| * | Tier 4 - Inferred from name | (Tier 4 - [UNVERIFIED]) |

Note: Upstream production wikis available for Trade.PositionTbl and Trade.OpenPositionEndOfDay. Columns with direct passthrough or view-computed staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2.

**Column Groups** (134 total):

#### Group A: Core Identity (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 3 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 4 | CurrencyID | int | NO | FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0. (Tier 1 — Trade.PositionTbl) |
| 5 | ProviderID | int | NO | References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen). (Tier 1 — Trade.PositionTbl) |

#### Group B: Lifecycle Timestamps and Date IDs (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | OpenOccurred | datetime | NO | When position was persisted (mapped from Occurred in production). Default getutcdate(). (Tier 1 — Trade.PositionTbl) |
| 7 | CloseOccurred | datetime | NO | When close was persisted. (Tier 1 — Trade.PositionTbl) |
| 8 | OpenDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 9 | CloseDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 10 | RequestOpenOccurred | datetime2(7) | YES | When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time). (Tier 1 — Trade.PositionTbl) |
| 11 | RequestCloseOccurred | datetime2(7) | YES | When close request arrived at API. (Tier 1 — Trade.PositionTbl) |

#### Group C: Financial Metrics (13 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Amount | money | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl) |
| 14 | InitialAmountCents | money | YES | Initial amount in cents. Used for ratio calculations. (Tier 1 — Trade.PositionTbl) |
| 15 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 16 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 17 | PnLInDollars | decimal(38,6) | YES | Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 18 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 19 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 20 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 21 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 22 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 23 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 24 | EndOfWeekFee | money | NO | Overnight/weekend carry fee. (Tier 1 — Trade.PositionTbl) |

#### Group D: ETL-Computed Volumes and Units (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | LotCountDecimal | decimal(16,6) | YES | Lot count from provider. Used for hedge aggregation and unit-based sizing. (Tier 1 — Trade.PositionTbl) |
| 26 | UnitMargin | decimal(15,8) | YES | Margin per unit. From Trade.ProviderToInstrument. (Tier 1 — Trade.PositionTbl) |
| 27 | Volume | int | YES | ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 28 | VolumeOnClose | int | YES | ETL-computed USD volume at close: ROUND(AmountInUnitsDecimal * EndForexRate * USD conversion, 0). 0 for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group E: Direction, Leverage, and Trade Settings (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | IsBuy | bit | NO | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 30 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 31 | CloseOnEndOfWeek | bit | NO | Weekend-close flag. 1 = position auto-closes at end of trading week. (Tier 1 — Trade.PositionTbl) |
| 32 | LimitRate | decimal(16,8) | YES | Take-profit rate set at open (or most recent update). (Tier 1 — Trade.PositionTbl) |
| 33 | StopRate | decimal(16,8) | YES | Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog. (Tier 1 — Trade.PositionTbl) |

#### Group F: Forex Rates (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | InitForexRate | decimal(16,8) | NO | Opening price rate at position open. Used for PnL calculation. (Tier 1 — Trade.PositionTbl) |
| 35 | EndForexRate | decimal(16,8) | YES | Closing rate at position close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |
| 36 | LastOpConversionRate | decimal(16,8) | YES | Conversion rate for last operation. (Tier 1 — Trade.PositionTbl) |
| 37 | InitConversionRate | decimal(16,8) | YES | Currency conversion rate at open. (Tier 1 — Trade.PositionTbl) |
| 38 | SpreadedPipBid | decimal(16,8) | YES | Bid rate with spread at open. From Trade.CurrencyPrice/spread config. (Tier 1 — Trade.PositionTbl) |
| 39 | SpreadedPipAsk | decimal(16,8) | YES | Ask rate with spread at open. (Tier 1 — Trade.PositionTbl) |

#### Group G: Price Rate IDs and Execution IDs (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | InitForexPriceRateID | bigint | YES | FK to price log table -- the specific price rate record at open. (Tier 1 — Trade.PositionTbl) |
| 41 | EndForexPriceRateID | bigint | YES | Price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 42 | LastOpPriceRateID | bigint | YES | Last operation price rate ID. (Tier 1 — Trade.PositionTbl) |
| 43 | LastOpPriceRate | decimal(16,8) | YES | Last operation price. Updated on partial close, dividend, etc. (Tier 1 — Trade.PositionTbl) |
| 44 | OpenMarketPriceRateID | bigint | YES | Market price rate ID at open. (Tier 1 — Trade.PositionTbl) |
| 45 | CloseMarketPriceRateID | bigint | YES | Market price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 46 | InitConversionRateID | bigint | YES | Conversion rate record ID at open. (Tier 1 — Trade.PositionTbl) |

#### Group H: Execution IDs (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | InitExecutionID | bigint | YES | Execution record ID at open. (Tier 1 — Trade.PositionTbl) |
| 48 | EndExecutionID | bigint | YES | Execution record ID at close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |

#### Group I: Market Price Data at Open (10 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 49 | InitForex_Ask | numeric(16,8) | YES | Raw ask price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | InitForex_Bid | numeric(16,8) | YES | Raw bid price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 51 | InitForex_AskSpreaded | numeric(16,8) | YES | Ask price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 52 | InitForex_BidSpreaded | numeric(16,8) | YES | Bid price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 53 | InitForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 54 | EndForex_Ask | numeric(16,8) | YES | Raw ask at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 55 | EndForex_Bid | numeric(16,8) | YES | Raw bid at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 56 | EndForex_AskSpreaded | numeric(16,8) | YES | Spreaded ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 57 | EndForex_BidSpreaded | numeric(16,8) | YES | Spreaded bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 58 | EndForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at close from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group J: Market Spread Data (8 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 59 | OpenMarket_Ask | numeric(16,8) | YES | Market ask at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 60 | OpenMarket_Bid | numeric(16,8) | YES | Market bid at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 61 | OpenMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 62 | OpenMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | OpenMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 64 | OpenMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 65 | CloseMarket_Ask | numeric(16,8) | YES | Market ask at close event. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 66 | CloseMarket_Bid | numeric(16,8) | YES | Market bid at close event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group K: Close Market Spread (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 67 | CloseMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | CloseMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 69 | CloseMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 70 | CloseMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group L: Markup and Spread Metrics (7 columns -- added 2024-01-15)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 71 | OpenMarketSpread | decimal(38,18) | YES | Spread at open. (Tier 1 — Trade.PositionTbl) |
| 72 | CloseMarketSpread | decimal(38,18) | YES | Spread at close. (Tier 1 — Trade.PositionTbl) |
| 73 | CloseMarkupOnOpen | decimal(38,18) | YES | Close markup projected at open. (Tier 1 — Trade.PositionTbl) |
| 74 | OpenMarkup | decimal(38,18) | YES | Markup at open. (Tier 1 — Trade.PositionTbl) |
| 75 | CloseMarkup | decimal(38,18) | YES | Markup at close. (Tier 1 — Trade.PositionTbl) |
| 76 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 77 | SpreadedCommission | int | YES | Spread-related commission component. (Tier 1 — Trade.PositionTbl) |

#### Group M: Social Trading and Hierarchy (8 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 79 | HedgeID | int | YES | FK to Trade.Hedge. Broker executed hedge. NULL until hedge is opened. (Tier 1 — Trade.PositionTbl) |
| 80 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 81 | ParentPositionID | bigint | YES | Copy-trade parent. 0/1 = root. Positive = child of referenced position. (Tier 1 — Trade.PositionTbl) |
| 82 | OrigParentPositionID | bigint | YES | Original parent before any detachment. (Tier 1 — Trade.PositionTbl) |
| 83 | TreeID | bigint | YES | Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative. (Tier 1 — Trade.PositionTbl) |
| 84 | IsCopyFundPosition | int | YES | 1=position belongs to a copy fund tree (TreeID's CID has AccountTypeID=9). ETL-computed via JOIN chain. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 85 | IsOpenOpen | bit | YES | Open-on-open copy behavior. From Mirror. (Tier 1 — Trade.PositionTbl) |

#### Group N: Partial Close and ReOpen (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 87 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 88 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 89 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 90 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 91 | IsPartialCloseChildFromReOpen | int | YES | 1=partial close child that was created via a ReOpen flow. (Tier 4 - [UNVERIFIED]) |
| 92 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group O: Settlement and Redemption (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 93 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 94 | IsSettledOnOpen | int | YES | 1 = real asset, 0 = CFD asset. Value at position open (snapshot); same 0/1 encoding as IsSettled. (Tier 5 — Expert Review) |
| 95 | RedeemStatus | tinyint | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 96 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 97 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_EquitiesWithSustainabilityStamp.md`

# BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp

> 218-row reference table listing equities stamped as EU sustainability-friendly, sourced from a Fivetran-synced Google Sheet joined to DWH_dbo.Dim_Instrument for InstrumentID resolution, loaded via truncate-and-reload by SP_Equities_With_Sustainability_Stamp. Last refreshed 2024-01-30.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Sheet (QSR Sustainability List) via SP_Equities_With_Sustainability_Stamp |
| **Refresh** | On-demand truncate-and-reload via SP_Equities_With_Sustainability_Stamp |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Generic Pipeline mapping |

---

## 1. Business Meaning

BI_DB_EquitiesWithSustainabilityStamp is a 218-row reference table that identifies equities stamped as sustainability-friendly under EU regulation. The data originates from a manually maintained Google Sheet synced to Synapse via Fivetran into the external table `BI_DB_dbo.External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp`.

The writer SP (`SP_Equities_With_Sustainability_Stamp`) performs a full truncate-and-reload: it joins the Fivetran external table to `DWH_dbo.Dim_Instrument` on `ISINCode = ISIN` to resolve each equity's InstrumentID. The table contains 178 distinct tickers/ISINs (some equities share the same ticker across different ISINs). All 218 rows carry an identical UpdateDate of 2024-01-30, indicating the table has not been refreshed since that date.

The SP header notes this sustainability stamp will eventually be implemented directly in the production database, but for now the Google Sheet remains the source of truth.

---

## 2. Business Logic

### 2.1 ISIN-to-InstrumentID Resolution

**What**: Maps each sustainability-stamped equity to its eToro platform InstrumentID via ISIN matching.

**Columns Involved**: `ISIN`, `InstrumentID`

**Rules**:
- JOIN condition: `DWH_dbo.Dim_Instrument.ISINCode = External_table.ISIN`
- Only equities present in both the Google Sheet AND Dim_Instrument appear in the output
- Equities in the sheet with no matching ISIN in Dim_Instrument are silently dropped (INNER JOIN)

### 2.2 Truncate-and-Reload Pattern

**What**: Full table replacement on each SP execution.

**Columns Involved**: All

**Rules**:
- TRUNCATE TABLE runs first, then INSERT…SELECT
- No incremental/delta logic — every run replaces all rows
- UpdateDate is set to GETDATE() at execution time (same value for all rows in a load)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with a CLUSTERED INDEX on InstrumentID. For a 218-row table, distribution strategy is immaterial — the entire table fits in a single distribution segment. The clustered index supports efficient point lookups by InstrumentID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is instrument X sustainability-stamped? | `WHERE InstrumentID = @id` — clustered index seek |
| List all sustainability equities by ticker | `SELECT * ORDER BY Ticker` |
| Check if an ISIN is sustainability-stamped | `WHERE ISIN = @isin` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON e.InstrumentID = di.InstrumentID` | Enrich with instrument metadata (exchange, symbol, asset class) |
| BI_DB reporting tables | `ON r.InstrumentID = e.InstrumentID` | Filter reporting to sustainability-stamped equities only |

### 3.4 Gotchas

- **Stale data**: All rows have UpdateDate = 2024-01-30 — the table has not been refreshed since January 2024. Verify with the QSR team whether the Google Sheet is still maintained.
- **INNER JOIN drops unmatched ISINs**: If a sustainability equity exists in the Google Sheet but its ISIN is not in Dim_Instrument, it will not appear here. No orphan tracking.
- **178 distinct tickers for 218 rows**: Some tickers map to multiple ISINs (e.g., dual-listed equities).
- **No Generic Pipeline mapping**: This table is not exported to Unity Catalog.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_Equities_With_Sustainability_Stamp — transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Ticker | varchar(100) | YES | Stock ticker symbol from the Fivetran-synced Google Sheet (QSR Sustainability List). Identifies the equity by its exchange ticker (e.g., "AAPL", "GOOG"). 178 distinct values across 218 rows. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 2 | ISIN | varchar(100) | YES | International Securities Identification Number from the Fivetran-synced Google Sheet. Used as the JOIN key to resolve InstrumentID via Dim_Instrument.ISINCode (e.g., "US0378331005" for Apple). 178 distinct values. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 3 | Name | varchar(100) | YES | Company/equity display name from the Fivetran-synced Google Sheet (e.g., "Apple", "Microsoft"). Human-readable label for the sustainability-stamped equity. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 4 | InstrumentID | int | YES | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. Passthrough from Dim_Instrument via JOIN on ISINCode = ISIN. (Tier 1 — Trade.GetInstrument) |
| 5 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Equities_With_Sustainability_Stamp run. All rows share the same value per load. (Tier 2 — SP_Equities_With_Sustainability_Stamp) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| Ticker | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | Ticker | Passthrough |
| ISIN | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | ISIN | Passthrough |
| Name | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | Name | Passthrough |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Dim-lookup via ISINCode = ISIN |
| UpdateDate | SP_Equities_With_Sustainability_Stamp | — | GETDATE() |

### 5.2 ETL Pipeline

```
Google Sheet (QSR Sustainability List — EU sustainability-stamped equities)
  |-- Fivetran sync ---|
  v
BI_DB_dbo.External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp
  |                                                          |
  |-- SP_Equities_With_Sustainability_Stamp (truncate-and-reload) ---|
  |   JOIN DWH_dbo.Dim_Instrument ON ISINCode = ISIN                 |
  v                                                                   v
BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp (218 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolved via ISIN match — instrument dimension lookup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_RBSF | InstrumentID | Sustainability filter for RBSF reporting |
| BI_DB_dbo.SP_Q_QSR_New | InstrumentID | QSR sustainability equity filter |
| BI_DB_dbo.QST | InstrumentID | QST sustainability equity filter |

---

## 7. Sample Queries

### 7.1 List all sustainability-stamped equities
```sql
SELECT Ticker, ISIN, Name, InstrumentID
FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp
ORDER BY Ticker
```

### 7.2 Check if a specific instrument is sustainability-stamped
```sql
SELECT e.Ticker, e.Name, di.InstrumentDisplayName, di.Exchange
FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp e
JOIN DWH_dbo.Dim_Instrument di ON e.InstrumentID = di.InstrumentID
WHERE e.InstrumentID = 1001
```

### 7.3 Find sustainability equities not in the stamp table (gap analysis)
```sql
SELECT di.InstrumentID, di.Symbol, di.ISINCode
FROM DWH_dbo.Dim_Instrument di
WHERE di.InstrumentTypeID = 5  -- Stocks only
  AND di.ISINCode IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp e
    WHERE e.ISIN = di.ISINCode
  )
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 1 T2, 3 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp | Type: Table | Production Source: Fivetran Google Sheet (QSR Sustainability List) via SP_Equities_With_Sustainability_Stamp*


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> 15,707-row replicated dimension table containing every tradeable instrument on the eToro platform — forex pairs, stocks, ETFs, commodities, indices, and crypto — sourced from Trade.GetInstrument, Trade.InstrumentMetaData, Trade.ProviderToInstrument, Trade.FuturesMetaData, and Rankings.StockInfo via SP_Dim_Instrument (truncate-and-reload).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument + Trade.InstrumentMetaData + Trade.ProviderToInstrument + Trade.FuturesMetaData via SP_Dim_Instrument |
| **Refresh** | Daily truncate-and-reload via SP_Dim_Instrument @dt |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline) |

---

## 1. Business Meaning

Dim_Instrument is the master instrument dimension for the DWH, containing 15,707 rows representing every tradeable instrument on the eToro platform. It covers Stocks (12,849), ETFs (1,287), Crypto Currencies (667), Commodities (503), Indices (247), and Currencies/Forex (153), plus one sentinel row (InstrumentID=0, 'NA').

The table is populated by `DWH_dbo.SP_Dim_Instrument`, which performs a full truncate-and-reload on each run. The SP joins the staging replica of the production `Trade.GetInstrument` view with `Dictionary.Currency` (for buy/sell abbreviations), `Trade.InstrumentMetaData` (display names, symbols, exchange, ISIN, industry), `Trade.ProviderToInstrument` (precision, allow flags, bonus credit, provider margin), `Trade.InstrumentCusip` (CUSIP identifiers), `Trade.FuturesMetaData` (multiplier, settlement time), `Trade.FuturesInstrumentsInitialMarginByProviderMapping` (provider margin per lot), and `Trade.Instrument` (OperationMode).

After the initial INSERT, the SP performs post-insert UPDATEs to enrich rows with: ReceivedOnPriceServer (from PriceLog history), AssetClass/IndustryGroup (from a static classification table), ADV_Last3Months/MKTcap/SharesOutStanding (from Rankings.StockInfo.InstrumentData), and PlatformSector/PlatformIndustry (from Rankings platform metadata). Finally, a sentinel row (InstrumentID=0) is inserted with 'NA' placeholder values, and `SP_Dim_Instrument_Snapshot` is called for date-partitioned snapshots.

---

## 2. Business Logic

### 2.1 InstrumentType CASE Mapping

**What**: Translates numeric InstrumentTypeID into human-readable asset class labels.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`

**Rules**:
- 1 = Currencies (153 instruments)
- 2 = Commodities (503)
- 4 = Indices (247)
- 5 = Stocks (12,849)
- 6 = ETF (1,287)
- 10 = Crypto Currencies (667)
- All others = Other

### 2.2 IsMajor Flag Mapping

**What**: Converts the production bit flag IsMajor (0/1) into a Yes/No string.

**Columns Involved**: `IsMajorID`, `IsMajor`

**Rules**:
- IsMajorID stores the raw bit value from Trade.GetInstrument.IsMajor
- IsMajor = 'Yes' when IsMajorID = 1, 'No' otherwise
- Yes: 6,963 instruments; No: 8,743; NA: 1 (sentinel)

### 2.3 IsFuture Derivation from InstrumentGroups

**What**: Determines whether an instrument is a futures contract based on membership in GroupID=25 in Trade.InstrumentGroups.

**Columns Involved**: `IsFuture`

**Rules**:
- 1 if InstrumentID exists in Trade.InstrumentGroups WHERE GroupID=25
- 0 otherwise
- 243 instruments flagged as futures; 15,463 non-futures

### 2.4 Post-Insert Market Data Enrichment

**What**: After the main INSERT, the SP updates financial metrics from Rankings.StockInfo data.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- ADV_Last3Months from MetadataID=8557 (KeyName='AverageDailyVolumeLast3Months-TTM')
- MKTcap = ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — falls back to crypto market cap
- SharesOutStanding from MetadataID=8444 (KeyName='SharesOutstandingCurrent-Annual')
- PlatformSector from MetadataID=8436 (StrVal, pivoted)
- PlatformIndustry from MetadataID=8280 (StrVal, pivoted)

### 2.5 Sentinel Row

**What**: A placeholder row with InstrumentID=0 is inserted at the end of the SP for FK safety.

**Columns Involved**: All

**Rules**:
- InstrumentID=0, InstrumentTypeID=0, InstrumentType='NA', Name='NA'
- Most nullable columns set to NULL
- StatusID=NULL (vs 1 for data rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution means the full table is copied to every compute node — ideal for a 15K-row dimension used in JOINs with large fact tables. CLUSTERED INDEX on InstrumentID supports point lookups and range scans. No distribution key to worry about for colocation.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up an instrument by ID | `WHERE InstrumentID = @id` — clustered index seek |
| Filter by asset class | `WHERE InstrumentType = 'Stocks'` or `WHERE InstrumentTypeID = 5` |
| Find tradeable instruments | `WHERE Tradable = 1` |
| Futures only | `WHERE IsFuture = 1` |
| Search by symbol | `WHERE Symbol = 'AAPL'` or `WHERE SymbolFull = 'AAPL'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables (positions, orders) | `ON f.InstrumentID = di.InstrumentID` | Resolve instrument name, type, exchange |
| Dim_Customer | Via fact table bridge | Instrument exposure per customer |
| Fact_CurrencyPriceWithSplit | `ON f.InstrumentID = di.InstrumentID` | Price data with instrument metadata |

### 3.4 Gotchas

- **InstrumentID=0 is a sentinel** — exclude it with `WHERE InstrumentID > 0` in aggregations
- **IsMajor is a varchar 'Yes'/'No'**, not a bit — use IsMajorID (int) for numeric filters
- **InstrumentType 'NA'** only appears on the sentinel row
- **Multiplier is NULL** for 15,464 of 15,707 rows — only populated for futures instruments
- **AssetClass is NULL** for 13,557 rows — only populated from the static classification table
- **OperationMode is NULL** for sentinel row only; 0=Standard (13,140), 1=Alternate (2,566, primarily European stock CFDs)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_Dim_Instrument — transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) |
| 2 | InstrumentTypeID | int | NO | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) |
| 3 | InstrumentType | varchar(50) | NO | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. (Tier 1 — Trade.GetInstrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all data rows; NULL for sentinel row (InstrumentID=0). (Tier 2 — SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 8 | SellCurrencyID | int | NO | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 9 | BuyCurrency | varchar(50) | NO | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 — Dictionary.Currency) |
| 10 | SellCurrency | varchar(50) | NO | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) |
| 11 | TradeRange | int | NO | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Max pip difference for price validation. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 14 | IsMajorID | int | NO | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). (Tier 1 — Trade.GetInstrument) |
| 15 | IsMajor | varchar(3) | NO | ETL-computed label from IsMajorID: 'Yes' when IsMajor=1, 'No' otherwise. (Tier 2 — SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 — Trade.InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. (Tier 1 — Trade.InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 — Trade.InstrumentMetaData) |
| 24 | Tradable | int | YES | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. (Tier 1 — Trade.InstrumentMetaData) |
| 25 | Symbol | varchar(100) | YES | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 — Trade.InstrumentMetaData) |
| 26 | ReceivedOnPriceServer | datetime | YES | Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 — SP_Dim_Instrument) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — Trade.InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. (Tier 1 — Trade.InstrumentCusip) |
| 30 | Precision | int | YES | Decimal places for price display and rounding. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 31 | AllowBuy | int | YES | 1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 32 | AllowSell | int | YES | 1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Asset class classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. NULL for 13,557 of 15,707 rows. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 34 | IndustryGroup | nvarchar(400) | YES | Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average daily trading volume over the last 3 months (TTM). From Rankings.StockInfo.InstrumentData MetadataID=8557. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization. ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — uses stock market cap when available, falls back to crypto market cap. From Rankings.StockInfo MetadataID=8735/9315. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Current shares outstanding (annual). From Rankings.StockInfo.InstrumentData MetadataID=8444. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | 1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 39 | PlatformSector | varchar(max) | YES | Platform-level sector classification from Rankings.StockInfo MetadataID=8436 (StrVal pivot). E.g., "Electronic Technology", "Technology Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | Platform-level industry classification from Rankings.StockInfo MetadataID=8280 (StrVal pivot). E.g., "Telecommunications Equipment", "Internet Software Or Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 41 | IsFuture | int | YES | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). (Tier 1 — Trade.FuturesMetaData) |
| 43 | ProviderID | int | YES | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. (Tier 1 — Trade.FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Time of day for settlement. DWH note: reformatted from Trade.FuturesMetaData.SettlementTime via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00'). (Tier 1 — Trade.FuturesMetaData) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). From Trade.Instrument. (Tier 1 — Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| InstrumentID | Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | SP_Dim_Instrument | InstrumentTypeID | CASE mapping |
| Name | Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | Trade.GetInstrument | InstrumentID | Alias |
| StatusID | SP_Dim_Instrument | — | Hardcoded 1 |
| BuyCurrencyID | Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | Dictionary.Currency | Abbreviation | Buy-side join |
| SellCurrency | Dictionary.Currency | Abbreviation | Sell-side join |
| TradeRange | Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | Trade.GetInstrument | IsMajor | Rename |
| IsMajor | SP_Dim_Instrument | IsMajor | CASE Yes/No |
| UpdateDate | SP_Dim_Instrument | — | GETDATE() |
| InsertDate | SP_Dim_Instrument | — | GETDATE() |
| InstrumentDisplayName | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough |
| Industry | Trade.InstrumentMetaData | Industry | Passthrough |
| CompanyInfo | Trade.InstrumentMetaData | CompanyInfo | Passthrough |
| Exchange | Trade.InstrumentMetaData | Exchange | Passthrough |
| ISINCode | Trade.InstrumentMetaData | ISINCode | Passthrough |
| ISINCountryCode | Trade.InstrumentMetaData | ISINCountryCode | Passthrough |
| Tradable | Trade.InstrumentMetaData | Tradable | CAST to int |
| Symbol | Trade.InstrumentMetaData | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog_History_CurrencyPrice_Active | ReceivedOnPriceServer | MIN aggregation + static persistence |
| BonusCreditUsePercent | Trade.ProviderToInstrument | BonusCreditUsePercent | Passthrough |
| SymbolFull | Trade.InstrumentMetaData | SymbolFull | Passthrough |
| CUSIP | Trade.InstrumentCusip | CUSIP | Passthrough |
| Precision | Trade.ProviderToInstrument | Precision | Passthrough |
| AllowBuy | Trade.ProviderToInstrument | AllowBuy | CAST to int |
| AllowSell | Trade.ProviderToInstrument | AllowSell | CAST to int |
| AssetClass | Ext_Dim_Instrument_Classification_Static | AssetClass | Post-insert UPDATE |
| IndustryGroup | Ext_Dim_Instrument_Classification_Static | IndustryGroup | Post-insert UPDATE |
| ADV_Last3Months | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE, KeyName filter |
| MKTcap | Rankings.StockInfo.InstrumentData | NumVal | ISNULL(MarketCap, CryptoMarketCap) |
| SharesOutStanding | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE, KeyName filter |
| VisibleInternallyOnly | Trade.ProviderToInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo.InstrumentData | StrVal | Pivoted MetadataID=8436 |
| PlatformIndustry | Rankings.StockInfo.InstrumentData | StrVal | Pivoted MetadataID=8280 |
| IsFuture | Trade.InstrumentGroups | GroupID=25 | CASE membership check |
| Multiplier | Trade.FuturesMetaData | Multiplier | Passthrough |
| ProviderID | Trade.ProviderToInstrument | ProviderID | Passthrough |
| ProviderMarginPerLot | Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | Rename |
| eToroMarginPerLot | Trade.ProviderToInstrument | InitialMarginInAssetCurrency | Rename |
| SettlementTime | Trade.FuturesMetaData | SettlementTime | Time reformatting |
| OperationMode | Trade.Instrument | OperationMode | Passthrough |

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, joins Instrument + Currency + InstrumentMetaData)
etoro.Dictionary.Currency (table, buy + sell abbreviations)
etoro.Trade.InstrumentMetaData (table, display/symbol/exchange/ISIN)
etoro.Trade.ProviderToInstrument (table, precision/allow/margin)
etoro.Trade.InstrumentCusip (view, CUSIP/ISIN)
etoro.Trade.FuturesMetaData (table, multiplier/settlement)
etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping (table, provider margin)
etoro.Trade.Instrument (table, OperationMode)
etoro.Trade.InstrumentGroups (table, GroupID=25 for futures flag)
Rankings.StockInfo.InstrumentData (table, market data metrics)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_GetInstrument + etoro_Dictionary_Currency + ...
  |-- SP_Dim_Instrument @dt (truncate-and-reload + post-insert UPDATEs) ---|
  v
DWH_dbo.Dim_Instrument (15,707 rows)
  |-- SP_Dim_Instrument_Snapshot @dt (date-partitioned snapshot) ---|
  |-- Generic Pipeline (Override, delta) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Asset class (1=Forex, 5=Stocks, 10=Crypto, etc.) |
| BuyCurrencyID | Dictionary.Currency | Buy-side asset / base currency |
| SellCurrencyID | Dictionary.Currency | Sell-side denomination currency |
| ProviderID | Trade.Provider | Execution provider |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact tables (positions, orders, trades) | InstrumentID | Instrument dimension lookup |
| Fact_CurrencyPriceWithSplit | InstrumentID | Price data with instrument metadata |
| BI_DB aggregation tables | InstrumentID | Instrument attributes for reporting |

---

## 7. Sample Queries

### 7.1 Instrument breakdown by asset class
```sql
SELECT InstrumentType, COUNT(*) AS InstrumentCount
FROM DWH_dbo.Dim_Instrument
WHERE InstrumentID > 0
GROUP BY InstrumentType
ORDER BY InstrumentCount DESC
```

### 7.2 Find a stock by symbol with market data
```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, SymbolFull,
       Exchange, ISINCode, AssetClass, IndustryGroup,
       ADV_Last3Months, MKTcap, SharesOutStanding
FROM DWH_dbo.Dim_Instrument
WHERE Symbol = 'AAPL'
```

### 7.3 List futures instruments with margin data
```sql
SELECT InstrumentID, Name, InstrumentDisplayName, Multiplier,
       ProviderMarginPerLot, eToroMarginPerLot, SettlementTime
FROM DWH_dbo.Dim_Instrument
WHERE IsFuture = 1
ORDER BY InstrumentID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 30 T1, 13 T2, 2 T3, 0 T4, 0 T5 | Elements: 47/47, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Instrument | Type: Table | Production Source: Trade.GetInstrument + Trade.InstrumentMetaData via SP_Dim_Instrument*


### Upstream `BI_DB_dbo.BI_DB_PositionPnL` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PositionPnL`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md`

# BI_DB_dbo.BI_DB_PositionPnL

## 1. Overview

Daily end-of-day snapshot of **open trading positions** with unrealized P&L, rates, commissions, NOP, and close-price metrics. Grain is **one row per position per calendar day** (`DateID` + `PositionID`); only positions open as of end of `@dt` appear for that `DateID`.

## 2. Business Context

- **Rules**: Positions are sourced from `DWH_dbo.Dim_Position` with `OpenDateID < @ReportDateID` and still open on `@dt` (`CloseDateID >= @ReportDateID` or `CloseDateID = 0`). `Dim_PositionChangeLog` rewinds `Amount`, `StopRate`, `AmountInUnitsDecimal`, and `IsSettled` when changes occur after `@dt`; rows with partial-close child (`ChangeTypeID = 11`) after `@dt` are removed. Stock splits adjust `InitForexRate`, units, and EOD rates via `Dim_HistorySplitRatio` and `#Prices`. **PositionPnL** is `PnLInDollars` from Dim_Position (authoritative PnL engine) since 2024-03-24; **Price** and **NOP** still use SP formulas from EOD rates and `Dim_Instrument` FX chains. **DailyPnL** is updated after load as today `PositionPnL` minus prior day `PositionPnL` per `PositionID`.
- **Consumers**: Finance and CMR reporting; downstream BI_DB procedures and views (e.g. crypto zero / loan / NOP stacks, IFRS, compliance, dashboards) read this table as the canonical daily position P&L snapshot.

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object type** | Table |
| **Column count** | 39 |
| **Distribution** | `HASH (PositionID)` |
| **Clustered index** | `(DateID ASC, Date ASC, CID ASC, PositionID ASC)` |
| **Partitioning** | `PARTITION (DateID RANGE LEFT FOR VALUES (...))` -- daily boundaries aligned with main table (typically 2015 through current horizon) |
| **Nonclustered index** | `IX_BI_DB_PositionPnL_CID` on `(DateID, CID)` on main table (per deployment; switch staging builds CID NCIs on switch tables) |

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CID) |
| 2 | PositionID | bigint | NO | Unique position key; Synapse distribution key. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PositionID) |
| 3 | InstrumentID | int | NO | Traded instrument. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InstrumentID) |
| 4 | MirrorID | int | YES | Copy-trading mirror link when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.MirrorID) |
| 5 | Commission | money | NO | Opening commission in dollars. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Commission) |
| 6 | InitForexRate | numeric(16,8) | NO | Open rate; split-adjusted in SP when position spans a split. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InitForexRate / split logic) |
| 7 | SpreadedPipBid | numeric(16,8) | YES | Bid with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipBid) |
| 8 | SpreadedPipAsk | numeric(16,8) | YES | Ask with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipAsk) |
| 9 | PositionPnL | decimal(16,4) | YES | Unrealized P&L in USD; from `PnLInDollars` (replaces legacy formula). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PnLInDollars) |
| 10 | Price | numeric(38,6) | YES | Per-unit price-move expression × USD conversion factor from `#Pre_UnrealizedPnL` (bid/ask vs InitForexRate and instrument FX chain). (Tier 2 -- SP_PositionPnL, computed from #OpenPositions + Dim_Instrument + #Prices) |
| 11 | HedgeServerID | int | YES | Hedge server for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.HedgeServerID) |
| 12 | Amount | money | NO | Position amount in USD; rewound via `Dim_PositionChangeLog` when SL/partial-close edits after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Amount / PositionChangeLog.PreviousAmount) |
| 13 | AmountInUnitsDecimal | numeric(16,6) | YES | Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.AmountInUnitsDecimal / split + PositionChangeLog) |
| 14 | LimitRate | numeric(16,8) | NO | Take-profit rate. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.LimitRate) |
| 15 | StopRate | numeric(16,8) | NO | Stop-loss rate; rewound to `PreviousStopRate` when edited after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.StopRate / PositionChangeLog) |
| 16 | IsBuy | bit | NO | Long (1) vs short (0). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.IsBuy) |
| 17 | Occurred | datetime | NO | Position open timestamp (`OpenOccurred`). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.OpenOccurred) |
| 18 | Date | date | YES | Snapshot calendar date `@dt`. (Tier 3 -- SP_PositionPnL, parameter @dt) |
| 19 | DateID | int | NO | Snapshot date as YYYYMMDD; partition key. (Tier 3 -- SP_PositionPnL, CAST(CONVERT(CHAR(8),@dt,112) AS INT)) |
| 20 | UpdateDate | datetime | YES | Row load timestamp at insert (`GETDATE()`). (Tier 3 -- SP_PositionPnL, GETDATE()) |
| 21 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (`ChangeTypeID = 13`) when applicable. (Tier 5 — Expert Review) |
| 22 | NOP | money | YES | Net open position in USD from units × pair rate × direction × conversion (see `#Pre_UnrealizedPnL`). (Tier 2 -- SP_PositionPnL, computed) |
| 23 | DailyPnL | decimal(16,4) | YES | Day-over-day change: `PositionPnL - prior day PositionPnL` (NULL until post-switch UPDATE). (Tier 3 -- SP_PositionPnL, UPDATE vs prior DateID) |
| 24 | Leverage | int | YES | Position leverage. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Leverage) |
| 25 | RateBid | numeric(36,12) | YES | EOD bid from latest `Fact_CurrencyPriceWithSplit` row before `@ReportDate`, split-adjusted; uses `BidLastWithoutSpread` when discounted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 26 | RateAsk | numeric(36,12) | YES | EOD ask from same price row, split-adjusted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 27 | USD_CR | money | YES | End-of-day conversion rate used with PnL context; from Dim_Position `CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 28 | SettlementTypeID | int | YES | Modern settlement type from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SettlementTypeID) |
| 29 | EstimateCloseFeeForCFD | numeric(19,8) | YES | Estimated close fee for CFD from production PnL inputs. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeForCFD) |
| 30 | EstimateCloseFeeOnOpenByUnits | numeric(19,8) | YES | Estimated close fee per units-at-open path. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpenByUnits) |
| 31 | EstimateCloseFeeOnOpen | numeric(19,8) | YES | Estimated close fee from open parameters. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpen) |
| 32 | Close_PnLInDollars | decimal(19,4) | YES | Official close-price P&L in dollars from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PnLInDollars) |
| 33 | Close_CalculationRate | decimal(18,8) | YES | Rate used for close P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_CalculationRate) |
| 34 | Close_ConversionRate | decimal(18,8) | YES | FX conversion at close for regulated P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_ConversionRate) |
| 35 | Close_PriceType | int | YES | Close price type indicator from upstream PnL. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PriceType) |
| 36 | CurrentCalculationRate | numeric(18,8) | YES | Max-date calculation rate for last-bid style P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentCalculationRate) |
| 37 | CurrentConversionRate | numeric(18,8) | YES | Conversion rate paired with current calculation rate (same source family as USD_CR). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 38 | Close_NOP | numeric(18,8) | YES | NOP using close rates: `AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |
| 39 | Current_NOP | numeric(18,8) | YES | NOP using current rates: `AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |

## 5. Relationships

**Source tables (ETL read path)**

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Open positions, PnL dollars, fees, close/current rates, core attributes |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Latest bid/ask before `@ReportDate` per instrument |
| DWH_dbo.Dim_HistorySplitRatio | Split boundaries and ratios for rate/unit adjustment |
| DWH_dbo.Dim_PositionChangeLog | Rewind deletes/updates for post-`@dt` changes |
| DWH_dbo.Dim_Instrument (+ self-joins / #Prices) | Instrument currency pair and USD cross for Price and NOP |

**Consumers (representative)**

Includes finance and CMR pipelines and many BI_DB dependents such as **`BI_DB_Crypto_Zero`**, **`BI_DB_Real_Crypto_Loan`**, **`BI_DB_DailyZero_TreeSize_NEW`** (and related daily zero / NOP procedures), plus roll-over and dividend logic (**`SP_RollOverFee_Dividends`** reads prior-day `AmountInUnitsDecimal`), IFRS, compliance, and diagnostics. Confirm additional references with a repo search on `BI_DB_PositionPnL`.

## 6. ETL & Lifecycle

| Aspect | Detail |
|--------|--------|
| **Writer** | `BI_DB_dbo.SP_PositionPnL` @dt |
| **OpsDB** | Priority **99**, ProcessType **4** (FinanceReportSPS), frequency **Daily** |
| **Pattern** | Build `#UnrealizedPnL` -- create `BI_DB_PositionPnL_SWITCH_SINGLE` with same distribution/index/partition scheme as main table -- `INSERT ... SELECT` from `#UnrealizedPnL` -- `SP_BI_DB_PositionPnL_SWITCH` partition swap -- `UPDATE` **DailyPnL** vs previous `DateID` |
| **Grain** | One row per open `PositionID` per `DateID` |
| **Delete scope** | Daily partition replaced via switch for the target `DateID` (not a full-table DELETE) |

## 7. Query Advisory

- **Partition elimination**: Always filter **`WHERE DateID = ...` or a tight `DateID` range**; scanning all daily partitions is prohibitively expensive.
- **Distribution**: **`PositionID`** is the hash key -- joins and GROUP BY on `PositionID` minimize movement; filtering large sets by `CID` alone may benefit from **`IX_BI_DB_PositionPnL_CID (DateID, CID)`** when present.
- **Semantics**: Table holds **open** positions only for each snapshot date; closed-position economics live in `Dim_Position` / fact tables.
- **DailyPnL**: Populated in a second step; for intraday copies of switch tables, expect NULL until the main-table UPDATE runs.

## 8. Classification & Status

| Field | Value |
|-------|--------|
| **Domain** | Finance / trading P&L and exposure |
| **Sensitivity** | Customer and position-level financial data -- internal use only |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


### Upstream `DWH_dbo.Fact_CustomerUnrealized_PnL` — synapse
- **Resolved as**: `DWH_dbo.Fact_CustomerUnrealized_PnL`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerUnrealized_PnL.md`

# DWH_dbo.Fact_CustomerUnrealized_PnL

> Daily customer-level unrealized PnL snapshot aggregating all open position profit/loss, commissions, Net Open Position (NOP) exposure, and notional values — broken down by asset class (stocks, crypto, futures, stock margin), settlement type (real vs CFD vs TRS), and ownership (manual vs copy vs copy-fund vs guru-connected) — with portfolio risk (standard deviation) computed from instrument covariance matrices.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Trade.OpenPositionEndOfDay + History.ClosePositionEndOfDay + PriceLog (multi-source aggregate) |
| **Key Identifier** | CID + DateModified (PK NOT ENFORCED) |
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED COLUMNSTORE |
| **Column Count** | 57 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl` |
| **Refresh** | Daily |
| **ETL Pattern** | Multi-SP orchestration: staging extract → price lookup → PnL calculation → NOP/Notional → risk → INSERT |

---

## 1. Business Meaning

`Fact_CustomerUnrealized_PnL` stores a daily end-of-day unrealized profit/loss snapshot per customer. While `Fact_SnapshotEquity` captures the balance sheet (cash, positions, AUM), this table captures the income statement — how much each customer is up or down on their open positions.

The table answers:
- **How much is each customer making/losing today?** (PositionPnL — total unrealized PnL in USD)
- **Where is the PnL coming from?** — split by asset class (stocks, crypto, futures, stock margin), settlement type (real/CFD/TRS), and ownership (manual vs copy vs guru)
- **What is the platform's exposure?** — NOP (Net Open Position, signed directional exposure) and Notional (absolute exposure) per asset class
- **What is the commission revenue?** — CommissionOnOpen, CommissionByUnits broken down by asset class
- **How risky is each customer's portfolio?** — StandardDeviation computed from instrument covariance matrix

### Business Context (from Confluence)

- **Unrealized PnL**: "PnL of customer opened positions" — the difference between realized equity and unrealized equity (Confluence: Basic Concepts)
- **NOP**: "Net of positions — eToro holding of each instrument" — signed directional exposure in USD (Confluence: Basic Concepts)
- **V0 vs V1 PnL**: The PnL calculation underwent a major migration. PositionPnL_old uses the V0 formula (CalculatedNetProfit from price differences). PositionPnL uses V1 PnLInDollars from the staging view. Gaps are monitored via SP_PNL_Alerts_Gap_Old_VS_New (Confluence: PnL Milestone #2)
- **V_Liabilities**: "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence: Summary of V-Liabilities)

---

## 2. Business Logic

### 2.1 ETL Orchestration (SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse)

Extracts 8 staging tables then calls the main computation SP:

```
1. Ext_FCUPNL_History_SplitRatio      ← History.SplitRatio (stock split adjustment ratios)
2. Ext_FCUPNL_BackOfficeCustomer      ← History.BackOfficeCustomer (fund accounts: AccountTypeID=9)
3. Ext_FCUPNL_Dictionary_Instrument   ← Trade.GetInstrument (instrument metadata)
4. Ext_FCUPNL_History_Mirror          ← History.Mirror (MirrorOperationID=1: copy-open events)
5. Ext_FCUPNL_History_Position        ← History.ClosePositionEndOfDay (same-day closed, with GetInstrument)
6. Ext_FCUPNL_Trade_Position          ← Trade.OpenPositionEndOfDay (open positions, with GetInstrument)
7. Ext_FCUPNL_PositionChangeLog       ← History.PositionChangeLog (IsSettled changes)
8. Ext_FCUPNL_CurrencyPriceMaxDateWithSplit ← PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
→ EXEC SP_Fact_CustomerUnrealized_PnL @dt
```

### 2.2 Main Computation (SP_Fact_CustomerUnrealized_PnL)

```
Phase 1: Revert IsSettled via PositionChangeLog (same as SnapshotEquity)
Phase 2: Get prices — spreaded bid/ask with split ratio adjustment
Phase 3: Identify CopyFund positions (parent CID had AccountTypeID=9 at position open time)
Phase 4: Build #OpenPositions — UNION of trade + history positions with prices, split-adjusted
Phase 5: Identify futures (Dim_Instrument.IsFuture=1)
Phase 6: Aggregate partial closes → #OpenPositionsFinal (GROUP BY OriginalPositionID)
Phase 7: Compute EndConvertionRate (USD conversion for non-USD instruments via currency pair chain)
Phase 8: Compute #UnrealizedPnL — per-position CalculatedNetProfit using V0 or V1 formula
Phase 9: Compute #final_NOP_Notional — per-CID NOP and Notional by asset class
Phase 10: Compute #CIDsRisk — portfolio standard deviation from covariance matrix
Phase 11: Final INSERT — aggregate per-position data into per-CID summaries
Phase 12: Copy subset to Fact_CustomerUnrealized_PnL_UserAPI
```

### 2.3 PnL Formula (V0 vs V1)

```sql
-- V0 (PnLVersion=0, PositionPnL_old):
CalculatedNetProfit = (RateBid/RateAsk - InitForexRate) × EndConvertionRate × AmountInUnitsDecimal

-- V1 (PnLVersion=1, PositionPnL):
CalculatedNetProfit = (Rate × EndConvertionRate - InitForexRate × InitConversionRate) × AmountInUnitsDecimal
```

V1 introduced 2024-01-03 (Katy F) to handle multi-currency PnL more accurately by separating init and end conversion rates.

### 2.4 NOP/Notional Computation

NOP = signed directional USD exposure: `AmountInUnitsDecimal × Rate × Direction × USDConversion`
Notional = ABS(NOP) — absolute exposure

Both are computed for each asset class filter (all, crypto, CFD, crypto-CFD, stock, stock-CFD, crypto-TRS, futures-real, stock-margin).

### 2.5 Portfolio Risk (StandardDeviation)

Computed only for dates >= 2012-12-31. Uses instrument covariance matrix from `Dim_Instrument_Correlation` (weekly, SampleSize > 100). Formula: `√(Σ(weight_a × weight_b × covariance))` where weights = position USD value / equity.

### 2.6 Asset Class Classification

Same mutual exclusivity rules as Fact_SnapshotEquity (Guy M fix, 2025-07-29):
- **Stocks**: InstrumentTypeID IN (5,6) AND NOT futures
- **Crypto**: InstrumentTypeID = 10 AND NOT futures
- **Futures**: Dim_Instrument.IsFuture = 1
- **Stock Margin**: SettlementTypeID = 5
- **Real**: IsSettled = 1
- **CFD**: IsSettled = 0
- **TRS**: SettlementTypeID = 2

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(CID)**: Customer-specific queries are single-node. Date-range queries across customers require data movement.
- **CLUSTERED COLUMNSTORE**: Optimized for analytical aggregations across many customers. Many columns are zero for most rows (sparse data).
- **PK (CID, DateModified) NOT ENFORCED**: Logical uniqueness — one row per customer per day.

### 3.2 Data Freshness

- Daily load via SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse
- Depends on DWH_staging position tables and price data being loaded first
- After main fact INSERT, a subset is copied to Fact_CustomerUnrealized_PnL_UserAPI for API consumption

---

## 4. Elements

> Note: This is a fully DWH-computed table. All 57 columns are aggregated/computed by the ETL SPs from position data, price data, and risk matrices. No upstream production wikis exist for the primary sources. All columns are Tier 2.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. Grouping key for all PnL aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key, part of PK. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 2 | DateModified | int | NO | Date key in YYYYMMDD integer format. Part of PK. One row per CID per day. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 3 | PositionPnL | decimal(16,2) | NO | Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 4 | CopyPositionPnL | decimal(16,2) | NO | Unrealized PnL from copy-trading positions only (MirrorID > 0). Includes all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 5 | MenualPositionPnL | decimal(16,2) | NO | Unrealized PnL from manually-opened positions only (MirrorID = 0). Note: column name is a typo for "Manual". (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 6 | StocksPositionPnL | decimal(16,2) | NO | Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Includes both real and CFD stocks, both manual and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp (GETDATE() at INSERT time). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 8 | TransURPnL | decimal(16,2) | YES | Transaction unrealized PnL. Not populated by the current ETL SP — always NULL. Legacy column. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 9 | StandardDeviation | float | YES | Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: √(Σ weight_a × weight_b × covariance). NULL for pre-2013 data. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 10 | CommissionOnOpen | decimal(16,2) | YES | Sum of opening commissions (Commission) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 11 | MirrorStocksPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 12 | CryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 13 | ManualCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 14 | CopyCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 15 | CopyFundPnL | decimal(16,2) | YES | Unrealized PnL from positions opened via copy-fund relationships (parent CID had AccountTypeID=9 at the time the copy was opened). Identified via History.BackOfficeCustomer + History.Mirror join. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 16 | FullCommissionOnOpen | decimal(16,2) | YES | Sum of full opening commissions (FullCommission, before any discounts) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 17 | NOP | decimal(16,2) | YES | Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. "eToro holding of each instrument" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 18 | Notional | decimal(16,2) | YES | Total absolute USD exposure across all instruments. ABS(NOP) per instrument, then summed. Always >= 0. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 19 | NOP_Crypto | decimal(16,2) | YES | Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 20 | Notional_Crypto | decimal(16,2) | YES | Absolute USD exposure for crypto instruments only. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 21 | NOP_CFD | decimal(16,2) | YES | Net Open Position for all CFD positions (IsSettled = 0), all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 22 | Notional_CFD | decimal(16,2) | YES | Absolute USD exposure for all CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 23 | NOP_Crypto_CFD | decimal(16,2) | YES | Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 24 | Notional_Crypto_CFD | decimal(16,2) | YES | Absolute USD exposure for crypto CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 25 | CommissionByUnits | decimal(38,6) | YES | Sum of prorated commissions (CommissionByUnits) across all open positions. Accounts for partial closes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 26 | FullCommissionByUnits | decimal(38,6) | YES | Sum of full prorated commissions (FullCommissionByUnits, before discounts) across all open positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 27 | NOP_Stock | decimal(16,2) | YES | Net Open Position for stock instruments (InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 28 | Notional_Stock | decimal(16,2) | YES | Absolute USD exposure for stock instruments. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 29 | NOP_Stock_CFD | decimal(16,2) | YES | Net Open Position for stock CFD positions (InstrumentTypeID IN (5,6) AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 30 | Notional_Stock_CFD | decimal(16,2) | YES | Absolute USD exposure for stock CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 31 | PositionPnLStocksReal | decimal(16,2) | YES | Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 32 | PositionPnLCryptoReal | decimal(16,2) | YES | Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 33 | FullCommissionByUnitsStocksReal | decimal(38,6) | YES | Full prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 34 | FullCommissionByUnitsCryptoReal | decimal(38,6) | YES | Full prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 35 | GuruCopiesPNL | decimal(16,2) | YES | Unrealized PnL from guru-connected copy positions (ConnectedGuruCopies = 1 AND MirrorID > 0). ConnectedGuruCopies = 1 means ParentPositionID != 0. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 36 | GuruCopiesPNL_Dit | decimal(16,2) | YES | Unrealized PnL from non-guru-connected copy positions (ConnectedGuruCopies = 0 AND MirrorID > 0). "Dit" = direct copy without guru position linkage. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 37 | CommissionByUnitsStocksReal | decimal(38,6) | YES | Prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 38 | CommissionByUnitsCryptoReal | decimal(38,6) | YES | Prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 39 | FullCommissionByUnitsStocksCFD | decimal(38,6) | YES | Full prorated commission for stock CFD positions (IsSettled = 0 AND InstrumentTypeID IN (5,6)). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 40 | FullCommissionByUnitsCryptoCFD | decimal(38,6) | YES | Full prorated commission for crypto CFD positions (IsSettled = 0 AND InstrumentTypeID = 10). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 41 | CommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). Added 2022-01-27 (Inbal BML). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 42 | CopyCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 43 | CryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 44 | FullCommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Full prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 45 | ManualCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto TRS positions (InstrumentTypeID = 10 AND MirrorID = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 46 | NOP_Crypto_TRS | decimal(16,2) | YES | Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 47 | Notional_Crypto_TRS | decimal(16,2) | YES | Absolute USD exposure for crypto TRS positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 48 | PositionPnL_old | decimal(38,6) | YES | Legacy PnL calculated using V0 formula (CalculatedNetProfit from bid/ask price differences). Kept for V0-vs-V1 gap monitoring (SP_PNL_Alerts_Gap_Old_VS_New). Will eventually be deprecated. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 49 | MirrorRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading futures positions (IsFuture = 1 AND MirrorID > 0). Uses PnLInDollars. Added 2024-11-10 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 50 | ManualRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened futures positions (IsFuture = 1 AND MirrorID = 0). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 51 | NOP_FuturesReal | decimal(16,2) | YES | Net Open Position for futures instruments (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 52 | Notional_FuturesReal | decimal(16,2) | YES | Absolute USD exposure for futures instruments. Always positive (uses ABS for sell positions). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 53 | PositionPnLFuturesReal | decimal(16,2) | YES | Total unrealized PnL from all futures positions (IsFuture = 1). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 54 | FullCommissionByUnitsFuturesReal | decimal(38,6) | YES | Full prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 55 | CommissionByUnitsFuturesReal | decimal(38,6) | YES | Prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 56 | NOP_StocksMargin | decimal(16,2) | YES | Net Open Position for stock margin positions (SettlementTypeID = 5). Added 2025-09-25 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 57 | PositionPnLStocksMargin | decimal(16,2) | YES | Unrealized PnL from stock margin positions (SettlementTypeID = 5). Uses PnLInDollars. Added 2025-09-25. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |

---

## 5. Lineage

### 5.1 Staging Sources

| DWH Staging Table | Production Source | Role |
|-------------------|-------------------|------|
| etoro_Trade_OpenPositionEndOfDay | Trade.OpenPositionEndOfDay | Open positions for PnL calculation |
| etoro_History_ClosePositionEndOfDay | History.ClosePositionEndOfDay | Same-day closed positions |
| etoro_Trade_GetInstrument | Trade.GetInstrument | InstrumentTypeID for asset class classification |
| etoro_History_PositionChangeLog | History.PositionChangeLog | IsSettled changes (ChangeTypeID=13) |
| etoro_History_SplitRatio | History.SplitRatio | Stock split adjustment ratios for price and amount |
| etoro_History_BackOfficeCustomer | History.BackOfficeCustomer | Fund account identification (AccountTypeID=9) |
| etoro_History_Mirror | History.Mirror | Copy-fund relationship detection (MirrorOperationID=1) |
| PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | PriceLog | End-of-day bid/ask prices (spreaded and unspreaded) |

### 5.2 Internal DWH Dependencies

| Table/Object | Role |
|------|------|
| Dim_Instrument | IsFuture flag for futures detection |
| Dim_Instrument_Correlation | Instrument covariance matrix for risk calculation |
| Fact_SnapshotEquity + V_M2M_Date_DateRange | Equity values for portfolio weight calculation in risk |
| Fact_CustomerUnrealized_PnL_UserAPI | Receives subset of columns after main INSERT (API consumption) |

### 5.3 Upstream Wiki Availability

No upstream production table wikis exist for the primary sources (History.ActiveCredit, PriceLog.Candles, etc.). All columns are DWH-computed aggregations — Tier 2.

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| DateModified | Dim_Date | DateModified = DateKey |

### 6.2 Downstream Consumers

| Object | Usage |
|--------|-------|
| V_Fact_CustomerUnrealized_PnL_For_DWH_Rep | Replication view for DWH_rep database |
| Fact_CustomerUnrealized_PnL_UserAPI | Subset table for UserStatsAPI consumption |
| V_Liabilities | Uses PositionPnL to compute unrealized equity |
| SP_Client_Balance_New | Customer balance reporting |
| SP_Y_RBSF | Regulatory balance reporting |

### 6.3 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Customer PnL breakdown for today
SELECT CID, PositionPnL, StocksPositionPnL, CryptoPositionPnL,
       CopyPositionPnL, MenualPositionPnL, StandardDeviation
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified = CONVERT(INT, CONVERT(VARCHAR, GETDATE(), 112))
  AND CID = 12345;

-- Platform NOP exposure by asset class
SELECT DateModified,
       SUM(NOP) AS TotalNOP,
       SUM(NOP_Stock) AS StockNOP,
       SUM(NOP_Crypto) AS CryptoNOP,
       SUM(NOP_FuturesReal) AS FuturesNOP,
       SUM(Notional) AS TotalNotional
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified = 20260318
GROUP BY DateModified;

-- V0 vs V1 PnL gap monitoring
SELECT DateModified,
       SUM(PositionPnL) AS V1_PnL,
       SUM(PositionPnL_old) AS V0_PnL,
       SUM(PositionPnL) - SUM(PositionPnL_old) AS Gap
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified >= 20260301
GROUP BY DateModified
ORDER BY DateModified;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| DWH View Fact_CustomerUnrealized_PnL (Confluence/DROD) | Column-level insert examples with business explanations |
| PnL Milestone #2: From New Views to Staging Tables (Confluence/BDP) | V0 vs V1 PnL migration documentation; PositionPnL_old vs PositionPnL gap monitoring |
| Basic Concepts (Confluence/DROD) | Definitions: "Unrealized PnL = PnL of customer opened positions", "NOP = Net of positions — eToro holding of each instrument" |
| Summary of V-Liabilities (Confluence/BI) | "The difference between Realized Equity and Unrealized Equity is the Position PnL"; NOP calculations for Real and CFD |
| PNL_Alerts_Gap_Old_VS_New (Confluence/BDP) | Monitoring SP that compares PositionPnL vs PositionPnL_old for gap detection |

---
*Generated: 2026-03-19 | Quality: 9.0/10*
*Tiers: 0 T1, 57 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Q_QSR_New`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Q_QSR_New.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Q_QSR_New] @sdate [date] AS 
     
/********************************************************************************************      
Author:      Guy Manova       
Date:        2020-07-22      
Description: replaces the very old code for Quarterly Statistics Report (aka Needed Data). updated code with present definitions (of everything - populations are different, metrics different) after 
				discussions with finance. due to the extreme sensitive nature of this report (compared with CB) it's best to align sources and definitions in new proc, but keep the 
				old running for a while to see grosso modo changes which might lead to inquiries from CySEC, since we did make many changes. 
				this report has two inherent inaccuracies: one, for volume and revenue of positions opened and closed within the period, the volume and commissions are taken on the CLOSED
				regulation only. two, in order to rely on V_liabilities and be 100% agreed with CB, i used the equity ratio of sustainable and non-sustainable equities with the VLiability 
				equity rather than use BI_DB_PositionPnL. in the future we might want to change that to be more precise based on actual PositionPnL equity at the EOP. 

				VERY IMPORTANT: all rows are duplicated, once in Euro, once in USD, for easy toggling in tableau as this report is submitted in Euro (but is checked in USD against othr reports
      
**************************      
** Change History      
**************************      
Date         Author       Description       
      
2021-03-05	Guy Manova	 changed the date parameter logic to work with "yesterday" (being the last day of quarter) rather than "today" (being first day of new quarter" 
						 to be in line with all the rest of the DS operations. 
2021-04-21	Guy Manova		fixed divide by zero bug
2021-07-15	Guy Manova	 fixed a wrong computation of CFD Realized and added 6 new measures
2021-07-19	Guy Manova	 somehow a self join in #pnl0 happened (vl.CID = vl.CID) which killed the proc, fixed. 
2024-01-25	Guy Manova	 synapse migrartion 
2024-01-30	Guy Manova	 fixed rollover defnition (was showing overnight not rollover) 
2025-10-23  Markos Ch    Add StockMargin
----------    ----------   ------------------------------------*/      

-- exec BI_DB_dbo.SP_Q_QSR_New '20250930'




BEGIN  

--DECLARE @sdate DATE = '20250930'
DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)
--DECLARE @cid INT = 7975664

--SELECT @sdate date, @QuarterStartDate QuarterStartDate, @QuarterEndDate QuarterEndDate, @QuarterStartDateID QuarterStartDateID, @QuarterEndDateID QuarterEndDateID, @PreviousQuarterEndDate PreviousQuarterEndDate, 
--@PreviousQuarterEndDateID PreviousQuarterEndDateID,@CurrentQuarter CurrentQuarter, @PreviousQuarter PreviousQuarter, @YearStartDate YearStartDate, @YearStartDateID YearStartDateID

--drop table if exists ##QSRTimes
--CREATE TABLE ##QSRTimes
--(
--    elapsedtime nvarchar(max)  NULL
--);
--declare @sysstart datetime 
--set @sysstart = SYSDATETIME()

---- statuses on end date -----

IF OBJECT_ID('tempdb..#fscEndDate') IS NOT NULL DROP TABLE #fscEndDate
CREATE TABLE #fscEndDate  
    WITH (HEAP,DISTRIBUTION=HASH(RealCID))
AS
SELECT
	fsc.RealCID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,dr1.Name AS Regulation
   ,dmc.Name AS MifidCategory
   ,dps.Name AS PlayerStatus
   ,dc.Name AS Country
   ,@QuarterEndDateID AS DateID
   ,CASE
		WHEN fsc.RealCID IN (2244852, 2283663, 2283668) THEN 'eToro Group'
		WHEN fsc.RealCID IN (5969868, 5969870, 5969875,5969866) THEN 'eToro Trading Group'
		ELSE 'RealUser'
	END AS IsEtoroBVI
FROM DWH_dbo.Fact_SnapshotCustomer fsc WITH (nolock)
		JOIN DWH_dbo.Dim_Range dr WITH (nolock)
				ON fsc.DateRangeID=dr.DateRangeID
				   AND @QuarterEndDateID BETWEEN dr.FromDateID AND dr.ToDateID
		JOIN DWH_dbo.Dim_Regulation dr1 WITH (nolock)
				ON fsc.RegulationID=dr1.DWHRegulationID
		JOIN DWH_dbo.Dim_MifidCategorization dmc WITH (nolock)
				ON fsc.MifidCategorizationID=dmc.MifidCategorizationID
		JOIN DWH_dbo.Dim_PlayerStatus dps WITH (nolock)
				ON fsc.PlayerStatusID=dps.PlayerStatusID
		JOIN DWH_dbo.Dim_Country dc WITH (nolock)
			ON fsc.CountryID = dc.CountryID
--WHERE fsc.RealCID = @cid

-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #fscEndDate'



----- liabilities on end date -----

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#vliabiltyprep') IS NOT NULL DROP TABLE #vliabiltyprep
CREATE TABLE #vliabiltyprep  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT * FROM DWH_dbo.V_Liabilities vl
WHERE vl.DateID = @QuarterEndDateID


--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)


IF OBJECT_ID('tempdb..#LiabilitiesCBusersEndDate') IS NOT NULL DROP TABLE #LiabilitiesCBusersEndDate
CREATE TABLE #LiabilitiesCBusersEndDate  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT
	vl.CID
   ,vl.DateID
   ,vl.RealizedEquity
   ,vl.PositionPnL
   ,vl.StocksPositionPnL
   ,vl.CryptoPositionPnL
   ,vl.Liabilities
   ,vl.LiabilitiesStockReal
   ,vl.LiabilitiesCryptoReal
   ,vl.PositionPnLStocksReal
   ,vl.PositionPnLCryptoReal
   ,vl.TotalRealStocks
   ,vl.TotalRealCrypto
   ,ISNULL(vl.TotalStockPositionAmount,0) + ISNULL(vl.StocksPositionPnL,0) AS TotalStockLiabilities
   ,ISNULL(vl.TotalCryptoPositionAmount,0) + ISNULL(vl.CryptoPositionPnL,0) AS TotalCryptoLiabilities
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,fsc.Regulation
   ,fsc.MifidCategory
   ,fsc.PlayerStatus
   ,fsc.Country
   ,CASE
		WHEN vl.CID IN (2244852, 2283663, 2283668) THEN 'eToro Group'
		WHEN vl.CID IN (5969868, 5969870, 5969875,5969866) THEN 'eToro Trading Group'
		ELSE 'RealUser'
	END AS IsEtoroBVI
FROM #vliabiltyprep vl WITH (NOLOCK)
		JOIN #fscEndDate fsc
				ON fsc.RealCID=vl.CID
				   --AND vl.DateID=fsc.DateID
--WHERE CID = @cid



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #LiabilitiesCBusersEndDate'

--- all relevant CIDs ---


IF OBJECT_ID('tempdb..#relevantCIDs') IS NOT NULL DROP TABLE #relevantCIDs
CREATE TABLE #relevantCIDs  
    WITH (DISTRIBUTION=HASH(CID))
AS
SELECT DISTINCT CID
FROM #LiabilitiesCBusersEndDate
WHERE 1=1 



-- select count(*) from #LiabilitiesCBusersEndDate

---- rollovers -----

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#rollovers') IS NOT NULL DROP TABLE #rollovers
CREATE TABLE #rollovers  
    WITH (HEAP,DISTRIBUTION=hash(PositionID))
AS
SELECT
	fca.PositionID
   ,fca.RealCID
   ,SUM (-fca.Amount) AS RollOver
   , case WHEN fca.SettlementTypeID = 5 then 1 ELSE 0 end AS StockMargin -- Added Stock Margin
FROM DWH_dbo.Fact_CustomerAction fca WITH (nolock)
WHERE
	fca.ActionTypeID=35
	AND fca.DateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID
	AND fca.IsFeeDividend = 1
GROUP BY
	fca.PositionID
   ,fca.RealCID
   , case WHEN fca.SettlementTypeID = 5 then 1 ELSE 0 end


-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #rollovers'

--- relevant positions to the period ----

--DECLARE @sdate DATE = '20250930'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#relpos') IS NOT NULL DROP TABLE #relpos
CREATE TABLE #relpos  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT dp.*, 
	CASE WHEN dp.OpenDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN 1 ELSE 0 END AS OpenedInPeriod,
	CASE WHEN dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN 1 ELSE 0 end AS ClosedInPeriod,
	CASE WHEN (dp.OpenDateID < @QuarterStartDateID AND (dp.CloseDateID = 0 OR dp.CloseDateID > @QuarterEndDateID)) THEN 1 ELSE 0 END AS HeldInPeriod
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,dr1.Name AS Regulation
   ,dmc.Name AS MifidCategory
   ,dps.Name AS PlayerStatus
   ,dc.Name AS Country
   ,CASE WHEN se.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS IsSustainableEquity
   ,di.InstrumentTypeID
   ,r.RollOver
   ,CASE
		WHEN dp.CID IN (2244852, 2283663, 2283668) THEN 'eToro Group'
		WHEN dp.CID IN (5969868, 5969870, 5969875,5969866) THEN 'eToro Trading Group'
		ELSE 'RealUser'
	END AS IsEtoroBVI
	,CASE WHEN dp.OpenDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID AND dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN dp.CloseDateID
		 WHEN dp.OpenDateID BETWEEN  @QuarterStartDateID AND @QuarterEndDateID AND dp.CloseDateID  = 0 OR dp.CloseDateID > @QuarterEndDateID THEN dp.OpenDateID
		 WHEN dp.OpenDateID <  @QuarterStartDateID  AND dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN dp.CloseDateID
		 ELSE 0 
	END AS DateForSnapshotJoin
	, case WHEN dp.SettlementTypeID = 5 then 1 ELSE 0 end AS StockMargin -- Added Stock Margin
FROM DWH_dbo.Dim_Position dp WITH (nolock)
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (nolock)
		ON fsc.RealCID = dp.CID 
	JOIN DWH_dbo.Dim_Range dr WITH (nolock)
		ON fsc.DateRangeID = dr.DateRangeID 
			AND CASE WHEN dp.OpenDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID AND dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN dp.CloseDateID
					 WHEN dp.OpenDateID BETWEEN  @QuarterStartDateID AND @QuarterEndDateID AND dp.CloseDateID  = 0 OR dp.CloseDateID > @QuarterEndDateID THEN dp.OpenDateID
					 WHEN dp.OpenDateID <  @QuarterStartDateID  AND dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN dp.CloseDateID
				ELSE 0 
		END BETWEEN dr.FromDateID AND dr.ToDateID --- this is a compromise. to avoid duplications need to decide which snapshot to take, open or close. 
	LEFT JOIN DWH_dbo.Dim_Regulation dr1 WITH (nolock)
			ON fsc.RegulationID=dr1.DWHRegulationID
	LEFT JOIN DWH_dbo.Dim_MifidCategorization dmc WITH (nolock)
			ON fsc.MifidCategorizationID=dmc.MifidCategorizationID
	LEFT JOIN DWH_dbo.Dim_PlayerStatus dps WITH (nolock)
			ON fsc.PlayerStatusID=dps.PlayerStatusID
	LEFT JOIN DWH_dbo.Dim_Country dc WITH (nolock)
		ON fsc.CountryID = dc.CountryID
	LEFT JOIN BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp se WITH (nolock)
		ON dp.InstrumentID = se.InstrumentID
	LEFT JOIN DWH_dbo.Dim_Instrument di WITH (nolock)
		ON dp.InstrumentID = di.InstrumentID
	LEFT JOIN #rollovers r
		ON dp.PositionID = r.PositionID
WHERE (dp.OpenDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID
	OR dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID
	OR (dp.OpenDateID < @QuarterStartDateID AND (dp.CloseDateID = 0 OR dp.CloseDateID > @QuarterEndDateID)))
--	AND dp.CID = @cid
-- AND dp.PositionID = 717929799

-- SELECT * from #relpos



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #relpos'


--- sustainability ratios for stocks ---
-- explanation: in order to avoid possible issues with PositionPnL not adding up, i'm using an arbitrary ratio to discern sustainable/non sustainable equities based on V_Liability number

--DECLARE @sdate DATE = '20250930'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#PPlEndDate') IS NOT NULL DROP TABLE #PPlEndDate
CREATE TABLE #PPlEndDate  
    WITH (DISTRIBUTION=ROUND_ROBIN)
AS
SELECT
	ppl.PositionID
   ,CID
   ,ppl.InstrumentID
   ,CASE WHEN se.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS ISsustainableEquity
   ,ppl.Amount + ppl.PositionPnL AS EquityInPosition
   , case WHEN ppl.SettlementTypeID = 5 then 1 ELSE 0 end AS StockMargin -- Added Stock Margin
FROM BI_DB_dbo.BI_DB_PositionPnL ppl WITH (nolock)
	JOIN DWH_dbo.Dim_Instrument di WITH (nolock)
		ON ppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5,6)
	LEFT JOIN BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp se WITH (nolock)
		ON ppl.InstrumentID = se.InstrumentID
WHERE ppl.DateID = @QuarterEndDateID
--	AND ppl.CID = @cid



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #PPlEndDate'

-- select top 10 * from #PPlEndDate

--DECLARE @sdate DATE = '20250930'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#ratios') IS NOT NULL DROP TABLE #ratios
CREATE TABLE #ratios  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
WITH "amounts" AS
(
	  SELECT  CID
		 ,SUM (CASE WHEN ISsustainableEquity=1 THEN EquityInPosition END) AS EquityInSustainables
		 ,SUM (CASE WHEN ISsustainableEquity=0 THEN EquityInPosition END) AS EquityInNonSustainables
	  FROM #PPlEndDate
	  GROUP BY
		  CID)
SELECT
	CID
   ,ISNULL (EquityInSustainables, 0)/ NULLIF((ISNULL(EquityInSustainables, 0)+ISNULL (EquityInNonSustainables, 0)),0) AS SustainablesRatio
   ,1-ISNULL (EquityInSustainables, 0)/ NULLIF((ISNULL (EquityInSustainables, 0)+ISNULL (EquityInNonSustainables, 0)),0) AS NotSustainablesRatio
FROM "amounts"


-- SELECT TOP 10 * FROM #ratios

--- adding to liabilities

IF OBJECT_ID('tempdb..#liabilitiesWithRatios') IS NOT NULL DROP TABLE #liabilitiesWithRatios
CREATE TABLE #liabilitiesWithRatios  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT
	lced.*
   ,lced.LiabilitiesStockReal*r.SustainablesRatio AS LiabilitiesStocksRealSustainable
   ,lced.LiabilitiesStockReal*r.NotSustainablesRatio AS LiabilitiesStocksRealNonSustainable
   ,lced.TotalStockLiabilities*r.SustainablesRatio AS LiabilitiesTotalStockSustainable
   ,lced.TotalStockLiabilities*r.NotSustainablesRatio AS LiabilitiesTotalStockNonSustainable
FROM #LiabilitiesCBusersEndDate lced
LEFT JOIN #ratios r	
	ON lced.CID = r.CID


---- pnl0 -------

--- positions open start date

--DECLARE @sdate DATE = '20250930'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#pnl0') IS NOT NULL DROP TABLE #pnl0
CREATE TABLE #pnl0  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT
	vl.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,fsc.Regulation
   ,fsc.MifidCategory
   ,fsc.PlayerStatus
   ,fsc.Country
   ,fsc.IsEtoroBVI
   ,SUM (isnull(vl.PositionPnL,0)) AS PnL
   ,SUM (isnull(vl.PositionPnLCryptoReal,0)) AS PnLCryptoReal
   ,SUM (isnull(vl.PositionPnLStocksReal,0)) AS pnlStocksReal
FROM DWH_dbo.Fact_CustomerUnrealized_PnL vl WITH (nolock)
LEFT JOIN (SELECT
				CID
			   ,RegulationID
			   ,MifidCategorizationID
			   ,PlayerStatusID
			   ,IsCreditReportValidCB
			   ,CountryID
			   ,Regulation
			   ,MifidCategory
			   ,PlayerStatus
			   ,Country
			   ,IsEtoroBVI
			FROM #LiabilitiesCBusersEndDate) fsc
		ON vl.CID = fsc.CID
WHERE vl.DateModified = @PreviousQuarterEndDateID
--	AND fsc.CID = @cid
GROUP BY 
	vl.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,fsc.Regulation
   ,fsc.MifidCategory
   ,fsc.PlayerStatus
   ,fsc.Country
   ,fsc.IsEtoroBVI
   ,fsc.IsEtoroBVI



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #pnl0'

---- pnl0 -------

--- positions open start date

IF OBJECT_ID('tempdb..#pnl1') IS NOT NULL DROP TABLE #pnl1
CREATE TABLE #pnl1  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT
	vl.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,fsc.Regulation
   ,fsc.MifidCategory
   ,fsc.PlayerStatus
   ,fsc.Country
   ,fsc.IsEtoroBVI
   ,SUM (isnull(vl.PositionPnL,0)) AS PnL
   ,SUM (isnull(vl.PositionPnLCryptoReal,0)) AS PnLCryptoReal
   ,SUM (isnull(vl.PositionPnLStocksReal,0)) AS pnlStocksReal
--INTO #pnl1
FROM DWH_dbo.Fact_CustomerUnrealized_PnL vl WITH (nolock)
LEFT JOIN (SELECT
			CID
		   ,RegulationID
		   ,MifidCategorizationID
		   ,PlayerStatusID
		   ,IsCreditReportValidCB
		   ,CountryID
		   ,Regulation
		   ,MifidCategory
		   ,PlayerStatus
		   ,Country
		   ,IsEtoroBVI
			FROM #LiabilitiesCBusersEndDate) fsc
	ON fsc.CID = vl.CID
WHERE vl.DateModified = @QuarterEndDateID
--	AND vl.CID = @cid
GROUP BY 
	vl.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,fsc.Regulation
   ,fsc.MifidCategory
   ,fsc.PlayerStatus
   ,fsc.Country
   ,fsc.IsEtoroBVI
   ,fsc.IsEtoroBVI



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #pnl1'

---- Realized PnL -----

--- realized PnL: netprofit  from closed positions during period. used to be Realized Zero, changed to Realized PnL in 2020

--DECLARE @sdate DATE = '20250930'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#realized') IS NOT NULL DROP TABLE #realized
CREATE TABLE #realized  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT
	dp.CID
   ,dp.RegulationID
   ,dp.MifidCategorizationID
   ,dp.PlayerStatusID
   ,dp.IsCreditReportValidCB
   ,dp.CountryID
   ,dp.Regulation
   ,dp.MifidCategory
   ,dp.PlayerStatus
   ,dp.Country
   ,dp.IsSustainableEquity
   ,dp.IsEtoroBVI
   ,dp.InstrumentTypeID
	,SUM(CASE WHEN dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID THEN dp.NetProfit ELSE 0 END) AS QuarterRealizedPnL
	,SUM(CASE WHEN dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID AND dp.InstrumentTypeID = 10 AND dp.IsSettled = 1 THEN dp.NetProfit ELSE 0 END) AS QuarterRealizedPnLRealCrypto
	,SUM(CASE WHEN dp.CloseDateID BETWEEN @QuarterStartDateID AND @QuarterEndDateID AND dp.InstrumentTypeID IN (5, 6) AND dp.IsSettled = 1 THEN dp.NetProfit ELSE 0 END) AS QuarterRealizedPnLRealStocks
	,dp.StockMargin
--INTO #realized
FROM #relpos dp
WHERE dp.ClosedInPeriod = 1
--AND dp.CID = @cid
GROUP BY
	dp.CID
   ,dp.RegulationID
   ,dp.MifidCategorizationID
   ,dp.PlayerStatusID
   ,dp.IsCreditReportValidCB
   ,dp.CountryID
   ,dp.Regulation
   ,dp.MifidCategory
   ,dp.PlayerStatus
   ,dp.Country
   ,dp.IsSustainableEquity
   ,dp.IsEtoroBVI
   ,dp.InstrumentTypeID
   ,dp.StockMargin



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #realized'

-- SELECT * FROM #realized r WHERE CID = 12864475

--- RealizedPnL CID level ---

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#RealizedPnLCIDLevel') IS NOT NULL DROP TABLE #RealizedPnLCIDLevel
CREATE TABLE #RealizedPnLCIDLevel  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
--DROP TABLE IF EXISTS #RealizedPnLCIDLevel
SELECT
	p.CID
   ,p.IsEtoroBVI
   ,l.RegulationID
   ,l.MifidCategorizationID
   ,l.PlayerStatusID
   ,l.IsCreditReportValidCB
   ,l.CountryID
   ,l.Regulation
   ,l.MifidCategory
   ,l.PlayerStatus
   ,sum(p.QuarterRealizedPnL) QuarterRealizedPnL
   ,sum(p.QuarterRealizedPnLRealCrypto) QuarterRealizedPnLRealCrypto
   ,sum(p.QuarterRealizedPnLRealStocks) QuarterRealizedPnLRealStocks
   ,p.StockMargin
--INTO #RealizedPnLCIDLevel
FROM #realized p
JOIN (SELECT
		RealCID
	   ,RegulationID
	   ,MifidCategorizationID
	   ,PlayerStatusID
	   ,IsCreditReportValidCB
	   ,CountryID
	   ,Regulation
	   ,MifidCategory
	   ,PlayerStatus
	   ,Country
	FROM #fscEndDate ed ) l
		ON p.CID = l.RealCID
WHERE 1=1  
--	AND p.CID = @cid
GROUP BY p.CID
   ,p.IsEtoroBVI
   ,l.RegulationID
   ,l.MifidCategorizationID
   ,l.PlayerStatusID
   ,l.IsCreditReportValidCB
   ,l.CountryID
   ,l.Regulation
   ,l.MifidCategory
   ,l.PlayerStatus
   ,p.StockMargin



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #RealizedPnLCIDLevel'

-- SELECT SUM(QuarterRealizedPnL) FROM #RealizedPnLCIDLevel

---  final PnL CID level

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#pnlCIDFinal') IS NOT NULL DROP TABLE #pnlCIDFinal
CREATE TABLE #pnlCIDFinal  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
--DROP TABLE IF EXISTS #pnlCIDFinal
SELECT
	c.CID
   ,ed.RegulationID
   ,ed.MifidCategorizationID
   ,ed.PlayerStatusID
   ,ed.IsCreditReportValidCB
   ,ed.CountryID
   ,ed.Regulation
   ,ed.MifidCategory
   ,ed.PlayerStatus
   ,ed.Country
   ,ed.IsEtoroBVI
   ,ISNULL(wr.Liabilities,0) AS ClientBalanceEnd
   ,ISNULL(wr.LiabilitiesCryptoReal,0) AS ClientBalanceEndRealCrypto
   ,ISNULL(wr.Liabilities,0) - ISNULL(wr.LiabilitiesCryptoReal,0) - ISNULL(wr.LiabilitiesStockReal,0) AS ClientBalanceEnd_CFD
   ,ISNULL(wr.LiabilitiesStocksRealSustainable,0) LiabilitiesStocksRealSustainable
   ,ISNULL(wr.LiabilitiesStocksRealNonSustainable,0) LiabilitiesStocksRealNonSustainable
   ,ISNULL(wr.LiabilitiesTotalStockSustainable,0) LiabilitiesTotalStockSustainable
   ,ISNULL(wr.LiabilitiesTotalStockNonSustainable,0) LiabilitiesTotalStockNonSustainable
   ,ISNULL(wr.TotalStockLiabilities,0) TotalStockLiabilities
   ,ISNULL (re.QuarterRealizedPnL, 0) AS RealizedPnL
   ,ISNULL (re.QuarterRealizedPnLRealCrypto, 0) AS RealizedRealCrypto
   ,ISNULL (re.QuarterRealizedPnLRealStocks, 0) AS RealizedRealStocks
   ,ISNULL (re.QuarterRealizedPnLRealStocks, 0)-ISNULL (re.QuarterRealizedPnLRealCrypto, 0)-ISNULL (re.QuarterRealizedPnLRealStocks, 0) AS RealizedCFDWithBugPre2021Q2
   ,ISNULL (re.QuarterRealizedPnL, 0)-ISNULL (re.QuarterRealizedPnLRealCrypto, 0)-ISNULL (re.QuarterRealizedPnLRealStocks, 0) AS RealizedCFD
   ,ISNULL (p1.PnL, 0) AS UnrealizedEnd
   ,ISNULL (p1.PnLCryptoReal, 0) AS UnrealizedRealCryptoEnd
   ,ISNULL (p1.pnlStocksReal, 0) AS UnrealizedRealStocksEnd
   ,ISNULL (p0.PnL, 0) AS UnrealizedStart
   ,ISNULL (p0.PnLCryptoReal, 0) AS UnrealizedRealCryptoStart
   ,ISNULL (p0.pnlStocksReal, 0) AS UnrealizedRealStocksStart
   ,ISNULL (p1.PnL, 0)-ISNULL (p0.PnL, 0) AS UnrealizedChange
   ,ISNULL (p1.PnLCryptoReal, 0)-ISNULL (p0.PnLCryptoReal, 0) AS UnrealizedRealCryptoChange
   ,ISNULL (p1.pnlStocksReal, 0)-ISNULL (p0.pnlStocksReal, 0) AS UnrealizedRealStocksChange
   ,ISNULL (p1.PnL, 0)-ISNULL (p1.pnlStocksReal, 0)-ISNULL (p1.PnLCryptoReal, 0) AS UnrealizedCFDEnd
   ,@CurrentQuarter AS [Quarter]
   ,re.StockMargin
--INTO #pnlCIDFinal
FROM #relevantCIDs c
	LEFT JOIN #fscEndDate ed
		ON ed.RealCID = c.CID
	LEFT JOIN #liabilitiesWithRatios wr
		ON c.CID = wr.CID
	LEFT JOIN #pnl1 p1
		ON c.CID = p1.CID
	left JOIN #pnl0 p0
			ON c.CID = p0.CID
	LEFT JOIN #RealizedPnLCIDLevel re
			ON c.CID = re.CID



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #pnlCIDFinal'


-- SELECT TOP 10 * FROM #pnlCIDFinal

--- ECB rates euro dollar ----

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#ECBRateEuroDollar') IS NOT NULL DROP TABLE #ECBRateEuroDollar
CREATE TABLE #ECBRateEuroDollar  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
--Drop Table if exists #ECBRateEuroDollar
 WITH "lastrates" AS
(
SELECT *,
	ROW_NUMBER () OVER (ORDER BY DateID DESC) AS RN
FROM [BI_DB_dbo].[BI_DB_ECB_RateExtractFromAPI]
WHERE DateID <=  CAST(FORMAT(CAST(@QuarterEndDate AS DATE),'yyyyMMdd') as INT) 
)
SELECT Date, DateID, YEAR([Date]) * 100 + DATEPART(qq, [Date]) AS Quarter, ECBRate AS Rate
--INTO #ECBRateEuroDollar
FROM "lastrates"
WHERE RN = 1

-- SELECT * FROM #ECBRateEuroDollar eed

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

IF OBJECT_ID('tempdb..#balance') IS NOT NULL DROP TABLE #balance
CREATE TABLE #balance  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
--Drop Table if exists #balance
SELECT 
	c.Quarter
	,'USD' AS ReportCurrency
	,eed1.Rate
	,c.CID
	,c.RegulationID
	,c.MifidCategorizationID
	,c.PlayerStatusID
	,CASE WHEN c.IsCreditReportValidCB = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' END AS IsCreditReportValidCB
	,c.CountryID
	,c.Regulation
	,c.MifidCategory
	,c.PlayerStatus
	,c.Country
	,CONCAT (dc.Name, ',', dc.Abbreviation) AS [CountryFormatted]
	,c.IsEtoroBVI
	,c.ClientBalanceEnd
	,c.RealizedPnL
	,c.UnrealizedEnd
	,c.ClientBalanceEndRealCrypto
	,c.ClientBalanceEnd_CFD
	,c.RealizedCFD
	,c.UnrealizedCFDEnd
	,c.LiabilitiesStocksRealSustainable
	,c.LiabilitiesStocksRealNonSustainable
	,c.LiabilitiesTotalStockSustainable
	,c.LiabilitiesTotalStockNonSustainable
	,c.TotalStockLiabilities
	,CASE WHEN c.ClientBalanceEnd = 0 OR c.ClientBalanceEnd IS null THEN 'ZeroBalanceEndPeriod' ELSE 'NonZeroBalanceEndPeriod' END AS IsZeroBalance
	,CASE WHEN c.ClientBalanceEnd < 0 THEN 'NegativeBalanceEndPeriod'
			WHEN c.ClientBalanceEnd > 0 THEN 'PositiveBalanceEndPeriod' 
			ELSE 'ZeroBalanceEndPeriod' END AS IsNegativeBalance
	,CASE WHEN c.LiabilitiesTotalStockSustainable > 0 THEN 'HasSustainableEquity' ELSE 'DoesntHaveSustainableEquity' END AS HasSustainableEquityEOP
	,c.RealizedRealCrypto as RealizedPnLRealCrypto
	,c.RealizedRealStocks as RealizedPnLRealStocks
	,c.UnrealizedRealCryptoEnd
	,c.UnrealizedRealCryptoChange
	,c.UnrealizedRealStocksEnd
	,c.UnrealizedRealStocksChange
	,c.RealizedCFDWithBugPre2021Q2
	,c.StockMargin
--INTO #balance
FROM #pnlCIDFinal c
JOIN DWH_dbo.Dim_Country dc
	ON c.CountryID = dc.CountryID
JOIN #ECBRateEuroDollar eed1
	ON c.Quarter = eed1.Quarter
UNION
SELECT
     c.Quarter
	,'EURO' AS ReportCurrency
	,eed.Rate
 	,c.CID
	,c.RegulationID
	,c.MifidCategorizationID
	,c.PlayerStatusID
	,CASE WHEN c.IsCreditReportValidCB = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' END AS IsCreditReportValidCB
	,c.CountryID
	,c.Regulation
	,c.MifidCategory
	,c.PlayerStatus
	,c.Country
	,CONCAT (dc.Name, ',', dc.Abbreviation) AS [CountryFormatted]
	,c.IsEtoroBVI
	,c.ClientBalanceEnd						/ eed.Rate as ClientBalanceEnd						
	,c.RealizedPnL							/ eed.Rate as RealizedPnL							
	,c.UnrealizedEnd						/ eed.Rate as UnrealizedEnd						
	,c.ClientBalanceEndRealCrypto			/ eed.Rate as ClientBalanceEndRealCrypto			
	,c.ClientBalanceEnd_CFD					/ eed.Rate as ClientBalanceEnd_CFD					
	,c.RealizedCFD							/ eed.Rate as RealizedCFD							
	,c.UnrealizedCFDEnd						/ eed.Rate as UnrealizedCFDEnd						
	,c.LiabilitiesStocksRealSustainable		/ eed.Rate AS LiabilitiesStocksRealSustainable		
	,c.LiabilitiesStocksRealNonSustainable	/ eed.Rate as LiabilitiesStocksRealNonSustainable	
	,c.LiabilitiesTotalStockSustainable		/ eed.Rate as LiabilitiesTotalStockSustainable		
	,c.LiabilitiesTotalStockNonSustainable	/ eed.Rate as LiabilitiesTotalStockNonSustainable	
	,c.TotalStockLiabilities				/ eed.Rate as TotalStockLiabilities				
	,CASE WHEN c.ClientBalanceEnd = 0 OR c.ClientBalanceEnd IS null THEN 'ZeroBalanceEndPeriod' ELSE 'NonZeroBalanceEndPeriod' END AS IsZeroBalance
	,CASE WHEN c.ClientBalanceEnd < 0 THEN 'NegativeBalanceEndPeriod'
			WHEN c.ClientBalanceEnd > 0 THEN 'PositiveBalanceEndPeriod' 
			ELSE 'ZeroBalanceEndPeriod' END AS IsNegativeBalance
	,CASE WHEN c.LiabilitiesTotalStockSustainable > 0 THEN 'HasSustainableEquity' ELSE 'DoesntHaveSustainableEquity' END AS HasSustainableEquityEOP
	,c.RealizedRealCrypto					/ eed.Rate as RealizedPnLRealCrypto
	,c.RealizedRealStocks					/ eed.Rate as RealizedPnLRealStocks
	,c.UnrealizedRealCryptoEnd				/ eed.Rate as UnrealizedRealCryptoEnd	
	,c.UnrealizedRealCryptoChange			/ eed.Rate as UnrealizedRealCryptoChange
	,c.UnrealizedRealStocksEnd				/ eed.Rate as UnrealizedRealStocksEnd	
	,c.UnrealizedRealStocksChange			/ eed.Rate as UnrealizedRealStocksChange
	,c.RealizedCFDWithBugPre2021Q2			/ eed.Rate AS RealizedCFDWithBugPre2021Q2
	, c.StockMargin
FROM #pnlCIDFinal c
JOIN #ECBRateEuroDollar eed
	ON c.Quarter = eed.Quarter
JOIN DWH_dbo.Dim_Country dc
	ON c.CountryID = dc.CountryID

-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #balance'

--- select top 10 * from #balance

------------------------  Volume and revenue tables ----------------------------------------

--- commissions and volumes

--DECLARE @sdate DATE = '20201001'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate) - 1, 0)
--DECLARE @QuarterEndDate DATE = DATEADD(dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)

-- SELECT TOP 10 * FROM #relpos r



IF OBJECT_ID('tempdb..#TradeCommissionsAndVolumes') IS NOT NULL DROP TABLE #TradeCommissionsAndVolumes
CREATE TABLE #TradeCommissionsAndVolumes  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
--DROP TABLE IF EXISTS #TradeCommissionsAndVolumes
SELECT 
   @CurrentQuarter AS [Quarter]
   ,r.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,dr1.Name AS Regulation
   ,dmc.Name AS MifidCategory
   ,dps.Name AS PlayerStatus
   ,dc.Name AS Country
   ,@QuarterEndDateID AS DateID
	,r.InstrumentTypeID
	, r.InstrumentID
	,r.IsSustainableEquity
	,r.IsSettled
   ,CASE
		WHEN r.CID IN (2244852, 2283663, 2283668) THEN 'eToro Group'
		WHEN r.CID IN (5969868, 5969870, 5969875,5969866) THEN 'eToro Trading Group'
		ELSE 'RealUser'
	END AS IsEtoroBVI
	, SUM(CASE WHEN r.OpenedInPeriod = 1 AND r.ClosedInPeriod = 0 THEN r.FullCommissionByUnits
		   WHEN r.OpenedInPeriod = 1 AND r.ClosedInPeriod = 1 THEN r.FullCommissionOnClose
		   WHEN r.OpenedInPeriod = 0 AND r.ClosedInPeriod = 1 THEN r.FullCommissionOnClose - r.FullCommissionByUnits
	  ELSE 0 
	END) AS Commission
	, SUM(CASE WHEN r.OpenedInPeriod = 1 AND r.ClosedInPeriod = 0 THEN CAST(r.Volume AS BIGINT)
		   WHEN r.OpenedInPeriod = 1 AND r.ClosedInPeriod = 1 THEN CAST(r.Volume AS BIGINT) + CAST(r.VolumeOnClose AS BIGINT)
		   WHEN r.OpenedInPeriod = 0 AND r.ClosedInPeriod = 1 THEN CAST(r.VolumeOnClose AS BIGINT)
	  ELSE 0 
	END) AS Volume
	, SUM(ISNULL(r.RollOver,0)) AS RollOver
	,r.StockMargin
--INTO #TradeCommissionsAndVolumes
FROM #relpos r
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (nolock)
		ON r.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr WITH (nolock)
		ON fsc.DateRangeID = dr.DateRangeID AND r.DateForSnapshotJoin BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Regulation dr1 WITH (nolock)
			ON fsc.RegulationID=dr1.DWHRegulationID
	JOIN DWH_dbo.Dim_MifidCategorization dmc WITH (nolock)
			ON fsc.MifidCategorizationID=dmc.MifidCategorizationID
	JOIN DWH_dbo.Dim_PlayerStatus dps WITH (nolock)
			ON fsc.PlayerStatusID=dps.PlayerStatusID
	JOIN DWH_dbo.Dim_Country dc WITH (nolock)
		ON fsc.CountryID = dc.CountryID
GROUP BY 
   r.CID
   ,fsc.RegulationID
   ,fsc.MifidCategorizationID
   ,fsc.PlayerStatusID
   ,fsc.IsCreditReportValidCB
   ,fsc.CountryID
   ,dr1.Name
   ,dmc.Name 
   ,dps.Name 
   ,dc.Name 
	,r.InstrumentTypeID
	,r.IsSustainableEquity
	,r.IsSettled
		, r.InstrumentID
		,r.StockMargin



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #TradeCommissionsAndVolumes'

---- did user trade in sus/non sus



IF OBJECT_ID('tempdb..#tradedSus') IS NOT NULL DROP TABLE #tradedSus
CREATE TABLE #tradedSus  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
--DROP TABLE IF EXISTS #tradedSus
SELECT CID, MAX(CASE WHEN IsSustainableEquity = 1 THEN 1 ELSE 0 END) AS UserTradedSustainbleEquity
--INTO #tradedSus
FROM #relpos
GROUP BY CID




---- volumes and commissions CID level ---

-- select top 10 * from #TradeCommissionsAndVolumes

IF OBJECT_ID('tempdb..#volumeAndCommsUSD') IS NOT NULL DROP TABLE #volumeAndCommsUSD
CREATE TABLE #volumeAndCommsUSD  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
--DROP TABLE IF EXISTS #volumeAndCommsUSD
SELECT
    a.Quarter
	,'USD' AS ReportCurrency
	,eed1.Rate
    ,a.CID
    ,a.RegulationID
    ,a.MifidCategorizationID
    ,a.PlayerStatusID
	,CASE WHEN a.IsCreditReportValidCB = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' END AS IsCreditReportValidCB
    ,a.CountryID
    ,a.Regulation
    ,a.MifidCategory
    ,a.PlayerStatus
    ,a.Country
    ,a.IsEtoroBVI
    ,CONCAT (dc.Name, ',', dc.Abbreviation) AS [CountryFormatted]
	,sum(CASE WHEN InstrumentTypeID IN (1) AND IsSettled = 0 THEN a.Volume ELSE 0 end) AS [Quarter_FX_CFD_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (2) AND IsSettled = 0 THEN a.Volume ELSE 0 end) AS [Quarter_Commodities_Volume]
	,sum(CASE WHEN InstrumentTypeID NOT IN (1, 2, 10) AND IsSettled = 0 THEN a.Volume ELSE 0 end) AS [Quarter_Other_CFD_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 0 THEN a.Volume ELSE 0 end) AS [Quarter_Crypto_CFD_Volume]
	,sum(CASE WHEN IsSettled = 0 THEN a.Volume ELSE 0 end) AS [Quarter_Total_Volume_CFD]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 1 THEN a.Volume ELSE 0 end) AS [Quarter_Total_RealCrypto_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 1 THEN a.Volume ELSE 0 end) AS [Quarter_Total_Sustainable_Equities_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 0 THEN a.Volume ELSE 0 end) AS [Quarter_Total_Non_Sustainable_Equities_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 THEN a.Volume ELSE 0 end) AS [Quarter_Total_RealStocks_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 1 THEN a.Commission + a.RollOver ELSE 0 end) AS [Quarter_Total_RealCrypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 0 THEN a.Commission + a.RollOver ELSE 0 end) AS [Quarter_Total_CFDCrypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (10) THEN a.Commission + a.RollOver ELSE 0 end) AS [Quarter_Total_Crypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 1 THEN a.Commission + a.RollOver ELSE 0 end) AS [Quarter_Total_Sustainable_Equities_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 0 THEN a.Commission + a.RollOver ELSE 0 end) AS [Quarter_Non_Total_Sustainable_Equities_Revenue]
	,MAX(s.UserTradedSustainbleEquity) AS UserTradedSustainbleEquity
	, a.StockMargin
--INTO #volumeAndCommsUSD
FROM #TradeCommissionsAndVolumes a
JOIN DWH_dbo.Dim_Country dc
	ON a.CountryID = dc.CountryID
JOIN #ECBRateEuroDollar eed1
	ON a.Quarter = eed1.Quarter -- select top 10 * from #ECBRateEuroDollar
LEFT JOIN #tradedSus s
	ON a.CID = s.CID
GROUP BY 
    a.Quarter
    ,a.CID
    ,a.RegulationID
    ,a.MifidCategorizationID
    ,a.PlayerStatusID
    ,a.IsCreditReportValidCB
    ,a.CountryID
    ,a.Regulation
    ,a.MifidCategory
    ,a.PlayerStatus
    ,a.Country
    ,a.IsEtoroBVI
    ,CONCAT (dc.Name, ',', dc.Abbreviation) 
	,eed1.Rate
	,a.StockMargin
UNION
SELECT
    a.Quarter
	,'EURO' AS ReportCurrency
	,eed.Rate
    ,a.CID
    ,a.RegulationID
    ,a.MifidCategorizationID
    ,a.PlayerStatusID
	,CASE WHEN a.IsCreditReportValidCB = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' END AS IsCreditReportValidCB
    ,a.CountryID
    ,a.Regulation
    ,a.MifidCategory
    ,a.PlayerStatus
    ,a.Country
    ,a.IsEtoroBVI
    ,CONCAT (dc.Name, ',', dc.Abbreviation) AS [CountryFormatted]
	,sum(CASE WHEN InstrumentTypeID IN (1) AND IsSettled = 0 THEN a.Volume/ cast(eed.Rate AS DECIMAL (16,8)) ELSE 0 end) AS [Quarter_FX_CFD_Volume] 
	,sum(CASE WHEN InstrumentTypeID IN (2) AND IsSettled = 0 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Commodities_Volume]
	,sum(CASE WHEN InstrumentTypeID NOT IN (1, 2, 10) AND IsSettled = 0 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Other_CFD_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 0 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Crypto_CFD_Volume]
	,sum(CASE WHEN IsSettled = 0 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_Volume_CFD]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 1 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_RealCrypto_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 1 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_Sustainable_Equities_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 0 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_Non_Sustainable_Equities_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 THEN a.Volume / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_RealStocks_Volume]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 1 THEN (a.Commission + a.RollOver) / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_RealCrypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (10) AND IsSettled = 0 THEN (a.Commission + a.RollOver) / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_CFDCrypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (10) THEN (a.Commission + a.RollOver) / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_Crypto_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 1 THEN (a.Commission + a.RollOver) / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Total_Sustainable_Equities_Revenue]
	,sum(CASE WHEN InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND a.IsSustainableEquity = 0 THEN (a.Commission + a.RollOver) / cast(eed.Rate as Decimal (16,8)) ELSE 0 end) AS [Quarter_Non_Total_Sustainable_Equities_Revenue]
	,MAX(s.UserTradedSustainbleEquity) AS UserTradedSustainbleEquity
	,a.StockMargin
FROM #TradeCommissionsAndVolumes a
	JOIN #ECBRateEuroDollar eed	
		ON a.Quarter = eed.Quarter
	JOIN DWH_dbo.Dim_Country dc
		ON a.CountryID = dc.CountryID
LEFT JOIN #tradedSus s
	ON a.CID = s.CID
GROUP BY 
    a.Quarter
    ,a.CID
    ,a.RegulationID
    ,a.MifidCategorizationID
    ,a.PlayerStatusID
    ,a.IsCreditReportValidCB
    ,a.CountryID
    ,a.Regulation
    ,a.MifidCategory
    ,a.PlayerStatus
    ,a.Country
    ,a.IsEtoroBVI
    ,CONCAT (dc.Name, ',', dc.Abbreviation) 
	,eed.Rate
	,a.StockMargin

-- select * from #volumeAndCommsUSD where CID = 8498501



-- insert into  ##QSRTimes select cast(datediff(second,@sysstart,SYSDATETIME()) as varchar) + ' to populate #volumeAndCommsUSD'

-------------- table writes ------------------

--DECLARE @sdate DATE = '20230630'
--DECLARE @QuarterStartDate DATE = DATEADD(qq, DATEDIFF(qq, 0, @sdate), 0)
--DECLARE @QuarterEndDate DATE =  DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @sdate) +1, 0))
--DECLARE @QuarterStartDateID INT = CONVERT(VARCHAR, @QuarterStartDate, 112)
--DECLARE @QuarterEndDateID INT = CONVERT(VARCHAR, @QuarterEndDate, 112)
--DECLARE @PreviousQuarterEndDate DATE = DATEADD(DAY,-1,@QuarterStartDate)
--DECLARE @PreviousQuarterEndDateID int = CONVERT(VARCHAR, @PreviousQuarterEndDate, 112)
--DECLARE @CurrentQuarter INT = YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate)
--DECLARE @PreviousQuarter INT = YEAR(@PreviousQuarterEndDate) * 100 + DATEPART(qq, @PreviousQuarterEndDate)
--DECLARE @YearStartDate DATE = DATEADD(yy, DATEDIFF(yy, 0, @QuarterStartDate), 0)
--DECLARE @YearStartDateID int = CONVERT(VARCHAR, @YearStartDate, 112)

DELETE FROM BI_DB_dbo.BI_DB_QSR_Volume_New WHERE Quarter = @CurrentQuarter 
insert INTO BI_DB_dbo.BI_DB_QSR_Volume_New (
[Quarter]
,[ReportCurrency]
,[Rate]
,[CID]
,[IsCreditReportValidCB]
,[Regulation]
,[MifidCategory]
,[PlayerStatus]
,[Country]
,[IsEtoroBVI]
,[CountryFormatted]
,[Quarter_FX_CFD_Volume]
,[Quarter_Commodities_Volume]
,[Quarter_Other_CFD_Volume]
,[Quarter_Crypto_CFD_Volume]
,[Quarter_Total_Volume_CFD]
,[Quarter_Total_RealCrypto_Volume]
,[Quarter_Total_Sustainable_Equities_Volume]
,[Quarter_Total_Non_Sustainable_Equities_Volume]
,[Quarter_Total_RealStocks_Volume]
,[Quarter_Total_RealCrypto_Revenue]
,[Quarter_Total_CFDCrypto_Revenue]
,[Quarter_Total_Crypto_Revenue]
,[Quarter_Total_Sustainable_Equities_Revenue]
,[Quarter_Non_Total_Sustainable_Equities_Revenue]
,[UserTradedSustainbleEquity]
,[UpdateDate]
,[StockMargin]
)
SELECT 
[Quarter]
,[ReportCurrency]
,[Rate]
,[CID]
,[IsCreditReportValidCB]
,[Regulation]
,[MifidCategory]
,[PlayerStatus]
,[Country]
,[IsEtoroBVI]
,[CountryFormatted]
,[Quarter_FX_CFD_Volume]
,[Quarter_Commodities_Volume]
,[Quarter_Other_CFD_Volume]
,[Quarter_Crypto_CFD_Volume]
,[Quarter_Total_Volume_CFD]
,[Quarter_Total_RealCrypto_Volume]
,[Quarter_Total_Sustainable_Equities_Volume]
,[Quarter_Total_Non_Sustainable_Equities_Volume]
,[Quarter_Total_RealStocks_Volume]
,[Quarter_Total_RealCrypto_Revenue]
,[Quarter_Total_CFDCrypto_Revenue]
,[Quarter_Total_Crypto_Revenue]
,[Quarter_Total_Sustainable_Equities_Revenue]
,[Quarter_Non_Total_Sustainable_Equities_Revenue]
,CASE WHEN [UserTradedSustainbleEquity] = 1 THEN 'TradedSustainableEquityInPeriod' ELSE 'DidntTradeSustainableEquityInPeriod' END AS [UserTradedSustainbleEquity]
,GETDATE() AS [UpdateDate]
, acu.StockMargin
FROM #volumeAndCommsUSD acu
WHERE acu.Quarter = @CurrentQuarter


DELETE FROM BI_DB_dbo.BI_DB_QSR_Balance_New WHERE Quarter = @CurrentQuarter 
INSERT INTO BI_DB_dbo.BI_DB_QSR_Balance_New (
[Quarter]
,[ReportCurrency]
,[Rate]
,[CID]
,[IsCreditReportValidCB]
,[Regulation]
,[MifidCategory]
,[PlayerStatus]
,[Country]
,[CountryFormatted]
,[IsEtoroBVI]
,[ClientBalanceEnd]
,[RealizedPnL]
,[UnrealizedEnd]
,[ClientBalanceEndRealCrypto]
,[ClientBalanceEnd_CFD]
,[RealizedCFD]
,[UnrealizedCFDEnd]
,[LiabilitiesStocksSustainable]
,[LiabilitiesStocksNonSustainable]
,[LiabilitiesStocksRealSustainable]
,[LiabilitiesStocksRealNonSustainable]
,[TotalStockLiabilities]
,[IsZeroBalance] 
,[IsNegativeBalance] 
,[HasSustainableEquityEOP]
,[UpdateDate]
,[RealizedPnLRealCrypto]
,[RealizedPnLRealStocks]
,[UnrealizedRealCryptoEnd]
,[UnrealizedRealCryptoChange]
,[UnrealizedRealStocksEnd]
,[UnrealizedRealStocksChange]
,[RealizedCFDWithBugPre2021Q2]
,[StockMargin]
)
SELECT
[Quarter]
,[ReportCurrency]
,[Rate]
,[CID]
,[IsCreditReportValidCB]
,[Regulation]
,[MifidCategory]
,[PlayerStatus]
,[Country]
,[CountryFormatted]
,[IsEtoroBVI]
,[ClientBalanceEnd]
,[RealizedPnL]
,[UnrealizedEnd]
,[ClientBalanceEndRealCrypto]
,[ClientBalanceEnd_CFD]
,[RealizedCFD]
,[UnrealizedCFDEnd]
,LiabilitiesTotalStockSustainable
,[LiabilitiesTotalStockNonSustainable]
,[LiabilitiesStocksRealSustainable]
,[LiabilitiesStocksRealNonSustainable]
,[TotalStockLiabilities]
,[IsZeroBalance] 
,[IsNegativeBalance] 
,[HasSustainableEquityEOP]
,GETDATE() AS [UpdateDate]
,[RealizedPnLRealCrypto]
,[RealizedPnLRealStocks]
,[UnrealizedRealCryptoEnd]
,[UnrealizedRealCryptoChange]
,[UnrealizedRealStocksEnd]
,[UnrealizedRealStocksChange]
,[RealizedCFDWithBugPre2021Q2]
, b.StockMargin
FROM #balance b
WHERE b.Quarter = @CurrentQuarter

END 

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Q_QSR_New` | synapse_sp | BI_DB_dbo | SP_Q_QSR_New | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Q_QSR_New.sql` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_MifidCategorization` | synapse | DWH_dbo | Dim_MifidCategorization | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.V_Liabilities` | synapse | DWH_dbo | V_Liabilities | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp` | synapse | BI_DB_dbo | BI_DB_EquitiesWithSustainabilityStamp | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_EquitiesWithSustainabilityStamp.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `BI_DB_dbo.BI_DB_PositionPnL` | synapse | BI_DB_dbo | BI_DB_PositionPnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md` |
| `DWH_dbo.Fact_CustomerUnrealized_PnL` | synapse | DWH_dbo | Fact_CustomerUnrealized_PnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerUnrealized_PnL.md` |
| `BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI` | unresolved | BI_DB_dbo | BI_DB_ECB_RateExtractFromAPI | `—` |
| `BI_DB_dbo.BI_DB_QSR_Volume_New` | unresolved | BI_DB_dbo | BI_DB_QSR_Volume_New | `—` |
