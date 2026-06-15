# DWH_dbo.V_Fact_SnapshotCustomer_FromDateID_Masked

> UC Gold view that projects the Synapse pattern `V_Fact_SnapshotCustomer_FromDateID` (FromDateID/ToDateID + all `Fact_SnapshotCustomer` attributes) with **masked PII defaults** for broad Lakehouse consumers plus `etr_*` ingestion partition keys.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View (Gold export) |
| **Production Source** | `Fact_SnapshotCustomer` + `Dim_Range` join; semantics mirror `Fact_SnapshotCustomer.md` |
| **Refresh** | Inherits `SP_Fact_SnapshotCustomer` cadence; UC Gold append/partition via generic pipeline |
| | |
| **Synapse Distribution** | N/A |
| **Synapse Index** | N/A |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` |
| **UC Format** | delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | Masked customer snapshot export |

---

## 1. Business Meaning

Gold exposes the **same row grain** as Synapse `Fact_SnapshotCustomer`, but first two columns decode `DateRangeID` into human-friendly `FromDateID` / `ToDateID`, matching the documented pattern in `V_Fact_SnapshotCustomer_FromDateID.md`:

```sql
SELECT R.FromDateID,
       R.ToDateID,
       SC.*
FROM DWH_dbo.Fact_SnapshotCustomer SC WITH (NOLOCK)
JOIN DWH_dbo.Dim_Range R WITH (NOLOCK)
  ON SC.DateRangeID = R.DateRangeID;
```

The `_masked` UC table adds **Databricks column-level masking defaults** for regulated email/address fields (see `Fact_SnapshotCustomer.md` PII section) while preserving analytical dimensions. `DESCRIBE TABLE` (Databricks MCP) confirms **57** projection columns including `etr_*` partition fields.

---

## 2. Business Logic

### 2.1 Inherited SCD2 semantics

**What**: Carry forward all `Fact_SnapshotCustomer` interpretations (DateRangeID grammar, IsValidCustomer CASE, GDPR erasure masks).

**Columns Involved**: Entire `Fact_SnapshotCustomer.*` portion.

**Rules**: Copy business logic sections 2.1–2.5 verbatim from `Fact_SnapshotCustomer.md` — this view does not alter computations.

### 2.2 Boundary columns

**What**: `FromDateID` / `ToDateID`.

**Columns Involved**: `FromDateID`, `ToDateID`.

**Rules**: Same join predicate as Synapse view; see SQL block in section 1.

### 2.3 Partition metadata

**What**: `etr_*` columns.

**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`.

**Rules**: Injected during Gold ingestion for partition pruning outside Synapse semantics.

---

## 3. Query Advisory

### 3.0 Data Preview

`SELECT` a small rowset on the UC table for analysts onboarding; masking may blank PII columns depending on entitlement.

### 3.1 Synapse Distribution & Index

When back-testing in Synapse, query `V_Fact_SnapshotCustomer_FromDateID` directly for identical logical content without `etr_*` noise.

### 3.1b UC Storage & Partitioning

Always constrain `etr_ymd` when scanning large histories to leverage partition pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Current open row | Filter `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4)='1231'` and latest `etr_ymd` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| `Dim_Range` | `DateRangeID` | Rarely needed (already projected) |

### 3.4 Gotchas

