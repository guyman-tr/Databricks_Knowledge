# Lineage: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

## Source Objects

| Source Object | Schema | Type | Relationship | Join Key / Filter |
|---------------|--------|------|-------------|-------------------|
| eMoneyClientBalance | eMoney_dbo | Table | Hard — sole data source | BalanceDateID = @DateID; HAVING SUM(OpeningBalanceGAP) <> 0 |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | CAST(CONVERT(DATETIME, CONVERT(char(8), BalanceDateID)) AS DATE) — converts integer YYYYMMDD back to date | Tier 2 |
| Openning_Balance_Gap | eMoney_dbo.eMoneyClientBalance | OpeningBalanceGAP | SUM(OpeningBalanceGAP) GROUP BY BalanceDateID, filtered HAVING <> 0 | Tier 2 |
| UpdateDate | (SP parameter) | @Date | Set to SP input parameter @Date (passed from SP_eMoney_ClientBalance as the business date) | Tier 2 |
