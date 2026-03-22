# Column Lineage — BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report

**Writer SP**: `BI_DB_dbo.SP_Finance_Non_US_Settlement_Report` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by SettlementDate (daily incremental)
**Population Filter**: InstrumentTypeID IN (5,6) = Real stocks, IsSettled = 1, IsCreditReportValidCB = 1, RegulationID NOT IN (6,7,8) = Non-US only

**Note**: This SP writes to 3 tables: BI_DB_CIDLevel_Settlement_Report, BI_DB_GAML_Real_Positions_Report_Opened_2022, BI_DB_GAML_Real_Positions_Report_Closed, plus the main BI_DB_Finance_Non_US_Settlement_Report.

---

## Source Chain

```
BI_DB_PositionPnL (pl) ──┐
Dim_Instrument (di) ─────┤
Fact_SnapshotCustomer ────┤
Dim_Range (dr) ──────────┤──→ #relPos2 (position-level, filtered)
Dim_Country (dc) ────────┤
Dim_PlayerLevel (dpl) ───┤
Dim_Regulation ──────────┤
Dim_Position (dp) ───────┤
V_GermanBaFin (gb) ──────┘
           ↓
    #relPos1 (CID × Instrument aggregation: SUM Total_Open_$, SUM Units)
           ↓
    INSERT INTO BI_DB_CIDLevel_Settlement_Report
```

---

## Column-Level Lineage

⛔ **Alias-level source attribution applied**

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| InstrumentID | BI_DB_PositionPnL (pl) | InstrumentID | Direct via #relPos2 → #relPos1 GROUP BY |
| InstrumentName | Dim_Instrument (di) | Name | Direct. Format: "OLED/USD", "GRG/GBX", "TTE.PA/EUR" |
| SettlementDate | computed | @dateID | YYYYMMDD integer from SP @dt parameter |
| EffectiveEODPrice | computed | Total_Open_$ / Units | CAST(Total_Open_$ / Units AS DECIMAL(18,4)). Effective end-of-day price per unit |
| CID | BI_DB_PositionPnL (pl) | CID | Direct. GROUP BY grain in #relPos1 |
| Regulation | Dim_Regulation | Name | Direct via Fact_SnapshotCustomer.RegulationID. Non-US only (NOT IN 6,7,8) |
| SettledInUnits | BI_DB_PositionPnL (pl) | AmountInUnitsDecimal | SUM(Units) from #relPos1. Aggregated units across positions |
| SettledIn$ | BI_DB_PositionPnL (pl) | Amount + PositionPnL | SUM(Amount + PositionPnL) = Total_Open_$. Mark-to-market value in USD |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| IsGermanBaFin | V_GermanBaFin (gb) | CID existence | CASE WHEN gb.CID IS NOT NULL THEN 1 ELSE 0 END |
