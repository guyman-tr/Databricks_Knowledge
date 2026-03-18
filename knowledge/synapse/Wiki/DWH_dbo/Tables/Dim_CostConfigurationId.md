# DWH_dbo.Dim_CostConfigurationId

> Lookup of cost configuration categories in the HistoryCosts domain — classifies how trading costs are configured (markup types, ticket fees, currency conversion markup).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CostConfigurationId (int, CLUSTERED INDEX) |
| **Row Count** | 4 rows |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX on CostConfigurationId ASC |

---

## 1. Business Meaning

`Dim_CostConfigurationId` classifies cost configurations used in the HistoryCosts domain:

| ID | Configuration |
|----|---------------|
| 1 | MarkupReal — Spread markup on real assets |
| 2 | MarkupCfd — Spread markup on CFD instruments |
| 3 | TicketFee — Per-trade flat fee |
| 4 | CurrencyConversionMarkup — FX conversion markup |

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `HistoryCosts.Dictionary.CostConfigurationId` |
| **Staging Table** | `DWH_staging.HistoryCosts_Dictionary_CostConfigurationId` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | `Id` → `CostConfigurationId`, `CostConfigurationId` (source name) → `CostConfiguration`, + `GETDATE()` |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CostConfigurationId | int | YES | Tier 2 | Configuration identifier (1–4). Renamed from source `Id`. |
| 2 | CostConfiguration | nvarchar(max) | YES | Tier 2 | Configuration name (MarkupReal, MarkupCfd, TicketFee, CurrencyConversionMarkup). |
| 3 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 3 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CostConfigurationId.sql*
