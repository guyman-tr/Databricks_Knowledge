# BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_HighRedeemsApprovalForManagement |
| Refresh | TRUNCATE + INSERT daily (GETDATE()-1 = yesterday; no @date parameter) |
| Row count | ~3 rows (2026-04-13 live count; fluctuates daily) |
| Date range | Single-day snapshot; MaxRequestDate 2026-04-07–2026-04-12 as of 2026-04-13 |
| UC target | _Not_Migrated |
| SP author | Pavlina Masuora (2021-06-10; no recorded change history) |

**Tier legend**: T1 = verbatim upstream wiki (Dictionary.Country, Dictionary.Regulation, Dictionary.PlayerStatus) · T2 = SP-derived/computed · T3 = N/A · T4 = N/A

---

## 1. Business Meaning

Daily management approval report listing customers with high-value pending withdrawal requests. Specifically: customers who have one or more open redeems (RedeemStatusID=1) where the total EOD value — computed as `SUM(Units × BidLast)` at yesterday's closing price — exceeds **$50,000**. Each customer appears in exactly one row containing their risk profile, compliance flags, financial summary, and account manager information.

Intended audience: Risk, AML, and senior management for same-day review and approval of large pending withdrawals. The table provides a daily at-a-glance view of which customers are waiting on high-value redeems, their compliance standing (AML/Risk comments, POI expiry, selfie status), and recent relationship-management activity.

Populated by `SP_HighRedeemsApprovalForManagement` (TRUNCATE+INSERT, daily, no @date parameter — always reflects the state as of yesterday = `GETDATE()-1`).

---

## 2. Business Logic & Derivation Rules

### 2.1 Population — Threshold Filter

The SP first builds `#EOD` from `External_etoro_Billing_Redeem` (RedeemStatusID=1 — pending/active redeems only), joining `Dim_GetSpreadedPriceCandle60MinSplitted` on `InstrumentID` at `DateTo=@day` (yesterday) to get `BidLast`. EOD value per position = `Units * BidLast`.

Then `#redeems` aggregates to CID level with `HAVING SUM(ValueEOD) > 50000`. Only customers whose total pending redeem value exceeds $50,000 appear in the final table.

### 2.2 Amount — EOD Valuation

Amount is `SUM(Units × BidLast)` for all pending positions. This is a mark-to-market value at yesterday's close — it fluctuates with market prices. The same customer's Amount can differ each day as prices change or additional redeems are added/processed.

### 2.3 V_Liabilities Hardcoded DateID — CRITICAL DEFECT

The SP contains:
```sql
LEFT JOIN [DWH_dbo].[V_Liabilities] V ON V.CID=a.CID AND DateID=20230504
```
The `DateID` is **hardcoded to 20230504 (May 4, 2023)**. This means:
- **NWA** (V_Liabilities.BonusCredit): always reflects May 2023 bonus credit. Live data shows 0.0000 for all current rows.
- **Balance** (V_Liabilities.Credit): always reflects May 2023 cash balance. NULL if the customer had no V_Liabilities record on that exact date.
- **Equity** (V_Liabilities.Liabilities + ActualNWA): same staleness. NULL for some customers.

**Do not use NWA, Balance, or Equity for any current financial analysis.** The correct fix is `DateID=@dayID` (the SP's own yesterday variable). This is a known defect in line 214 of the SP.

### 2.4 Revenues — Lifetime, Not Redeem-Specific

`Revenues = SUM(CommissionOnClose)` from `Dim_Position` for all positions ever closed by this customer — across all time, all instruments. It is not filtered to the redeem period, the pending redeem instruments, or crypto vs. non-crypto. It represents the customer's all-time lifetime trading value to eToro.

### 2.5 Account Manager Priority

Two sources are joined:
1. `#sf1`: distinct CIDs from `BI_DB_UsageTracking_SF` with `ActionName='Phone_Call_Succeed__c'` in last 12 months, linked via `Dim_Customer.AccountManagerID → Dim_Manager`.
2. Fallback: `Dim_Customer.AccountManagerID → Dim_Manager` directly.

The CASE expression `CASE WHEN sf.[Account Manager] IS NOT NULL THEN sf.[Account Manager] ELSE dm.FirstName + ' ' + dm.LastName END` prefers the SF-linked manager over the demographic one — but both resolve to `Dim_Manager.FirstName + ' ' + LastName`, so in practice they yield the same name.

### 2.6 Case Inconsistency in Flag Columns

Three binary flag columns have inconsistent casing:
- `ProvidedSelfie`: 'Yes' / 'No' (Title Case)
- `WasContactedLast12Months`: 'yes' / 'no' (lowercase)
- `ExpiredPOI`: 'yes' / 'no' (lowercase)

String comparisons must use the exact case. `WHERE ProvidedSelfie = 'Yes'` and `WHERE ExpiredPOI = 'yes'` — not interchangeable.

### 2.7 AMLComment / RiskComment Empty String Convention

Stored as `''` (empty string), not NULL, when no comment exists. Filter using `AMLComment <> ''` rather than `AMLComment IS NOT NULL`.

---

## 3. Column / Element Reference

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID (platform RealCID). Sourced from External_etoro_Billing_Redeem; population confirmed via Dim_Customer.RealCID joins. Only customers with SUM(pending redeem EOD value) > $50,000 appear. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 2 | MaxRequestDate | date | YES | Most recent pending redeem request date — MAX(CAST(RequestDate AS date)) per CID across all open redeems. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 3 | Amount | money | YES | Total EOD value of all pending redeems in USD — SUM(Units × BidLast) at yesterday's closing price from Dim_GetSpreadedPriceCandle60MinSplitted (DateTo=@day). Threshold filter: >$50,000. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 4 | Type | varchar(100) | YES | Hardcoded literal constant 'Redeem'. No other values exist in this table. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 5 | Country | varchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dictionary.Country) |
| 6 | Age | int | YES | Customer age in full years at ETL run time — DATEDIFF(year, BirthDate, GETDATE()). Reflects age at SP execution, not at redeem request date. Not birthday-accurate (truncates fractional years). (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 7 | Regulation | varchar(100) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — Dictionary.Regulation) |
| 8 | AMLComment | varchar(8000) | YES | AML team review notes from BackOffice — ISNULL(AMLComment, ''). Stored as '' (empty string, not NULL) when no comment. May contain multi-date annotated review history as free text. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 9 | RiskComment | varchar(8000) | YES | Risk team review notes from BackOffice — ISNULL(RiskComment, ''). Empty string when no comment. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 10 | ProvidedSelfie | varchar(100) | YES | Whether the customer submitted a selfie document — 'Yes' if DocumentTypeID=15 found in BackOffice CustomerDocument records, 'No' otherwise. Values: 'Yes', 'No' (Title Case). (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 11 | WasContactedLast12Months | varchar(100) | YES | Whether a successful Salesforce phone call exists in last 12 months — 'yes' if ActionName='Phone_Call_Succeed__c' in BI_DB_UsageTracking_SF within DATEADD(MONTH,-12,GETDATE()). Values: 'yes', 'no' (lowercase — differs from ProvidedSelfie). (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 12 | [Account Manager] | varchar(100) | YES | Full name (FirstName + ' ' + LastName) of assigned account manager. Priority: SF-linked manager from most recent successful phone contact; falls back to Dim_Customer.AccountManagerID → Dim_Manager. Square brackets required in queries due to space in column name. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 13 | NWA | money | YES | Bonus/credit balance from V_Liabilities.BonusCredit — ISNULL(BonusCredit, 0). STALE: DateID hardcoded to 20230504 (May 4, 2023). Live data confirms 0.0000 for all current rows. Do not use for current financial analysis. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 14 | Revenues | money | YES | All-time lifetime trading commissions — SUM(CommissionOnClose) from Dim_Position for all closed positions. Not filtered by period, instrument type, or date range. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 15 | CustomerStatus | varchar(100) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. (Tier 1 — Dictionary.PlayerStatus) |
| 16 | Verification | varchar(100) | YES | KYC verification status — CASE WHEN VerificationLevelID=3 THEN 'Verified' ELSE 'Not Verified'. Values: 'Verified', 'Not Verified'. Only VerificationLevelID=3 maps to 'Verified'. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 17 | ExpiredPOI | varchar(100) | YES | Whether proof of identity has expired — 'yes' if IsIDProofExpiryDate <= GETDATE(), 'no' otherwise. Values: 'yes', 'no' (lowercase). (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 18 | CompensationAmount | money | YES | Total lifetime compensation credits — SUM(Fact_CustomerAction.Amount WHERE ActionTypeID=36). ISNULL(..., 0): 0 if no compensation. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 19 | Equity | money | YES | Total equity — V_Liabilities.Liabilities + V_Liabilities.ActualNWA. STALE: DateID hardcoded to 20230504. NULL if no V_Liabilities record for this customer at that date. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 20 | Balance | money | YES | Cash credit balance — V_Liabilities.Credit. STALE: DateID hardcoded to 20230504. NULL if no record at that date. (Tier 2 — SP_HighRedeemsApprovalForManagement) |
| 21 | UpdateDate | datetime | YES | SP execution timestamp — GETDATE() at TRUNCATE+INSERT time. (Tier 2 — SP_HighRedeemsApprovalForManagement) |

---

## 4. Typical Data Patterns

- **Row count**: Very small (0–dozens). As of 2026-04-13: **3 rows**. The $50,000 threshold is intentionally high — only significant redeems appear.
- **All rows Type='Redeem'**: The Type column is a constant; no other values have ever appeared.
- **NWA always 0.0000**: Due to the hardcoded DateID=20230504 in V_Liabilities join, BonusCredit returns 0 for current customers with no historical bonus at that exact date.
- **Equity/Balance can be NULL**: Customers who had no V_Liabilities record on 2023-05-04 will have NULL Equity and Balance (confirmed in live data for FCA row).
- **Amount range**: $69,992–$156,041 in current sample. Real values vary with asset prices and redeem activity.
- **UpdateDate**: All rows share the same timestamp (single SP execution per day), e.g., 2026-04-13 04:24:10.
- **MaxRequestDate**: Within the last ~5 business days (redeems pending longer than that are typically resolved or escalated).

---

## 5. Source Systems & ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_Redeem (RedeemStatusID=1 — pending redeems only)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (BidLast at DateTo=@day=yesterday)
  → #EOD: Units * BidLast per position
  → #maxrequest: MAX(RequestDate) per CID
  → #redeems: SUM(ValueEOD) per CID — HAVING SUM > $50,000 threshold
                                       Type = 'Redeem' (hardcoded)

BI_DB_dbo.External_etoro_BackOffice_Customer (AMLComment, RiskComment)
BI_DB_dbo.External_etoro_BackOffice_CustomerDocument (DocumentTypeID=15 → ProvidedSelfie)
BI_DB_dbo.BI_DB_UsageTracking_SF (Phone_Call_Succeed__c last 12 months → WasContactedLast12Months)
DWH_dbo.Dim_Customer + Dim_Country + Dim_Regulation + Dim_PlayerStatus + Dim_Manager
DWH_dbo.Dim_Position (SUM CommissionOnClose → Revenues)
DWH_dbo.Fact_CustomerAction (ActionTypeID=36 → CompensationAmount)
DWH_dbo.V_Liabilities (DateID=20230504 HARDCODED → NWA/Balance/Equity — STALE)
  |
  |-- SP_HighRedeemsApprovalForManagement
  |     TRUNCATE TABLE BI_DB_D_HighRedeemsApprovalForManagement
  |     + INSERT FROM #clients
  |     (No @date parameter; always yesterday = GETDATE()-1)
  v
BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement
  (~3 rows as of 2026-04-13 | HEAP | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Common Query Patterns

```sql
-- Current high redeem approvals pending (ordered by amount)
SELECT
    CID, MaxRequestDate, Amount, Country, Regulation,
    CustomerStatus, Verification, ExpiredPOI,
    WasContactedLast12Months, [Account Manager],
    AMLComment, Revenues
FROM BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement
ORDER BY Amount DESC;
```

```sql
-- Customers with AML or Risk flags on high redeems
SELECT
    CID, Amount, Country, Regulation,
    AMLComment, RiskComment, Verification, CompensationAmount
FROM BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement
WHERE AMLComment <> '' OR RiskComment <> ''
ORDER BY Amount DESC;
```

```sql
-- FCA-regulated customers not recently contacted
SELECT
    CID, MaxRequestDate, Amount,
    [Account Manager], WasContactedLast12Months,
    ExpiredPOI, Verification
FROM BI_DB_dbo.BI_DB_D_HighRedeemsApprovalForManagement
WHERE Regulation = 'FCA'
  AND WasContactedLast12Months = 'no'
ORDER BY Amount DESC;
```

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| SP_HighRedeemsApprovalForManagement | Writer stored procedure (TRUNCATE+INSERT daily) |
| BI_DB_dbo.External_etoro_Billing_Redeem | Source for pending redeem positions and EOD valuation base |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | EOD bid price source (DateTo=yesterday) |
| DWH_dbo.V_Liabilities | Source for NWA/Balance/Equity (STALE — DateID hardcoded 20230504) |
| BI_DB_dbo.External_etoro_BackOffice_Customer | Source for AMLComment, RiskComment |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | Source for ProvidedSelfie (DocumentTypeID=15) |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Source for WasContactedLast12Months (SF phone call history) |
| DWH_dbo.Dim_Position | Source for Revenues (lifetime SUM CommissionOnClose) |
| DWH_dbo.Fact_CustomerAction | Source for CompensationAmount (ActionTypeID=36 compensation) |
| DWH_dbo.Dim_Customer | Source for Age, RegulationID, CountryID, VerificationLevelID, IsIDProofExpiryDate |
| DWH_dbo.Dim_Manager | Source for Account Manager name |
| DWH_dbo.Dim_Country | T1 source for Country |
| DWH_dbo.Dim_Regulation | T1 source for Regulation |
| DWH_dbo.Dim_PlayerStatus | T1 source for CustomerStatus |

---

## 8. Atlassian Knowledge Sources

*(No Confluence pages or Jira tickets linked at time of documentation.)*

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 13/14*
