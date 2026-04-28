# Lineage: eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

## Source Objects

| Source Object | Schema | Type | Relationship | Join Key / Filter |
|---------------|--------|------|-------------|-------------------|
| eMoneyClientBalance | eMoney_dbo | Table | Hard — sole data source | BalanceDateID = @DateID; GROUP BY BalanceDateID HAVING SUM(CheckCalc) <> 0 |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` — integer YYYYMMDD converted to date | Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap |
| Exceptions_Gap | eMoney_dbo.eMoneyClientBalance | CheckCalc | `SUM(CheckCalc)` across all accounts for the business date, filtered by HAVING SUM <> 0 | Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap |
| UpdateDate | (SP parameter) | @Date | Direct assignment of SP input parameter (business date) | Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap |
