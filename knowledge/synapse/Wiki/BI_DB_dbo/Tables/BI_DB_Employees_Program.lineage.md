# BI_DB_dbo.BI_DB_Employees_Program — Column Lineage

## Writer SP
`BI_DB_dbo.SP_M_EmployeesProgram`

## Source Objects
- `DWH_dbo.Dim_Customer` — employee list (PlayerLevelID=4, AccountTypeID IN 7,13)
- `DWH_dbo.V_Liabilities` — equity, cash, NWA, credit, positions over the program year
- `DWH_dbo.Fact_CustomerAction` — trade actions (manual opens, copy starts), bonus/compensation dates
- `DWH_dbo.Dim_Position` — position details for volume calculation (manual only, MirrorID=0)
- `DWH_dbo.Fact_CurrencyPriceWithSplit` — EOD prices for volume USD conversion
- `DWH_dbo.Dim_Instrument` — currency pair info for USD conversion

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | SP parameter | @Date | Direct |
| CID | Dim_Customer | RealCID | Direct (employee filter) |
| GCID | Dim_Customer | GCID | Direct |
| FirstName | Dim_Customer | FirstName | Direct (PII) |
| LastName | Dim_Customer | LastName | Direct (PII) |
| UserName | Dim_Customer | UserName | Direct (PII) |
| Email | Dim_Customer | Email | Direct (PII) |
| StartProgramDate | Fact_CustomerAction | MIN(Occurred) | WHERE ActionTypeID IN (9,36) — first Bonus/Compensation |
| TotalEquity | V_Liabilities | ActualNWA + Liabilities | Current-day snapshot |
| ActualNWA | V_Liabilities | ActualNWA | Current-day snapshot |
| Credit | V_Liabilities | Credit | Current-day snapshot |
| AvgInvestment | V_Liabilities | (RealizedEquity - Credit) / RealizedEquity | AVG over program year |
| ManualTrades | Fact_CustomerAction | ActionTypeID=1 | COUNT in program year |
| NewCopy | Fact_CustomerAction | ActionTypeID=17 | COUNT in program year |
| NumOfActions | Computed | ManualTrades + NewCopy | SUM |
| AvgActionPerM | Computed | NumOfActions / months | Actions per month |
| VolumeAtOpen | Dim_Position + Prices | AmountInUnitsDecimal * InitForexRate * USD conversion | SUM of open volumes |
| AvgMVolToEqy | Computed | AVG(monthly VolumeAtOpen / monthly AvgEquity) | Volume-to-equity ratio |
| IsEligible | Computed | AvgInvestment, NumOfActions, AvgMVolToEqy | CASE: >=50% invested OR (>=100 actions AND >=10 vol/equity) |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| TotalPositionsAmount | V_Liabilities | TotalPositionsAmount | Current-day snapshot |
| PositionPnL | V_Liabilities | PositionPnL | Current-day snapshot |
| TotalCash | V_Liabilities | TotalCash | Current-day snapshot |
| BonusCredit | V_Liabilities | BonusCredit | Current-day snapshot |
