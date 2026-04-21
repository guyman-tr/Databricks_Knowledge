# Lineage — eMoney_dbo.eMoney_Daily_Shortfall_CID_Level

**Generated**: 2026-04-21
**Writer SP**: `eMoney_dbo.SP_eMoney_Daily_Shortfall_CID_Level` (@date DATE parameter)
**Load Pattern**: Daily DELETE+INSERT by DateID. Filters eMoneyClientBalance for the specific date where Shortfall < 0 and EtoroDeposits > 0.

## Source Objects

| Source | Type | Role |
|--------|------|------|
| `eMoney_dbo.eMoneyClientBalance` | eMoney DWH table | Primary source — daily account-level balance with all transaction categories |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|--------------|-----------|
| 1 | CID | eMoneyClientBalance | CID | Direct (customer ID) |
| 2 | AccountId | eMoneyClientBalance | AccountId | Direct (Tribe account ID) |
| 3 | DateID | eMoneyClientBalance | BalanceDateID | Renamed: BalanceDateID → DateID |
| 4 | Date | eMoneyClientBalance | BalanceDate | Renamed: BalanceDate → Date |
| 5 | Shortfall | Computed | eMoneyClientBalance | `BankPayIns + BankPayOuts + Card_POS + Card_ATM + BalanceAdjustments + ChargeBackAdjustments + ATMFee + FxFee + OtherFee + OpeningBalance` — sum of all balance components; negative values only |
| 6 | UpdateDate | Computed | — | `GETDATE()` at INSERT time |
| 7 | BankPayIns | eMoneyClientBalance | BankPayIns | Direct |
| 8 | BankPayOuts | eMoneyClientBalance | BankPayOuts | Direct |
| 9 | Card_POS | eMoneyClientBalance | Card_POS | Direct |
| 10 | Card_ATM | eMoneyClientBalance | Card_ATM | Direct |
| 11 | BalanceAdjustments | eMoneyClientBalance | BalanceAdjustments | Direct |
| 12 | ChargeBackAdjustments | eMoneyClientBalance | ChargeBackAdjustments | Direct |
| 13 | ATMFee | eMoneyClientBalance | ATMFee | Direct |
| 14 | FxFee | eMoneyClientBalance | FxFee | Direct |
| 15 | OtherFee | eMoneyClientBalance | OtherFee | Direct |
| 16 | OpeningBalance | eMoneyClientBalance | OpeningBalance | Direct |
| 17 | Entity | eMoneyClientBalance | Entity | Direct |
| 18 | CurrencyIson | eMoneyClientBalance | CurrencyIson | Direct |

## Filter Logic

The SP applies two WHERE conditions on eMoneyClientBalance:
1. `BalanceDateID = @DateID` — single-date snapshot
2. `EtoroDeposits > 0` — excludes accounts with no eToro deposits (pure provisioned/unactivated accounts)

Then the outer query applies: `WHERE Shortfall < 0` — only overdrawn accounts are inserted.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (eMoneyClientBalance is an internal DWH table with no DB_Schema upstream wiki) |
| Tier 2 | 18 | All columns — direct passthrough or computation from eMoneyClientBalance |

## UC External Lineage

| Synapse | UC Target |
|---------|-----------|
| eMoney_dbo.eMoney_Daily_Shortfall_CID_Level | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_shortfall_cid_level` |

**PHASE 10B CHECKPOINT: PASS**
