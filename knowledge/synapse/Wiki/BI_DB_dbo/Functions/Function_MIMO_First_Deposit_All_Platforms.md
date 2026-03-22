# Function_MIMO_First_Deposit_All_Platforms

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | MIMO |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 56 (T1: 46, T2: 10) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Single entry point for **first-time deposit (FTD)** attributes per customer across eMoney and trading-platform sources, with **date-routed logic**: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses `Dim_Customer` as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Each row is enriched with `Fact_SnapshotCustomer` as-of the FTD date via `Dim_Range`.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| eMoney_Fact_Transaction_Status | eMoney_dbo |
| FiatTransactions | eMoney_dbo |
| Fact_CustomerAction | DWH_dbo |
| Dim_Customer | DWH_dbo |
| Dim_FTDPlatform | DWH_dbo |
| Fact_BillingDeposit | DWH_dbo |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | Routed OLD_BASE vs NEW_BASE; NEW from Dim_Customer; OLD from first-ranked eMoney/TP deposit | T2 |
| 2 | DepositID | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | CASE on FTDPlatformID / joins; IBAN TransactionID, TP DepositID, or neutralized | T2 |
| 3 | FirstDepositDate | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | OLD: earliest across IBAN/TP union; NEW: Dim_Customer.FirstDepositDate | T2 |
| 4 | FirstDepositAmount | Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction | Same routing as date/amount sources | T2 |
| 5 | FTDPlatform | Dim_FTDPlatform, literals | Dim_FTDPlatform.FTDPlatformName (NEW) or 'eMoney' / 'TradingPlatform' (OLD) | T2 |
| 6 | FTDPlatformID | Dim_Customer, literals | 3 eMoney / 1 TP (OLD) or Dim_Customer.FTDPlatformID (NEW) | T2 |
| 7 | IsCryptoToFiat | eMoney_Fact_Transaction_Status | TxTypeID = 14 flags; COALESCE across IBAN/TP in NEW | T2 |
| 8 | IsIBANTrade | Fact_CustomerAction | ActionTypeID = 44; COALESCE(tp, ib) in NEW | T2 |
| 9 | IsIBANQuickTransfer | Fact_CustomerAction | MoveMoneyReasonID = 6; COALESCE in NEW | T2 |
| 10 | IsC2USD | Fact_BillingDeposit | CAST(0 AS BIT) OLD; NEW: CASE WHEN C2USD match THEN 1 ELSE 0 END | T2 |
| 11 | GCID | Fact_SnapshotCustomer.GCID | Direct | T1 |
| 12 | DemoCID | Fact_SnapshotCustomer.DemoCID | Direct | T1 |
| 13 | CustomerChangeTypeID | Fact_SnapshotCustomer.CustomerChangeTypeID | Direct | T1 |
| 14 | CurentValue | Fact_SnapshotCustomer.CurentValue | Direct | T1 |
| 15 | PreviousValue | Fact_SnapshotCustomer.PreviousValue | Direct | T1 |
| 16 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T1 |
| 17 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T1 |
| 18 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T1 |
| 19 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T1 |
| 20 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T1 |
| 21 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T1 |
| 22 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T1 |
| 23 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T1 |
| 24 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T1 |
| 25 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T1 |
| 26 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T1 |
| 27 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T1 |
| 28 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T1 |
| 29 | UpdateDate | Fact_SnapshotCustomer.UpdateDate | Direct | T1 |
| 30 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T1 |
| 31 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T1 |
| 32 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T1 |
| 33 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T1 |
| 34 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T1 |
| 35 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T1 |
| 36 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T1 |
| 37 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T1 |
| 38 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T1 |
| 39 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T1 |
| 40 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T1 |
| 41 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T1 |
| 42 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T1 |
| 43 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T1 |
| 44 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T1 |
| 45 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T1 |
| 46 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T1 |
| 47 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T1 |
| 48 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T1 |
| 49 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 50 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 51 | Address | Fact_SnapshotCustomer.Address | Direct | T1 |
| 52 | Zip | Fact_SnapshotCustomer.Zip | Direct | T1 |
| 53 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T1 |
| 54 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T1 |
| 55 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T1 |
| 56 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T1 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-06-14 | Guy M | Trade From IBAN (44) & C2F edge case |
| 2025-09-13 | Guy M | Replaced old logic with Dim_Customer; added c2USD; combined old+new with date routing |
| 2025-10-06 | Guy M | FiatTransactions.Created in ROW_NUMBER; options/global FTD notes |
| 2025-10-26 | Guy M | TRY_CONVERT on FTD join keys (options platform strings) |
| 2025-11-23 | Guy M | REMOVE_BAD_FTDS exclusion for wrongly tagged FTDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
