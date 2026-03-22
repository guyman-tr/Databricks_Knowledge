# Lineage: Dealing_dbo.Dealing_GS_Credit_Risk

## Source Tables
| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Client open positions (CFD, HedgeServerID=101) |
| DWH_dbo.Dim_Instrument | Instrument metadata — InstrumentTypeID IN (5,6) |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter |
| DWH_dbo.Fact_CurrencyPriceWithSplit | End-of-day prices for NOP USD conversion |
| Dealing_staging.etoro_History_Netting_History | LP netting positions (SCD2 temporal) |
| Dealing_staging.etoro_Hedge_Netting | LP netting positions (current) |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Parameter | `@Date` |
| InstrumentID | Dim_Instrument | Passed through from netting → Dim_Instrument join |
| InstrumentType | Dim_Instrument.InstrumentType | Direct |
| InstrumentName | Dim_Instrument.Name | Direct |
| InstrumentDisplayName | Dim_Instrument.InstrumentDisplayName | Direct |
| OPLong | BI_DB_PositionPnL.NOP | `SUM(CASE WHEN IsBuy=1 THEN ABS(Clients_NOP) ELSE 0 END)` |
| EffLevLong | BI_DB_PositionPnL.NOP, Amount, PositionPnL | Weighted avg: `SUM(ABS(NOP)*EffLev)/SUM(ABS(NOP))` where `EffLev=ABS(NOP)/NULLIF(Amount+PositionPnL,0)` |
| OPShort | BI_DB_PositionPnL.NOP | `SUM(CASE WHEN IsBuy=0 THEN ABS(Clients_NOP) ELSE 0 END)` |
| EffLevShort | BI_DB_PositionPnL.NOP, Amount, PositionPnL | Same formula, IsBuy=0 |
| Clients_NOP | BI_DB_PositionPnL.NOP | `SUM(Clients_NOP)` (signed) |
| LP_NOP | etoro_Hedge_Netting.Units, IsBuy | `Units*(IsBuy?Bid:Ask)*(2*IsBuy-1)*FX_Rate` |
| NetExposure(Clients-LP) | Derived | `Clients_NOP - LP_NOP` |
| Buffer_Long | Derived | `1 / EffLevLong` |
| Buffer_Short | Derived | `1 / EffLevShort` |
| Scenario_1_-15% | Derived | `CASE WHEN Buffer_Long>0.15 THEN 0 ELSE OPLong*(0.15-Buffer_Long) END` |
| Scenario_2_-20% | Derived | Same pattern with 0.2 threshold |
| Scenario_3_-25% | Derived | Same pattern with 0.25 threshold |
| Scenario_4_-30% | Derived | Same pattern with 0.3 threshold |
| Scenario_5_15% | Derived | Same pattern for shorts with 0.15 threshold |
| Scenario_6_20% | Derived | Same pattern for shorts with 0.2 threshold |
| Scenario_7_25% | Derived | Same pattern for shorts with 0.25 threshold |
| Scenario_8_30% | Derived | Same pattern for shorts with 0.3 threshold |
| Scenario_9_-50% | Derived | Same pattern with 0.5 threshold (longs) |
| Scenario_10_50% | Derived | Same pattern with 0.5 threshold (shorts) |
| UpdateDate | — | `GETDATE()` |

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping — it is a Synapse-native reporting table.
