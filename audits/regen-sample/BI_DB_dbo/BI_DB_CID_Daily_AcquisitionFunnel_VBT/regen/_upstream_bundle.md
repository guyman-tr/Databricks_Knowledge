# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
(
	[CID] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[DateID] [int] NOT NULL,
	[YearMonth] [int] NOT NULL,
	[Desk] [varchar](8000) NULL,
	[Region] [nvarchar](500) NULL,
	[Country] [varchar](500) NULL,
	[Channel] [nvarchar](500) NULL,
	[SubChannel] [nvarchar](500) NULL,
	[Regulation] [varchar](50) NULL,
	[DesignatedRegulation] [varchar](50) NULL,
	[Reg_Date] [date] NULL,
	[Registration] [int] NOT NULL,
	[V2_Date] [date] NULL,
	[V2] [int] NOT NULL,
	[V3_Date] [date] NULL,
	[V3] [int] NOT NULL,
	[FTD_Date] [date] NULL,
	[FTD] [int] NOT NULL,
	[FTDA] [money] NULL,
	[FirstPosOpen_Date] [date] NULL,
	[FirstPosOpen] [int] NOT NULL,
	[IsVBT] [int] NOT NULL,
	[PlayerStatusID] [int] NULL,
	[PlayerStatus] [varchar](50) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


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


### Upstream `BI_DB_dbo.BI_DB_CIDFirstDates` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CIDFirstDates`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`

# BI_DB_dbo.BI_DB_CIDFirstDates

> Master customer milestone table — tracks the first and last occurrence of every key customer lifecycle event (registration, deposit, trade, login, copy, contact, verification, funded status) with resolved dimension names, serving as the central customer-centric denormalized reference for 32+ downstream BI reports.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple — Dim_Customer (primary identity), Fact_CustomerAction (events), Fact_BillingDeposit (deposit details), Fact_SnapshotCustomer (verification), V_Liabilities (equity), external compliance/appsflyer tables |
| **Refresh** | Daily (SB_Daily) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFirstDates` is the BI layer's central customer milestone tracker. For every valid customer, it records **when** each major lifecycle event first (and last) occurred — registration, first login, first deposit, first trade, first copy, first contact, first verification, first funded date — along with resolved dimension names (country, language, channel, club, manager) so downstream reports can filter and segment without additional JOINs.

The table draws from 13+ DWH source tables via `SP_CIDFirstDates` (1,467 lines). The core identity and demographics come from `DWH_dbo.Dim_Customer`, event timestamps from `Fact_CustomerAction` (filtered by ActionTypeID), deposit details from `Fact_BillingDeposit` via the FTDTransactionID link, and verification milestones from `Fact_SnapshotCustomer`. The "funded" status columns use two inline functions (`Function_Population_Funded`, `Function_Population_First_Time_Funded`) that implement the business definition of "funded" — deposited + verified + traded/received IOB + equity > 0.

The SP runs daily as part of the Service Broker `SB_Daily` process at **Priority 90** (final aggregation wave — runs after nearly all other BI_DB SPs). It uses an incremental update pattern: new customers are INSERTed, existing customers are updated only when dimension attributes change (CDC-style change detection), and event dates are updated only when a new earlier (first) or later (last) event is found. Internal/invalid customers (IsValidCustomer=0) are actively DELETEd. There are 29+ legacy/disabled/nullified columns that remain in the DDL but are no longer populated.

---

## 2. Business Logic

### 2.1 Customer Lifecycle Events

**What**: Each "First*" column captures the earliest occurrence of a customer action; each "Last*" column captures the most recent.

**Columns Involved**: `FirstLoggedIn`, `FirstPosOpenDate`, `FirstDepositDate`, `FirstMirrorRegistrationDate`, `FirstCashierLogin`, `FirstStocksOpenDate`, `FirstCashoutDate`, `FirstTimeBeingCopied`, `FirstContactDate`, and their `Last*` counterparts.

**Rules**:
- Events are sourced from `Fact_CustomerAction` filtered by specific ActionTypeIDs
- ActionTypeID mapping: 1=ManualPosOpen, 2=MirrorPosOpen, 7=Deposit, 8=Cashout, 14=Login, 15=LifeStageEvent, 17=MirrorRegistration, 21=PublishPost, 27=DepositAttempt (FirstCustomerAction), 29=CashierLogin, 34=StocksOpen
- First dates update only when NULL or when new event is earlier than existing
- Last dates update to the most recent occurrence
- `registered` = MIN(RegisteredDemo, RegisteredReal) — whichever happened first

**Diagram**:
```
Registration ─→ Login ─→ Deposit Attempt ─→ First Deposit ─→ First Trade ─→ Funded
     │              │              │                │               │           │
     ▼              ▼              ▼                ▼               ▼           ▼
 registered   FirstLoggedIn  FirstDeposit    FirstDeposit   FirstPosOpen  IsFundedNew
                             Attempt         Date/Amount    Date          FirstNewFundedDate
```

### 2.2 Funded Status Definition

**What**: The business definition of "funded" — a customer who has deposited, is verified, has traded (or received IOB/options trade), and has positive equity.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- `IsFundedNew` = 1 if `Function_Population_Funded(@dateINT)` returns the RealCID. The function checks: depositor (IsDepositor=1) + verified (VerificationLevelID=3) + has activity (trade OR IOB/interest OR options trade) + equity > 0 (from BI_DB_Client_Balance_CID_Level_New + eMoneyClientBalance + Options)
- `FirstNewFundedDate` = GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)) — the latest of the three qualifying criteria
- `LastNewFundedDate` = MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1, coalesced with yesterday's funded check
- "Bad FTDs" (2025-08-18 to 2025-08-20 with Amount=1 and single deposit) are excluded

### 2.3 Deposit Flow (Alias-Level Attribution)

**What**: First deposit details are split across two source paths depending on which column.

**Columns Involved**: `FirstDepositDate`, `FirstDepositAmount`, `FirstDepositProcessor`, `FirstDepositFundingType`

**Rules**:
- `FirstDepositDate` and `FirstDepositAmount` are read **directly from Dim_Customer** (alias `dc` in SP line 604/607). Dim_Customer sources these from `CustomerFinanceDB.Customer.FirstTimeDeposits` with FTDRecoveryDate override logic.
- `FirstDepositProcessor` and `FirstDepositFundingType` are **join-enriched** from `Dim_BillingDepot` and `Dim_FundingType` respectively, via `Fact_BillingDeposit` matched using `dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000))`.
- These are distinct source paths despite appearing in the same SELECT block — the JOIN to Fact_BillingDeposit serves the processor/funding columns, not the date/amount columns.

### 2.4 Change Detection (SCD Update)

**What**: Dimension attributes are only updated when they actually change.

**Columns Involved**: `Club`, `Language`, `CommunicationLanguage`, `Blocked`, `Email`, `BirthDate`, `Gender`, `PotentialDesk`, `Region`, `CountryID`, `State`, `PrivacyPolicyID`, `SubAffiliateID`, `SerialID`, `LabelName`, `Channel`, `SubChannel`, `Verified`, `Manager`, `RegulationID`

**Rules**:
- A `#updatenew` temp table compares every dimension column between the current BI_DB row and the freshly-resolved #CustomerData
- Uses `ISNULL(old,'') <> ISNULL(new,'') COLLATE Latin1_General_BIN` for string comparisons
- Only customers with at least one changed attribute are updated
- `UpdateDate` is set to `GETDATE()` on every modification

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `CID` with a CLUSTERED INDEX on `CID`. Always include `CID` in WHERE clauses or JOINs for optimal Synapse query performance. JOINs to other CID-distributed tables (like BI_DB_Client_Balance_CID_Level_New) will be co-located.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer funnel conversion rates | Filter by `registered` date range, count non-NULL milestone dates (FirstDepositDate, FirstPosOpenDate, etc.) |
| FTD cohort analysis | `WHERE YEAR(FirstDepositDate) != 1900 AND FirstDepositDate BETWEEN @start AND @end` |
| Active funded customers | `WHERE IsFundedNew = 1` |
| Time-to-deposit from registration | `DATEDIFF(DAY, registered, FirstDepositDate) WHERE YEAR(FirstDepositDate) != 1900` |
| Customers never deposited | `WHERE FirstDepositDate IS NULL OR YEAR(FirstDepositDate) = 1900` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | ON CID = CID | Daily balance and P&L metrics |
| BI_DB_dbo.BI_DB_PositionPnL | ON CID = CID | Position-level P&L |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Country details (already resolved as Country column) |
| DWH_dbo.Dim_Regulation | ON RegulationID = RegulationID | Regulation name |

