# BI_DB_dbo.BI_DB_AML_SAR_Report_FCA — Column Lineage

**Generated**: 2026-04-21 | **Schema**: BI_DB_dbo | **Writer SP**: SP_AML_SAR_Report  
**Load pattern**: TRUNCATE + INSERT daily | **Row count**: 1,414,989  
**UC Target**: _Not_Migrated

---

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| DWH_dbo.Dim_Customer | Table | Primary source — FCA customer profile (RegulationID=2, IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2) |
| DWH_dbo.Dim_Country | Table | Country name resolution (JOIN on CountryID) |
| DWH_dbo.Dim_Regulation | Table | Regulation name (FCA only — DWHRegulationID=2) |
| DWH_dbo.Dim_PlayerLevel | Table | Club/tier name resolution (PlayerLevelID) |
| DWH_dbo.Dim_PlayerStatus | Table | Player status name (PlayerStatusID) |
| DWH_dbo.Dim_AccountType | Table | Account type name (AccountTypeID) |
| DWH_dbo.Dim_FundingType | Table | Payment method name (FundingTypeID) |
| DWH_dbo.Fact_BillingDeposit | Table | Deposit transactions (PaymentStatusID=2 approved) |
| DWH_dbo.Fact_BillingWithdraw | Table | Cashout transactions (CashoutStatusID=3 approved) |
| DWH_dbo.V_Liabilities | View | Daily equity snapshot (Liabilities + ActualNWA per DateID) |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | GBP/USD exchange rate (InstrumentID=2, for GBP conversion) |
| BI_DB_dbo.BI_DB_KYC_Panel | Table | Occupation via KYC question 18 (Q18_AnswerText, LEFT JOIN) |

---

## ETL Pipeline

