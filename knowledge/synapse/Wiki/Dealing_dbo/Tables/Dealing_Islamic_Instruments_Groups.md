# Dealing_dbo.Dealing_Islamic_Instruments_Groups

> Islamic fee instrument-to-group mapping — assigns each instrument to a fee tier group for administrative fee calculation.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual (updated when instruments are added/reclassified) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_id |

---

## 1. Business Meaning

This reference table maps individual instruments to fee tier groups for Islamic account administrative fee calculation. Each instrument is assigned to a `instrument_group` (1-4) within its `instrument_type_id` (asset class). The group determines the USD fee rate from `Dealing_Islamic_Admin_Fee_Per_Group`.

Only instruments in this table are subject to the group-based Islamic fee. Stock/ETF CFDs with Leverage>1 and Crypto CFDs are included via SP logic even without a mapping in this table.

---

## 2. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_id | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 3 — live data) |
| 2 | name | nvarchar(4000) | YES | Instrument name (e.g., "EUR/USD", "GBP/USD"). From manual configuration. (Tier 3 — live data) |
| 3 | instrument_group | int | YES | Fee tier group (1-4). Maps to `Dealing_Islamic_Admin_Fee_Per_Group.instrument_group` for fee rate lookup. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | instrument_type_id | int | YES | Asset class: 1=Currencies, 2=Commodities, 4=Indices. (Tier 2 — SP_Islamic_Administrative_Fee) |

---

## 3. Relationships

### 3.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| instrument_id | DWH_dbo.Dim_Instrument | Instrument definition |
| (instrument_group, instrument_type_id) | Dealing_Islamic_Admin_Fee_Per_Group | Fee rate lookup |

### 3.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | LEFT JOIN on instrument_id for group assignment |

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 2 T2, 2 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Islamic_Instruments_Groups | Type: Table (reference)*
