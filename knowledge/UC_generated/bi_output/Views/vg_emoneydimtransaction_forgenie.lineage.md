# Column Lineage: main.bi_output.vg_emoneydimtransaction_forgenie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoneydimtransaction_forgenie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoneydimtransaction_forgenie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoneydimtransaction_forgenie.json` (rows: 13, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoneydimtransaction_forgenie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | mdt.CID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `GCID` | `passthrough` | (Tier 1 — dbo.FiatAccount) | mdt.GCID |
| 3 | `TxTypeID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxTypeID` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxTypeID |
| 4 | `TxType` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxType` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxType |
| 5 | `TxTypeDescription` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `—` | `case` | — | CASE WHEN mdt.TxTypeID IN (1, 2, 3, 4, 13) THEN mdt.TxType \|\| ' - eToro Debit Card Transaction' WHEN mdt.TxType = 'Payment' THEN 'Payment  |
| 6 | `USDAmountApprox` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `USDAmountApprox` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.USDAmountApprox |
| 7 | `HolderAmount` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `HolderAmount` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.HolderAmount |
| 8 | `HolderCurrencyDesc` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `HolderCurrencyDesc` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.HolderCurrencyDesc |
| 9 | `MerchantID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `MerchantID` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.MerchantID |
| 10 | `TxStatusModificationTime` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxStatusModificationTime` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxStatusModificationTime |
| 11 | `TxLabel` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxLabel` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.TxLabel |
| 12 | `MoneyMoveDirection` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `MoneyMoveDirection` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.MoneyMoveDirection |
| 13 | `USDRateApprox` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `USDRateApprox` | `passthrough` | (Tier 2 — SP_eMoney_DimFact_Transaction) | mdt.USDRateApprox |

## Cross-check vs system.access.column_lineage

- Total target columns: **13**
- OK: **12**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `TxTypeDescription` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction.txtype`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction.txtypeid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
