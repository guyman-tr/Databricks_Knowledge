# BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss

Generated: 2026-04-21 | Writer SP: SP_Affiliate_Fraud_Loss | Batch 13 #4

## Business Meaning

Daily fraud monitoring table for **affiliate account holders** — eToro customers registered under AccountTypeID 6 (Affiliate Private Account) or 15 (Affiliate Corporate Account). This table is **not** about clients referred by affiliates; it tracks affiliates **themselves** as eToro customers.

Each row represents one affiliate's activity on a given day, combining:
- **Commission payments** received by the affiliate on that day (`AffiliatePayment` = `CompensationToAffiliate` from `BI_DB_Client_Balance_CID_Level_New`)
- **Fraud/loss flags** identifying affiliates who are blocked and flagged as 'Suspicious Affiliate' (RiskStatusID=60)
- **Total loss exposure** (`Loss` = all-time accumulated CompensationToAffiliate for blocked affiliates)

Two row types co-exist:
- **Payment rows**: Affiliates with CompensationToAffiliate > 0 on @Date — captures all active payment events whether or not the affiliate is blocked.
- **Block-only rows**: Affiliates who were **newly flagged** (RiskStatusID=60) on @Date but had no payment that day — captured to record the block event even with zero payment.

**Row count**: 15,464 | **Day range**: 20220110–20260324 | **Grain**: Affiliate (RealCID) × day (YearMonthDay) | **2,251 distinct affiliates**

---

## Business Logic

### Affiliate Account Scope
The SP builds `#all` from `Dim_Customer` where `AccountTypeID IN (6, 15)` AND `IsValidCustomer=1`. This restricts the population to affiliate-type eToro accounts only — it does **not** include all affiliates in the marketing system. An affiliate can have clients without being in this table if they have no eToro trading account of type 6/15.

### Two Row Sources (UNION)
1. **#monthpayments** (payment-triggered rows): Affiliates with `CompensationToAffiliate > 0` on `@Date`. Joined with risk/block info. AffiliateStatus='Blocked' if the affiliate is in `#blocked` at run time; 'Active' otherwise.
2. **#blockeinmonth** (block-triggered rows): Affiliates whose first RiskStatusID=60 event occurred on `@Date`, who have NO payment on `@Date`. Ensures the block event is recorded even without a payment. Filtered via `WHERE b.RealCID NOT IN (SELECT CID FROM #monthpayments)` to prevent double-counting.

