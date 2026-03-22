# Column Lineage — Dealing_dbo.Dealing_IBRecon_EODHoldings_CFD

**Writer**: `Dealing_dbo.SP_IB_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — IB CFD account (HS 300) vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_dbo.Dealing_Duco_EODRecon | Production (Tier 1) | eToro EOD side (HS 300) |
| Dealing_staging.LP_IB_I1893329_Open_Positions | LP Feed (Tier 2) | IB CFD positions |

## Column → Source Mapping

Same as `Dealing_IBRecon_EODHoldings` except:
- `HedgeServerID` = 300 (CFD hedge server, changed from HS 121 per SR-308489 Apr 2025)
- `LastExecutionTime` is absent (not in CFD variant)
- Source is LP_IB_I1893329_Open_Positions for CFD accounts

| Column | Source | Notes |
|---|---|---|
| Date | @Date2 | IB date fallback logic |
| InstrumentID | Dim_Instrument | Via ISIN join |
| IB_Units | LP_IB_I1893329_Open_Positions | CFD open position quantity |
| eToro_Units | Duco_EODRecon | eToro_Units (HS 300) |
| Clients_Units | Duco_EODRecon | ClientUnits |
| Reality-Supposed | Computed | IB_AmountUSD − eToro_AmountUSD |
| Reality-Client | Computed | IB_AmountUSD − Clients_AmountNOP |
| HedgeServerID | SP logic | 300 (changed from 121 per SR-308489) |
| ClientAccountID | LP_IB | "UL1894678" primarily |
| UpdateDate | GETDATE() | Insertion timestamp |
