# Column Lineage: main.bi_output.vg_emoneydimaccount_forgenie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoneydimaccount_forgenie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoneydimaccount_forgenie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoneydimaccount_forgenie.json` (rows: 8, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoneydimaccount_forgenie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | mda.CID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `GCID` | `passthrough` | (Tier 1 — dbo.FiatAccount) | mda.GCID |
| 3 | `AccountSubProgram` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountSubProgram` | `passthrough` | (Tier 2 — SP_eMoney_Dim_Account) | mda.AccountSubProgram |
| 4 | `AccountCreateDate` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountCreateDate` | `passthrough` | (Tier 2 — SP_eMoney_Dim_Account) | mda.AccountCreateDate |
| 5 | `RegAccountSubProgram` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `RegAccountSubProgram` | `passthrough` | (Tier 2 — SP_eMoney_Dim_Account) | mda.RegAccountSubProgram |
| 6 | `CurrencyBalanceStatus` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `—` | `coalesce` | — | COALESCE(mda.CurrencyBalanceStatus, 'Active') AS CurrencyBalanceStatus |
| 7 | `CurrencyBalanceISODesc` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `CurrencyBalanceISODesc` | `passthrough` | (Tier 2 — SP_eMoney_Dim_Account) | mda.CurrencyBalanceISODesc |
| 8 | `CurrencyBalanceID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `CurrencyBalanceID` | `passthrough` | (Tier 1 — dbo.FiatCurrencyBalances) | mda.CurrencyBalanceID |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **7**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `CurrencyBalanceStatus` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account.currencybalancestatus` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
