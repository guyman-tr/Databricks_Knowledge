# Column Lineage: Dealing_dbo.Dealing_ApexRecon_Holdings

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_ApexRecon_Holdings` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `Dealing_staging.LP_APEX_EXT982_3EU` (Apex LP EOD holdings file) + `Dealing_dbo.Dealing_Duco_EODRecon` |
| **ETL SP** | `Dealing_dbo.SP_Apex_Recon` |
| **Secondary Sources** | `CopyFromLake.etoro_Hedge_ExecutionLog`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `DWH_dbo.Dim_Instrument`, `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
External: Apex LP EOD file → Dealing_staging.LP_APEX_EXT982_3EU (Apex holdings)
Dealing_dbo.Dealing_Duco_EODRecon ← eToro EOD reconciliation
CopyFromLake.etoro_Hedge_ExecutionLog ← etoro.Hedge.ExecutionLog (daylight savings supplement)
Dealing_staging.External_Fivetran_dealing_active_hs_mappings ← Fivetran (Google Sheet HS/LP mapping)
    ↓
SP_Apex_Recon(@Date) — Holdings section
  → #Fivetran (active HS/LP mapping as of @Date)
  → #Apex_Ins (Apex CUSIP → DWH InstrumentID mapping)
  → #ApexHoldings (Apex EOD: Apex_Units, Apex_EOD_Price, Apex_Amount)
  → #eToroSide_EOD_00GMT (eToro EOD: Etoro_Units, Client_NOP_Units, Etoro_Amount)
  → #etoroAllocationDaylightSavings (DST supplement via etoro_Hedge_ExecutionLog)
  → #eToroSide_EOD (FULL OUTER JOIN of the two eToro sources)
  → INSERT: FULL OUTER JOIN #ApexHoldings to #eToroSide_EOD
    ↓
Dealing_dbo.Dealing_ApexRecon_Holdings
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` parameter | |
| InstrumentID | Dim_Instrument (via CUSIP match) | InstrumentID | passthrough | CUSIP-based match from #Apex_Ins; from ISNULL(ah.InstrumentID, eh.InstrumentID) | NULL when CUSIP unmatched |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | passthrough | ISNULL(Apex side, eToro side) | |
| ISINCode | Dealing_Duco_EODRecon / Dim_Instrument | ISINCode | passthrough | ISNULL(eh.ISINCode, di1.ISINCode) | |
| Etoro_Units | Dealing_Duco_EODRecon + etoro_Hedge_ExecutionLog | eToro_Units, eToroUnits | ETL-computed | SUM(eToro_Units) from Duco + SUM(eToroUnits) from ExecutionLog (DST supplement); NULLIF(0) | |
| Apex_Units | Dealing_staging.LP_APEX_EXT982_3EU | TradeQuantity | ETL-computed | `SUM(TradeQuantity)` per Instrument×HS | |
| Etoro_Rate | Dealing_Duco_EODRecon | eToroRate | passthrough | MAX(eToroRate) = EOD price; NULLIF(0) | |
| Apex_Rate | Dealing_staging.LP_APEX_EXT982_3EU | ClosingPrice | passthrough | Direct: Apex EOD closing price | |
| Etoro_Amount | Dealing_Duco_EODRecon + etoro_Hedge_ExecutionLog | eToroUSDAmount | ETL-computed | SUM from Duco + SUM from ExecutionLog; NULLIF(0) | USD value |
| Apex_Amount | Dealing_staging.LP_APEX_EXT982_3EU | MarketValue | ETL-computed | `SUM(MarketValue)` | |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |
| HedgeServerID | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | hs_dealing_desk | passthrough | Via #Fivetran | |
| Symbol | Dealing_staging.LP_APEX_EXT982_3EU / Dim_Instrument | Symbol | passthrough | ISNULL(Apex side, Dim_Instrument.Symbol) | Apex ticker |
| Client_NOP | Dealing_Duco_EODRecon | ClientAmount | ETL-computed | `SUM(ClientAmount)` | Client USD exposure |
| Client_NOP_Units | Dealing_Duco_EODRecon | ClientUnits | ETL-computed | `SUM(ClientUnits)` | Client share exposure |
| LastExecutionTime | — | — | — | Always NULL (column not populated) | Legacy column |
| CUSIP | Dealing_staging.LP_APEX_EXT982_3EU / Dealing_Duco_EODRecon | CUSIP | passthrough | ISNULL(Apex CUSIP, eToro CUSIP) | |
| Exchange | Dim_Instrument | Exchange | passthrough | ISNULL(di1.Exchange, di2.Exchange) | From eToro instrument match |
| AccountNumber | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | lp_accounts | passthrough | Via #Fivetran | Apex LP account ID |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **ETL-computed** | 8 |
| **Legacy/NULL** | 1 |
| **Total** | 18 |
