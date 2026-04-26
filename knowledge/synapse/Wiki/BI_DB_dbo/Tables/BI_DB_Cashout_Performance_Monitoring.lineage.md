# BI_DB_dbo.BI_DB_Cashout_Performance_Monitoring — Column Lineage

**Generated**: 2026-04-23 | **Phase**: 10B | **Writer SP**: SP_H_Cashout_Performance_Monitoring

## ETL Chain

```
etoro (production)
  Billing.Withdraw                         ← main driver (ModificationDate >= GETDATE()-15)
  Billing.WithdrawToFunding                ← funding leg linkage
  History.vWithdrawToFundingAction         ← last BO action for Prepared By
  BackOffice.Manager                       ← manager name resolution
    |
    | External Tables (External_etoro_*)
    v
BI_DB_dbo (via TRUNCATE + INSERT, Hourly)
  BI_DB_Cashout_Performance_Monitoring
    |
    | No downstream consumers identified
    v
  (Operational monitoring — no known downstream SPs or UC target)
```

## Column Lineage

| DWH Column | Source DB | Source Table | Source Column | Transform |
|---|---|---|---|---|
| [Status Modification Time] | etoro | Billing.Withdraw | ModificationDate | Rename only |
| [Request Time] | etoro | Billing.Withdraw | RequestDate | Rename only |
| [Withdraw Status] | etoro (via DWH) | Dim_CashoutStatus (from Dictionary.CashoutStatus) | Name | INNER JOIN on CashoutStatusID → resolve Name |
| [WithdrawID] | etoro | Billing.Withdraw | WithdrawID | Passthrough |
| [Prepared By] | etoro | BackOffice.Manager | FirstName, LastName | OUTER APPLY TOP 1 → CONCAT(FirstName, ' ', LastName) for CashoutStatusID IN (1,14) |
| [UpdateDate] | ETL | — | — | GETDATE() — ETL run timestamp |

## Tier Pre-Assignment

| DWH Column | Upstream Wiki | Transform | Pre-Tier |
|---|---|---|---|
| [Status Modification Time] | Billing.Withdraw.md ✓ (ModificationDate) | Rename | Tier 1 |
| [Request Time] | Billing.Withdraw.md ✓ (RequestDate) | Rename | Tier 1 |
| [Withdraw Status] | Dim_CashoutStatus.Name (join-derived) | JOIN lookup | Tier 2 |
| [WithdrawID] | Billing.Withdraw.md ✓ (WithdrawID) | Passthrough | Tier 1 |
| [Prepared By] | No upstream wiki for BackOffice.Manager | CONCAT computed | Tier 2 |
| [UpdateDate] | Propagation blacklist | GETDATE() | Propagation |

## Source External Tables

- `BI_DB_dbo.External_etoro_Billing_Withdraw`
- `BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll`
- `BI_DB_dbo.External_etoro_History_vWithdrawToFundingAction`
- `BI_DB_dbo.External_etoro_BackOffice_Manager`
