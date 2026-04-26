# BI_DB_DepositUsersFirstTouchPoints — Column Lineage

**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_DepositUsersFirstTouchPoints  
**Generated**: 2026-04-22

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Date | SP_DepositUsersFirstTouchPoints | @date | @CalcDate = first of month 2 years prior; each row Date = milestone event date from CIDFirstDates | Tier 2 |
| 2 | AffiliateID | BI_DB_dbo.BI_DB_CIDFirstDates | SerialID | passthrough (renamed) | Tier 1 |
| 3 | CID | BI_DB_dbo.BI_DB_CIDFirstDates | CID | passthrough (IsValidCustomer=1 filter applied) | Tier 1 |
| 4 | Channel | BI_DB_dbo.BI_DB_CIDFirstDates | Channel | passthrough | Tier 2 |
| 5 | SubChannel | BI_DB_dbo.BI_DB_CIDFirstDates | SubChannel | passthrough | Tier 2 |
| 6 | SubAffiliateID | BI_DB_dbo.BI_DB_CIDFirstDates | SubAffiliateID | passthrough (= Dim_Customer.SubSerialID) | Tier 1 |
| 7 | Desk | DWH_dbo.Dim_Country | Desk | JOIN on Country=Name → Desk (sales desk assignment) | Tier 3 |
| 8 | Region | BI_DB_dbo.BI_DB_CIDFirstDates | Region | passthrough | Tier 2 |
| 9 | Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | passthrough | Tier 2 |
| 10 | State | BI_DB_dbo.BI_DB_CIDFirstDates | State | passthrough | Tier 2 |
| 11 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID = BI_DB_CIDFirstDates.RegulationID | Tier 2 |
| 12 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID = BI_DB_CIDFirstDates.DesignatedRegulationID | Tier 2 |
| 13 | FunnelFrom | BI_DB_dbo.BI_DB_CIDFirstDates | FunnelFromName | passthrough (renamed) | Tier 2 |
| 14 | Platform | BI_DB_dbo.BI_DB_CIDFirstDates | FunnelName | passthrough (renamed) | Tier 2 |
| 15 | Install | BI_DB_dbo.BI_DB_CIDFirstDates | FirstInstallDate | PIVOT count(Action='Install') WHERE FirstInstallDate >= @CalcDate → 0/1 | Tier 2 |
| 16 | Registration | BI_DB_dbo.BI_DB_CIDFirstDates | registered | PIVOT count(Action='Registration') → 0/1 | Tier 2 |
| 17 | EmailVerification | — | — | NULL (disabled — permanently not populated) | Tier 2 |
| 18 | VerificationLevel1 | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel1Date | PIVOT count(Action='VerificationLevel1') → 0/1 | Tier 2 |
| 19 | VerificationLevel2 | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | PIVOT count(Action='VerificationLevel2') → 0/1 | Tier 2 |
| 20 | DepositView | — | — | NULL (disabled — permanently not populated) | Tier 2 |
| 21 | DepositSubmits | — | — | NULL (disabled — permanently not populated) | Tier 2 |
| 22 | DepositSubmitClick | — | — | NULL (disabled — permanently not populated) | Tier 2 |
| 23 | VerificationLevel3 | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | PIVOT count(Action='VerificationLevel3') → 0/1 | Tier 2 |
| 24 | DepositAttDB | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositAttempt | PIVOT count(Action='DepositAttDB') → 0/1 | Tier 2 |
| 25 | FTD | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | PIVOT count(Action='FTD') → 0/1 | Tier 2 |
| 26 | OpenTrade | BI_DB_dbo.BI_DB_CIDFirstDates | FirstPosOpenDate | PIVOT count(Action='OpenTrade') → 0/1 | Tier 2 |
| 27 | UpdateDate | SP_DepositUsersFirstTouchPoints | — | GETDATE() at INSERT time | Tier 2 |
| 28 | Platform_fromAction_Regs | DWH_dbo.Fact_CustomerAction | PlatformID | MIN(Platform_fromAction) WHERE ActionTypeID=41 → CASE PlatformID: 'Android_App'/'iOS_App'/'Android_Web'/'iOS_Web'/'Desktop_Web' | Tier 2 |
| 29 | Platform_fromAction_FTD | DWH_dbo.Fact_CustomerAction | PlatformID | MIN(Platform_fromAction) WHERE ActionTypeID=7 AND IsFTD=1 → same CASE | Tier 2 |
| 30 | PhoneVerification | — | — | NULL (disabled since 2021-12-27) | Tier 2 |
| 31 | EvMatchStatus | BI_DB_dbo.BI_DB_CIDFirstDates | EvMatchStatusDate | PIVOT count(Action='EvMatchStatus') → 0/1 | Tier 2 |
| 32 | KYCFlow | — | — | NULL (disabled since 2022-07-03, removed to prevent duplicates) | Tier 2 |
| 33 | FirstNewFunded | BI_DB_dbo.BI_DB_CIDFirstDates | FirstNewFundedDate | PIVOT count(Action='FirstNewFunded') → 0/1 | Tier 2 |
| 34 | FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | PIVOT count(Action='FirstAction') → 0/1 (first trade date) | Tier 2 |
| 35 | SecondAction | BI_DB_dbo.BI_DB_First5Actions | SecondActionDate | PIVOT count(Action='SecondAction') → 0/1 | Tier 2 |
| 36 | FirstCross | BI_DB_dbo.BI_DB_First5Actions | FirstCrossDate | PIVOT count(Action='FirstCross') → 0/1 | Tier 2 |
| 37 | FirstDemoTrade | — | — | Hardcoded '19000101' sentinel (Demo table disconnected since 2024-01-15) → always 0 | Tier 2 |
| 38 | FirstActionType | BI_DB_dbo.BI_DB_First5Actions | FirstAction_Detailed | passthrough | Tier 2 |

