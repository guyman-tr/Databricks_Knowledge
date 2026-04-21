# Lineage — eMoney_dbo.eMoney_Reports_MIMO_Actions

**Generated**: 2026-04-21
**Writer SP**: `eMoney_dbo.SP_eMoney_Daily_MIMO` (prior to 2024-09-30 modification)
**Load Pattern**: Historical — same daily DELETE+INSERT WHILE loop as eMoney_Daily_MIMO_New_Reports_Action. FROZEN since 2024-10-12 when the SP was redirected to write to eMoney_Daily_MIMO_New_Reports_Action.

## Source Objects

| Source | Type | Role |
|--------|------|------|
| `DWH_dbo.Fact_CustomerAction` | DWH fact table | Primary source: deposit/cashout transactions (ActionTypeID IN 7, 8) |
| `DWH_dbo.Dim_Customer` | DWH dimension | FirstDepositDate (seniority), AccountTypeID (corporate flag) |
| `DWH_dbo.Dim_ActionType` | DWH dictionary | ActionType name (Deposit, Cashout) |
| `DWH_dbo.Dim_FundingType` | DWH dictionary | FundingType name (eToroMoney=ID 33, etc.) |
| `DWH_dbo.Dim_PlayerLevel` | DWH dictionary | Club tier name (Bronze, Silver, Gold, etc.) |
| `DWH_dbo.Fact_SnapshotCustomer` | DWH fact table | Point-in-time CountryID and IsValidCustomer |
| `eMoney_dbo.eMoney_Dim_Account` | eMoney DWH table | IsValidETM filter |
| `eMoney_dbo.eMoney_Dim_Country_Rollout` | eMoney DWH table | Open countries filter + CountryName |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|--------------|-----------|
| 1 | ActionDate | Fact_CustomerAction | Occurred | `CAST(Occurred AS DATE)` |
| 2 | Country | Fact_SnapshotCustomer → eMoney_Dim_Country_Rollout | CountryID → CountryName | JOIN chain |
| 3 | Club | Dim_PlayerLevel | Name | JOIN via Fact_SnapshotCustomer.PlayerLevelID |
| 4 | ActionType | Dim_ActionType | Name | JOIN via ActionTypeID (7=Deposit, 8=Cashout) |
| 5 | FundingType | Dim_FundingType | Name | JOIN via FundingTypeID |
| 6 | IsValid | eMoney_Dim_Account | IsValidETM | `ISNULL(mda.IsValidETM, 1)` |
| 7 | Seniority_daily_FTD_Group | Dim_Customer | FirstDepositDate | CASE DATEDIFF buckets |
| 8 | Is_Corporate_Account | Dim_Customer | AccountTypeID | `CASE WHEN AccountTypeID=2 THEN 1 ELSE 0 END` |
| 9 | CNT_TotalActions | Aggregated | Fact_CustomerAction.GCID | `COUNT(GCID)` |
| 10 | CNT_UniqueGCIDs | Aggregated | Fact_CustomerAction.GCID | `COUNT(DISTINCT GCID)` |
| 11 | CNT_eMoneyActions | Aggregated | Fact_CustomerAction.FundingTypeID | `SUM(CASE WHEN FundingTypeID=33 THEN 1 ELSE 0 END)` |
| 12 | CNT_OtherActions | Aggregated | Fact_CustomerAction.FundingTypeID | `SUM(CASE WHEN FundingTypeID<>33 THEN 1 ELSE 0 END)` |
| 13 | CNT_OtherActionsByeMoneyClients | Aggregated | Fact_CustomerAction, eMoney_Dim_Account | `SUM(CASE WHEN FundingTypeID<>33 AND mda.GCID IS NOT NULL THEN 1 ELSE 0 END)` |
| 14 | CNT_eMoneyActionsByeMoneyClients | Aggregated | Fact_CustomerAction, eMoney_Dim_Account | `SUM(CASE WHEN FundingTypeID=33 AND mda.GCID IS NOT NULL THEN 1 ELSE 0 END)` |
| 15 | Value_TotalActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount)` |
| 16 | Value_eMoneyActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount WHERE FundingTypeID=33)` |
| 17 | Value_OtherActions | Aggregated | Fact_CustomerAction.Amount | `SUM(Amount WHERE FundingTypeID<>33)` |
| 18 | Value_OtherActionsByeMoneyClients | Aggregated | Fact_CustomerAction.Amount | `SUM(OtherAction.Amount WHERE mda.GCID IS NOT NULL)` |
| 19 | Value_eMoneyActionsByeMoneyClients | Aggregated | Fact_CustomerAction.Amount | `SUM(eMoneyAction.Amount WHERE mda.GCID IS NOT NULL)` |
| 20 | UpdateDate | Computed | — | `GETDATE()` at INSERT time (nullable here vs NOT NULL in successor) |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (identical source chain to eMoney_Daily_MIMO_New_Reports_Action) |
| Tier 2 | 20 | All columns — SP-computed aggregations or dimension label lookups |

## UC External Lineage

| Synapse | UC Target |
|---------|-----------|
| eMoney_dbo.eMoney_Reports_MIMO_Actions | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions` (if exported) |

**PHASE 10B CHECKPOINT: PASS**
