# Lineage: Dealing_dbo.Dealing_JP_Credit_Risk

## Source Tables
| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Client open positions (CFD, JPM hedge servers) |
| DWH_dbo.Dim_Instrument | Instrument metadata — InstrumentTypeID IN (5,6) |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter |
| DWH_dbo.Fact_CurrencyPriceWithSplit | End-of-day prices for FX conversion |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Dynamic JPM hedge server lookup |
| Dealing_staging.etoro_History_Netting_History | LP netting positions (SCD2) |
| Dealing_staging.etoro_Hedge_Netting | LP netting positions (current) |

## Column Lineage
Same computation pattern as Dealing_GS_Credit_Risk. Key differences:
- **HedgeServerID**: from `#Fivetran.hs_dealing_desk` (dynamic, not hardcoded)
- **LP filter**: `HedgeServerID IN (SELECT DISTINCT hs_dealing_desk FROM #Fivetran)` instead of `=101`
- **Final join**: FULL OUTER JOIN between client and LP data on (InstrumentID, HedgeServerID)

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