---

## ETL Pipeline

```
BI_DB_CIDFirstDates (WHERE ANY milestone date >= @CalcDate AND IsValidCustomer=1)
  + DWH_dbo.Dim_Regulation (x2: Regulation + DesignatedRegulation)
  + BI_DB_First5Actions (FirstActionDate, SecondActionDate, FirstCrossDate, FirstAction_Detailed)
  → #tmp: all qualifying customers with all milestone dates
  → #date: UNION explode (one row per milestone event per customer)
  → #pivot: PIVOT by milestone action → (Date, CID, ...) with 0/1 flags
  + DWH_dbo.Dim_Country → Desk (via Country=Name JOIN)
  + DWH_dbo.Fact_CustomerAction → Platform_fromAction_Regs/FTD
  |-- SP_DepositUsersFirstTouchPoints @date (TRUNCATE + INSERT, full refresh) --|
  v
BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints (14M rows, rolling 2-year window, 2024–2026)
  |-- UC: Not Migrated --|
```

---

## Source Objects

| Source Schema | Source Object | Role |
|---|---|---|
| BI_DB_dbo | BI_DB_CIDFirstDates | Demographics anchor; all milestone dates for qualifying customers |
| BI_DB_dbo | BI_DB_First5Actions | FirstActionDate, SecondActionDate, FirstCrossDate, FirstAction_Detailed |
| DWH_dbo | Dim_Customer | IsValidCustomer=1 filter only (no columns taken) |
| DWH_dbo | Dim_Regulation | Regulation and DesignatedRegulation names via DWHRegulationID |
| DWH_dbo | Dim_Country | Desk lookup via Country name |
| DWH_dbo | Fact_CustomerAction | Platform detection for Registration (ActionTypeID=41) and FTD (ActionTypeID=7 IsFTD=1) |

---

## UC External Lineage

UC Target: **Not Migrated** — no UC entry exists for this table.
