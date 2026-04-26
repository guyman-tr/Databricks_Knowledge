# Column Lineage — BI_DB_dbo.BI_DB_MarketingDailyRawData

**Writer SP**: `BI_DB_dbo.SP_Marketing_Cube` (@Date parameter, daily)
**ETL Pattern**: DELETE-INSERT — deletes DateID ≥ last-month-start AND DateID < 2-years-back, then re-inserts from @StartOfLastMonth to @Date
**Grain**: AffiliateID × CountryID × DateID × Funnel (CROSS JOIN of all active combinations with any data)
**Rolling window**: ~2 years (DateID range: 2024-03-01 → 2026-04-11 as of Apr 2026 sample)
**Note**: Sparse matrix — most AffiliateID×CountryID×DateID×Funnel combinations have NULL metrics; WHERE clause at INSERT filters out rows with no data across all metrics.

---

## Source Chain

```
DWH_dbo.Dim_Affiliate ────────────────────────────────→ #AffiliateBasicData (Channel, Contract, Group details)
DWH_dbo.Dim_Channel ──────────────────────────────────→ (via Dim_Affiliate.SubChannelID)
DWH_dbo.Dim_ContractType ─────────────────────────────→ (via Dim_Affiliate.ContractType)
DWH_dbo.Dim_Customer ──┐
DWH_dbo.Dim_Funnel ────┤──→ #funnel (CID → AffiliateID × Funnel [Dim_Platform])
DWH_dbo.Dim_Platform ──┘

External_fiktivo_AffiliateCommission_* ──────────────→ #CostOfLastMonth (TotalCost, RevShare, Chargebacks, CPA, CPL, eCost, Lead_Comm, Tier2/3)
External_fiktivo_AffiliateCommission_Credit (Tier=1) ─→ #FTDe (EFTD) + #FTDA (FTDA amounts)
DWH_dbo.Dim_Customer ────────────────────────────────→ #Registration (Registration counts)
DWH_dbo.Dim_Customer + fiktivo_AffiliateCommission ──→ #FTDandSameDayFTDWithFunnel (FTD + SameDayFTD)
BI_DB_dbo.BI_DB_CIDFirstDates ───────────────────────→ #IsRev (IsRev, Redeposits) [UPDATE after INSERT]
BI_DB_dbo.BI_DB_FirstTimeRev10 ──────────────────────→ #IsRev (Rev10) [UPDATE after INSERT]
BI_DB_dbo.BI_DB_LTV_BI_Actual ───────────────────────→ #LTV (GLTV, totalGroupLTV, totalExtLTV, FTDfromLTV)
BI_DB_dbo.BI_DB_AppFlyer_Reports ────────────────────→ #AffInstalls (Installs)
fiktivo_AffiliateCommission_ClosedPosition ──────────→ #NetRevWithFunnel (NetRevenues)
DWH_dbo.Dim_Customer + Billing deposits ─────────────→ #TotalDeposit_TotalRevenue (TotalDeposit, DBRev)
fiktivo_AffiliateCommission (RAF) ───────────────────→ #CostRAF (RAF_Comm)
DWH_dbo.Dim_Country ─────────────────────────────────→ CountryName, Region, Desk, NewMarketingRegion
DWH_dbo.Dim_Date ────────────────────────────────────→ DateID, Date (loop over @StartOfLastMonth→@Date)

#Affiliates (CROSS JOIN: Dim_Affiliate × Dim_Country × Dim_Platform) ──→ grain scaffold
         │
         ↓ (LEFT JOIN all metric temp tables on AffiliateID × CountryID × DateID × Funnel)
DELETE WHERE DateID >= @StartOfLastMonth OR DateID < @StartOfMonth2YearsBack
INSERT INTO BI_DB_dbo.BI_DB_MarketingDailyRawData
         │
         ↓ UPDATE pass: IsRev, Redeposits, Rev10 from #IsRev (3-month FTD window)
         ↓ UPDATE pass: Channel, SubChannel, Organic/Paid from current Dim_Affiliate (retroactive from 2019-01-01)
```

