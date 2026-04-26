# BI_DB_dbo.BI_DB_Affiliate_Guidlines_Report

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Affiliate_Guidlines_Report |
| **Refresh Pattern** | TRUNCATE + INSERT daily (no date parameter — full refresh) |
| **Frequency** | Daily |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | HASH (CID) |
| **Index** | CLUSTERED INDEX (CID ASC) |
| **Row Count** | ~71,336 rows (2026-04-23 sample) |
| **Columns** | 29 |

> **Note**: The table name contains a typo — "Guidlines" instead of "Guidelines" — preserved from the original SP/table definition.

---

## Summary

Daily snapshot of etoro customers who are linked to fiktivo affiliate partners. One row per customer × affiliate relationship, containing both the customer's account status (KYC, verification, account type, screening) and the affiliate's profile (contract type, payment details, marketing category). Used by the Affiliate team for compliance reporting and affiliate guidelines monitoring.

Grain: one row per customer × affiliate pairing. Customers with no affiliate linkage are excluded. Some customers appear in multiple rows if linked to multiple affiliates (~1,459 duplicates: 71,336 rows vs 69,877 distinct CIDs).

---

## Business Context

Supports affiliate program compliance and reporting by joining:
1. **etoro customer attributes** — KYC status, verification level, document dates, screening status, account type
2. **fiktivo affiliate profile** — contract type, marketing expense category, payment details, login names

The table is used to verify that affiliate-acquired customers meet compliance requirements ("guidelines") — hence the name. Key use cases:
- Monitoring KYC completion for affiliate-acquired customers
- Checking document expiry and utility bill submission
- Tracking screening outcomes for affiliate populations
- Reporting to affiliates on their customers' compliance status

**Population scope**: All etoro customers who can be matched to a fiktivo affiliate record via username lookup in Dim_Customer. The match is performed by comparing fiktivo payment usernames (UserName1/2/3) and login name (UserName4) against etoro's Dim_Customer.UserName (lowercase). If no username match is found, TradingAccount_CID=0 and the customer row is excluded from the final join.

---

## ETL / Refresh

**Pattern**: TRUNCATE → INSERT — full daily refresh, no history retained.

**Key join logic**:
```
fiktivo affiliate → etoro customer matching:
  UserName1 → Dim_Customer.UserName (lowercase, COLLATE Latin1_General_100_BIN)
  UserName2 → same fallback if UserName1 has no match
  UserName3 → same fallback if UserName1 and UserName2 have no match
  TradingAccount_CID = ISNULL(first matching CID, 0)
```

The final INSERT filters to customers WHERE CID = TradingAccount_CID — customers with no username match (TradingAccount_CID=0) produce no output rows.

