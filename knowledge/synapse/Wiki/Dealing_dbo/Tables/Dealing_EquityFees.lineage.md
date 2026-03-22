# Lineage Map — Dealing_dbo.Dealing_EquityFees

## Object
- **Table**: `Dealing_dbo.Dealing_EquityFees`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_EquityFees` |
| JP Morgan Source | `Dealing_staging.LP_JPM_EOD_eToro_Report_ComponentUnderlyings` |
| JP Morgan Rates | `Dealing_staging.LP_JPM_ETORO_AVAILABILITY` |
| Goldman Sachs Source | `Dealing_staging.LP_GS_SRPB_PositionValuationSummary` |
| Client NOP | `BI_DB_dbo.BI_DB_PositionPnL` (HedgeServerID IN (2,101)) |
| Instrument Lookup | `DWH_dbo.Dim_Instrument` |
| Generic Pipeline | Not applicable |

## ETL Flow
```
Dealing_staging.LP_JPM_EOD_eToro_Report_ComponentUnderlyings  (JP Morgan LP EOD)
    ↓ DEDUPLICATE on ISIN + Currency (take one per currency when multi-listed)
    ↓ LEFT JOIN Dealing_staging.LP_JPM_ETORO_AVAILABILITY (AllInRate, Requested, Approved, ShortFee, Rate_Desc)
         ON ISIN/RIC code
FULL OUTER JOIN
Dealing_staging.LP_GS_SRPB_PositionValuationSummary  (Goldman Sachs LP)
    ON ISINCode
LEFT JOIN
BI_DB_dbo.BI_DB_PositionPnL  (Client NOP, HedgeServerID IN (2,101))
    ON InstrumentID, aggregated to long/short units + NOP
LEFT JOIN
DWH_dbo.Dim_Instrument  (InstrumentID lookup by ISINCode/SedolCode)
→ Dealing_dbo.Dealing_EquityFees (DELETE + INSERT for @DateID)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | SP parameter | @Date passthrough |
| DateID | SP parameter | @DateID passthrough |
| InstrumentID | Dim_Instrument | Lookup by ISINCode / SedolCode; NULL if not found |
| InstrumentDisplayName | Dim_Instrument.InstrumentDisplayName | Passthrough |
| ISINCode | LP_JPM_EOD_Report.ISINCode | Passthrough |
| RICCode | LP_JPM_EOD_Report.RICCode | Passthrough |
| SedolCode | LP_JPM_EOD_Report.SedolCode | Passthrough |
| Currency | LP_JPM_EOD_Report.Currency | Passthrough |
| JP_LongQuantity | LP_JPM_EOD_eToro_Report_ComponentUnderlyings | JP Morgan long units |
| JP_ShortQuantity | LP_JPM_EOD_eToro_Report_ComponentUnderlyings | JP Morgan short units |
| JP_CurrentPrice | LP_JPM_EOD_Report | JP Morgan EOD price |
| JP_LongFianancingCost | LP_JPM_EOD_Report | Long financing cost; "Fianancing" typo from LP source |
| JP_ShortFianancingCost | LP_JPM_EOD_Report | Short financing cost; typo preserved |
| JP_FinancingAllInRate | LP_JPM_ETORO_AVAILABILITY.AllInRate | All-in financing rate |
| JP_LongMarketValue_Local | LP_JPM_EOD_Report | Long market value in local currency |
| JP_ShortMarketValue_Local | LP_JPM_EOD_Report | Short market value in local currency |
| JP_LongMarketValue_USD | LP_JPM_EOD_Report | Long market value USD |
| JP_ShortMarketValue_USD | LP_JPM_EOD_Report | Short market value USD |
| JP_FX | LP_JPM_EOD_Report | JP Morgan FX conversion rate |
| JP_Requested | LP_JPM_ETORO_AVAILABILITY.Requested | Requested quantity |
| JP_Approved | LP_JPM_ETORO_AVAILABILITY.Approved | Approved quantity |
| JP_ShortFee | LP_JPM_ETORO_AVAILABILITY.ShortFee | Short fee rate |
| JP_Rate_Desc | LP_JPM_ETORO_AVAILABILITY.Rate_Desc | Rate description |
| GS_Long_Quantity | LP_GS_SRPB_PositionValuationSummary | GS long quantity |
| GS_Short_Quantity | LP_GS_SRPB | GS short quantity |
| GS_Long_Value_Local | LP_GS_SRPB | GS long value local currency |
| GS_Short_Value_Local | LP_GS_SRPB | GS short value local currency |
| GS_Long_Value_USD | LP_GS_SRPB | GS long value USD |
| GS_Short_Value_USD | LP_GS_SRPB | GS short value USD |
| GS_Price | LP_GS_SRPB | GS EOD price |
| GS_FX | LP_GS_SRPB | GS FX conversion rate |
| GS_Long_Fianancing_Fee | LP_GS_SRPB | GS long financing fee; "Fianancing" typo from LP source |
| GS_Short_Fianancing_Fee | LP_GS_SRPB | GS short financing fee; typo preserved |
| LongClients_NOP | BI_DB_PositionPnL | SUM(NOP) for long CBH-hedged clients (HedgeServerID IN (2,101)) |
| ShortClients_NOP | BI_DB_PositionPnL | SUM(NOP) for short CBH-hedged clients |
| LongClients_Units | BI_DB_PositionPnL | SUM(Units) for long CBH-hedged clients |
| ShortClients_Units | BI_DB_PositionPnL | SUM(Units) for short CBH-hedged clients |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- Author: Graham Ellinson (2022-04-14)
- "Fianancing" typo in 4 column names is intentional — inherited from LP report format; preserved in DDL
- NULL InstrumentID rows exist when ISIN/SEDOL not found in Dim_Instrument
- Client NOP limited to CBH hedge-server clients (HedgeServerID IN (2,101))
- FULL OUTER JOIN between JP and GS — NULLs on either side are meaningful
