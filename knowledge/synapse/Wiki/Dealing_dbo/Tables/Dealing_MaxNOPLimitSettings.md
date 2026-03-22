---
object: Dealing_MaxNOPLimitSettings
schema: Dealing_dbo
type: Table
description: Daily snapshot of maximum NOP (Net Open Position) limits per instrument and restriction scope. Sourced from EXW_Settings schema tables (Resources, SystemRestrictions, Tags). Supports global, instrument-level, and CID-level overrides via TagType/TagValue.
etl_sp: Dealing_dbo.SP_MaxNOPLimitSettings
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~3,081,101
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_MaxNOPLimitSettings

Daily configuration snapshot of maximum NOP limits maintained in the EXW (execution) settings system. Each row defines a NOP cap for a given scope: global defaults, instrument-specific limits, or individual client (CID) overrides. The `RestrictionWeight` column encodes priority — higher weight = higher precedence when multiple rules apply to the same client/instrument combination.

**Source schema**: `EXW_Settings` — a separate settings database from `BI_DB_dbo.External_SettingsDB` used by `Dealing_MAXLeverageByNOP`. These are distinct systems with different governance.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `EXW_Settings.Resources` | Base resource/instrument definitions |
| Source | `EXW_Settings.SystemRestrictions` | NOP limit rules per resource |
| Source | `EXW_Settings.Tags` | Scope tags: TagType='Customer' with TagValue=CID for individual overrides |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentName join |
| Writer | `Dealing_dbo.SP_MaxNOPLimitSettings` | Daily, OpsDB Priority 0 |

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `InstrumentID` | int | NULL | Instrument primary key. NULL for global-scope restrictions. |
| `InstrumentName` | varchar(100) | NULL | Instrument name. Denormalized. NULL when InstrumentID is NULL. |
| `MaxNOP` | decimal(32,8) | NULL | Maximum NOP allowed for this scope. In USD or instrument units (confirm with reviewer). |
| `RestrictionWeight` | int | NULL | Priority weight. Higher value = higher precedence. Used when multiple restrictions match. |
| `TagType` | varchar(50) | NULL | Scope qualifier. 'Customer' indicates a CID-specific override; NULL or other values indicate broader scope. |
| `TagValue` | varchar(100) | NULL | The tag value — when TagType='Customer', this is the CID (as string). |
| `IsActive` | bit | NULL | Whether this restriction is currently active. |
| `RestrictionType` | varchar(50) | NULL | Type classification of the restriction (e.g., 'MaxNOP', 'Position Limit'). |
| `Direction` | varchar(10) | NULL | 'Buy', 'Sell', or NULL for direction-agnostic limits. |
| `Currency` | varchar(10) | NULL | Currency of the MaxNOP value. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated. |

## Distributions & Observations

- Active: → 2026-03-10 (daily), 3,081,101 rows
- Mixture of global defaults, instrument-level rules, and per-CID overrides in the same table
- TagType='Customer' rows: TagValue = CID string — allows individual client NOP exceptions
- ROUND_ROBIN distribution — filter by Date + InstrumentID or TagValue (CID) for specific lookups
- EXW_Settings schema is separate from BI_DB_dbo.External_SettingsDB — different governance/ownership

## Business Context

Defines eToro's position-limit guardrails at multiple scopes. Global limits protect against systemic concentration; instrument-specific limits manage single-stock risk; CID-level overrides allow exceptions for specific clients (e.g., professional traders with larger approved limits). The `RestrictionWeight` priority system ensures the most specific applicable rule wins. Used by the Dealing/Risk team to enforce regulatory and internal risk policy.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_MAXLeverageByNOP` | Sibling — leverage tiers by NOP level (sourced from BI_DB_dbo.External_SettingsDB, different system) |
| `Dealing_MaxPositionUnits` | Sibling — unit-based position limits from DWH_staging |
| `Dealing_NOP_Report` | Complementary — actual LP NOP vs. these configured limits |

## Quality Score: 8.0/10
*Strong: EXW_Settings schema separation noted, CID-override pattern documented, RestrictionWeight priority explained. Deductions: MaxNOP currency/unit convention not confirmed; exact column list partially inferred from SP logic; TagType enum not fully known.*