### Suspicious Affiliate Definition
An affiliate is 'Suspicious' if ALL three conditions hold:
- PlayerStatus IN ('Blocked', 'Trade & MIMO Blocked') — currently blocked
- Has a risk event where RiskStatusID=60 AND RiskEventStatusID=1 in External_etoro_BackOffice_CustomerRisk
- (Linked to affiliate's own eToro account via GCID → RealCID)

When these conditions hold, `RiskStatus` is **overridden** to the hardcoded string `'Suspicous Affiliate'` (note: typo preserved from SP — should be "Suspicious"). For non-suspicious affiliates, RiskStatus comes from Dim_RiskStatus.Name.

### Loss Calculation
`Loss` = SUM of all CompensationToAffiliate (any date) from BI_DB_Client_Balance_CID_Level_New for **blocked** affiliates. For non-blocked affiliates, Loss = 0. This represents total historical commission payout to blocked/suspicious affiliates — a proxy for fraud-related financial exposure.

### Block Date Columns
`YearMonth-Block` and `YearMonthDay-Block` capture the YYYYMM/YYYYMMDD of the **first** risk event date for blocked affiliates. NULL for affiliates who are not blocked/suspicious.

---

## Query Advisory

- **This table tracks affiliates as eToro customers**, not clients referred by affiliates. `RealCID` is the affiliate's own trading account CID (NOT a referred client's CID). Do not join to BI_DB_CIDFirstDates on RealCID expecting client data.
- **Column names with hyphens** (`YearMonth-Block`, `YearMonthDay-Block`) require square-bracket quoting in T-SQL: `[YearMonth-Block]`.
- **Country and KYCCountry are typically identical** — both are resolved from `Dim_Country.Name` via `Dim_Customer.CountryID`. Do not use both in GROUP BY/analysis without verifying they diverge (see review notes).
- **'Suspicous Affiliate' has a typo** (missing 'i') — string comparisons must use the misspelled form: `WHERE RiskStatus = 'Suspicous Affiliate'`.
- **AffiliatePayment = 0 for block-only rows** — block-triggered rows (#blockeinmonth) may have AffiliatePayment = 0 when the affiliate was newly blocked on @Date but had no CompensationToAffiliate payment that day.
- **ROUND_ROBIN, HEAP** — no clustered index. Range predicates on YearMonthDay improve performance. Avoid full scans; always filter by date or RealCID.
- **ID column is IDENTITY** — auto-assigned, not carried through the SP INSERT. It is a physical surrogate key only.

---

## Elements

| # | Column | Type | Description | Tier |
|---|--------|------|-------------|------|
| 1 | ID | INT IDENTITY | Auto-increment surrogate key. Not inserted via the SP (IDENTITY); assigned by Synapse at INSERT time. Not a meaningful business key. | Tier 5 |
| 2 | RealCID | INT | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here: the affiliate's own eToro trading account CID (AccountTypeID 6/15). | Tier 1 — DWH_dbo.Dim_Customer |
| 3 | YearMonth | INT | Compact year-month integer (YYYYMM). For payment rows: derived from BI_DB_Client_Balance_CID_Level_New.Date. For block-only rows: derived from the block event date (MIN(r.Occurred) in #blockedaffiliates). | Tier 2 |
| 4 | YearMonthDay | INT | Compact date integer (YYYYMMDD). Same sourcing logic as YearMonth. The DELETE pattern removes all rows WHERE YearMonthDay=@YearMonthDay before re-inserting. | Tier 2 |
| 5 | AffiliatePayment | MONEY | Sum of CompensationToAffiliate from BI_DB_Client_Balance_CID_Level_New for @Date. Represents affiliate commission paid on that day. 0 for block-only rows (ISNULL(…,0)). | Tier 2 |
| 6 | Loss | MONEY | Sum of all-time CompensationToAffiliate for blocked (suspicious) affiliates — total historical commission paid as fraud-related loss exposure. 0 for non-blocked affiliates (ISNULL(…,0)). | Tier 2 |
| 7 | DesignatedRegulation | VARCHAR(MAX) | Short code for the regulation (DesignatedRegulationID). Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. | Tier 1 — DWH_dbo.Dim_Regulation |
| 8 | Regulation | VARCHAR(MAX) | Short code for the regulation (primary RegulationID). Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. | Tier 1 — DWH_dbo.Dim_Regulation |
| 9 | PlayerStatus | VARCHAR(MAX) | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. | Tier 1 — DWH_dbo.Dim_PlayerStatus |
| 10 | RegisteredReal | DATETIME | Account registration date (renamed from Registered). Default=getdate(). Real-account registration datetime from eToro BackOffice. | Tier 1 — DWH_dbo.Dim_Customer |
| 11 | RiskStatus | VARCHAR(MAX) | Override: 'Suspicous Affiliate' (hardcoded — note typo) for affiliates who are blocked AND have RiskStatusID=60 risk events. For all others: human-readable risk flag name from Dim_RiskStatus.Name. Mix of PascalCase codes and plain English. | Tier 2 |
| 12 | Country | VARCHAR(MAX) | Country name resolved from Dim_Country.Name via Dim_Customer.CountryID at the time #all is built. Typically identical to KYCCountry. | Tier 1 — DWH_dbo.Dim_Country |
| 13 | AffiliateStatus | VARCHAR(MAX) | ETL-computed account status. 'Blocked' if the affiliate is in the #blocked set (PlayerStatus IN ('Blocked','Trade & MIMO Blocked') AND has a risk event) at run time; 'Active' otherwise. | Tier 2 |
| 14 | YearMonth-Block | INT | Compact year-month (YYYYMM) of the first suspicious risk event date for blocked affiliates. NULL for non-blocked/non-suspicious affiliates. Requires square-bracket quoting: [YearMonth-Block]. | Tier 2 |
| 15 | YearMonthDay-Block | INT | Compact date (YYYYMMDD) of the first suspicious risk event for blocked affiliates. NULL for non-blocked/non-suspicious affiliates. Requires square-bracket quoting: [YearMonthDay-Block]. | Tier 2 |
| 16 | KYCCountry | VARCHAR(MAX) | Country name resolved from Dim_Country.Name via Dim_Customer.CountryID in #FINAL enrichment join. In practice identical to Country — same source (CountryID). See review notes for redundancy assessment. | Tier 1 — DWH_dbo.Dim_Country |
| 17 | CountryByRegIP | VARCHAR(MAX) | Country name resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP. Country inferred from the IP address at registration. May differ from Country/KYCCountry if VPN or relocation detected. | Tier 1 — DWH_dbo.Dim_Country |
| 18 | FundingType | VARCHAR(MAX) | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Most recent funding type from Fact_CustomerAction (ActionTypeID IN (7,8)) ordered by Occurred DESC. NULL if no qualifying action exists. | Tier 1 — DWH_dbo.Dim_FundingType |
| 19 | UpdateDate | DATETIME | ETL metadata: timestamp when the row was inserted, set via GETDATE() at INSERT time. | Tier 5 |

**Tier legend**: Tier 1 = value/description inherited verbatim from upstream DWH_dbo wiki. Tier 2 = derived by SP/ETL logic. Tier 5 = canonical ETL metadata column (ID surrogate key, UpdateDate).

---

## Lineage

See [BI_DB_Affiliate_Fraud_Loss.lineage.md](BI_DB_Affiliate_Fraud_Loss.lineage.md) for full ETL chain, column lineage, and source objects.

```
DWH_dbo.Dim_Customer (AccountTypeID IN 6,15 — affiliate accounts)
  |-- #all: full affiliate roster with regulation/country/status enrichment
  |-- #blocked + #risk → #blockedaffiliates → #blockedtime
  |-- BI_DB_Client_Balance_CID_Level_New → #DATA (payments on @Date), #DATA1 (all-time)
  |-- #LOSS: total loss for blocked affiliates
  |-- #monthpayments UNION #blockeinmonth → #FINAL1
  |-- Dim_Customer + Dim_Country + Fact_CustomerAction → #FINAL
  v
SP_Affiliate_Fraud_Loss (@Date — Daily, SB_Daily, Priority 20)
  DELETE WHERE YearMonthDay=@YearMonthDay → INSERT
  v
BI_DB_Affiliate_Fraud_Loss (15,464 rows, 2,251 affiliates)
  v [UC Target: _Not_Migrated]
```

**Distribution**: ROUND_ROBIN | **Index**: HEAP | **UC Target**: _Not_Migrated

---

## Relationships

| Object | Schema | Type | Join Key | Purpose |
|--------|--------|------|----------|---------|
| Dim_Customer | DWH_dbo | Source | AccountTypeID IN (6,15) | Affiliate-type accounts: RealCID, RegisteredReal, CountryID, CountryIDByIP, RegulationID, DesignatedRegulationID, PlayerStatusID |
| Dim_Regulation | DWH_dbo | Dimension | DesignatedRegulationID / RegulationID | DesignatedRegulation and Regulation names |
| Dim_Country | DWH_dbo | Dimension | CountryID / CountryIDByIP | Country, KYCCountry, CountryByRegIP names |
| Dim_PlayerStatus | DWH_dbo | Dimension | PlayerStatusID | PlayerStatus name |
| Dim_RiskStatus | DWH_dbo | Dimension | RiskStatusID | RiskStatus name (overridden for suspicious affiliates) |
| Dim_FundingType | DWH_dbo | Dimension | FundingTypeID | FundingType name |
| Fact_CustomerAction | DWH_dbo | Source | RealCID | Most recent deposit method (ActionTypeID IN (7,8)) |
| External_etoro_BackOffice_CustomerRisk | BI_DB_dbo | Source | GCID → RealCID | Risk events: RiskStatusID=60, RiskEventStatusID=1 |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo | Source | CID = RealCID | Daily CompensationToAffiliate commission payments |

---

## Sample Queries

```sql
-- Suspicious affiliates flagged today with their total loss exposure
SELECT
    RealCID,
    DesignatedRegulation,
    Country,
    AffiliatePayment,
    Loss,
    RiskStatus,
    [YearMonth-Block],
    FundingType
FROM BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss
WHERE YearMonthDay = 20260324
  AND RiskStatus = 'Suspicous Affiliate'
ORDER BY Loss DESC;

-- Monthly affiliate payment summary by regulation (exclude blocked)
SELECT
    YearMonth,
    DesignatedRegulation,
    SUM(AffiliatePayment) AS TotalPayments,
    COUNT(DISTINCT RealCID) AS AffiliateCount
FROM BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss
WHERE AffiliateStatus = 'Active'
GROUP BY YearMonth, DesignatedRegulation
ORDER BY YearMonth DESC, TotalPayments DESC;

-- All-time top loss affiliates (blocked, by accumulated payments)
SELECT
    RealCID,
    Country,
    DesignatedRegulation,
    MAX(Loss) AS MaxLoss,
    MIN([YearMonth-Block]) AS FirstBlockMonth
FROM BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss
WHERE AffiliateStatus = 'Blocked'
GROUP BY RealCID, Country, DesignatedRegulation
ORDER BY MaxLoss DESC;
```

---

## Atlassian

**Confluence**: No dedicated page identified for this specific table.
**Jira**: No open tickets identified.

---

Quality: 8.5/10
