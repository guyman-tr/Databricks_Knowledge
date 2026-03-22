# Column Lineage -- BI_DB_dbo.BI_DB_Crypto_Net_Units_During_Month

**Writer SP**: `BI_DB_dbo.SP_M_Crypto_RECON` (Priority 99 -- FinanceReportSPS, Monthly)
**ETL Pattern**: DELETE-INSERT by Month
**Population Filter**: InstrumentTypeID = 10 (crypto only)

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Dim_Position | DP (via #pos) | Primary -- position units, buy/sell, settlement |
| DWH_dbo.Dim_Instrument | DI | Instrument name + crypto filter |
| DWH_dbo.Fact_SnapshotCustomer | DC | Customer regulation, validity |
| DWH_dbo.Dim_Range | RR | Date range resolution |
| DWH_dbo.Dim_Regulation | DR | Regulation name |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- two-step: #pos temp table then final SELECT.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Month | computed | @start | CONVERT(VARCHAR(7), @start, 126). First day of month from @date |
| CID | #pos (pos) | CID | Direct. Originally from Dim_Position.CID |
| Regulation | Dim_Regulation (DR) | Name | Direct via DC.RegulationID = DR.DWHRegulationID |
| Instrument | #pos (pos) | Instrument | Direct. Originally Dim_Instrument.Name via DP.InstrumentID |
| Units | #pos (pos) | AmountInUnitsDecimal, IsBuy, Is_open | SUM(AmountInUnitsDecimal * (2*IsBuy-1) * (2*Is_open-1)) |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| SettlementType | #pos (pos) | SettlementType | CASE: IsSettled=1->"Real", SettlementTypeID 0/2/3 -> CFD/TRS/CMT |
| IsValidCustomer | Fact_SnapshotCustomer (DC) | IsValidCustomer | Direct |