### 3.4 Gotchas

- **Sentinel dates**: `1900-01-01` means "never happened." Always filter with `YEAR(column) != 1900` or `column IS NOT NULL AND column > '1900-01-02'`.
- **29+ dead columns**: Many columns (Demo*, Social*, Model_*, Risk/DepositGroup, PEP*, Retention*, Feed*, etc.) are no longer populated. They remain in the DDL but contain only NULL or stale data. See the "Not Populated / Disabled / Nullified" section in the lineage file.
- **FirstDepositAttemptProcessor/FundingType**: Always contain 'NA' — these are not actually resolved despite the column names. Only the actual first deposit columns (FirstDepositProcessor, FirstDepositFundingType) have real values.
- **Credit/RealizedEquity**: Only updated when @date = @yesterday (the SP's date parameter). These reflect yesterday's V_Liabilities snapshot, not a historical value for the customer.
- **Blocked**: 1 if PlayerStatusID IN (2,4,6,7,8,9), not a direct flag from production.
- **PII columns**: Email, BirthDate, UserName, Gender, IP are PII. Email and IP have dynamic data masking. UC PII table: `pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag | `[UNVERIFIED]`? |
|-------|-------|-----|-----------------|
| 5 stars | Tier 5 (domain expert / glossary) | `(Tier 5 — domain expert)` | No |
| 4 stars | Tier 1 (upstream wiki verbatim) | `(Tier 1 — ...)` | No |
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` | No |
| 2 stars | Tier 3 (live data / sampling) | `(Tier 3 — ...)` | No |
| 1.5 stars | Tier 4-Atlassian | `(Tier 4 — Confluence/Jira)` | No |
| 1 star | Tier 4-Inferred | `[UNVERIFIED] (Tier 4 — inferred)` | **Yes** |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts. (Tier 1 — Customer.CustomerStatic) |
| 3 | OriginalCID | int | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 4 | UserName | varchar(500) | YES | Customer login username. PII — dynamic data masking in UC. (Tier 1 — Customer.CustomerStatic) |
| 5 | Club | varchar(500) | YES | Customer experience tier name. Resolved from Dim_PlayerLevel.Name via PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Diamond, etc. (Tier 2 — SP_CIDFirstDates, Dim_PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired. Sourced from Dim_Customer.AffiliateID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | Internal segment label name. Resolved from Dim_Label.Name via LabelID. (Tier 2 — SP_CIDFirstDates, Dim_Label) |
| 10 | Country | varchar(500) | YES | Country of residence name. Resolved from Dim_Country.Name via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 11 | Language | char(500) | YES | Platform language name. Resolved from Dim_Language.Name via LanguageID. (Tier 2 — SP_CIDFirstDates, Dim_Language) |
| 12 | Region | nvarchar(500) | NO | Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 14 | Email | varchar(500) | YES | Customer email address. PII — masked with `FUNCTION = 'default()'`. (Tier 1 — Customer.CustomerStatic) |
| 15 | Credit | money | YES | Customer credit balance (yesterday's snapshot). From V_Liabilities.Credit, ISNULL(,0). Only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) |
| 16 | RealizedEquity | money | YES | Customer realized equity (yesterday's snapshot). From V_Liabilities.RealizedEquity, ISNULL(,0). Only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) |
| 17 | SocialConnect | int | YES | Social media connection flag. **Disabled** — linked server source removed. Contains stale/NULL data. (Tier 3b — DDL structure, disabled) |
| 18 | Verified | int | YES | Verification level ID. Resolved from Dim_VerificationLevel.ID via VerificationLevelID. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. (Tier 2 — SP_CIDFirstDates, Dim_VerificationLevel) |
| 19 | KYC | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 20 | DocsOK | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 21 | Blocked | int | YES | Account blocked flag. CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0. 2=Suspended, 4=AccountClosed, 6=BlockedByBO, 7=BlockedByRisk, 8=BlockedByPayment, 9=BlockedByCompliance. (Tier 2 — SP_CIDFirstDates) |
| 22 | IsSales | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 23 | HasPic | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 24 | Bankruptcy | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 25 | FunnelName | varchar(500) | YES | Registration funnel name. Resolved from Dim_Funnel.Name via FunnelID. (Tier 2 — SP_CIDFirstDates, Dim_Funnel) |
| 26 | DownloadID | int | YES | Platform download source ID. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 27 | registered | datetime | NO | Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. (Tier 2 — SP_CIDFirstDates) |
| 28 | FirstTimeUser | datetime | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 29 | FirstLoggedIn | datetime | YES | First platform login date. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 30 | FirstDemoLoggedIn | datetime | YES | **Disabled** — demo step disabled 2017-01-26. Contains stale/NULL data. (Tier 3b — DDL structure, disabled) |
| 31 | FirstDemoPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 32 | FirstDemoMirrorRegistrationDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 33 | LastDemoMirrorRegistrationDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 34 | FirstDemoMirrorPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 35 | FirstCashierLogin | datetime | YES | First cashier (deposit page) login. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 36 | FirstDepositAttempt | datetime | YES | First deposit attempt date. From Fact_FirstCustomerAction.FirstOccurred WHERE ActionTypeID=27. (Tier 2 — SP_CIDFirstDates, Fact_FirstCustomerAction) |
| 37 | FirstDepositAttemptAmount | numeric(36,12) | YES | First deposit attempt amount (USD). Amount*ExchangeRate from Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 — SP_CIDFirstDates, Fact_FirstCustomerAction) |
| 38 | FirstDepositAttemptProcessor | varchar(500) | YES | First deposit attempt processor. Always 'NA' — not actually resolved. (Tier 2 — SP_CIDFirstDates) |
| 39 | FirstDepositAttemptFundingType | varchar(500) | YES | First deposit attempt funding type. Always 'NA' — not actually resolved. (Tier 2 — SP_CIDFirstDates) |
| 40 | FirstDepositDate | datetime | YES | First successful deposit date. Read directly from Dim_Customer.FirstDepositDate (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FirstDepositDate) != 1900`. (Tier 2 — SP_Dim_Customer ← CustomerFinanceDB.FirstTimeDeposits) |
| 41 | FirstDepositProcessor | varchar(500) | YES | Payment processor for the first deposit. Resolved from Dim_BillingDepot.Name (alias `dbd`) via Fact_BillingDeposit.DepotID, matched to the FTD record using Dim_Customer.FTDTransactionID = CAST(Fact_BillingDeposit.DepositID AS NVARCHAR(4000)). (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_BillingDepot) |
| 42 | FirstDepositFundingType | varchar(500) | YES | Funding type for the first deposit. Resolved from Dim_FundingType.Name (alias `F`) via Fact_BillingDeposit.FundingTypeID, matched to the FTD record using Dim_Customer.FTDTransactionID = CAST(Fact_BillingDeposit.DepositID AS NVARCHAR(4000)). Values: CreditCard, Wire, PayPal, eToroMoney, IXOPAY-Nuvei, etc. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_FundingType) |
| 43 | FirstDepositAmount | money | YES | Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. (Tier 2 — SP_Dim_Customer ← CustomerFinanceDB.FirstTimeDeposits) |
| 44 | FirstEngagementDate | datetime | YES | **Disabled** — engagement section commented out. (Tier 3b — DDL structure, disabled) |
| 45 | FirstPosOpenDate | datetime | YES | First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 46 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade registration date. Occurred from Fact_CustomerAction WHERE ActionTypeID=17 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 47 | LastMirrorRegistrationDate | datetime | YES | Last copy-trade registration date. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 48 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=2 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 49 | FirstLeadDate | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 50 | FirstDepositAmountExtended | money | YES | **Not populated** by SP. Legacy extended deposit amount. (Tier 3b — DDL structure, not populated) |
| 51 | ReferralID | int | YES | Referral CID — the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 52 | LastDemoLoggedIn | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 53 | LastDemoMirrorPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 54 | LastDemoPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 55 | LastEngagementDate | datetime | YES | **Disabled** — engagement section commented out. (Tier 3b — DDL structure, disabled) |
| 56 | LastLoggedIn | datetime | YES | Last platform login date. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 57 | LastMirrorPosOpenDate | datetime | YES | Last copy-trade position open date. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 58 | LastPosOpenDate | datetime | YES | Last position open date (manual or copy). MAX(Occurred) WHERE ActionTypeID IN (1,2). (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 59 | CertifiedGuru | int | YES | **Not populated** by SP. Legacy Popular Investor flag. (Tier 3b — DDL structure, not populated) |
| 60 | FirstTimeBeingCopied | datetime | YES | First time this customer was copied by another. MIN(OpenOccurred) from Dim_Mirror GROUP BY ParentCID. (Tier 2 — SP_CIDFirstDates, Dim_Mirror) |
| 61 | LastTimeBeingCopied | datetime | YES | Last time this customer was copied. MAX(OpenOccurred) from Dim_Mirror GROUP BY ParentCID. (Tier 2 — SP_CIDFirstDates, Dim_Mirror) |
| 62 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). PII. (Tier 1 — Customer.CustomerStatic) |
| 63 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. (Tier 1 — Customer.CustomerStatic) |
| 64 | FirstMenualPosOpenDate | datetime | YES | First manual (non-copy) position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=1 AND rn=1. Note: column name has typo "Menual". (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 65 | BirthDate | datetime | YES | Customer date of birth. PII. (Tier 1 — Customer.CustomerStatic) |
| 66 | CommunicationLanguage | varchar(500) | YES | Language for customer communications. Resolved from Dim_Language.Name via CommunicationLanguageID. (Tier 2 — SP_CIDFirstDates, Dim_Language) |
| 67 | LastMenualPosOpenDate | datetime | YES | Last manual position open date. MAX(Occurred) WHERE ActionTypeID=1. Note: column name has typo "Menual". (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 68 | FirstTimeSocialConnect | datetime | YES | **Disabled** — social connect section disabled (linked server removed). (Tier 3b — DDL structure, disabled) |
| 69 | LastCashierLogin | datetime | YES | Last cashier (deposit page) login. MAX(Occurred) WHERE ActionTypeID=29. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 70 | FirstCashoutDate | datetime | YES | First withdrawal date. Occurred from Fact_CustomerAction WHERE ActionTypeID=8 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 71 | FunnelFromName | varchar(500) | YES | Source funnel variant name. Resolved from Dim_Funnel.Name via FunnelFromID. (Tier 2 — SP_CIDFirstDates, Dim_Funnel) |
| 72 | BannerID | int | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 73 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate identifier string. Sourced from Dim_Customer.SubSerialID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 74 | FirstCampaignID | nvarchar(1024) | YES | First campaign ID. From External_etoro_History_Credit.CampaignID, ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Occurred)=1. (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 75 | FirstCampaignDate | datetime | YES | First campaign occurrence date. From External_etoro_History_Credit.Occurred (first by date). (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 76 | FirstCampaignAmount | money | YES | First campaign payment amount. From External_etoro_History_Credit.Payment (first by date). (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 77 | FirstStocksOpenDate | datetime | YES | First real stock position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=34 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 78 | SevenDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 79 | FirstToSevenDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 80 | FirstDateRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 81 | LastContactAttemptDate_ByPhone | datetime | YES | Last phone contact attempt date. PII — masked. **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 82 | LastContactDate | datetime | YES | Last successful contact date (email or phone). MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 83 | LastContactAttemptDate | datetime | YES | **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 84 | LastContactDate_ByPhone | datetime | YES | Last successful phone contact date. PII — masked. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 85 | FirstContactAttemptDate | datetime | YES | **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 86 | FirstContactAttemptDate_ByPhone | datetime | YES | **Not directly populated** by SP. PII — masked. Legacy column. (Tier 3b — DDL structure, not populated) |
| 87 | FirstContactDate | datetime | YES | First successful contact date (email or phone). MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 88 | FirstContactDate_ByPhone | datetime | YES | **Not directly populated** by SP. PII — masked. Legacy column. (Tier 3b — DDL structure, not populated) |
| 89 | PremiumAccount | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 90 | Evangelist | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 91 | FirstToThirtyDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 92 | FirstWallEngagement | datetime | YES | **Not populated** by SP. Legacy social wall metric. (Tier 3b — DDL structure, not populated) |
| 93 | FeedUnBlocked | tinyint | YES | **Not populated** by SP. Legacy social feed flag. (Tier 3b — DDL structure, not populated) |
| 94 | PrivacyPolicyID | tinyint | YES | Version of the privacy policy the customer has accepted. (Tier 1 — Customer.CustomerStatic) |
| 95 | IP | bigint | YES | Registration IP address (stored as bigint). PII — masked. (Tier 1 — Customer.CustomerStatic) |
| 96 | FeedUnlocked | tinyint | YES | **Not populated** by SP. Legacy social feed flag. (Tier 3b — DDL structure, not populated) |
| 97 | Follow5UsersDate | datetime | YES | **Not populated** by SP. Legacy social onboarding metric. (Tier 3b — DDL structure, not populated) |
| 98 | NumberOfUsersFollowed | int | YES | **Not populated** by SP. Legacy social metric. (Tier 3b — DDL structure, not populated) |
| 99 | PopularInvestor | int | YES | **Not populated** by SP. Legacy Popular Investor flag. (Tier 3b — DDL structure, not populated) |
| 100 | Manager | nvarchar(500) | YES | Account manager full name. Resolved from Dim_Manager: FirstName+' '+LastName via AccountManagerID. (Tier 2 — SP_CIDFirstDates, Dim_Manager) |
| 101 | SuitabilityTestCompletedAt | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 102 | PassedSuitabilityTest | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 103 | Model_FTDsOTDs | float | YES | **Not populated** by SP. Legacy ML model prediction score. (Tier 3b — DDL structure, not populated) |
| 104 | Model_Leads | float | YES | **Not populated** by SP. Legacy ML model prediction score. (Tier 3b — DDL structure, not populated) |
| 105 | LastDepositDate | datetime | YES | Last deposit date. Fact_BillingDeposit.ModificationDate from #fundingLast WHERE rn_desc=1 (latest by Occurred). (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit) |
| 106 | LastDepositAmount | money | YES | Last deposit amount in USD. Amount*ExchangeRate from Fact_BillingDeposit via #fundingLast WHERE rn_desc=1. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit) |
| 107 | LastDepositFundingType | varchar(500) | YES | Last deposit funding type. Resolved from Dim_FundingType.Name via Fact_BillingDeposit.FundingTypeID from #fundingLast. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_FundingType) |
| 108 | Model_ReDepositor | money | YES | **Not populated** by SP. Legacy ML model prediction. (Tier 3b — DDL structure, not populated) |
| 109 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 — BackOffice.Customer) |
| 110 | RiskGroup | varchar(500) | YES | **Disabled** — risk group section disabled 2023-05-09. Contains stale data. (Tier 3b — DDL structure, disabled) |
| 111 | DepositGroup | varchar(500) | YES | **Disabled** — deposit group section disabled 2023-05-09. Contains stale data. (Tier 3b — DDL structure, disabled) |
| 112 | UpdateDate | datetime | YES | ETL load timestamp — set to GETDATE() on each row insert or update. (Tier 2 — SP_CIDFirstDates) |
| 113 | VerificationLevel1Date | datetime | YES | First date customer reached verification level 1. MIN(FromDateID) from Fact_SnapshotCustomer WHERE VerificationLevelID=1 via Dim_Range. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 114 | VerificationLevel2Date | datetime | YES | First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 115 | VerificationLevel3Date | datetime | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 1

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

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


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_CID_Daily_AcquisitionFunnel_VBT`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CID_Daily_AcquisitionFunnel_VBT.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_CID_Daily_AcquisitionFunnel_VBT] @date [DATE] AS
BEGIN
-- declare @date date = cast(getdate()-1 as date)
DECLARE @DateINT INT = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

/*****************************************VBT CIDs*************************************************************************/


IF OBJECT_ID('tempdb..#VBT_CIDs') IS NOT NULL DROP TABLE #VBT_CIDs
CREATE TABLE #VBT_CIDs
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT DISTINCT GCID 
FROM (SELECT k.GCID
	FROM [BI_DB_dbo].[External_ComplianceStateDB_Compliance_KycFlow] k 
	WHERE k.KYCFlowTypeID = 2 
	UNION 
	SELECT h.GCID
	FROM [BI_DB_dbo].[External_ComplianceStateDB_History_KycFlow] h  
	WHERE h.KYCFlowTypeID = 2) a


/*****************************************All Relevant CIDs****************************************************************/


IF OBJECT_ID('tempdb..#CIDs') IS NOT NULL DROP TABLE #CIDs
CREATE TABLE #CIDs
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT sc.RealCID AS CID
	,fd.PotentialDesk Desk
	,fd.Region
	,fd.Country
	,fd.Channel
	,fd.SubChannel
	,dr1.Name Regulation
	,dr2.Name DesignatedRegulation
	,CAST(fd.registered as DATE) Reg_Date
	,CASE WHEN CAST(fd.registered AS date) = @date THEN 1 ELSE 0 END AS Registration
	,CAST(fd.VerificationLevel2Date as DATE) V2_Date
	,CASE WHEN CAST(fd.VerificationLevel2Date AS date) = @date THEN 1 ELSE 0 END AS V2
	,CAST(fd.VerificationLevel3Date as DATE) V3_Date
	,CASE WHEN CAST(fd.VerificationLevel3Date AS date) = @date THEN 1 ELSE 0 END AS V3
	,CAST(fd.FirstDepositDate AS date) AS FTD_Date
	,CASE WHEN CAST(fd.FirstDepositDate AS date) = @date THEN 1 ELSE 0 END AS FTD
	,fd.FirstDepositAmount AS FTDA
	,CAST(fd.FirstPosOpenDate AS date) AS FirstPosOpen_Date
	,CASE WHEN CAST(fd.FirstPosOpenDate AS date) = @date THEN 1 ELSE 0 END AS FirstPosOpen
	,CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1 END AS IsVBT
	,sc.PlayerStatusID
	,ps.Name PlayerStatus
FROM [DWH_dbo].[Fact_SnapshotCustomer] sc WITH(NOLOCK)
	JOIN [DWH_dbo].[Dim_Range] dr WITH(NOLOCK)
		ON dr.DateRangeID = sc.DateRangeID
	JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH(NOLOCK)
		ON fd.CID = sc.RealCID
	LEFT JOIN [DWH_dbo].[Dim_PlayerStatus] ps WITH(NOLOCK)
		ON sc.PlayerStatusID = ps.PlayerStatusID
	LEFT JOIN #VBT_CIDs vbt
		ON sc.GCID = vbt.GCID
	LEFT JOIN [DWH_dbo].[Dim_Regulation] dr1 WITH(NOLOCK)
		ON sc.RegulationID = dr1.DWHRegulationID
	LEFT JOIN [DWH_dbo].[Dim_Regulation] dr2 WITH(NOLOCK)
		ON sc.DesignatedRegulationID = dr2.DWHRegulationID
WHERE sc.IsValidCustomer = 1
	AND sc.PlayerStatusID NOT IN (2,4,13)
	AND @DateINT BETWEEN dr.FromDateID AND dr.ToDateID
	AND (CASE WHEN CAST(fd.registered AS date) = @date THEN 1 ELSE 0 END = 1 
		OR CASE WHEN CAST(fd.VerificationLevel2Date AS date) = @date THEN 1 ELSE 0 END = 1 
		OR CASE WHEN CAST(fd.VerificationLevel3Date AS date) = @date THEN 1 ELSE 0 END = 1 
		OR CASE WHEN CAST(fd.FirstDepositDate AS date) = @date THEN 1 ELSE 0 END = 1 
		OR CASE WHEN CAST(fd.FirstPosOpenDate AS date) = @date THEN 1 ELSE 0 END = 1)

/*************************************Insert INTO BI_DB Table****************************************************************/

DELETE FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT]
WHERE [Date] = @date

INSERT INTO [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT] (
	 [CID]
	,[Date]
	,[DateID]
	,[YearMonth]
	,[Desk]
	,[Region]
	,[Country]
	,[Channel]
	,[SubChannel]
	,[Regulation]
	,[DesignatedRegulation]
	,[Reg_Date]
	,[Registration]
	,[V2_Date]
	,[V2]
	,[V3_Date]
	,[V3]
	,[FTD_Date]
	,[FTD]
	,[FTDA]
	,[FirstPosOpen_Date]
	,[FirstPosOpen]
	,[IsVBT]
	,[PlayerStatusID]
	,[PlayerStatus]
	,[UpdateDate]
	)

SELECT c.CID
	,@date AS [Date]
	,@DateINT DateID	  	
	,YEAR(@date) * 100 + MONTH(@date) AS YearMonth
	,c.Desk
	,c.Region
	,c.Country
	,c.Channel
	,c.SubChannel
	,c.Regulation
	,c.DesignatedRegulation
	,c.Reg_Date
	,c.Registration
	,c.V2_Date
	,c.V2
	,c.V3_Date
	,c.V3
	,c.FTD_Date
	,c.FTD
	,c.FTDA
	,c.FirstPosOpen_Date
	,c.FirstPosOpen
	,c.IsVBT
	,c.PlayerStatusID
	,c.PlayerStatus
	,GETDATE()
FROM #CIDs c


END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_CID_Daily_AcquisitionFunnel_VBT` | synapse_sp | BI_DB_dbo | SP_CID_Daily_AcquisitionFunnel_VBT | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_CID_Daily_AcquisitionFunnel_VBT.sql` |
| `BI_DB_dbo.External_ComplianceStateDB_Compliance_KycFlow` | unresolved | BI_DB_dbo | External_ComplianceStateDB_Compliance_KycFlow | `—` |
| `BI_DB_dbo.External_ComplianceStateDB_History_KycFlow` | unresolved | BI_DB_dbo | External_ComplianceStateDB_History_KycFlow | `—` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | synapse | BI_DB_dbo | BI_DB_CIDFirstDates | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `DWH_dbo.Dim_PlayerStatus` | synapse | DWH_dbo | Dim_PlayerStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
