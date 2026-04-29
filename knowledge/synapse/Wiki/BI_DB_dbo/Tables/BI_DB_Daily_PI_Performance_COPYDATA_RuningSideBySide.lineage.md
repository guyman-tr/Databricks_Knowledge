# Lineage — BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide

## Source Objects

| Source Object | Schema | Kind | Role in ETL |
|--------------|--------|------|-------------|
| SP_Daily_PI_Performance_COPYDATA_RuningSideBySide | BI_DB_dbo | SP (writer) | DELETE WHERE DateINT=@yesterdayINT + INSERT daily |
| BI_DB_PI_Dashboard | BI_DB_dbo | Table | PI population filter (PI/CP='PI', Date=@yesterday); supplies CID, UserName, PI_level, Acc_RiskIndex, IsBlocked, Classification, TraderType, performance metrics |
| BI_DB_PositionPnL | BI_DB_dbo | Table | Position amounts, PnL, and leverage per CID on @yesterdayINT for top-position computation |
| Dim_Instrument | DWH_dbo | Table | SymbolFull lookup for each InstrumentID |
| V_Liabilities | DWH_dbo | View | Credit denominator for Value_percenet calculation on @yesterdayINT |
| Fact_CustomerAction | DWH_dbo | Table | Mirror-flow amounts (ActionTypeID 15–18) on @yesterdayINT for NetMoneyIn |
| Dim_Mirror | DWH_dbo | Table | Maps MirrorID → ParentCID to identify the PI as copy leader |
| Dim_Customer | DWH_dbo | Table | PI validation join (GuruStatusID ≥ 2, IsValidCustomer=1) in NetMoneyIn subquery |
| BI_DB_CopyDailyData | BI_DB_dbo | Table | CopyAUM (→ CopyEquity), NumOfCopiers, Manager, Country for DateID=@yesterdayINT |

---

## Column Lineage

| # | Column | Source Object | Source Column | Tier | Transform |
|---|--------|--------------|---------------|------|-----------|
| 1 | Date | SP param | @yesterday | Tier 2 | Direct assignment of @yesterday (DATE) |
| 2 | DateINT | SP param | @yesterday | Tier 2 | CONVERT(CHAR(8), @yesterday, 112) cast to INT |
| 3 | CID | BI_DB_PI_Dashboard | CID | Tier 3 | Passthrough; BI_DB_PI_Dashboard has no upstream wiki in bundle |
| 4 | UserName | BI_DB_PI_Dashboard | UserName | Tier 3 | Passthrough; no upstream wiki |
| 5 | PI_level | BI_DB_PI_Dashboard | PI_level | Tier 3 | Passthrough; no upstream wiki |
| 6 | Acc_RiskIndex | BI_DB_PI_Dashboard | Acc_RiskIndex | Tier 3 | Passthrough; no upstream wiki |
| 7 | IsBlocked | BI_DB_PI_Dashboard | IsBlocked | Tier 3 | Passthrough; no upstream wiki |
| 8 | Classification | BI_DB_PI_Dashboard | Classification | Tier 3 | Passthrough; no upstream wiki |
| 9 | TraderType | BI_DB_PI_Dashboard | TraderType | Tier 3 | Passthrough; no upstream wiki |
| 10 | SymbolFull | DWH_dbo.Dim_Instrument | SymbolFull | Tier 1 | Passthrough via #TopPositionValue (top position by Value_percenet per CID); root: Trade.InstrumentMetaData; wiki: `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md` |
| 11 | Value_percenet | BI_DB_PositionPnL + V_Liabilities | Amount, PositionPnL, Credit | Tier 2 | ROUND(SUM(Amount+PositionPnL) / (Total_Position_Value + V_Liabilities.Credit), 3) for top instrument |
| 12 | Lev_weighted_average | BI_DB_PositionPnL | Leverage, Amount | Tier 2 | COALESCE(SUM(Leverage*Amount)/NULLIF(SUM(Amount),0),0) for the top-ranked instrument |
| 13 | Last_Day_Performance | BI_DB_PI_Dashboard | Last_Day_Performance | Tier 3 | Passthrough; no upstream wiki |
| 14 | YTD | BI_DB_PI_Dashboard | YTD | Tier 3 | Passthrough; no upstream wiki |
| 15 | MTD | BI_DB_PI_Dashboard | MTD | Tier 3 | Passthrough; no upstream wiki |
| 16 | CopyEquity | BI_DB_CopyDailyData | CopyAUM | Tier 1 | Passthrough renamed CopyAUM → CopyEquity; ISNULL(CopyAUM, 0) in SP. Root formula: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers; wiki: `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md` |
| 17 | NumOfCopiers | BI_DB_CopyDailyData | NumOfCopiers | Tier 1 | ISNULL(NumOfCopiers, 0); wiki: `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md` |
| 18 | NetMoneyIn | DWH_dbo.Fact_CustomerAction | Amount | Tier 2 | -1 * SUM(Amount) for ActionTypeID IN (15,16,17,18) where PI is the copy leader (via Dim_Mirror.ParentCID) |
| 19 | UpdateDate | SP | GETDATE() | Tier 2 | Row-load timestamp set to GETDATE() at SP execution |
| 20 | Manager | BI_DB_CopyDailyData | Manager | Tier 1 | Passthrough; wiki: `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md` |
| 21 | Country | BI_DB_CopyDailyData | Country | Tier 1 | Passthrough; root: Dictionary.Country; wiki: `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md` |
