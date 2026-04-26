# BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement — Column Lineage

**Generated**: 2026-04-22 | **Writer SP**: SP_HighRedeemsApprovalForManagement | **Batch**: 20

## Summary

Daily TRUNCATE+INSERT snapshot of customers with pending redeems (RedeemStatusID=1) whose total EOD redeem value exceeds $50,000 (yesterday's closing price). Intended as a management approval report for high-value withdrawals. Population is dynamic — re-evaluated each day from External_etoro_Billing_Redeem. Sources: External_etoro_Billing_Redeem (positions), Dim_GetSpreadedPriceCandle60MinSplitted (EOD price), Dim_Customer (demographics), V_Liabilities (financials — **HARDCODED DateID=20230504, stale**), BackOffice External tables (AML/Risk comments, selfie), BI_DB_UsageTracking_SF (account manager contact history), Dim_Position (commissions).

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | BI_DB_dbo.External_etoro_Billing_Redeem | CID | Direct — customer ID from pending redeem requests (RedeemStatusID=1). Equates to RealCID based on downstream DWH joins (Dim_Customer dc ON dc.RealCID=a.CID). | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 2 | MaxRequestDate | BI_DB_dbo.External_etoro_Billing_Redeem | RequestDate | MAX(CAST(RequestDate AS date)) per CID — most recent redeem request date for this customer. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 3 | Amount | BI_DB_dbo.External_etoro_Billing_Redeem + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Units, BidLast | SUM(Units * BidLast) per CID — total EOD value of all pending redeems at yesterday's closing price (DateTo=@day). HAVING SUM > 50,000 threshold. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 4 | Type | — | — | Hardcoded string constant 'Redeem'. Exists to allow future union with other request types (e.g., withdrawals). | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 5 | Country | DWH_dbo.Dim_Country | Name | dc1.Name AS Country via Dim_Customer.CountryID = Dim_Country.CountryID. Full country name in English. | Tier 1 — Dictionary.Country |
| 6 | Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(year, BirthDate, GETDATE()) — computed age in years at ETL run time. Reflects age at daily SP execution, not at redeem date. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 7 | Regulation | DWH_dbo.Dim_Regulation | Name | dr.Name AS Regulation via Dim_Customer.RegulationID = Dim_Regulation.ID. Short code for the regulation; values match production Dictionary.Regulation.Name. | Tier 1 — Dictionary.Regulation |
| 8 | AMLComment | BI_DB_dbo.External_etoro_BackOffice_Customer | AMLComment | ISNULL(bo.AMLComment, '') — AML team review notes from BackOffice system. Empty string if no AML comment exists. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 9 | RiskComment | BI_DB_dbo.External_etoro_BackOffice_Customer | RiskComment | ISNULL(bo.RiskComment, '') — Risk team review notes from BackOffice system. Empty string if no Risk comment exists. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 10 | ProvidedSelfie | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | — | 'Yes' if customer has at least one document of DocumentTypeID=15 (selfie) in BackOffice records, 'No' otherwise. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 11 | WasContactedLast12Months | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | 'yes' if the customer has a Salesforce record with ActionName='Phone_Call_Succeed__c' in the last 12 months (CreatedDate_SF >= DATEADD(MONTH,-12,GETDATE())). 'no' otherwise. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 12 | Account Manager | DWH_dbo.Dim_Manager | FirstName, LastName | FirstName + ' ' + LastName from Dim_Manager. Priority: if the customer had a successful phone contact in the last 12 months (SF), uses that contact's manager; otherwise falls back to Dim_Customer.AccountManagerID → Dim_Manager. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 13 | NWA | DWH_dbo.V_Liabilities | BonusCredit | ISNULL(V.BonusCredit, 0) — bonus/credit balance from V_Liabilities. **STALE: JOIN hardcoded to DateID=20230504 (May 4, 2023). Always reflects May 2023 BonusCredit; current value if zero on that date returns 0.** | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 14 | Revenues | DWH_dbo.Dim_Position | CommissionOnClose | SUM(CommissionOnClose) per CID — ALL-TIME total commissions from all closed positions. Not filtered by redeem period or instrument type. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 15 | CustomerStatus | DWH_dbo.Dim_PlayerStatus | Name | ps.Name AS CustomerStatus via Dim_Customer.PlayerStatusID = Dim_PlayerStatus.PlayerStatusID. Human-readable restriction state label; unique per status; values match production Dictionary.PlayerStatus.Name. | Tier 1 — Dictionary.PlayerStatus |
| 16 | Verification | DWH_dbo.Dim_Customer | VerificationLevelID | CASE WHEN VerificationLevelID=3 THEN 'Verified' ELSE 'Not Verified'. Values: 'Verified', 'Not Verified'. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 17 | ExpiredPOI | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | 'yes' if IsIDProofExpiryDate <= GETDATE() (ID proof document is expired), 'no' otherwise. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 18 | CompensationAmount | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=36 per CID — total compensation payments received by this customer across all time. | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 19 | Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | V.Liabilities + V.ActualNWA — total equity at V_Liabilities. **STALE: JOIN hardcoded to DateID=20230504. NULL if no V_Liabilities row for this CID at that date.** | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 20 | Balance | DWH_dbo.V_Liabilities | Credit | V.Credit — credit balance from V_Liabilities. **STALE: JOIN hardcoded to DateID=20230504. NULL if no V_Liabilities row for this CID at that date.** | Tier 2 — SP_HighRedeemsApprovalForManagement |
| 21 | UpdateDate | — | — | GETDATE() at ETL execution time (TRUNCATE+INSERT daily). | Tier 2 — SP_HighRedeemsApprovalForManagement |

## ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_Redeem (RedeemStatusID=1, pending redeems)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (BidLast at DateTo=@day)
  → #EOD (Units*BidLast per position)
  → #maxrequest (MAX RequestDate per CID)
  → #redeems (SUM(ValueEOD) per CID, HAVING > 50,000 threshold)

BI_DB_dbo.External_etoro_BackOffice_Customer (AMLComment, RiskComment)
BI_DB_dbo.External_etoro_BackOffice_CustomerDocument + CustomerDocumentToDocumentType (selfie DocumentTypeID=15)
BI_DB_dbo.BI_DB_UsageTracking_SF (ActionName='Phone_Call_Succeed__c', last 12 months)
DWH_dbo.Dim_Customer (BirthDate, CountryID, RegulationID, PlayerStatusID, AccountManagerID, VerificationLevelID, IsIDProofExpiryDate)
DWH_dbo.Dim_Country (Name → Country)
DWH_dbo.Dim_Regulation (Name → Regulation)
DWH_dbo.Dim_PlayerStatus (Name → CustomerStatus)
DWH_dbo.Dim_Manager (FirstName+LastName → Account Manager)
DWH_dbo.Dim_Position (SUM(CommissionOnClose) → Revenues)
DWH_dbo.Fact_CustomerAction (ActionTypeID=36 → CompensationAmount)
DWH_dbo.V_Liabilities (DateID=20230504 HARDCODED → Balance, Equity, NWA)
  |
  |-- SP_HighRedeemsApprovalForManagement @day=YESTERDAY
  |     TRUNCATE TABLE BI_DB_D_HighRedeemsApprovalForManagement
  |     + INSERT FROM #clients
  v
BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement
  (~3 rows as of 2026-04-13 | HEAP | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 3 | Country, Regulation, CustomerStatus |
| Tier 2 | 18 | CID, MaxRequestDate, Amount, Type, Age, AMLComment, RiskComment, ProvidedSelfie, WasContactedLast12Months, Account Manager, NWA, Revenues, Verification, ExpiredPOI, CompensationAmount, Equity, Balance, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
