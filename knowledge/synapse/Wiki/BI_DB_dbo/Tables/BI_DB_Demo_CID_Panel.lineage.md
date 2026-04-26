# BI_DB_dbo.BI_DB_Demo_CID_Panel — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_Demo_CID_Panel |
| **Writer SP** | BI_DB_dbo.SP_Demo_CID_Panel |
| **Author** | Eti (2025-01-27 rewrite, original Adi Ferber 2016-03-01) |
| **Primary Source** | BI_DB_dbo.External_Marketing_Acquisition_Demo |
| **Load Pattern** | Daily DELETE recent 3 months + INSERT new CIDs + UPDATE OpenPositions14days |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | CID | External_Marketing_Acquisition_Demo | CID | Passthrough | Tier 2 |
| 2 | Reg_YearMonth | External_Marketing_Acquisition_Demo | Registered | CONVERT(VARCHAR(7), Registered, 126) → YYYY-MM | Tier 2 |
| 3 | FDT_YearMonth | External_Marketing_Acquisition_Demo | FirstDemoTrade | CONVERT(VARCHAR(7), FirstDemoTrade, 126) → YYYY-MM | Tier 2 |
| 4 | FirstDemoTrade | External_Marketing_Acquisition_Demo | FirstDemoTrade | Passthrough | Tier 2 |
| 5 | FirstAction | External_Marketing_Acquisition_Demo | InstrumentID, IsBuy, Leverage, InstrumentTypeID | CASE: Real Stocks/ETFs (ID 5,6 + IsBuy=1 + Lev=1), Fx/Comm/Ind (type 1,2,4), CFD Stocks/ETFs (type 5,6), Crypto (type 10), Copy (type 0), else Other | Tier 2 |
| 6 | FirstInstrument | External_Marketing_Acquisition_Demo | InstrumentID | Passthrough | Tier 2 |
| 7 | IsTradedDemo | External_Marketing_Acquisition_Demo | FirstDemoTrade | CASE WHEN FirstDemoTrade IS NOT NULL THEN 1 ELSE 0 | Tier 2 |
| 8 | OpenPositions14days | External_Marketing_Acquisition_Demo | Pos14Days | Passthrough (updated daily if changed) | Tier 2 |
| 9 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| BI_DB_dbo.External_Marketing_Acquisition_Demo | External Table | Demo account activity data — registrations, first demo trade, position counts |
