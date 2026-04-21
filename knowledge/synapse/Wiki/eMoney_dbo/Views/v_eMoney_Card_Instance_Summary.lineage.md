# eMoney_dbo.v_eMoney_Card_Instance_Summary — Column Lineage

This is a view. All columns are passthrough from the base table `eMoney_dbo.eMoney_Card_Instance_Summary`. No transformations or filters are applied — the view only excludes the `MaskedPAN` column (PII).

| # | View Column | Base Table | Base Column | Transform | Tier |
|---|------------|-----------|-------------|-----------|------|
| 1 | CID | eMoney_dbo.eMoney_Card_Instance_Summary | CID | Passthrough | 1 |
| 2 | ProviderHolderID | eMoney_dbo.eMoney_Card_Instance_Summary | ProviderHolderID | Passthrough | 1 |
| 3 | FMI_Date | eMoney_dbo.eMoney_Card_Instance_Summary | FMI_Date | Passthrough | 2 |
| 4 | DWH_CardID | eMoney_dbo.eMoney_Card_Instance_Summary | DWH_CardID | Passthrough | 1 |
| 5 | ProviderCardID | eMoney_dbo.eMoney_Card_Instance_Summary | ProviderCardID | Passthrough | 2 |
| 6 | CardCreateDate | eMoney_dbo.eMoney_Card_Instance_Summary | CardCreateDate | Passthrough | 2 |
| 7 | IsValidETM | eMoney_dbo.eMoney_Card_Instance_Summary | IsValidETM | Passthrough | 2 |
| 8 | GCID_Unique_Count | eMoney_dbo.eMoney_Card_Instance_Summary | GCID_Unique_Count | Passthrough | 2 |
| 9 | DWH_CardInstanceId | eMoney_dbo.eMoney_Card_Instance_Summary | DWH_CardInstanceId | Passthrough | 1 |
| 10 | InstanceStatus | eMoney_dbo.eMoney_Card_Instance_Summary | InstanceStatus | Passthrough | 2 |
| 11 | InstanceCreatedDate | eMoney_dbo.eMoney_Card_Instance_Summary | InstanceCreatedDate | Passthrough | 2 |
| 12 | InstanceActivationDate | eMoney_dbo.eMoney_Card_Instance_Summary | InstanceActivationDate | Passthrough | 2 |
| 13 | InstanceExpirationDate | eMoney_dbo.eMoney_Card_Instance_Summary | InstanceExpirationDate | Passthrough | 1 |
| 14 | StatusByHighestRNDasc | eMoney_dbo.eMoney_Card_Instance_Summary | StatusByHighestRNDasc | Passthrough | 2 |
| 15 | NextActivationDateTime | eMoney_dbo.eMoney_Card_Instance_Summary | NextActivationDateTime | Passthrough | 2 |
| 16 | TxAfterActivationCount | eMoney_dbo.eMoney_Card_Instance_Summary | TxAfterActivationCount | Passthrough | 2 |
| 17 | UpdateDate | eMoney_dbo.eMoney_Card_Instance_Summary | UpdateDate | Passthrough | 2 |

## Excluded Column (PII)

| Column | Reason |
|--------|--------|
| MaskedPAN | Excluded from view — PII field (masked card number). Use base table only for authorized PAN-related reconciliation. |

## ETL Chain Summary

```
eMoney_dbo.eMoney_Card_Instance_Summary (base table, 130K rows)
  |-- SELECT all columns EXCEPT MaskedPAN ---|
  v
eMoney_dbo.v_eMoney_Card_Instance_Summary (view, same row count, 17 cols)
  Standard analytics interface — recommended for all non-PAN uses.
```
