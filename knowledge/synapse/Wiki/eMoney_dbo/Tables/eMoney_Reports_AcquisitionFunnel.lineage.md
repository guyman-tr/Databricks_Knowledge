# Column Lineage — eMoney_dbo.eMoney_Reports_AcquisitionFunnel

**Generated**: 2026-04-21
**Writer SP**: `SP_eMoney_Reports_Daily` (Steps 1–4)
**Primary Sources**: DWH_dbo.Dim_Customer, eMoney_Dim_Country_Rollout, DWH_dbo.Dim_PlayerLevel, DWH_dbo.Fact_CustomerAction, eMoney_Dim_Account, eMoney_Panel_FirstDates
**ETL Pattern**: TRUNCATE + INSERT (full refresh daily, as of 2022-07-22 change from DELETE)

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID → CID) | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | Tier 1 |
| 3 | Country | eMoney_Dim_Account / eMoney_Dim_Country_Rollout | RegCountry / CountryName | ISNULL(mda.RegCountry, dcr.CountryName) — eMoney registered country preferred | Tier 2 |
| 4 | Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough (player level display name) | Tier 2 |
| 5 | IsValidForFunnel | eMoney_Dim_Account | IsValidETM | ISNULL(IsValidETM, 1) — defaults to 1 if no eMoney account (customer is still valid but not yet enrolled) | Tier 2 |
| 6 | IsVerifiedFTD | DWH_dbo.Dim_Customer | IsDepositor + VerificationLevelID | Hardcoded 1 (all qualifying customers are verified depositors by filter) | Tier 2 |
| 7 | IsVerifiedFTDPlus2Weeks | DWH_dbo.Dim_Customer | FirstDepositDate | CASE WHEN DATEDIFF(DAY, FirstDepositDate, @Date) > 14 THEN 1 ELSE 0 END | Tier 2 |
| 8 | IsActiveMIMO | DWH_dbo.Fact_CustomerAction | GCID / ActionTypeID | CASE WHEN ActionTypeID IN (7,8) in last 91 days THEN 1 ELSE 0 END | Tier 2 |
| 9 | IseMoneyAccount | eMoney_Panel_FirstDates | GCID | CASE WHEN Panel_FirstDates.GCID IS NOT NULL THEN 1 ELSE 0 END (has eMoney account in panel) | Tier 2 |
| 10 | IsFMI | eMoney_Panel_FirstDates | FMI_Date | CASE WHEN FMI_Date IS NOT NULL THEN 1 ELSE 0 END | Tier 2 |
| 11 | IsFMO | eMoney_Panel_FirstDates | FMO_Date | CASE WHEN FMO_Date IS NOT NULL THEN 1 ELSE 0 END | Tier 2 |
| 12 | IsCardCreated | eMoney_Dim_Account | CardCreateTime | CASE WHEN CardCreateTime IS NOT NULL THEN 1 ELSE 0 END | Tier 2 |
| 13 | IsCardActivated | eMoney_Panel_FirstDates | CardActivationTime | CASE WHEN CardActivationTime IS NOT NULL THEN 1 ELSE 0 END | Tier 2 |
| 14 | IsCardFirstTx | eMoney_Panel_FirstDates | FirstCardSettledTXDate | CASE WHEN FirstCardSettledTXDate IS NOT NULL THEN 1 ELSE 0 END | Tier 2 |
| 15 | UpdateDate | SP_eMoney_Reports_Daily | — | GETDATE() at insert time | Tier 2 |

---

## ETL Pipeline

```
DWH_dbo.Dim_Customer (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3, PlayerStatusID NOT IN [2,4,14,15])
  + INNER JOIN eMoney_Dim_Country_Rollout (CountryID filter — only eMoney markets)
  + INNER JOIN DWH_dbo.Dim_PlayerLevel (Club/PlayerLevel name)
  + LEFT JOIN eMoney_Dim_Account (RegCountry, IsValidETM, CardCreateTime)
  + LEFT JOIN eMoney_Panel_FirstDates (FMI_Date, FMO_Date, CardActivationTime, FirstCardSettledTXDate)
  + Fact_CustomerAction subquery (ActionTypeID IN [7,8], last 91 days → IsActiveMIMO)
    |-- SP_eMoney_Reports_Daily Steps 1-4 (TRUNCATE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Reports_AcquisitionFunnel (3,672,801 rows)
    |-- Generic Pipeline (Override, delta, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
```

---

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Dim_Customer | DWH_dbo | CID, GCID, FirstDepositDate, country/club filter keys |
| Dim_PlayerLevel | DWH_dbo | Club name (Name column) |
| Fact_CustomerAction | DWH_dbo | MIMO activity detection (ActionTypeID 7,8) |
| eMoney_Dim_Country_Rollout | eMoney_dbo | Country filter + fallback country name |
| eMoney_Dim_Account | eMoney_dbo | RegCountry override, IsValidETM, CardCreateTime |
| eMoney_Panel_FirstDates | eMoney_dbo | FMI/FMO dates, CardActivation, FirstCardSettledTX |