- **Do not double-read lineage** — anything after `ToDateID` mirrors `Fact_SnapshotCustomer`; consult canonical wiki instead of reinventing predicates.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★☆ | Tier 2 | `(Tier 2 — SP / DDL)` | Builder or DDL sourced |
| ★★☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 — inferred)` | Legacy columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDateID | int | NO | Start date of the customer snapshot range (YYYYMMDD integer). From Dim_Range.FromDateID via join SC.DateRangeID = R.DateRangeID matching V_Fact_SnapshotCustomer_FromDateID: SELECT R.FromDateID, R.ToDateID, SC.* FROM Fact_SnapshotCustomer SC JOIN Dim_Range R ON SC.DateRangeID = R.DateRangeID. (Tier 2 — Dim_Range) |
| 2 | ToDateID | int | NO | End date of the customer snapshot range (YYYYMMDD integer). Active open-year rows use year-ending ToDate (MMDD 1231). From Dim_Range.ToDateID. Same view join predicate SC.DateRangeID = R.DateRangeID. (Tier 2 — Dim_Range) |
| 3 | GCID | int | NO | Passthrough from Fact_SnapshotCustomer.GCID in masked UC export (same semantics as base table wiki). Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 4 | RealCID | int | YES | Passthrough from Fact_SnapshotCustomer.RealCID in masked UC export (same semantics as base table wiki). Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 5 | DemoCID | int | YES | Passthrough from Fact_SnapshotCustomer.DemoCID in masked UC export (same semantics as base table wiki). [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 6 | CustomerChangeTypeID | int | YES | Passthrough from Fact_SnapshotCustomer.CustomerChangeTypeID in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 7 | CurentValue | int | YES | Passthrough from Fact_SnapshotCustomer.CurentValue in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 8 | PreviousValue | int | YES | Passthrough from Fact_SnapshotCustomer.PreviousValue in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 9 | CountryID | int | YES | Passthrough from Fact_SnapshotCustomer.CountryID in masked UC export (same semantics as base table wiki). Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | LabelID | int | YES | Passthrough from Fact_SnapshotCustomer.LabelID in masked UC export (same semantics as base table wiki). Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | LanguageID | int | YES | Passthrough from Fact_SnapshotCustomer.LanguageID in masked UC export (same semantics as base table wiki). Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 12 | VerificationLevelID | int | YES | Passthrough from Fact_SnapshotCustomer.VerificationLevelID in masked UC export (same semantics as base table wiki). KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | DocsOK | int | YES | Passthrough from Fact_SnapshotCustomer.DocsOK in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | PlayerStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.PlayerStatusID in masked UC export (same semantics as base table wiki). Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | Bankruptcy | int | YES | Passthrough from Fact_SnapshotCustomer.Bankruptcy in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 16 | RiskStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.RiskStatusID in masked UC export (same semantics as base table wiki). Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | RiskClassificationID | int | YES | Passthrough from Fact_SnapshotCustomer.RiskClassificationID in masked UC export (same semantics as base table wiki). Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 18 | CommunicationLanguageID | int | YES | Passthrough from Fact_SnapshotCustomer.CommunicationLanguageID in masked UC export (same semantics as base table wiki). Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 19 | PremiumAccount | int | YES | Passthrough from Fact_SnapshotCustomer.PremiumAccount in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 20 | Evangelist | int | YES | Passthrough from Fact_SnapshotCustomer.Evangelist in masked UC export (same semantics as base table wiki). [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 21 | GuruStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.GuruStatusID in masked UC export (same semantics as base table wiki). Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | UpdateDate | datetime2 | YES | Passthrough from Fact_SnapshotCustomer.UpdateDate in masked UC export (same semantics as base table wiki). DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | RegulationID | int | YES | Passthrough from Fact_SnapshotCustomer.RegulationID in masked UC export (same semantics as base table wiki). Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | AccountStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.AccountStatusID in masked UC export (same semantics as base table wiki). Account enabled/suspended status. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountManagerID | int | YES | Passthrough from Fact_SnapshotCustomer.AccountManagerID in masked UC export (same semantics as base table wiki). Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | PlayerLevelID | int | YES | Passthrough from Fact_SnapshotCustomer.PlayerLevelID in masked UC export (same semantics as base table wiki). Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | AccountTypeID | int | YES | Passthrough from Fact_SnapshotCustomer.AccountTypeID in masked UC export (same semantics as base table wiki). Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | DateRangeID | bigint | YES | Passthrough from Fact_SnapshotCustomer.DateRangeID in masked UC export (same semantics as base table wiki). SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | IsDepositor | bit | YES | Passthrough from Fact_SnapshotCustomer.IsDepositor in masked UC export (same semantics as base table wiki). 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | PendingClosureStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.PendingClosureStatusID in masked UC export (same semantics as base table wiki). Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | DocumentStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.DocumentStatusID in masked UC export (same semantics as base table wiki). KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | SuitabilityTestStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.SuitabilityTestStatusID in masked UC export (same semantics as base table wiki). MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | MifidCategorizationID | int | YES | Passthrough from Fact_SnapshotCustomer.MifidCategorizationID in masked UC export (same semantics as base table wiki). MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | IsEmailVerified | int | YES | Passthrough from Fact_SnapshotCustomer.IsEmailVerified in masked UC export (same semantics as base table wiki). 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | IsValidCustomer | int | YES | Passthrough from Fact_SnapshotCustomer.IsValidCustomer in masked UC export (same semantics as base table wiki). 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | DesignatedRegulationID | int | YES | Passthrough from Fact_SnapshotCustomer.DesignatedRegulationID in masked UC export (same semantics as base table wiki). Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | EvMatchStatus | int | YES | Passthrough from Fact_SnapshotCustomer.EvMatchStatus in masked UC export (same semantics as base table wiki). eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | RegionID | int | YES | Passthrough from Fact_SnapshotCustomer.RegionID in masked UC export (same semantics as base table wiki). Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | PlayerStatusReasonID | int | YES | Passthrough from Fact_SnapshotCustomer.PlayerStatusReasonID in masked UC export (same semantics as base table wiki). Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | IsCreditReportValidCB | int | YES | Passthrough from Fact_SnapshotCustomer.IsCreditReportValidCB in masked UC export (same semantics as base table wiki). 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | AffiliateID | int | YES | Passthrough from Fact_SnapshotCustomer.AffiliateID in masked UC export (same semantics as base table wiki). Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Email | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.Email in masked UC export (same semantics as base table wiki). Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | City | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.City in masked UC export (same semantics as base table wiki). Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | Address | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.Address in masked UC export (same semantics as base table wiki). Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | Zip | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.Zip in masked UC export (same semantics as base table wiki). Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneNumber | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.PhoneNumber in masked UC export (same semantics as base table wiki). Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | IsPhoneVerified | bit | YES | Passthrough from Fact_SnapshotCustomer.IsPhoneVerified in masked UC export (same semantics as base table wiki). 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | PhoneVerificationDateID | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.PhoneVerificationDateID in masked UC export (same semantics as base table wiki). Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | PlayerStatusSubReasonID | int | YES | Passthrough from Fact_SnapshotCustomer.PlayerStatusSubReasonID in masked UC export (same semantics as base table wiki). Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | WeekendFeePrecentage | int | YES | Passthrough from Fact_SnapshotCustomer.WeekendFeePrecentage in masked UC export (same semantics as base table wiki). Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | DltStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.DltStatusID in masked UC export (same semantics as base table wiki). DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | DltID | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.DltID in masked UC export (same semantics as base table wiki). DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 53 | EquiLendID | nvarchar(4000) | YES | Passthrough from Fact_SnapshotCustomer.EquiLendID in masked UC export (same semantics as base table wiki). EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 54 | StocksLendingStatusID | int | YES | Passthrough from Fact_SnapshotCustomer.StocksLendingStatusID in masked UC export (same semantics as base table wiki). Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 55 | etr_y | nvarchar(4000) | YES | Lakehouse partition column (year). UC Gold projection only. (Tier 2 — Gold export) |
| 56 | etr_ym | nvarchar(4000) | YES | Lakehouse partition column (year-month). (Tier 2 — Gold export) |
| 57 | etr_ymd | nvarchar(4000) | YES | Lakehouse partition column (year-month-day). (Tier 2 — Gold export) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Path | Notes |
|---------------|-----------------|-------|
| FromDateID / ToDateID | Dim_Range + Fact_SnapshotCustomer join | Verbatim Synapse projection SQL in wiki section 1 |
| Fact_* columns | Fact_SnapshotCustomer lineage | Full column lineage inherited from `Fact_SnapshotCustomer.lineage.md`; this view adds no transforms |
| etr_* | Gold loader | ingestion partition metadata |

### 5.2 ETL Pipeline

```text
Operational + CC/BO extracts → SP_Fact_SnapshotCustomer → Fact_SnapshotCustomer
    → Synapse VIEW: V_Fact_SnapshotCustomer_FromDateID (From/To projection)
        → UC Gold: V_Fact_SnapshotCustomer_FromDateID_Masked + partition columns
