# DWH_dbo.VU_FactBilling_ForBigQuery

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[VU_FactBilling_ForBigQuery]` |
| **Type** | View |
| **Base Tables** | `Fact_BillingDeposit` |
| **Purpose** | Export-ready view of `Fact_BillingDeposit` that sanitizes string columns through `DWH_dbo.RemoveSpecialChars()` for safe ingestion into Google BigQuery. |

## 2. Business Context

This view prepares billing deposit data for export to **Google BigQuery**. The "VU_" prefix suggests it is part of a data unload/export pipeline.

### Sanitization Pattern
All string/detail columns are processed through a two-step transformation:
1. `CONVERT(NVARCHAR(MAX), ...)` — ensures consistent string type
2. `DWH_dbo.RemoveSpecialChars(...)` — strips characters that could break CSV/JSON export or BigQuery ingestion (likely special characters, control characters, or delimiters)

Approximately **70+ columns** receive this sanitization treatment. Numeric and date columns pass through without transformation.

### Column Groups

| Group | Count | Treatment |
|-------|-------|-----------|
| Core billing | ~20 | Direct passthrough (CID, Amount, dates, IDs) |
| Card/payment detail strings | ~70 | `RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))` |
| Exchange/fee | ~5 | Direct passthrough |

### Notable String Columns
The view exposes extensive payment processor detail columns (card data, bank details, payer information, 3DS data, Plaid integration fields) that come from the raw billing system. Many have suffixed type hints (e.g., `AsString`, `AsDecimal`, `AsInteger`) indicating they were originally typed fields serialized as strings.

## 3. Elements

Due to the large column count (~125), columns are grouped rather than listed individually:

| Group | Key Columns | Description |
|-------|-------------|-------------|
| Identity | `CID` | Customer ID. FK to Dim_Customer. |
| Transaction | `FundingID`, `DepositID`, `Amount`, `AmountUSD`, `ExchangeRate`, `BaseExchangeRate` | Core transaction details |
| Dates | `ModificationDate`, `ModificationDateID`, `PaymentDate`, `ProcessorValueDate`, `ClearingHouseEffectiveDate`, `ExpirationDateID` | Transaction timestamps |
| Status | `PaymentStatusID`, `RiskManagementStatusID`, `MatchStatusID`, `BonusStatusID`, `Approved` | Processing status IDs |
| Payment method | `FundingTypeID`, `DepotID`, `CurrencyID`, `ProtocolMIDSettingsID` | Payment configuration |
| Bonus | `BonusAmount`, `BonusErrorCode` | Deposit bonus info |
| Card detail (sanitized) | `SecuredCardDataAsString`, `BinCodeAsString`, `CardNumberAsString`, etc. | Sanitized via RemoveSpecialChars |
| Bank detail (sanitized) | `BankNameAsString`, `BankAccountAsString`, `IBANCodeAsString`, `BICCodeAsString`, etc. | Sanitized bank transfer fields |
| Customer detail (sanitized) | `CustomerNameAsString`, `CustomerAddressAsString`, `EmailAsString`, etc. | Sanitized PII fields |
| 3DS/Security (sanitized) | `ThreeDsAsJson`, `ThreeDsResponseType`, `SecretKeyAsString`, `MD5AsString` | Security/3DS fields |
| Provider response (sanitized) | `ResponseMessageAsString`, `ResponseTimeAsString`, `ErrorCodeAsString`, `ErrorTypeAsString` | Payment gateway responses |
| Misc (sanitized) | `MOPCountry`, `PromotionCodeAsString`, `PSPCodeAsString`, `SessionID`, `PlatformID`, `FunnelID` | Supplementary fields |

See [Fact_BillingDeposit.md](../Tables/Fact_BillingDeposit.md) for full column documentation.

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| NOLOCK hint | Medium | Uses `WITH (NOLOCK)` — may read uncommitted billing records |
| RemoveSpecialChars UDF | Low | Scalar UDF may impact performance on large exports — consider inline TVF if performance is an issue |
| Column `v` | Low | Ambiguous single-letter column name — appears to be a billing detail field processed through RemoveSpecialChars |
| Commented-out JSON | Info | `FOR JSON PATH, WITHOUT_ARRAY_WRAPPER` is commented out — view was possibly designed for JSON export originally |

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | Documents Fact Billing Deposit grain (CID, deposit time, modification date) and usage notes |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900) | DWH diagrams include fact-billing deposit/withdraw pipelines |
| [Mimo Terms Explanations - Deposit / Withdraw](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11478827085) | Billing service / withdraw status terminology aligned with deposit fact detail fields |

---
*Generated: 2026-03-19 | Quality: 7.8/10 | ~125-column sanitized export view for BigQuery | Sources: 8/10*