---

## Column-Level Lineage

| BI_DB Column | Source Table | Source Column | Transform |
|-------------|-------------|---------------|-----------|
| AffiliateID | DWH_dbo.Dim_Affiliate | AffiliateID | CROSS JOIN grain. All affiliates active in any metric source for the period |
| CountryID | DWH_dbo.Dim_Country | CountryID | CROSS JOIN grain. All 249 countries |
| DateID | DWH_dbo.Dim_Date | DateKey | YYYYMMDD string. Loop covers @StartOfLastMonth → @Date |
| Date | DWH_dbo.Dim_Date | FullDate | Date. Loop covers @StartOfLastMonth → @Date |
| Funnel | DWH_dbo.Dim_Platform | Platform | CROSS JOIN grain. Values: Web, IOS, Android, Undefined. Via Dim_Funnel.PlatformID |
| CountryName | DWH_dbo.Dim_Country | Name | Direct. ISNULL(DC.Name, j.CountryName) with fallback to #AffInstalls |
| Region | DWH_dbo.Dim_Country | Region | Standard geographic region from Dim_Country.Region |
| Desk | DWH_dbo.Dim_Country | Desk | Country desk assignment from Dim_Country.Desk |
| DateCreated | DWH_dbo.Dim_Affiliate | DateCreated | Affiliate account creation date. ISNULL with #AffInstalls fallback |
| Channel | DWH_dbo.Dim_Channel | Channel | Via Dim_Affiliate.SubChannelID → Dim_Channel. Retroactively updated for DateID ≥ 2019-01-01 |
| SubChannel | DWH_dbo.Dim_Channel | SubChannel | Same join |
| Organic/Paid | DWH_dbo.Dim_Channel | Organic/Paid | Classification flag from Dim_Channel |
| Contact | DWH_dbo.Dim_Affiliate | Contact | Affiliate contact/campaign identifier |
| ContractName | DWH_dbo.Dim_Affiliate | ContractName | Affiliate contract name |
| ContractType | DWH_dbo.Dim_ContractType | Name | Via Dim_Affiliate.ContractType = Dim_ContractType.ContractTypeID |
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Affiliate group/network name |
| AccountActivated | DWH_dbo.Dim_Affiliate | AccountActivated | Whether affiliate account is activated |
| TotalCost | Fiktivo AffiliateCommission | Commission (all types) | SUM of all commission types: RevShare + Chargebacks + CPA + CPL + eCost + Lead_Comm |
| RevShare_Comm | Fiktivo AffiliateCommission_ClosedPosition | Commission | Revenue share commission from closed positions |
| Chargebacks | Fiktivo AffiliateCommission_Credit (CreditTypeID IN 4,5) | Commission | Chargeback + Refund commission credits |
| NumberOfChargebacks | Fiktivo AffiliateCommission_Credit | COUNT(*) | Number of chargeback/refund events |
| CPA_Comm | Fiktivo AffiliateCommission_Credit (CreditTypeID=1) | Commission | Cost Per Acquisition commission |
| CPL_Comm | Fiktivo tblaff_Leads_Commissions | Commission | Cost Per Lead commission |
| eCost | Fiktivo tblaff_eCost_Commissions | Commission | eCost marketing commission |
| Lead_Comm | Fiktivo AffiliateCommission Registration | Commission | Lead commission from registration tracking (added 2023-05) |
| Tier2Commition | Fiktivo AffiliateCommission | Commission (Tier=2) | Sub-affiliate Tier-2 commission amount |
| Tier3Commition | Fiktivo AffiliateCommission | Commission (Tier=3) | Sub-affiliate Tier-3 commission amount |
| Registration | DWH_dbo.Dim_Customer + Fiktivo Registration | COUNT(CID) | Registration count — customers registered under this affiliate during the period |
| SameDayFTD | Fiktivo AffiliateCommission_Credit | CASE | FTD where deposit DateID = registration DateID (same calendar day as sign-up) |
| FTD | Fiktivo AffiliateCommission_Credit | COUNT | Affiliate-attributed First-Time Deposit count. IMPORTANT: Fiktivo affiliate FTDs only, NOT all platform FTDs |
| EFTD | Fiktivo AffiliateCommission_Credit (Tier=1, Valid=1) | IsFirstDeposit | Eligible FTD count: Tier-1 valid CPA-eligible FTDs |
| FTDA | Fiktivo AffiliateCommission_Credit (Tier=1) | Amount | Sum of FTD amounts (USD) for Tier-1 CPA credits only. NOT billing deposit total |
| NetRevenues | Fiktivo ClosedPosition revenue + bonus | Revenues + USED_BONUS_GRAND_TOTAL + Chargebacks | Net revenue = sales revenues + bonus usage + chargeback reversals |
| VerificationLevelID2 | DWH_dbo.Dim_Customer | COUNT(VerificationLevelID=2) | Count of customers who achieved KYC level 2 (document verification) |
| VerificationLevelID3 | DWH_dbo.Dim_Customer | COUNT(VerificationLevelID=3) | Count of customers who achieved KYC level 3 |
| Installs | BI_DB_AppFlyer_Reports | Installs | Mobile app install events tracked via AppsFlyer (restored 2023-07 after data quality fix) |
| TotalDeposit | Billing/DWH deposit pipeline | SUM(deposit amount) | Total deposit amount (all deposits, not only FTD) for this affiliate × country × date |
| DBRev | DWH deposit revenue pipeline | SUM(DBRev) | "Database Revenue" — trading revenue attributed to deposits for this affiliate × country × date |
| RAF_Comm | Fiktivo RAF commission | Commission | Refer-A-Friend commission cost |
| IsRev | BI_DB_CIDFirstDates | SUM(CASE FirstPosOpenDate IS NOT NULL) | Count of FTDs who opened their first trading position within 3 months (revenue-generating). Updated by UPDATE pass |
| Redeposits | BI_DB_CIDFirstDates | SUM(CASE LastDepositDate≠FirstDepositDate) | Count of FTDs who made at least one subsequent deposit. Updated by UPDATE pass |
| PastGRevenue | — | 0 (hardcoded) | Legacy Optimove Gross Revenue field. Always 0 from SP (removed 2020-05). Default value |
| GLTV | BI_DB_LTV_BI_Actual | TotalLTV (SUM) | Gross Lifetime Value: projected total revenue from acquired customers. Source updated 2020-05 |
| FTDfromLTV | BI_DB_LTV_BI_Actual | FTDfromLTV (SUM) | Count of FTDs tracked in the LTV model |
| Rev10 | BI_DB_FirstTimeRev10 | COUNT(CID) | Count of FTDs who achieved the "Rev10" revenue milestone. Updated by UPDATE pass |
| UpdateDate | GETDATE() | — | ETL metadata: SP execution timestamp |
| LTV_NoExtreme | BI_DB_LTV_BI_Actual (separate SP) | LTV excluding outliers | LTV excluding extreme-value outliers. Added 2020-05. Populated by separate LTV SP, not SP_Marketing_Cube |
| NewMarketingRegion | DWH_dbo.Dim_Country | MarketingRegionManualName | Marketing team curated region name. Added 2021-02 |
| Lead_Comm | Fiktivo AffiliateCommission Registration | Commission | Lead commission column (added 2023-05 as separate field, also included in TotalCost) |
| totalGroupLTV | BI_DB_LTV_BI_Actual | totalGroupLTV (SUM) | Group-level total LTV component |
| totalExtLTV | BI_DB_LTV_BI_Actual | totalExtLTV (SUM) | External/extreme component of total LTV |
