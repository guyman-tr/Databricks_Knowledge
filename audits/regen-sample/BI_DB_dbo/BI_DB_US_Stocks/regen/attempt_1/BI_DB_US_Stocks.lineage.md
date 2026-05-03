# BI_DB_dbo.BI_DB_US_Stocks — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---|---|---|---|
| 1 | Unknown (manually loaded) | External | Writer | No writer SP found in SSDT; no generic pipeline mapping; no OpsDB entry. Table appears to be a static reference list loaded manually or via an ad-hoc process. |
| 2 | DWH_dbo.Dim_Instrument | DWH Dimension | Reader (FK target) | SP_Daily_Dividends JOINs BI_DB_US_Stocks.InstrumentID to Dim_Instrument.InstrumentID |
| 3 | BI_DB_dbo.SP_Daily_Dividends | Stored Procedure | Reader | LEFT JOIN on InstrumentID to derive Is_US_Stock flag for BI_DB_Daily_Dividends |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|
| InstrumentID | Unknown | InstrumentID | None — manually loaded reference key | Tier 3 |
| Name | Unknown | Name | None — manually loaded instrument ticker | Tier 3 |
| UpdateDate | Unknown | UpdateDate | None — manually loaded timestamp | Tier 3 |

---

*Generated: 2026-04-30*
