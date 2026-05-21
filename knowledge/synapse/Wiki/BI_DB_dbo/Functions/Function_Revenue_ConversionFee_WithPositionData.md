# Function_Revenue_ConversionFee_WithPositionData

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 67 (T1: 62, T2: 5) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Same grain as `Function_Revenue_ConversionFee`: **ConversionFee** = **PIPsCalculation** with **DateID BETWEEN @sdateInt AND @edateInt** (plus snapshot `Dim_Range` join). Adds **position-level attributes** for IBAN-linked flows via **BI_DB_Positions_Opened_From_IBAN** / **BI_DB_Positions_Closed_To_IBAN**, then **Dim_Position** / **Dim_Instrument**, and **ExecutionIBANTradeSuccess** when IBAN trade rows lack a resolved position.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DepositWithdrawFee | BI_DB_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_BillingDeposit | DWH_dbo |
| Fact_BillingWithdraw | DWH_dbo |
| BI_DB_Positions_Opened_From_IBAN | BI_DB_dbo |
| BI_DB_Positions_Closed_To_IBAN | BI_DB_dbo |
| Dim_Position | DWH_dbo |
| Dim_Instrument | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | BI_DB_DepositWithdrawFee.CID | Direct | T2 |
| 2 | ConversionFee | BI_DB_DepositWithdrawFee.PIPsCalculation | PIPsCalculation AS ConversionFee WHERE DateID BETWEEN @sdateInt AND @edateInt (and snapshot DateRange join) | T2 |
| 3 | TransactionType | BI_DB_DepositWithdrawFee.TransactionType | Direct | T2 |
| 4 | IsIBANTrade | BI_DB_DepositWithdrawFee.IsIBANTrade | Direct | T2 |
| 5 | DateID | BI_DB_DepositWithdrawFee.DateID | Direct | T2 |
| 6 | TransactionID | BI_DB_DepositWithdrawFee.TransactionID | CAST(LEFT(TransactionID, LEN(TransactionID) - 1) AS INT) | T2 |
| 7 | PaymentMethod | BI_DB_DepositWithdrawFee.PaymentMethod | Direct | T2 |
| 8 | Amount | BI_DB_DepositWithdrawFee.Amount | Direct | T2 |
| 9 | Currency | BI_DB_DepositWithdrawFee.Currency | Direct | T2 |
| 10 | AmountUSD | BI_DB_DepositWithdrawFee.AmountUSD | Direct | T2 |
| 11 | ExchangeRate | BI_DB_DepositWithdrawFee.ExchangeRate | Direct | T2 |
| 12 | BaseExchangeRate | BI_DB_DepositWithdrawFee.BaseExchangeRate | Direct | T2 |
| 13 | Depot | BI_DB_DepositWithdrawFee.Depot | Direct | T2 |
| 14 | MIDValue | BI_DB_DepositWithdrawFee.MIDValue | Direct | T2 |
| 15 | IsRecurring | Fact_BillingDeposit.IsRecurring | Direct (LEFT JOIN on DepositID when TransactionType = 'Deposit') | T2 |
| 16 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 17 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 18 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 19 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T2 |
| 20 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 21 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T4 |
| 22 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 23 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T4 |
| 24 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 25 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 26 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T2 |
| 27 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T4 |
| 28 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T4 |
| 29 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 30 | UpdateDate | Fact_SnapshotCustomer.UpdateDate | Direct | T2 |
| 31 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 32 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 33 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 34 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 35 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 36 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T2 |
| 37 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 38 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T2 |
| 39 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T2 |
| 40 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 41 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 42 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T2 |
| 43 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 44 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T2 |
| 45 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T2 |
| 46 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T2 |
| 47 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T2 |
| 48 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 49 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |
| 50 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 51 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 52 | Address | Fact_SnapshotCustomer.Address | Direct | T2 |
| 53 | Zip | Fact_SnapshotCustomer.Zip | Direct | T2 |
| 54 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T2 |
| 55 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T2 |
| 56 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T2 |
| 57 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T2 |
| 58 | PositionID | BI_DB_Positions_Closed_To_IBAN.PositionID, BI_DB_Positions_Opened_From_IBAN.PositionID | COALESCE(bdpcti.PositionID, bdpofi.PositionID) | T2 |
| 59 | IsSettled | Dim_Position.IsSettled | Direct | T5 |
| 60 | IsBuy | Dim_Position.IsBuy | Direct | T1 |
| 61 | Leverage | Dim_Position.Leverage | Direct | T1 |
| 62 | IsAirDrop | Dim_Position.IsAirDrop | Direct | T2 |
| 63 | ExecutionIBANTradeSuccess | BI_DB_DepositWithdrawFee.IsIBANTrade, BI_DB_Positions_Closed_To_IBAN, BI_DB_Positions_Opened_From_IBAN | CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND IsIBANTrade = 1 THEN 0 ELSE 1 END | T2 |
| 64 | InstrumentID | Dim_Instrument.InstrumentID | Direct | T1 |
| 65 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 66 | InstrumentType | Dim_Instrument.InstrumentType | Direct | T2 |
| 67 | IsCopy | Dim_Position.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-03-10 | Guy M | Join to Fact_BillingDeposit for IsRecurring; extra columns |
| 2025-09-08 | Guy M | Position data for IBAN trades (less efficient; for specific reports) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
