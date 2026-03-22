# Column Lineage -- BI_DB_dbo.BI_DB_Crypto_Net_Units_End_Of_Month

**Writer SP**: `BI_DB_dbo.SP_M_Crypto_RECON` (Priority 99 -- FinanceReportSPS, Monthly)
**ETL Pattern**: DELETE-INSERT by Month
**Population Filter**: InstrumentTypeID = 10, positions open at month end

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Dim_Position | pos | Primary -- position units, buy/sell, open/close dates |
| DWH_dbo.Dim_Instrument | DI | Instrument name + crypto filter |
| DWH_dbo.Fact_SnapshotCustomer | DC | Customer regulation, validity |
| DWH_dbo.Dim_Range | RR | Date range resolution |
| DWH_dbo.Dim_Regulation | DR | Regulation name |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- single SELECT/INSERT.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Month | computed | @start | CONVERT(VARCHAR(7), @start, 126) |
| CID | Dim_Position (pos) | CID | Direct |
| Regulation | Dim_Regulation (DR) | Name | Direct via DC.RegulationID = DR.ID |
| Instrument | Dim_Instrument (DI) | Name | Direct via pos.InstrumentID |
| Units | Dim_Position (pos) | AmountInUnitsDecimal, IsBuy | SUM(AmountInUnitsDecimal * (2*IsBuy-1)). Net buys/sells |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| SettlementType | Dim_Position (pos) | IsSettled, SettlementTypeID | CASE: IsSettled=1 then Real, TypeID 0/2/3 then CFD/TRS/CMT |
| IsValidCustomer | Fact_SnapshotCustomer (DC) | IsValidCustomer | Direct |
