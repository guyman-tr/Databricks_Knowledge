# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (`DESCRIBE TABLE` verified 2026-05-14) |
| **Primary Sources** | `BI_DB_dbo.Function_Revenue_*` TVF family (`Function_Revenue_FullCommissions`, `Function_Revenue_Commissions`, `Function_Revenue_RolloverFee`, `Function_Revenue_Dividend`, `Function_Revenue_SDRT`, `Function_Revenue_TicketFee`, `Function_Revenue_TicketFeeByPercent`, `Function_Revenue_AdminFee`, `Function_Revenue_SpotAdjustFee`, `Function_Revenue_CashoutFee_ExcludeRedeem`, `Function_Revenue_ConversionFee`, `Function_Revenue_DormantFee`, `Function_Revenue_InterestFee`, `Function_Revenue_TransferCoinFee`, `Function_Revenue_Share_Lending`, `Function_Revenue_CryptoToFiat_C2F`, `Function_Revenue_StakingFee`, `Function_Revenue_OptionsPlatform`), plus `BI_DB_dbo.Function_Instrument_Snapshot_Enriched`, `DWH_dbo.Dim_ActionType`, `DWH_dbo.Dim_Instrument`, `BI_DB_dbo.Dim_Revenue_Metrics`, `BI_DB_dbo.V_C2P_Positions`, `BI_DB_dbo.BI_DB_CopyFund_Positions`, `DWH_dbo.Dim_Position`, IBAN/recurring parquet externals |
| **Grain** | One row per `DateID` × `RealCID` × `Metric` × segmentation flags (commission rows also keyed by `ActionTypeID` and instrument / trade posture attributes) |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions` (@date DATE) |
| **Synapse DDL columns** | 27 (`HASH(RealCID)` + clustered columnstore) |
| **Generated** | 2026-05-14 |

---

## Source Objects

| Source Object | Role |
|---------------|------|
| `BI_DB_dbo.Function_Revenue_FullCommissions` | `FullCommission` / `Commission` splits; position-level commission attributes keyed to `Fact_CustomerAction`-sourced grains |
| `BI_DB_dbo.Function_Revenue_Commissions` | `Commission`-only rollup branch |
| `BI_DB_dbo.Function_Revenue_RolloverFee` | `Rollover` overnight fee rows (`ActionTypeID` 35 staged, NULL in final rollup branch) |
| `BI_DB_dbo.Function_Revenue_Dividend` | `Dividends` metric |
| `BI_DB_dbo.Function_Instrument_Snapshot_Enriched` | `IsSQF` enrichment for dividends (`JOIN ON InstrumentID`); technical source Trade.InstrumentGroups `GroupID = 59` per function wiki |
| `BI_DB_dbo.Function_Revenue_SDRT` | `SDRT` metric |
| `BI_DB_dbo.Function_Revenue_TicketFee` / `Function_Revenue_TicketFeeByPercent` | `TicketFee`, `TicketFeeByPercent` |
| `BI_DB_dbo.Function_Revenue_AdminFee` | `AdminFee` |
| `BI_DB_dbo.Function_Revenue_SpotAdjustFee` | `SpotPriceAdjustment` |
| `BI_DB_dbo.Function_Revenue_CashoutFee_ExcludeRedeem` | `CashoutFeeExclRedeem` |
| `BI_DB_dbo.Function_Revenue_ConversionFee` | `ConversionFee` |
| `BI_DB_dbo.Function_Revenue_DormantFee` | `DormantFee` |
| `BI_DB_dbo.Function_Revenue_InterestFee` | `InterestFee` (`WHERE InterestFee IS NOT NULL`) |
| `BI_DB_dbo.Function_Revenue_TransferCoinFee` | `TransferCoinFee` (source filters `Fact_CustomerAction` `ActionTypeID = 30` AND `IsRedeem = 1` per TVF wiki) |
| `BI_DB_dbo.Function_Revenue_Share_Lending` | `ShareLending` |
| `BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F` | `CryptoToFiatFee` |
| `BI_DB_dbo.Function_Revenue_StakingFee` | `StakingLagOneMonth` (`DateID` lagged forward one calendar month vs source) |
| `BI_DB_dbo.Function_Revenue_OptionsPlatform` | `Options_PFOF` (second INSERT pass reloads entire options history keyed by `RevenueMetricID = 18`) |
| `DWH_dbo.Dim_ActionType` | `ActionType` text for commission grains (`JOIN … ON fc.ActionTypeID = dat.ActionTypeID`) |
| `DWH_dbo.Dim_Instrument` | `IsFuture` for `AdminFee` / `SpotPriceAdjustment` aggregations (`JOIN … ON InstrumentID`) |
| `BI_DB_dbo.Dim_Revenue_Metrics` | `RevenueMetricID`, `RevenueMetricCategoryID`, `IncludedInTotalRevenue` via `LEFT JOIN … ON r.Metric = drm.Metric` |
| `BI_DB_dbo.V_C2P_Positions` | `IsC2P` (`CASE WHEN c.PositionID IS NOT NULL THEN 1 ELSE 0 END`) |
| `BI_DB_dbo.BI_DB_CopyFund_Positions` | Smart Portfolio enrichment (`CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`) |
| `BI_DB_dbo.External_bi_output_finance_bi_db_positions_opened_from_iban_parquet` + `External_bi_output_finance_bi_db_positions_closed_to_iban_parquet` + `External_bi_db_recurringinvestment_positions_parquet` | Staged temp tables keyed by `PositionID`; `OPEN`/`CLOSE` dates reconciled vs `Dim_Position`; drive `UPDATE` overlays for `IsOpenedFromIBAN`, `IsClosedToIBAN`, `IsRecurring` |
| `DWH_dbo.Dim_Position` | Supplies `OpenDateID` / `CloseDateID` hydration for IBAN parquet temp tables |

---

## Lineage Chain

```
Production & DWH ledger / instruments (Bronze lake → Synapse dims & facts consumed inside BI_DB TVFs)
       │
       └── BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions (@date)
              │ Stage #rollovers / #dividends / #sdrt / #ticketFee / #ticketFeeByPercent / #fullcommissions / …
              │ Build #overnights (copy-fund overlays + UNION of overnight-style metrics)
              │ Build nested #commissions variants + UNION ALL into #revenue (Multi-metric rollup)
              │ Post-process UPDATEs (#revenue coercion for SDRT IncludedInTotalRevenue, crypto-to-fiat null sentinels, dividend IsBuy tweaks, OPTIONS margin-trade tweak)
              │ DELETE partition WHERE DateID=@dateID + INSERT SELECT (main pass)
              │ DELETE/INSERT reload for RevenueMetricID=18 (Options all-time reload)
              │ DELETE monthly slice + INSERT staking rows (`RevenueMetricID=12`, lagged staking dates)
              ▼
       BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions (~3.16B logical rows via sys.partitions est.)
             Generic Pipeline Override → UC gold mirror (`main.bi_db.gold_*`)
```

---

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column carried from BI_DB/DWH lineage without algebraic change within this SP slice (still subject to aggregates / ISNULL coercion) |
| **ETL-computed** | `CASE`, `SUM`, literals, `@date`, `GETDATE()`, `ISNULL(...)` packaging |
| **join-enriched** | Added columns from keyed JOIN to dimensions / parquet overlays |
| **SP-adjusted** | Value rewritten by later UPDATE in SP body |

### Columns (`| DWH Column | Source Table | Source Column | Transform | Notes |`)

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|--------------|---------------|-----------|-------|
| DateID | `SP_DDR_Fact_Revenue_Generating_Actions` / TVF outputs | `DateID`, `LastModificationDateID`, lagged staking `CAST(FORMAT(DATEADD(MONTH,1,frcf.Date)…))` | ETL-computed | Main path from grouped unions; Staking intentionally shifts month forward; Options uses `#optionsalltime.DateID`; partition key |
| Date | `@date`, TVF `@Date`, staking `CONVERT(VARCHAR(8),DateID)` | parameter / TVF / derived | ETL-computed | Insert uses `@date` for main INSERT; staking branch converts numeric `DateID` back to `DATE`; Options uses TVF-supplied `[Date]` |
| RealCID | `Function_Revenue_*` variants | `RealCID`/`CID` (renamed upstream per TVF) | passthrough + aggregate | Universal customer key; synonym of `CID` resolved inside individual TVFs; HASH distribution key |
| ActionTypeID | `Function_Revenue_FullCommissions`/`Commissions`; rollups expose `NULL` | `ActionTypeID` | ETL-computed | `ISNULL(r.ActionTypeID,-1)` at insert; `-1` sentinel for metrics without trading action key; commissions carry true `ActionTypeID` joined to `Dim_ActionType` |
| ActionType | `Dim_ActionType.Name` or literal | `Name` / SQL literal | ETL-computed | Commission metrics use `dat.Name`; other metrics use fixed strings (`'Rollover'`, `'SDRT'`, `'TransferCoinFee'`, etc.) |
| InstrumentTypeID | `Function_Revenue_*` / forced literals | `InstrumentTypeID` | ETL-computed | `ISNULL(...,-1)` at insert; account-level fees use `NULL` upstream → `-1`; some metrics hard-code `10` etc. |
| IsSettled | TVF + forced literals | `IsSettled` | ETL-computed | `ISNULL(...,-1)` at insert; account-level paths leave NULL → `-1` |
| IsCopy | `Fact_CustomerAction.MirrorID` via TVFs | `MirrorID` | ETL-computed | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` in TVF-driven temps; `ISNULL(...,-1)`; `CryptoToFiatFee` forced `-1` via UPDATE |
| Metric | `SP` literals / `ActionType` alias | — | ETL-computed | Drives TVF-to-metric mapping (`'FullCommission'`, `'RollOverFee'`, …) |
| Amount | TVF fee columns | `TotalFullCommission`, `TotalCommission`, `RolloverFee`, `Dividend`, `SDRT`, `TicketFee`, `CashoutFeeExcludeRedeem`, `ConversionFee`, `DormantFee`, `InterestFee`, `TransferCoinFee`, `AdminFee`, `SpotAdjustFee`, `ShareLendingGrossAmount`, `TotalFeeUSD`, `TotalUSDDistributed`, options `Amount`, etc. | ETL-computed | `SUM` aggregation per GROUP BY slice; sign semantics per revenue stream |
| CountTransactions | TVF / SP | `CountTransactions`, `RealCID`, `CID` | ETL-computed | `COUNT(*)` or `SUM(CountTransactions)` depending on branch; `ISNULL(...,0)` at insert |
| IncludedInTotalRevenue | `Dim_Revenue_Metrics` | `IncludedInTotalRevenue` | join-enriched + SP-adjusted | `LEFT JOIN drm ON r.Metric = drm.Metric`; SP `UPDATE` forces `Metric='SDRT'` rows to `0` post-join |
| CountAsActiveTrade | `Function_Revenue_*` | `ActionTypeID`, `IsAirDrop` | ETL-computed | `CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0)=0 THEN 1 ELSE 0 END` on commission branches; otherwise `0` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` on each INSERT pass |
| IsBuy | `Fact_CustomerAction` via TVFs | `IsBuy` | ETL-computed + SP-adjusted | `ISNULL(...,-1)` baseline; dividends overridden when `Metric='Dividends'` (`Amount >0 → 1`, `<0 → 0`); C2F forced `-1` |
| IsLeveraged | TVFs expose `Leverage` | `Leverage` | ETL-computed | `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`; `ISNULL(...,-1)` |
| IsFuture | TVFs / `Dim_Instrument` | `IsFuture` | passthrough/join-enriched | Admin/SpotAdjust join `Dim_Instrument`; others use TVF; `ISNULL(...,-1)`; C2F forced `-1` |
| IsCopyFund | `BI_DB_CopyFund_Positions` | Presence of `PositionID` | join-enriched | Starts NULL in raw commission temps; sequential `UPDATE` + final `CASE` sets flag; `ISNULL(...,-1)` |
| IsOpenedFromIBAN | parquet temp + reconciliation | Presence | SP-adjusted | `UPDATE … SET … = 1` when parquet match; INSERT `ISNULL(...,-1)` |
| IsClosedToIBAN | parquet temp | Presence | SP-adjusted | Same pattern |
| IsRecurring | `External_bi_db_recurringinvestment_positions_parquet` | Presence | SP-adjusted | Same pattern plus `ConversionFee` carries function `IsRecurring` |
| IsAirDrop | TVFs | `IsAirDrop` | passthrough | `ISNULL(...,-1)`; certain metrics force `-1` via UPDATE |
| IsSQF | TVFs / `Function_Instrument_Snapshot_Enriched` | `IsSQF` | passthrough + ETL-computed | Spot-dividend path uses `fise.IsSQF`; SDRT branch hard-codes `0`; downstream `UPDATE` normalizes SDRT `-1` → `0`; final `ISNULL(...,-1)` |
| RevenueMetricID | `Dim_Revenue_Metrics`; staking/options literals | `RevenueMetricID` | join-enriched | `LEFT JOIN` + staking seeds `12`, options `#optionsalltime` seeds `18` |
| RevenueMetricCategoryID | `Dim_Revenue_Metrics`; staking/options literals | `RevenueMetricCategoryID` | join-enriched | Staking/category `4`, Options/category `5` |
| IsMarginTrade | TVFs | `IsMarginTrade` | ETL-computed + SP-adjusted | Defaults `ISNULL`; `UPDATE #revenue SET IsMarginTrade=0 WHERE Metric='SDRT'`; options path reset for `Metric='Options_PFOF'` |
| IsC2P | `#c2p` (from `V_C2P_Positions`) | Presence | join-enriched | CASE join for commission + applicable overnight metrics |

---

## Summary

| Transform bucket | Columns |
|------------------|---------|
| join-enriched / overlay | IncludedInTotalRevenue, RevenueMetricID, RevenueMetricCategoryID, IsClosedToIBAN, IsOpenedFromIBAN, IsRecurring, IsC2P, IsCopyFund (partial lifecycle) |
| TVF-driven passthrough (with coercion) | RealCID, many flag columns sourced from BI_DB revenue TVFs |
| Pure ETL / aggregates | Metric, Amount, CountTransactions, CountAsActiveTrade, UpdateDate, Date stacking logic |

**Parity**: 27 lineage rows : 27 Synapse DDL columns — **MATCH**.
