# Column Lineage: main.bi_output.vg_emoney_txs

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_txs` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_txs.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_txs.json` (rows: 10, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoney_txs   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | mdt.CID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `GCID` | `passthrough` | (Tier 1 — dbo.FiatAccount) | mdt.GCID |
| 3 | `TxStatusModificationDate` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxStatusModificationDate` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxStatusModificationDate |
| 4 | `TxAmountInUSD` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `USDAmountApprox` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.USDAmountApprox AS TxAmountInUSD |
| 5 | `TransactionID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TransactionID` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TransactionID |
| 6 | `IsTxSettled` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `IsTxSettled` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.IsTxSettled |
| 7 | `TxType` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxType` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxType |
| 8 | `TxTypeID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxTypeID` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxTypeID |
| 9 | `HolderCurrencyISO` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `HolderCurrencyISO` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.HolderCurrencyISO |
| 10 | `LocalCurrencyISO` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `LocalCurrencyISO` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.LocalCurrencyISO |

## Cross-check vs system.access.column_lineage

- Total target columns: **10**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **10**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
