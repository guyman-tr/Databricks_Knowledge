# DWH_dbo.Dim_CostSubtype

> Lookup of cost subtypes in the HistoryCosts domain — granular classification of trading cost components (Markup, ConversionMarkup, TicketFee, SDRT, TransactionFee, Refund, FixPerLotFee).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CostSubtypeId (int, CLUSTERED INDEX) |
| **Row Count** | 7 rows |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX on CostSubtypeId ASC |

---

## 1. Business Meaning

`Dim_CostSubtype` provides granular classification of individual cost components:

| ID | Subtype | Description |
|----|---------|-------------|
| 0 | Markup | Base spread markup |
| 1 | ConversionMarkup | Currency conversion markup |
| 2 | TicketFee | Per-trade fixed fee |
| 3 | SDRT | Stamp Duty Reserve Tax (UK stocks) |
| 4 | TransactionFee | Per-transaction fee |
| 5 | Refund | Cost refund/reversal |
| 6 | FixPerLotFee | Fixed fee per lot |

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `HistoryCosts.Dictionary.CostSubtype` |
| **Staging Table** | `DWH_staging.HistoryCosts_Dictionary_CostSubtype` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CostSubtypeId | int | YES | Tier 2 | Subtype identifier (0–6). Renamed from source `Id`. |
| 2 | CostSubtype | nvarchar(max) | YES | Tier 2 | Subtype name. |
| 3 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 3 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CostSubtype.sql*
