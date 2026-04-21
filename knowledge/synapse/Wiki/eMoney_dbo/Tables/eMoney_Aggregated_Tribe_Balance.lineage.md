# Lineage — eMoney_dbo.eMoney_Aggregated_Tribe_Balance

**Generated**: 2026-04-21
**Writer SP**: `eMoney_dbo.SP_eMoney_Aggregated_Tribe_Balance`
**Load Pattern**: Incremental DELETE+INSERT (by BalanceDateID ≥ last BalanceDateID)

## Source Objects

| Source | Type | Role |
|--------|------|------|
| `eMoney_dbo.ETL_AccountSnapshot` | Internal staging table | Primary data source (account snapshots per day) |
| `eMoney_dbo.eMoney_Dim_Account` | eMoney DWH table | Customer dimension (GCID, AccountSubProgram, IsTestAccount) |
| `eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic` | eMoney DWH static table | Entity/CurrencyName lookup by CurrencyISO |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|--------------|-----------|
| 1 | BalanceDate | ETL_AccountSnapshot | Date | `DATEADD(dd,-1,Date)` — balance date = day before snapshot date |
| 2 | BalanceDateID | Computed | — | `CAST(FORMAT(BalanceDate,'yyyyMMdd') AS INT)` |
| 3 | Date | ETL_AccountSnapshot | Date | Direct (snapshot/processing date) |
| 4 | DateID | ETL_AccountSnapshot | DateID | Direct |
| 5 | WorkDate | ETL_AccountSnapshot | WorkDate | Direct |
| 6 | Entity | eMoney_EntityByCurrencyISO_MappingStatic | Entity | JOIN on CurrencyISO = CurrencyIson |
| 7 | ProgramId | ETL_AccountSnapshot | ProgramId | Direct |
| 8 | Program | Computed | ProgramId | CASE: 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test, else=NA |
| 9 | AccountSubProgramID | eMoney_Dim_Account | AccountSubProgramID | LEFT JOIN via ProviderCurrencyBalanceID or ProviderHolderID |
| 10 | AccountSubProgram | eMoney_Dim_Account | AccountSubProgram | LEFT JOIN via ProviderCurrencyBalanceID or ProviderHolderID |
| 11 | EpmMethodID | ETL_AccountSnapshot | EpmMethodID | Direct |
| 12 | AccountStatus | ETL_AccountSnapshot | AccountStatusDescription | Direct (renamed) |
| 13 | ExistingUser | Computed | — | `CASE WHEN COALESCE(dim1.GCID, dim2.GCID) IS NULL THEN 0 ELSE 1 END` — 1 if customer exists in eMoney_Dim_Account |
| 14 | TotalAccounts | Aggregated | ETL_AccountSnapshot.AccountId | `COUNT(DISTINCT AccountId)` |
| 15 | TotalIBANS | Aggregated | ETL_AccountSnapshot.BankAccountId | `COUNT(DISTINCT BankAccountId)` |
| 16 | FundedAccounts | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(CASE WHEN SettledBalance > 0 THEN 1 ELSE 0 END)` |
| 17 | FundedAbove5 | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(CASE WHEN SettledBalance > 5 THEN 1 ELSE 0 END)` |
| 18 | Active30 | Aggregated | ETL_AccountSnapshot.AccountDateTimeUpdated | `SUM(CASE WHEN AccountDateTimeUpdated >= DATEADD(dd,-30,BalanceDate) THEN 1 ELSE 0 END)` |
| 19 | Active90 | Aggregated | ETL_AccountSnapshot.AccountDateTimeUpdated | `SUM(CASE WHEN AccountDateTimeUpdated >= DATEADD(dd,-90,BalanceDate) THEN 1 ELSE 0 END)` |
| 20 | NeverActive | Aggregated | ETL_AccountSnapshot | `SUM(CASE WHEN AccountDateUpdated = AccountDateCreated THEN 1 ELSE 0 END)` |
| 21 | OverdrawnAccounts | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(CASE WHEN SettledBalance < 0 THEN 1 ELSE 0 END)` |
| 22 | NegativeBalances | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(SettledBalance WHERE IsNegative=1)` — money value of overdrawn balances |
| 23 | CASSBalances | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(SettledBalance WHERE IsNegative=0)` — CASS-segregated positive balances |
| 24 | TotalBalances | Aggregated | ETL_AccountSnapshot.SettledBalance | `SUM(SettledBalance)` — all balances including negative |
| 25 | UpdateDate | Computed | — | `GETDATE()` at INSERT time |
| 26 | CurrencyIson | ETL_AccountSnapshot | CurrencyIson | Direct — ISO 4217 numeric currency code |
| 27 | HolderCurrency | eMoney_EntityByCurrencyISO_MappingStatic | CurrencyName | JOIN on CurrencyISO |
| 28 | IsTest | eMoney_Dim_Account | IsTestAccount | LEFT JOIN (renamed) |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (all sources are internal DWH staging; no DB_Schema upstream wiki) |
| Tier 2 | 28 | All columns — ETL-computed aggregations or passthrough from internal staging |

## UC External Lineage

| Synapse | UC Target |
|---------|-----------|
| eMoney_dbo.eMoney_Aggregated_Tribe_Balance | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance` |

**PHASE 10B CHECKPOINT: PASS**
