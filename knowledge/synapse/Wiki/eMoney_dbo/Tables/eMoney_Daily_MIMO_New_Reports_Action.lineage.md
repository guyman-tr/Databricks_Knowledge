# Lineage — eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action

**Generated**: 2026-04-21
**Writer SP**: `eMoney_dbo.SP_eMoney_Daily_MIMO`
**Load Pattern**: Daily WHILE loop — DELETE WHERE ActionDate = @MIMODate, then INSERT aggregated metrics. Starts from MAX(ActionDate)+1 and iterates to yesterday.

## Source Objects

| Source | Type | Role |
|--------|------|------|
| `DWH_dbo.Fact_CustomerAction` | DWH fact table | Primary source: deposit/cashout transactions (ActionTypeID IN 7, 8) |
| `DWH_dbo.Dim_Customer` | DWH dimension | FirstDepositDate (for seniority calculation), AccountTypeID (corporate flag) |
| `DWH_dbo.Dim_ActionType` | DWH dictionary | ActionType name (Deposit, Cashout) via ActionTypeID |
| `DWH_dbo.Dim_FundingType` | DWH dictionary | FundingType name (eToroMoney, CreditCard, PayPal, etc.) via FundingTypeID |
| `DWH_dbo.Dim_PlayerLevel` | DWH dictionary | Club name (Bronze, Silver, Gold, etc.) via PlayerLevelID |
| `DWH_dbo.Fact_SnapshotCustomer` | DWH fact table | CountryID and IsValidCustomer at the action date (joined via Dim_Range for point-in-time snapshot) |
| `eMoney_dbo.eMoney_Dim_Account` | eMoney DWH table | IsValidETM flag, Type_of_IBAN (first 2 chars of BankAccountIBAN) |
| `eMoney_dbo.eMoney_Dim_Country_Rollout` | eMoney DWH table | Open countries filter and CountryName lookup |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|--------------|-----------|
| 1 | ActionDate | Fact_CustomerAction | Occurred | `CAST(fca.Occurred AS DATE)` |
| 2 | Country | Fact_SnapshotCustomer → eMoney_Dim_Country_Rollout | CountryID → CountryName | JOIN chain: SnapshotCustomer.CountryID → Country_Rollout.CountryName (open countries only) |
| 3 | Club | Dim_PlayerLevel | Name | JOIN via Fact_SnapshotCustomer.PlayerLevelID |
| 4 | ActionType | Dim_ActionType | Name | JOIN via fca.ActionTypeID (7=Deposit, 8=Cashout) |
| 5 | FundingType | Dim_FundingType | Name | JOIN via fca.FundingTypeID |
| 6 | IsValid | eMoney_Dim_Account | IsValidETM | `ISNULL(mda.IsValidETM, 1)` — 1 if eMoney-eligible, 0 otherwise; defaults to 1 when not joined |
| 7 | Seniority_daily_FTD_Group | Dim_Customer | FirstDepositDate | CASE based on DATEDIFF(FirstDepositDate, @MIMODate): No deposits / 0 / 1-4 / 5-7 / 8-14 / 15-30 / 31-91 / 92-183 / 184-365 / 366-730 / 731+ |
| 8 | Is_Corporate_Account | Dim_Customer | AccountTypeID | `CASE WHEN AccountTypeID=2 THEN 1 ELSE 0 END` |
| 9 | CNT_TotalActions | Aggregated | Fact_CustomerAction.GCID | `COUNT(GCID)` — total action count (not distinct) in grouping |
| 10 | CNT_UniqueGCIDs | Aggregated | Fact_CustomerAction.GCID | `COUNT(DISTINCT GCID)` — distinct customers |
| 11 | CNT_eMoneyActions | Aggregated | Fact_CustomerAction.FundingTypeID | `SUM(CASE WHEN FundingTypeID=33 THEN 1 ELSE 0 END)` — eToroMoney funding (FundingTypeID=33) |
| 12 | CNT_OtherActions | Aggregated | Fact_CustomerAction.FundingTypeID | `SUM(CASE WHEN FundingTypeID<>33 THEN 1 ELSE 0 END)` — non-eToroMoney funding |
| 13 | CNT_OtherActionsByeMoneyClients | Aggregated | Fact_CustomerAction, eMoney_Dim_Account | `SUM(CASE WHEN FundingTypeID<>33 AND mda.GCID IS NOT NULL THEN 1 ELSE 0 END)` — other-funded actions by eMoney-eligible customers |
| 14 | CNT_eMoneyActionsByeMoneyClients | Aggregated | Fact_CustomerAction, eMoney_Dim_Account | `SUM(CASE WHEN FundingTypeID=33 AND mda.GCID IS NOT NULL THEN 1 ELSE 0 END)` |
| 15 | Value_TotalActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount)` — total monetary value |
| 16 | Value_eMoneyActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount WHERE FundingTypeID=33)` |
| 17 | Value_OtherActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount WHERE FundingTypeID<>33)` |
| 18 | Value_OtherActionsByeMoneyClients | Aggregated | Fact_CustomerAction.Amount | `SUM(OtherAction.Amount WHERE mda.GCID IS NOT NULL)` |
| 19 | Value_eMoneyActionsByeMoneyClients | Aggregated | Fact_CustomerAction.Amount | `SUM(eMoneyAction.Amount WHERE mda.GCID IS NOT NULL)` |
| 20 | UpdateDate | Computed | — | `GETDATE()` at INSERT time |
| 21 | Type_of_IBAN | eMoney_Dim_Account | BankAccountIBAN | `LEFT(BankAccountIBAN, 2)` — first 2 chars = IBAN country code (GB, FR, DE, AU, etc.); added 2024-09-24 |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no DB_Schema upstream wiki columns pass through verbatim; all are aggregated or lookup-name columns) |
| Tier 2 | 22 | All columns — SP-computed aggregations or dimension label lookups from DWH_dbo |

## Predecessor Table Note

`eMoney_Reports_MIMO_Actions` is the predecessor table covering 2022-05-01 to 2024-10-12. The same SP previously wrote to that table. On 2024-09-30, the SP was modified by Adva Jakobson to target `eMoney_Daily_MIMO_New_Reports_Action` (adding Type_of_IBAN). The old table is frozen.

## UC External Lineage

| Synapse | UC Target |
|---------|-----------|
| eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action` |

**PHASE 10B CHECKPOINT: PASS**