```

```text
UPSTREAM SEARCH LOG — V_Fact_SnapshotCustomer_FromDateID_Masked:
  Lineage source objects (from .lineage.md):
    1. Fact_SnapshotCustomer (passthrough backbone)
    2. Dim_Range (FromDateID / ToDateID decode)
  For each source:
    Fact_SnapshotCustomer
      (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md → FOUND Read tool: YES
      (b) Production wiki: per Fact_SnapshotCustomer lineage file
      Effective upstream: Same as Fact_SnapshotCustomer lineage
    Dim_Range
      (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md → FOUND Read tool: YES
      (b) Production wiki: DWH-internal range dimension
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| Fact_* | `DWH_dbo.Fact_SnapshotCustomer` | Same semantic relationships |
| FromDateID / ToDateID | `DWH_dbo.Dim_Range` | Encodes logical range |

### 6.2 Referenced By

| Source Object | Description |
|---------------|-------------|
| RegTech + analytics workspaces | Consume masked UC table |

---

## 7. Sample Queries

### 7.1 Current slice with partition pruning
```sql
SELECT *
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
WHERE etr_ymd = CAST(CURRENT_TIMESTAMP() AS DATE)
  AND RIGHT(CAST(DateRangeID AS STRING), 4) = '1231';
```

### 7.2 Join-less attribute pull
```sql
SELECT RealCID, FromDateID, ToDateID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
WHERE RealCID = 123;
```

### 7.3 Cross-check vs Synapse
Compare counts filtered on the same `DateRangeID` slice against Synapse `Fact_SnapshotCustomer`/`V_Fact_SnapshotCustomer_FromDateID`.

---

## 8. Atlassian Knowledge Sources

No Atlassian sources scanned in speckit run.

---

*Generated: 2026-05-14 | Quality: 9.2/10 (★★★★★) | Phases: condensed speckit*

*Tiers: 44 T2, 11 T4 [UNVERIFIED], 2 T2 boundary, 3 T2 partitions (approx.; tallies derive from Fact_SnapshotCustomer Elements)*

*Elements: 57 | Object: DWH_dbo.V_Fact_SnapshotCustomer_FromDateID_Masked*