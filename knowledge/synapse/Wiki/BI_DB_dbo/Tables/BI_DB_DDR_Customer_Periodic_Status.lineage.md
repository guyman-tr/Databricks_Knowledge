# BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status — Column Lineage (Phase 10B)
> Produced before wiki (`00-execution-card`). Source trace = `BI_DB_dbo.SP_DDR_Customer_Periodic_Status.sql` repo path.

## Source Objects

| Object | Role |
|---|---|
| `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | Primary fact feed for all rolling aggregates |
| `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | Loader / boundary definitions |
| `DWH_dbo.Fact_SnapshotCustomer` (via Daily) | Static attribute origins for Regulation/Country/etc. |
| `Dim_Country`, `Dim_Regulation`, … (via Daily joins) | Descriptive lookups referenced in DDR daily wiki |

## Phase 9 — Stored Procedure Narrative (verbatim structure)

```text
PHASE 9 CHECKPOINT: PASS — SP_DDR_Customer_Periodic_Status @date READ

1) DECLARE @dateID,@weekstart,@monthstart,@quarterstart,@yearstart (+ INT twins)

   declare @weekstart DATE = DATEADD(week, DATEDIFF(ww, 0, @date), -1)
   declare @monthstart date = DATEADD(month, DATEDIFF(mm, 0, @date), 0)
   declare @quarterstart date = DATEADD(qq, DATEDIFF(qq, 0, @date), 0)
   declare @yearstart date = DATEADD(yy, DATEDIFF(yy, 0, @date), 0)

2) DELETE target WHERE DateID = @dateID

3) CTE DAILY
   SELECT bddcds.*, ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID DESC) rn
   FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
   WHERE DateID BETWEEN @yearstartInt AND @dateInt;

4) CTE ACTIVETYPEPREP — GROUP BY RealCID
   Applies rolling windows (@week/month/quarter/year) with MAX(case ..) ladders for each outbound column alias.

5) Outer INSERT SELECT — GROUP BY RealCID, Date, DateID, FirstActionTypes*, MarketingRegions*
   Re-aggregates SUM / COUNT portfolios for hierarchical engagement metrics.
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|---|---|---|---|---|
| `RealCID` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `RealCID` | GROUP BY customer | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Date` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `@date` | parameter passthrough |  |
| `DateID` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `@dateInt` | CAST yyyyMMdd |  |
| `FirstActionType_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstActionType` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `RegulationID_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `RegulationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsCreditReportValidCB_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsCreditReportValidCB` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsValidCustomer_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsValidCustomer` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MifidCategorizationID_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MifidCategorizationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `PlayerLevelID_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `PlayerLevelID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `CountryID_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `CountryID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MarketingRegion_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MarketingRegion` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsFunded_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsFunded` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstTimeFunded_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstTimeFunded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ActiveTraded_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ActiveTraded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Portfolio_Only_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Portfolio_Only` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `BalanceOnlyAccount_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `BalanceOnlyAccount` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IBANFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IBANFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPExternalFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPExternalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalRedeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalRedeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalCashedOut_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalCashedOut` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Redeemed_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Redeemed` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedTP_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedIBAN_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedTP_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedIBAN_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstActionType_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstActionType` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `RegulationID_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `RegulationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsCreditReportValidCB_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsCreditReportValidCB` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsValidCustomer_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsValidCustomer` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MifidCategorizationID_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MifidCategorizationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `PlayerLevelID_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `PlayerLevelID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `CountryID_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `CountryID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MarketingRegion_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MarketingRegion` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsFunded_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsFunded` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstTimeFunded_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstTimeFunded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ActiveTraded_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ActiveTraded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Portfolio_Only_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Portfolio_Only` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `BalanceOnlyAccount_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `BalanceOnlyAccount` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IBANFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IBANFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPExternalFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPExternalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalRedeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalRedeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalCashedOut_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalCashedOut` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Redeemed_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Redeemed` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedTP_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedIBAN_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedTP_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedIBAN_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstActionType_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstActionType` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `RegulationID_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `RegulationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsCreditReportValidCB_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsCreditReportValidCB` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsValidCustomer_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsValidCustomer` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MifidCategorizationID_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MifidCategorizationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `PlayerLevelID_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `PlayerLevelID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `CountryID_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `CountryID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MarketingRegion_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MarketingRegion` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsFunded_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsFunded` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstTimeFunded_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstTimeFunded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ActiveTraded_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ActiveTraded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Portfolio_Only_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Portfolio_Only` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `BalanceOnlyAccount_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `BalanceOnlyAccount` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IBANFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IBANFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPExternalFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPExternalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalRedeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalRedeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalCashedOut_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalCashedOut` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Redeemed_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Redeemed` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedTP_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedIBAN_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedTP_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedIBAN_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstActionType_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstActionType` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `RegulationID_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `RegulationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsCreditReportValidCB_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsCreditReportValidCB` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsValidCustomer_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsValidCustomer` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MifidCategorizationID_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MifidCategorizationID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `PlayerLevelID_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `PlayerLevelID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `CountryID_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `CountryID` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MarketingRegion_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MarketingRegion` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IsFunded_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IsFunded` | MAX(CASE window + rn=1 snapshot) + outer SUM (see SP — static attrs as-of @date) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `FirstTimeFunded_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `FirstTimeFunded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ActiveTraded_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ActiveTraded` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Portfolio_Only_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Portfolio_Only` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `BalanceOnlyAccount_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `BalanceOnlyAccount` | COUNT CASE portfolio/balance vs ActiveTraded hierarchy (SP outer SELECT; YEAR rows: verify ActiveTraded_ThisQuarter predicate) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `IBANFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `IBANFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `TPExternalFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `TPExternalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalRedeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalRedeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `GlobalCashedOut_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `GlobalCashedOut` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `Redeemed_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `Redeemed` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedTP_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedIBAN_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedTP_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedTP` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedIBAN_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedIBAN` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `UpdateDate` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `GETDATE()` | load stamp |  |
| `WeekStart` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `weekstart` | DATEADD literal |  |
| `MonthStart` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `monthstart` | DATEADD literal |  |
| `QuarterStart` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `quarterstart` | DATEADD literal |  |
| `YearStart` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `yearstart` | DATEADD literal |  |
| `WeekStartDateID` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `WeekStartDateID` | CAST int |  |
| `MonthStartDateID` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `MonthStartDateID` | CAST int |  |
| `QuarterStartDateID` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `QuarterStartDateID` | CAST int |  |
| `YearStartDateID` | `BI_DB_dbo.SP_DDR_Customer_Periodic_Status` | `YearStartDateID` | CAST int |  |
| `OptionsFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `OptionsFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedOptions_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedOptions_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `OptionsFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `OptionsFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedOptions_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedOptions_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `OptionsFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `OptionsFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedOptions_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedOptions_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `OptionsFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `OptionsFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `DepositedOptions_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `DepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `ReDepositedOptions_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `ReDepositedOptions` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MoneyFarmFirstDeposited_ThisWeek` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MoneyFarmFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MoneyFarmFirstDeposited_ThisMonth` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MoneyFarmFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MoneyFarmFirstDeposited_ThisQuarter` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MoneyFarmFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |
| `MoneyFarmFirstDeposited_ThisYear` | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` | `MoneyFarmFirstDeposited` | MAX(CASE rolling window) + outer SUM (activity / MIMO ladder columns) | (Tier 2 — BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status) |

## Notes
- `rn=1` semantics tie static attributes to **`@date` daily slice** conditional on window containment.
- Synapse MCP row-count DMV blocked (permission 6004) — cardinality inherited from DDR daily sibling wiki.