**Document type codes** (from External_etoro_BackOffice_CustomerDocumentToDocumentType):
- DocumentTypeID = 1: Utility bill (IssueDate → UtilityBill_Date)
- DocumentTypeID = 2: ID document, e.g. passport (ExpiryDate → ExpiryDate)

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | CID | int NULL | T1 — Customer.CustomerStatic | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. |
| 2 | Aff_ID | int NULL | T1 — Customer.CustomerStatic | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. Sourced from Dim_Customer.AffiliateID. NULL for direct/organic registrations. |
| 3 | AccountTypeName | varchar(50) NULL | T1 — Dictionary.AccountType | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. |
| 4 | CustomerStatus | varchar(50) NULL | T1 — Dictionary.PlayerStatus | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. |
| 5 | ExpiryDate | datetime NULL | T2 — SP_Affiliate_Guidlines_Report | Latest expiry date of the customer's ID documents (DocumentTypeID=2, e.g. passport). MAX(ExpiryDate) from External_etoro_BackOffice_CustomerDocument. NULL if no ID document on file. |
| 6 | UtilityBill_Date | datetime NULL | T2 — SP_Affiliate_Guidlines_Report | Latest issue date of the customer's utility bill documents (DocumentTypeID=1). MAX(IssueDate) from External_etoro_BackOffice_CustomerDocument. NULL if no utility bill on file. |
| 7 | KYC_filled | int NULL | T2 — SP_Affiliate_Guidlines_Report | **Always NULL.** Intended to count KYC questions answered by the customer (from UserApiDB.KYC.CustomerAnswers) but the source query is commented out in the SP. Do not use this column — it carries no data. |
| 8 | VerificationLevelID | int NULL | T1 — BackOffice.Customer | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. |
| 9 | PhoneVerified | varchar(50) NULL | T1 — Dictionary.PhoneVerified | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" — a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards. |
| 10 | Registered | datetime NULL | T1 — Customer.CustomerStatic | Account registration date (renamed from RegisteredReal in Dim_Customer). Sourced as Dim_Customer.RegisteredReal. Default=getdate(). |
| 11 | CashoutFeeGroup | varchar(50) NULL | T1 — Dictionary.CashoutFeeGroup | Human-readable fee group name: 'Default', 'Exempt', 'Discount'. Renamed from production Name column. Used in reporting to display the customer's cashout fee group. |
| 12 | TradingAccount_CID | int NULL | T2 — SP_Affiliate_Guidlines_Report | The etoro CID matched to the affiliate's fiktivo account via username lookup. Resolved by comparing fiktivo's UserName1/UserName2/UserName3 (lowercased) against Dim_Customer.UserName. Defaults to 0 if no username match found. Rows where TradingAccount_CID=0 are excluded from final output. |
| 13 | AffiliateID | int NULL | T1 — fiktivo.tblaff_Affiliates | Fiktivo's internal primary key for the affiliate record. Distinct from etoro's Aff_ID (which is the affiliate's customer-side identifier). Used to join back to fiktivo affiliate master data. |
| 14 | DateCreated | datetime NULL | T1 — fiktivo.tblaff_Affiliates | Date and time the affiliate account was created in fiktivo. Direct passthrough from fiktivo.dbo.tblaff_Affiliates.DateCreated. |
| 15 | AW_UserName | nvarchar(50) NULL | T1 — fiktivo.tblaff_Affiliates | Affiliate's fiktivo login name (from tblaff_Affiliates.LoginName), converted to NVARCHAR(24). Used for affiliate authentication and identification in the fiktivo affiliate management system. |
| 16 | ContractType | nvarchar(100) NULL | T1 — fiktivo.tblaff_AffiliateTypes | Affiliate contract type description. Sourced from fiktivo.dbo.tblaff_AffiliateTypes.Description via the affiliate's AffiliateTypeID. Describes the commercial arrangement (e.g. CPA, Revenue Share). |
| 17 | MarketingExpenseName | nvarchar(50) NULL | T1 — fiktivo.tblaff_MarketingExpense | Marketing expense category assigned to the affiliate. Sourced from fiktivo.dbo.tblaff_MarketingExpense.MarketingExpenseName. NULL if no marketing expense category is assigned. |
| 18 | Contact | nvarchar(255) NULL | T1 — fiktivo.tblaff_Affiliates | Affiliate contact information (email or phone) as stored in fiktivo.dbo.tblaff_Affiliates.Contact. |
| 19 | AffiliateCustom1 | nvarchar(255) NULL | T1 — fiktivo.tblaff_Affiliates | Custom free-text field 1 from fiktivo.dbo.tblaff_Affiliates.AffiliateCustom1. Usage varies by affiliate; populated at affiliate onboarding. |
| 20 | AccountActivated | int NULL | T1 — fiktivo.tblaff_Affiliates | Whether the fiktivo affiliate account is active. CAST from bit: 1=activated, 0=not activated. Direct passthrough from fiktivo.dbo.tblaff_Affiliates.AccountActivated. |
| 21 | UserName1 | varchar(50) NULL | T1 — fiktivo.tblaff_PaymentDetails | Lowercased etoro username from the affiliate's first payment details slot (pd1.Username), collated Latin1_General_100_BIN. Defaults to '''' (escaped empty string) if no first payment details record exists. Used for etoro ↔ fiktivo username matching. |
| 22 | UserName2 | varchar(50) NULL | T1 — fiktivo.tblaff_PaymentDetails | Lowercased etoro username from the affiliate's second payment details slot (pd2.Username). Defaults to '''' if no second payment details record exists. |
| 23 | UserName3 | varchar(50) NULL | T1 — fiktivo.tblaff_PaymentDetails | Lowercased etoro username from the affiliate's third payment details slot (pd3.Username). Defaults to '''' if no third payment details record exists. |
| 24 | UserName4 | nvarchar(50) NULL | T1 — fiktivo.tblaff_Affiliates | Affiliate's fiktivo LoginName, lowercased and collated Latin1_General_100_BIN. Used as a fallback matching field against etoro usernames. |
| 25 | PaymentDetailsDefault | int NULL | T1 — fiktivo.tblaff_Affiliates | Which payment details slot is the affiliate's default: 1=pd1, 2=pd2, 3=pd3. Direct passthrough from fiktivo.dbo.tblaff_Affiliates.PaymentDetailsDefault. |
| 26 | PaymentMethodID | int NULL | T2 — SP_Affiliate_Guidlines_Report | Payment method ID for the affiliate's default payment slot. CASE on PaymentDetailsDefault to select from pd1, pd2, or pd3.PaymentMethodID. NULL if no matching payment slot exists. |
| 27 | UpdateDate | datetime NULL | Propagation | ETL metadata: date when this row was inserted (CONVERT(DATE, GETDATE())). Note: stored as date-only despite the datetime column type in DDL. |
| 28 | ScreeningStatusID | int NULL | T1 — ScreeningService.Dictionary.ScreeningStatus | Primary key for screening outcome. Renamed from production ID column by ETL. 0=Unknown, 1=NoMatch, 2=PendingInvestigation, 3=PEP, 4=RiskMatch, 5=Technical, 6=MultipleMatch, 7=SanctionsMatch. |
| 29 | ScreeningStatus | varchar(50) NULL | T1 — ScreeningService.Dictionary.ScreeningStatus | Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. |

---

## Data Quality / Known Issues

### KYC_filled Is Always NULL

**Severity**: Medium — the column carries no data

The SP contains commented-out code that would populate `KYC_filled` from `UserApiDB.KYC.CustomerAnswers` (count of answered KYC questions per GCID). Both the direct query and the linked-server openquery variants are disabled:

```sql
-- isnull(qa.QuestionsAnswered, 0) As KYC_filled,  -- DISABLED
NULL As KYC_filled,  -- current code
```

Any downstream report relying on this column for KYC completion status will see NULL for all rows. Consider either re-enabling the source (if UserApiDB is accessible via a supported connection) or removing the column.

### UpdateDate Type Mismatch

`UpdateDate` is `datetime` in DDL but the SP inserts `CONVERT(DATE, GetDate())` — a date-only value. The time component will always be `00:00:00`. This is a minor schema discrepancy.

### TradingAccount_CID = 0 for Unmatched Affiliates

When no etoro customer can be matched to a fiktivo affiliate via username lookup, `TradingAccount_CID = 0`. The final INSERT filters these out via an inner join, so rows with `TradingAccount_CID=0` do not appear in the table. However, the count of unmatched affiliates is not logged anywhere.

### Duplicate Customers

~1,459 customer CIDs appear in more than one row (71,336 rows vs 69,877 distinct CIDs), indicating some customers are linked to multiple fiktivo affiliates. Downstream consumers aggregating at CID level must use DISTINCT or handle duplicates.

---

## Lineage

Full column-level lineage: [BI_DB_Affiliate_Guidlines_Report.lineage.md](./BI_DB_Affiliate_Guidlines_Report.lineage.md)

**Tier Summary**: 23 Tier 1, 5 Tier 2, 1 Propagation

**Upstream sources**:
- `DWH_dbo.Dim_Customer` → CID, Aff_ID, VerificationLevelID, Registered, PhoneVerifiedID, AccountTypeID, CashoutFeeGroupID, ScreeningStatusID
- `DWH_dbo.Dim_AccountType` → AccountTypeName
- `DWH_dbo.Dim_PlayerStatus` → CustomerStatus
- `DWH_dbo.Dim_PhoneVerified` → PhoneVerified
- `DWH_dbo.Dim_CashoutFeeGroup` → CashoutFeeGroup
- `DWH_dbo.Dim_ScreeningStatus` → ScreeningStatusID, ScreeningStatus
- `BI_DB_dbo.External_etoro_BackOffice_CustomerDocument` → ExpiryDate, UtilityBill_Date
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_Affiliates` → AffiliateID, DateCreated, AW_UserName, Contact, AffiliateCustom1, AccountActivated, UserName4, PaymentDetailsDefault
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_AffiliateTypes` → ContractType
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_MarketingExpense` → MarketingExpenseName
- `BI_DB_dbo.External_fiktivo_dbo_tblaff_PaymentDetails` → UserName1, UserName2, UserName3, PaymentMethodID
