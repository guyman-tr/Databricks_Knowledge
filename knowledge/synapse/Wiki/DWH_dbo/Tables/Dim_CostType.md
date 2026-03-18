# DWH_dbo.Dim_CostType

> Top-level cost type classification in the HistoryCosts domain — Markup, CurrencyMarkup, Fee, or Tax.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CostTypeId (int, CLUSTERED INDEX) |
| **Row Count** | 4 rows |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX on CostTypeId ASC |

---

## 1. Business Meaning

`Dim_CostType` is the top-level classification of trading costs:

| ID | Type | Description |
|----|------|-------------|
| 1 | Markup | Spread-based costs |
| 2 | CurrencyMarkup | FX conversion costs |
| 3 | Fee | Fixed fees (ticket fees, per-lot fees) |
| 4 | Tax | Regulatory taxes (e.g., SDRT) |

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `HistoryCosts.Dictionary.CostType` |
| **Staging Table** | `DWH_staging.HistoryCosts_Dictionary_CostType` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CostTypeId | int | YES | Tier 2 | Cost type identifier (1–4). Renamed from source `Id`. |
| 2 | CostType | nvarchar(max) | YES | Tier 2 | Cost type name. |
| 3 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 3 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CostType.sql*
