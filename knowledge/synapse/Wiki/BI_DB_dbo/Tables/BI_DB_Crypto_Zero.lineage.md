# Column Lineage -- BI_DB_dbo.BI_DB_Crypto_Zero

**Writer SP**: `BI_DB_dbo.SP_M_Crypto_RECON` (Priority 99 -- FinanceReportSPS, Monthly)
**ETL Pattern**: DELETE-INSERT by Month
**Architecture**: #PnL0 (start unrealized) + #PnL1 (end unrealized) + #realized -> FULL OUTER JOIN #final -> aggregated INSERT

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Dim_Position | dp | Position P&L, commissions, open/close dates |
| DWH_dbo.Dim_Instrument | di | Crypto filter (InstrumentTypeID=10) |
| DWH_dbo.Fact_SnapshotCustomer | DC | Customer regulation, validity |
| DWH_dbo.Dim_Range | RR | Date range resolution |
| DWH_dbo.Dim_Regulation | DR | Regulation name |
| DWH_dbo.Dim_Label | dl | Label name |
| DWH_dbo.Dim_Country | dc1 | Country name |
| BI_DB_dbo.BI_DB_PositionPnL | pp | Position PnL snapshot (LEFT JOIN) |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- complex multi-temp-table pipeline.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Month | computed | @start | CONVERT(VARCHAR(7), @start, 126) |
| CID | #final | CID | COALESCE(#PnL0.CID, #PnL1.CID, #realized.CID). Originally Dim_Position.CID |
| Regulation | #final | Regulation | COALESCE across temp tables. Originally Dim_Regulation.Name |
| Unrealized_Start | #PnL0 (a) | ZeroPnL | SUM(ISNULL(pp.PositionPnL,0) + dp.FullCommissionByUnits) at @DayBeforeStartINT. ISNULL(,0) in #final |
| Unrealized_End | #PnL1 (b) | ZeroPnL | SUM(ISNULL(pp.PositionPnL,0) + dp.FullCommissionByUnits) at @endINT. ISNULL(,0) in #final |
| UnRealizedDiff | #final | computed | Unrealized_End - Unrealized_Start |
| RealizedZero | #realized (c) | Realized_Zero | SUM(dp.NetProfit + dp.FullCommissionOnClose) for positions closed during month. ISNULL(,0) |
| TotalZero | #final | computed | UnRealizedDiff + RealizedZero |
| TotalCommission | #final | computed | ISNULL(#PnL1.FullCommission,0) - ISNULL(#PnL0.FullCommission,0) + ISNULL(#realized.Realized_Commission,0) |
| Label | #final | Label | COALESCE across temp tables. Originally Dim_Label.Name |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| Country | #final | Country | COALESCE across temp tables. Originally Dim_Country.Name |
| SettlementType | #final | SettlementType | COALESCE. CASE on ISNULL(pp.IsSettled, dp.IsSettled) and SettlementTypeID |
| IsValidCustomer | #final | IsValidCustomer | COALESCE. Originally Fact_SnapshotCustomer.IsValidCustomer |
