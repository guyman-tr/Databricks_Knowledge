---
object: Dealing_MAXLeverageByNOP
schema: Dealing_dbo
type: Table
description: Daily snapshot of maximum leverage allowed per instrument per trading direction and account type, tiered by NOP thresholds. Five NOP/leverage tier pairs per row. Sourced from JSON configuration in BI_DB_dbo.External_SettingsDB.
etl_sp: Dealing_dbo.SP_MAXLeverageByNOP
frequency: Daily
status: Active (last: 2026-03-11)
row_count: ~6,326,531
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_MAXLeverageByNOP

Daily leverage-tier configuration table. For each instrument × trading direction × account type combination, stores five NOP threshold/leverage pairs. As a client's NOP grows through each tier, the maximum allowed leverage decreases. The source configuration is maintained as JSON in `BI_DB_dbo.External_SettingsDB_Settings_SystemRestrictions` and extracted nightly via `JSON_VALUE`.

**No `@Date` parameter**: The SP uses `GETDATE()` to determine the current date — it always captures today's configuration, not a historical snapshot.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `BI_DB_dbo.External_SettingsDB_Settings_SystemRestrictions` | JSON column `SelectedValue` containing `MaxLeverageTiers` array |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument metadata |
| Writer | `Dealing_dbo.SP_MAXLeverageByNOP` | Daily, OpsDB Priority 0 |

**JSON extraction**: `JSON_VALUE(SelectedValue, '$.MaxLeverageTiers[0].MaxNOP')` pattern used to unpack 5 tiers into scalar columns.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date (set from GETDATE() at SP execution time). |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `InstrumentName` | varchar(100) | NULL | Instrument name. Denormalized. |
| `Direction` | varchar(10) | NULL | Trading direction: 'Buy' or 'Sell'. |
| `AccountType` | varchar(50) | NULL | Account classification (e.g., 'Default', 'Professional'). |
| `NOP1` | decimal(32,8) | NULL | Upper NOP bound for tier 1 (smallest tier — applies at low NOP). |
| `Leverage1` | decimal(32,8) | NULL | Maximum leverage allowed when NOP ≤ NOP1. |
| `NOP2` | decimal(32,8) | NULL | Upper NOP bound for tier 2. |
| `Leverage2` | decimal(32,8) | NULL | Maximum leverage allowed when NOP1 < NOP ≤ NOP2. |
| `NOP3` | decimal(32,8) | NULL | Upper NOP bound for tier 3. |
| `Leverage3` | decimal(32,8) | NULL | Maximum leverage allowed when NOP2 < NOP ≤ NOP3. |
| `NOP4` | decimal(32,8) | NULL | Upper NOP bound for tier 4. |
| `Leverage4` | decimal(32,8) | NULL | Maximum leverage allowed when NOP3 < NOP ≤ NOP4. |
| `NOP5` | decimal(32,8) | NULL | Upper NOP bound for tier 5 (largest tier). |
| `Leverage5` | decimal(32,8) | NULL | Maximum leverage allowed when NOP > NOP4. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated. |

*(Column names above are illustrative based on SP JSON extraction pattern; actual DDL may differ slightly for some names.)*

## Distributions & Observations

- Active: → 2026-03-11 (daily), 6,326,531 rows — **large table** (instruments × directions × account types × days)
- Sample (2026-03-11): EUR/GBP — Buy, Default/Default, NOP1=10,000,000, Leverage1=400
- Leverage tiers decrease as NOP increases — high-NOP positions face lower maximum leverage
- ROUND_ROBIN distribution — filter by Date + InstrumentID for efficient queries
- Because SP uses GETDATE() (no @Date), historical rows reflect the configuration active on that day — useful for auditing when tier changes took effect

## Business Context

Implements eToro's risk management policy of reducing maximum leverage as client NOP grows. High-NOP clients may pose greater market risk, so leverage is capped progressively. This table is the authoritative source for leverage enforcement per instrument/direction combination and feeds into position limit calculations. The JSON-source design allows the Risk/Product team to update tier thresholds in External_SettingsDB without changing SP code.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_MaxNOPLimitSettings` | Sibling — overall NOP limits per instrument (different dimension: position cap vs. leverage tier) |
| `Dealing_NOP_Report` | Complementary — actual LP NOP vs. this table's tier thresholds |
| `BI_DB_dbo.External_SettingsDB_Settings_SystemRestrictions` | Source — JSON tier configuration |

## Quality Score: 8.5/10
*Strong: JSON extraction pattern documented, NOP tier logic explained, no-@Date behavior noted. Minor deductions: exact column names in DDL partially inferred from SP logic; AccountType values not fully enumerated.*
