# Lineage: BI_DB_dbo.BI_DB_Affiliate_Guidlines_Report

**Writer SP**: `SP_Affiliate_Guidlines_Report` (Priority 0, Daily)
**Pattern**: TRUNCATE + INSERT daily (no date parameter — full refresh)
**UC Target**: `_Not_Migrated`

## ETL Chain

```
External_etoro_BackOffice_CustomerDocument (DocumentTypeID=2)
  JOIN External_etoro_BackOffice_CustomerDocumentToDocumentType
    → #CustomerDocumentExpiryDate (MAX(ExpiryDate) per CID — ID documents)

External_etoro_BackOffice_CustomerDocument (DocumentTypeID=1)
  JOIN External_etoro_BackOffice_CustomerDocumentToDocumentType
    → #CustomerDocumentUtilityBill_Date (MAX(IssueDate) per CID — utility bills)

External_fiktivo_dbo_tblaff_Affiliates
  LEFT JOIN External_fiktivo_dbo_tblaff_PaymentDetails (pd1, pd2, pd3)
  JOIN External_fiktivo_dbo_tblaff_AffiliateTypes (ContractType)
  LEFT JOIN External_fiktivo_dbo_tblaff_MarketingExpense
    → #fiktivo (all active affiliates with payment slots and contract details)

DWH_dbo.Dim_Customer (RealCID, GCID, AffiliateID/SerialID, UserName, VerificationLevelID, etc.)
    → #CID (all etoro customers with lowercase UserName for matching)

#fiktivo LEFT JOIN #CID (UserName1 → UserName_LOWER match)
         LEFT JOIN #CID (UserName2 → UserName_LOWER match)
         LEFT JOIN #CID (UserName3 → UserName_LOWER match)
    → #Customer (affiliate + first-matching etoro CID via username lookup)

#CID (all customers)
  JOIN #Customer ON CID = TradingAccount_CID
  LEFT JOIN Dim_AccountType (AccountTypeName)
  LEFT JOIN Dim_PlayerStatus (CustomerStatus)
  LEFT JOIN #CustomerDocumentExpiryDate
  LEFT JOIN #CustomerDocumentUtilityBill_Date
  LEFT JOIN Dim_PhoneVerified (PhoneVerified name)
  JOIN Dim_CashoutFeeGroup (CashoutFeeGroup name)
  LEFT JOIN Dim_Customer (ScreeningStatusID)
  LEFT JOIN Dim_ScreeningStatus (ScreeningStatus name)
    → #BI_DB_Affiliate_Guidlines_Report

TRUNCATE → INSERT BI_DB_Affiliate_Guidlines_Report
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Dim_Customer | RealCID | Direct (aliased as CID) | T1 — Customer.CustomerStatic |
| 2 | Aff_ID | Dim_Customer | AffiliateID (SerialID) | Direct (affiliate FK from customer record) | T1 — Customer.CustomerStatic |
| 3 | AccountTypeName | Dim_AccountType | Name | Lookup via Dim_Customer.AccountTypeID | T1 — Dictionary.AccountType |
| 4 | CustomerStatus | Dim_PlayerStatus | Name | Lookup via Dim_Customer.PlayerStatusID | T1 — Dictionary.PlayerStatus |
| 5 | ExpiryDate | External_etoro_BackOffice_CustomerDocument | ExpiryDate | MAX(ExpiryDate) for DocumentTypeID=2 (ID document) | T2 — SP_Affiliate_Guidlines_Report |
| 6 | UtilityBill_Date | External_etoro_BackOffice_CustomerDocument | IssueDate | MAX(IssueDate) for DocumentTypeID=1 (utility bill) | T2 — SP_Affiliate_Guidlines_Report |
| 7 | KYC_filled | — | — | HARDCODED NULL — source (UserApiDB.KYC.CustomerAnswers) is commented out | T2 — SP_Affiliate_Guidlines_Report |
| 8 | VerificationLevelID | Dim_Customer | VerificationLevelID | Direct | T1 — BackOffice.Customer |
| 9 | PhoneVerified | Dim_PhoneVerified | PhoneVerifiedName | Lookup via Dim_Customer.PhoneVerifiedID | T1 — Dictionary.PhoneVerified |
| 10 | Registered | Dim_Customer | RegisteredReal | Direct (renamed from RegisteredReal) | T1 — Customer.CustomerStatic |
| 11 | CashoutFeeGroup | Dim_CashoutFeeGroup | CashoutFeeGroupName | Lookup via Dim_Customer.CashoutFeeGroupID | T1 — Dictionary.CashoutFeeGroup |
| 12 | TradingAccount_CID | Dim_Customer | RealCID | ISNULL(first matching CID from UserName1/2/3 lookup, 0) — username-based match | T2 — SP_Affiliate_Guidlines_Report |
| 13 | AffiliateID | External_fiktivo_dbo_tblaff_Affiliates | AffiliateID | Direct (fiktivo PK) | T1 — fiktivo.tblaff_Affiliates |
| 14 | DateCreated | External_fiktivo_dbo_tblaff_Affiliates | DateCreated | Direct | T1 — fiktivo.tblaff_Affiliates |
| 15 | AW_UserName | External_fiktivo_dbo_tblaff_Affiliates | LoginName | CONVERT(NVARCHAR(24)) | T1 — fiktivo.tblaff_Affiliates |
| 16 | ContractType | External_fiktivo_dbo_tblaff_AffiliateTypes | Description | Lookup via AffiliateTypeID | T1 — fiktivo.tblaff_AffiliateTypes |
| 17 | MarketingExpenseName | External_fiktivo_dbo_tblaff_MarketingExpense | MarketingExpenseName | Lookup via MarketingExpenseID (LEFT JOIN) | T1 — fiktivo.tblaff_MarketingExpense |
| 18 | Contact | External_fiktivo_dbo_tblaff_Affiliates | Contact | Direct | T1 — fiktivo.tblaff_Affiliates |
| 19 | AffiliateCustom1 | External_fiktivo_dbo_tblaff_Affiliates | AffiliateCustom1 | Direct | T1 — fiktivo.tblaff_Affiliates |
| 20 | AccountActivated | External_fiktivo_dbo_tblaff_Affiliates | AccountActivated | CAST(bit → int) | T1 — fiktivo.tblaff_Affiliates |
| 21 | UserName1 | External_fiktivo_dbo_tblaff_PaymentDetails | Username (pd1) | LOWER(...) COLLATE Latin1_General_100_BIN; default '''' if NULL | T1 — fiktivo.tblaff_PaymentDetails |
| 22 | UserName2 | External_fiktivo_dbo_tblaff_PaymentDetails | Username (pd2) | LOWER(...) COLLATE Latin1_General_100_BIN; default '''' if NULL | T1 — fiktivo.tblaff_PaymentDetails |
| 23 | UserName3 | External_fiktivo_dbo_tblaff_PaymentDetails | Username (pd3) | LOWER(...) COLLATE Latin1_General_100_BIN; default '''' if NULL | T1 — fiktivo.tblaff_PaymentDetails |
| 24 | UserName4 | External_fiktivo_dbo_tblaff_Affiliates | LoginName | CONVERT(NVARCHAR(24)) COLLATE Latin1_General_100_BIN | T1 — fiktivo.tblaff_Affiliates |
| 25 | PaymentDetailsDefault | External_fiktivo_dbo_tblaff_Affiliates | PaymentDetailsDefault | Direct (1=pd1 is default, 2=pd2, 3=pd3) | T1 — fiktivo.tblaff_Affiliates |
| 26 | PaymentMethodID | External_fiktivo_dbo_tblaff_PaymentDetails | PaymentMethodID | CASE on PaymentDetailsDefault → selects from pd1/pd2/pd3 | T2 — SP_Affiliate_Guidlines_Report |
| 27 | UpdateDate | SP | GETDATE() | CONVERT(DATE, GetDate()) — date-only | Propagation |
| 28 | ScreeningStatusID | Dim_ScreeningStatus | ScreeningStatusID | Lookup via Dim_Customer.ScreeningStatusID | T1 — ScreeningService.Dictionary.ScreeningStatus |
| 29 | ScreeningStatus | Dim_ScreeningStatus | Name | Lookup via Dim_Customer.ScreeningStatusID | T1 — ScreeningService.Dictionary.ScreeningStatus |

## Tier Summary

- **Tier 1**: 23 (CID, Aff_ID, AccountTypeName, CustomerStatus, VerificationLevelID, PhoneVerified, Registered, CashoutFeeGroup, AffiliateID, DateCreated, AW_UserName, ContractType, MarketingExpenseName, Contact, AffiliateCustom1, AccountActivated, UserName1, UserName2, UserName3, UserName4, PaymentDetailsDefault, ScreeningStatusID, ScreeningStatus)
- **Tier 2**: 5 (ExpiryDate, UtilityBill_Date, KYC_filled, TradingAccount_CID, PaymentMethodID)
- **Propagation**: 1 (UpdateDate)
