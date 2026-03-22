---
object: Dealing_MaxNOPLimitSettings
lineage_type: Configuration Snapshot from EXW_Settings
production_source: EXW_Settings.Resources + EXW_Settings.SystemRestrictions + EXW_Settings.Tags
---

# Dealing_MaxNOPLimitSettings — Lineage Map

## Data Flow

```
EXW_Settings.Resources
  │ → Resource/instrument definitions
  │
EXW_Settings.SystemRestrictions
  │ → NOP limit rules per resource (MaxNOP, RestrictionWeight, IsActive, Direction)
  │
EXW_Settings.Tags
  │ → Scope qualifiers: TagType='Customer', TagValue=CID for individual overrides
  │
DWH_dbo.Dim_Instrument
  │ → InstrumentName
  │
  ▼
Dealing_MaxNOPLimitSettings
```

## Note on Source System
`EXW_Settings` is a separate schema from `BI_DB_dbo.External_SettingsDB` (used by SP_MAXLeverageByNOP).
These are distinct configuration systems maintained by different teams.

## Refresh Schedule
Daily — SP_MaxNOPLimitSettings, OpsDB Priority 0, ProcessType 1 (SQL). Active.