```
Customer.CustomerStatic (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_staging.etoro_Customer_Customer
  |-- SP_Dim_Customer --|
  v
DWH_dbo.Dim_Customer [FCA filter: RegulationID=2, IsDepositor=1, VerificationLevelID>=2]
  +
DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_AccountType
  +
DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw (all approved transactions)
  +
DWH_dbo.V_Liabilities + Fact_CurrencyPriceWithSplit (equity → GBP)
  +
BI_DB_dbo.BI_DB_KYC_Panel (Occupation / Q18_AnswerText)
  |-- SP_AML_SAR_Report @Date (TRUNCATE+INSERT daily) --|
  v
BI_DB_dbo.BI_DB_AML_SAR_Report_FCA (1,414,989 rows, FCA SAR export)
  |-- _Not_Migrated (no UC target) --|
```

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename (regulatory CID label) | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | Tier 1 |
| 3 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN on AccountTypeID | Tier 2 |
| 4 | BirthDate | DWH_dbo.Dim_Customer | BirthDate | CAST AS DATE | Tier 1 |
| 5 | Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()); NULL if BirthDate year=1900 | Tier 2 |
| 6 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID=2; always 'FCA' | Tier 2 |
| 7 | FirstName | DWH_dbo.Dim_Customer | FirstName | Passthrough | Tier 1 |
| 8 | LastName | DWH_dbo.Dim_Customer | LastName | Passthrough | Tier 1 |
| 9 | MiddleName | DWH_dbo.Dim_Customer | MiddleName | Passthrough | Tier 1 |
| 10 | FullName | DWH_dbo.Dim_Customer | FirstName, MiddleName, LastName | Concatenation: FirstName+' '+MiddleName+' '+LastName | Tier 2 |
| 11 | Gender | DWH_dbo.Dim_Customer | Gender | CASE: F→Female, M→Male, else→Unknown (char→nvarchar) | Tier 1 |
| 12 | Zip | DWH_dbo.Dim_Customer | Zip | Passthrough | Tier 1 |
| 13 | Address | DWH_dbo.Dim_Customer | Address | Passthrough | Tier 1 |
| 14 | AddressType | Hardcoded | — | Always 'Home Address' | Tier 2 |
| 15 | CurrentAddress | Hardcoded | — | Always 'Y' | Tier 2 |
| 16 | BuildingNumber | DWH_dbo.Dim_Customer | BuildingNumber | Passthrough | Tier 1 |
| 17 | City | DWH_dbo.Dim_Customer | City | Passthrough | Tier 1 |
| 18 | Country | DWH_dbo.Dim_Country | Name | JOIN on DWHCountryID=dc.CountryID | Tier 2 |
| 19 | IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | Passthrough (Dim_Customer Tier 2 source) | Tier 2 |
| 20 | POI_Expiry_Date | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | Rename | Tier 2 |
| 21 | IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | Passthrough | Tier 2 |
| 22 | POA_Expiry_Date | DWH_dbo.Dim_Customer | IsAddressProofExpiryDate | Rename | Tier 2 |
| 23 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | Tier 1 |
| 24 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough (Dim_Customer Tier 2 source) | Tier 2 |
| 25 | FirstDepositAmount | DWH_dbo.Dim_Customer | FirstDepositAmount | Passthrough (Dim_Customer Tier 2) | Tier 2 |
| 26 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID | Tier 2 |
| 27 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID (player tier label) | Tier 2 |
| 28 | Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | LEFT JOIN on RealCID; KYC question 18 free-text | Tier 4 |
| 29 | SourceRef | DWH_dbo.Dim_Customer | RealCID | Same as CID; regulatory report reference number field | Tier 1 |
| 30 | SARDate | Hardcoded | — | CAST(GETDATE() AS DATE) — run date | Tier 2 |
| 31 | Source | Hardcoded | — | Always 'eToro (UK) Limited' | Tier 2 |
| 32 | Currency | Hardcoded | — | Always 'GBP (POUND STERLING)' | Tier 2 |
| 33 | DisclosedAccountName | DWH_dbo.Dim_Customer | FirstName, MiddleName, LastName | Concatenation; same formula as FullName | Tier 2 |
| 34 | Consent_Required | Hardcoded | — | Always 'Y / N' (placeholder) | Tier 2 |
| 35 | Disclosure_Type | Hardcoded | — | Always 'Proceeds of Crime Act 2002' | Tier 2 |
| 36 | SourceOutlet | Hardcoded | — | Always 'London' | Tier 2 |
| 37 | NumOfMOP_CO | DWH_dbo.Fact_BillingWithdraw | — | COUNT of cashout MOP by CID (CashoutStatusID=3 approved) | Tier 2 |
| 38 | TypeCO | Hardcoded | — | Always 'Debit' | Tier 2 |
| 39 | MOP_CO | DWH_dbo.Dim_FundingType | Name | Most common cashout method (ROW_NUMBER by NumOfMOP DESC) | Tier 2 |
| 40 | TotalCO | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding / Amount_Withdraw | SUM(DISTINCT ISNULL(Amount_WithdrawToFunding, Amount_Withdraw)) | Tier 2 |
| 41 | NumOfMOP_Deposit | DWH_dbo.Fact_BillingDeposit | — | COUNT of deposit MOP by CID (PaymentStatusID=2 approved) | Tier 2 |
| 42 | TypeDep | Hardcoded | — | Always 'Credit' | Tier 2 |
| 43 | MOP_Dep | DWH_dbo.Dim_FundingType | Name | Most common deposit method (ROW_NUMBER by NumOfMOP_Deposit DESC) | Tier 2 |
| 44 | TotalDeposit_POUND | DWH_dbo.Fact_BillingDeposit | Amount | SUM(Amount) where PaymentStatusID=2 | Tier 2 |
| 45 | UpdateDate | Hardcoded | — | GETDATE() at insert time | Tier 2 |
| 46 | Phone | DWH_dbo.Dim_Customer | Phone | Passthrough | Tier 1 |
| 47 | Email | DWH_dbo.Dim_Customer | Email | Passthrough | Tier 1 |
| 48 | SarCode | DWH_dbo.V_Liabilities + Fact_CurrencyPriceWithSplit | Liabilities, ActualNWA, Bid | CASE WHEN GBP_Equity > 3000 THEN 'XXS99XX' ELSE 'XXGVTXX' | Tier 2 |
| 49 | TotalEquity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) | Tier 2 |
| 50 | GBP_Equity | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | TotalEquity × (1/Bid) where InstrumentID=2 (GBP/USD) | Tier 2 |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 15 | CID, GCID, BirthDate, FirstName, LastName, MiddleName, Gender, Zip, Address, BuildingNumber, City, RegisteredReal, Phone, Email, SourceRef |
| Tier 2 | 34 | AccountType, Age, Regulation, FullName, AddressType, CurrentAddress, Country, IsIDProof, POI_Expiry_Date, IsAddressProof, POA_Expiry_Date, FirstDepositDate, FirstDepositAmount, PlayerStatus, Club, SARDate, Source, Currency, DisclosedAccountName, Consent_Required, Disclosure_Type, SourceOutlet, NumOfMOP_CO, TypeCO, MOP_CO, TotalCO, NumOfMOP_Deposit, TypeDep, MOP_Dep, TotalDeposit_POUND, UpdateDate, SarCode, TotalEquity, GBP_Equity |
| Tier 4 | 1 | Occupation |
| **Total** | **50** | |
