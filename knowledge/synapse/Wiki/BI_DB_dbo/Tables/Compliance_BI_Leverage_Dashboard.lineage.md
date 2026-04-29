# BI_DB_dbo.Compliance_BI_Leverage_Dashboard — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| External_SettingsDB_Settings_Resources | BI_DB_dbo (External) | Leverage resource definitions (default/max leverage paths) | Tier 1 — SP code confirmed |
| External_SettingsDB_Settings_SystemRestrictions | BI_DB_dbo (External) | Restriction rules with selected values | Tier 1 — SP code confirmed |
| External_SettingsDB_Settings_Tags | BI_DB_dbo (External) | Tag metadata (Country, RegulationGroup, GeoRegistrationDate) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name from RegulationGroup tags | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument name from InstrumentID | Tier 1 — SP code confirmed |
| External_etoro_Trade_ProviderInstrumentToLeverage | BI_DB_dbo (External) | CM default/max leverage by instrument | Tier 1 — SP code confirmed |
| External_etoro_Dictionary_Leverage | BI_DB_dbo (External) | Leverage value lookup from LeverageID | Tier 1 — SP code confirmed |
| External_etoro_Trade_InstrumentMetaData | BI_DB_dbo (External) | Instrument display name and type | Tier 1 — SP code confirmed |
| Compliance_BI_Leverage_Dashboard (self) | BI_DB_dbo | Previous day's values for change detection | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Date | — | @Date SP parameter | passthrough |
| RestrictionId | SystemRestrictions | RestrictionId | passthrough |
| RestrictionType | Resources | ResourceName | computed — 'default' if LIKE '%default%', 'max' if LIKE '%max%' |
| TagType | Tags | TagType | passthrough (Country, CountryAndRegulation, RegulationGroup, GeoRegistrationDate) |
| TagId | Tags | TagId | passthrough |
| TagValue | Tags / Dim_Regulation | TagValue / Name | computed — Regulation name for RegulationGroup, else raw TagValue |
| ResourceId | Resources | ResourceId | passthrough |
| BeginDate | Resources | BeginDate | passthrough |
| EndDate | Resources | EndDate | passthrough (9999-12-31 = active) |
| InstrumentID | Resources | ResourceName | computed — numeric suffix extraction from resource path |
| InstrumentName | Dim_Instrument | Name | dim-lookup by InstrumentID |
| InstrumentTypeID | Resources | ResourceName | computed — mapped from text (Currencies=1, commodities=2, indices=4, stocks=5, etf=6, crypto=10, else=999) |
| InstrumentType | Resources | ResourceName | computed — text suffix from resource path |
| New_Settings_Default_Value | SystemRestrictions | SelectedValue (where default) | passthrough |
| New_Settings_Max_Value | SystemRestrictions | SelectedValue (where max) | passthrough |
| New_CM_Default_Value | ProviderInstrumentToLeverage + Leverage | Default_Leverage | computed — SUM where IsDefault=1 |
| New_CM_Max_Value | ProviderInstrumentToLeverage + Leverage | MAX(Value) | computed |
| Old_Settings_Default_Value | Self (previous day) | New_Settings_Default_Value | change detection — populated only when value changed |
| Old_Settings_Max_Value | Self (previous day) | New_Settings_Max_Value | change detection — populated only when value changed |
| Old_CM_Default_Value | Self (previous day) | New_CM_Default_Value | change detection — populated only when value changed |
| Old_CM_Max_Value | Self (previous day) | New_CM_Max_Value | change detection — populated only when value changed |

## Lineage Notes

- UC Target: _Not_Migrated.
- Self-referencing: SP reads previous day from same table for change detection.
- "Old_" columns are NULL when no change detected from previous snapshot.
