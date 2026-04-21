---
object: v_eMoney_Card_Instance_Summary
schema: eMoney_dbo
database: Synapse DWH
type: View
writer_sp: none (SELECT-only view)
etl_pattern: View — real-time SELECT passthrough; no ETL
upstream_wiki: eMoney_dbo/Tables/eMoney_Card_Instance_Summary.md (Batch 5, same session)
tier1_count: 3
tier2_count: 14
generated: 2026-04-19
---

# Column Lineage — eMoney_dbo.v_eMoney_Card_Instance_Summary

## ETL Chain

```
eMoney_dbo.eMoney_Card_Instance_Summary (base table — full 18 cols)
  |
eMoney_dbo.v_eMoney_Card_Instance_Summary (view — SELECT 17 cols; MaskedPAN excluded)
```

## Column Lineage

All 17 columns are direct passthroughs from `eMoney_Card_Instance_Summary`. Tier assignments are inherited from the base table. `MaskedPAN` (col 10 of the base table) is excluded — it is commented out in the view DDL (`-- [MaskedPAN]`).

| # | View Column | Source Table | Source Column | Transform | Tier |
|---|-------------|-------------|---------------|-----------|------|
| 1 | CID | eMoney_Card_Instance_Summary | CID | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 2 | ProviderHolderID | eMoney_Card_Instance_Summary | ProviderHolderID | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 3 | FMI_Date | eMoney_Card_Instance_Summary | FMI_Date | Passthrough | Tier 2 — eMoney_Dim_Transaction |
| 4 | DWH_CardID | eMoney_Card_Instance_Summary | DWH_CardID | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 5 | ProviderCardID | eMoney_Card_Instance_Summary | ProviderCardID | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 6 | CardCreateDate | eMoney_Card_Instance_Summary | CardCreateDate | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 7 | IsValidETM | eMoney_Card_Instance_Summary | IsValidETM | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 8 | GCID_Unique_Count | eMoney_Card_Instance_Summary | GCID_Unique_Count | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 9 | DWH_CardInstanceId | eMoney_Card_Instance_Summary | DWH_CardInstanceId | Passthrough | Tier 1 — FiatDwhDB.dbo.FiatCardInstances |
| — | *(MaskedPAN excluded)* | eMoney_Card_Instance_Summary | MaskedPAN | Excluded (commented out in DDL) | Tier 1 — FiatDwhDB.dbo.FiatCardInstances |
| 10 | InstanceStatus | eMoney_Card_Instance_Summary | InstanceStatus | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 11 | InstanceCreatedDate | eMoney_Card_Instance_Summary | InstanceCreatedDate | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 12 | InstanceActivationDate | eMoney_Card_Instance_Summary | InstanceActivationDate | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 13 | InstanceExpirationDate | eMoney_Card_Instance_Summary | InstanceExpirationDate | Passthrough | Tier 1 — FiatDwhDB.dbo.FiatCardInstances |
| 14 | StatusByHighestRNDasc | eMoney_Card_Instance_Summary | StatusByHighestRNDasc | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 15 | NextActivationDateTime | eMoney_Card_Instance_Summary | NextActivationDateTime | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 16 | TxAfterActivationCount | eMoney_Card_Instance_Summary | TxAfterActivationCount | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |
| 17 | UpdateDate | eMoney_Card_Instance_Summary | UpdateDate | Passthrough | Tier 2 — SP_eMoney_Card_Instance_Summary |

## Upstream Wiki Match Summary

| Upstream Wiki | Path | Columns Matched |
|---------------|------|----------------|
| eMoney_Card_Instance_Summary | eMoney_dbo/Tables/eMoney_Card_Instance_Summary.md | All 17 view columns — full passthrough |

**Tier 1 coverage**: 3 / 17 = 17.6% (inherited from base table; MaskedPAN Tier 1 col excluded from view)
