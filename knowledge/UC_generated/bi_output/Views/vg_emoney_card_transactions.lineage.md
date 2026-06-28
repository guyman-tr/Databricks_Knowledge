# Column Lineage: main.bi_output.vg_emoney_card_transactions

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_card_transactions` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_card_transactions.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_card_transactions.json` (rows: 9, mismatches: 0) |
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
main.bi_output.vg_emoney_card_transactions   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | CID |
| 2 | `CardTransaction_Time` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxStatusModificationTime` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | TxStatusModificationTime AS CardTransaction_Time |
| 3 | `CardTransaction_Type` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `TxType` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | TxType AS CardTransaction_Type |
| 4 | `CardTransaction_USDAmount` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `USDAmountApprox` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | USDAmountApprox AS CardTransaction_USDAmount |
| 5 | `CardTransaction_Local_Amount` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `LocalAmount` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | LocalAmount AS CardTransaction_Local_Amount |
| 6 | `CardTransaction_Local_Currency` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `LocalCurrencyDesc` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | LocalCurrencyDesc AS CardTransaction_Local_Currency |
| 7 | `CardTransaction_Club_AtTx` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `ClubTxDate` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | ClubTxDate AS CardTransaction_Club_AtTx |
| 8 | `CardTransaction_Country_AtTx` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `CountryTxDate` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | CountryTxDate AS CardTransaction_Country_AtTx |
| 9 | `CardTransaction_Regulation_AtTx` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | `RegulationTxDate` | `rename` | (Tier 2 — SP_eMoney_DimFact_Transaction) | RegulationTxDate AS CardTransaction_Regulation_AtTx |

## Cross-check vs system.access.column_lineage

- Total target columns: **9**
- OK: **9**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
