# Lineage — DWH_dbo.Dim_ClientWithdrawReason

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| ClientWithdrawReasonID | Dictionary.ClientWithdrawReason.ClientWithdrawReasonID | Passthrough |
| ClientWithdrawReasonName | Dictionary.ClientWithdrawReason.Name | Renamed |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
etoro.Dictionary.ClientWithdrawReason → DWH_staging.etoro_Dictionary_ClientWithdrawReason
  → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) → DWH_dbo.Dim_ClientWithdrawReason
```

*Generated: 2026-03-18*
