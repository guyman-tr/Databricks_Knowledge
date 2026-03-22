---
object: Dealing_MAXLeverageByNOP
lineage_type: Configuration Snapshot from External Settings JSON
production_source: BI_DB_dbo.External_SettingsDB_Settings_SystemRestrictions (JSON column)
---

# Dealing_MAXLeverageByNOP — Lineage Map

## Data Flow

```
BI_DB_dbo.External_SettingsDB_Settings_SystemRestrictions
  │ → SelectedValue (JSON): { "MaxLeverageTiers": [ {MaxNOP, MaxLeverage}, ... ] }
  │ → JSON_VALUE(SelectedValue, '$.MaxLeverageTiers[0].MaxNOP') → NOP1
  │ → JSON_VALUE(SelectedValue, '$.MaxLeverageTiers[0].MaxLeverage') → Leverage1
  │ → ... (5 tiers unpacked)
  │
DWH_dbo.Dim_Instrument
  │ → InstrumentName
  │
Date = GETDATE() (no @Date parameter)
  │
  ▼
Dealing_MAXLeverageByNOP
```

## Refresh Schedule
Daily — SP_MAXLeverageByNOP, OpsDB Priority 0, ProcessType 1 (SQL). Active.
No historical backfill possible — always captures today's configuration.
