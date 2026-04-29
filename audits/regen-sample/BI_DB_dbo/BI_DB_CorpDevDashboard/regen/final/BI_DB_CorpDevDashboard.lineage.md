# Lineage: BI_DB_dbo.BI_DB_CorpDevDashboard

## Source Objects

| # | Source Object | Schema | Type | Relationship | Join/Link |
|---|--------------|--------|------|-------------|-----------|
| 1 | BI_DB_CID_MonthlyPanel_FullData | BI_DB_dbo | Table | Primary aggregation source | Indicator='All': grouped by Active_Month, Region (CASE-mapped), EOM_Club; Indicator='Age': joined to CIDFirstDates on CID; Indicator='Soc': joined to social temp tables on Region |
| 2 | BI_DB_First5Actions | BI_DB_dbo | Table | First action distribution source | Indicator='FA': grouped by FirstActionTypeNew, FirstCrossNew, Region (CASE-mapped) |
| 3 | BI_DB_CIDFirstDates | BI_DB_dbo | Table | Registration and age source | Indicator='Regs': registration counts by Region; Indicator='Age': BirthDate for age calc; Indicator='AUA': deposit filter (FirstDepositDate IS NOT NULL) |
| 4 | BI_DB_PositionPnL | BI_DB_dbo | Table | AUA source | Indicator='AUA': Amount + PositionPnL by InstrumentTypeID for a single DateID |
| 5 | Dim_Instrument | DWH_dbo | Table | Instrument classification | Indicator='AUA': InstrumentTypeID for asset class bucketing (1=Currencies, 2=Commodities, 10=Crypto, 4/5/6=Equities) |
| 6 | BI_DB_Social_Activity | BI_DB_dbo | Table | Social engagement source | #Like (ActionTypeID=3), #Share (ActionTypeID=4) — funded customers only |
| 7 | BI_DB_Guru_Copiers | BI_DB_dbo | Table | Copy activity source | #WereCopied (ParentCID), #CopiedOther (CID) — funded customers only |
| 8 | SP_CorpDevDashboard | BI_DB_dbo | Stored Procedure | Writer SP | DELETE WHERE Active_Month = @SdateINT + INSERT from #tmp (6-way UNION) |

## Column Lineage

| Column | Source Object | Source Column | Transform | Tier |
|--------|-------------- |---------------|-----------|------|
| Active_Month | SP_CorpDevDashboard | @date parameter | YEAR(@date)*100+MONTH(@date) or from mp.Active_Month | Tier 2 |
| ActiveDate | SP_CorpDevDashboard | @date parameter / mp.ActiveDate | Direct or DATEFROMPARTS(YEAR,MONTH,1) | Tier 2 |
| Indicator | SP_CorpDevDashboard | — | Hardcoded per UNION branch: 'All', 'FA', 'Regs', 'Age', 'AUA', 'Soc' | Tier 2 |
| Region | SP_CorpDevDashboard | mp.Region / fd.Region | CASE mapping to 4 macro-regions: Americas, Middle East & Africa, APAC, Europe | Tier 2 |
| EOM_Club | BI_DB_CID_MonthlyPanel_FullData | EOM_Club | Passthrough (GROUP BY dimension) | Tier 1 |
| Age | SP_CorpDevDashboard | fd.BirthDate, mp.ActiveDate | SUM(DATEDIFF(DAY, fd.BirthDate, mp.ActiveDate) / 365.25) — total age-years for funded customers | Tier 2 |
| FirstAction | BI_DB_First5Actions | FirstActionTypeNew | Passthrough (renamed, GROUP BY dimension in FA indicator) | Tier 2 |
| FirstCross | BI_DB_First5Actions | FirstCrossNew | Passthrough (renamed, GROUP BY dimension in FA indicator) | Tier 2 |
| Regs | SP_CorpDevDashboard | BI_DB_CIDFirstDates | COUNT(*) of registrations (Regs indicator); 0 for other indicators | Tier 2 |
| CIDs | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.CID | COUNT(DISTINCT mp.CID) for All indicator; COUNT(*) for Age indicator; 0 for others | Tier 2 |
| EOM_IsFunded | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.IsEOM_Funded_NEW | SUM(mp.IsEOM_Funded_NEW) for All indicator; 0 for others | Tier 2 |
| NewFundedAccounts | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.Seniority_FundedNew | COUNT(DISTINCT CASE WHEN Seniority_FundedNew=0 THEN CID) for All indicator; 0 for others | Tier 2 |
| NewTrades_Copy | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.NewTrades_Copy | SUM(mp.NewTrades_Copy) for All indicator; 0 for others | Tier 2 |
| NewTrades_Total | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.NewTrades_Total | SUM(mp.NewTrades_Total) for All indicator; 0 for others | Tier 2 |
| Revenue_Currencies | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.A_Revenue_Currencies | SUM(mp.A_Revenue_Currencies) for All indicator; 0 for others | Tier 2 |
| Revenue_Commodities | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.A_Revenue_Commodities | SUM(mp.A_Revenue_Commodities) for All indicator; 0 for others | Tier 2 |
| Revenue_Crypto | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.A_Revenue_Crypto | SUM(mp.A_Revenue_Crypto) for All indicator; 0 for others | Tier 2 |
| Revenue_Equities | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.A_Revenue_Equities | SUM(mp.A_Revenue_Equities) for All indicator; 0 for others | Tier 2 |
| Revenue_Total | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.Revenue_Total | SUM(mp.Revenue_Total) for All indicator; 0 for others | Tier 2 |
| EOM_Equity | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.EOM_Equity | SUM(mp.EOM_Equity) for All indicator; 0 for others | Tier 2 |
| UpdateDate | SP_CorpDevDashboard | — | GETDATE() at INSERT time | Tier 2 |
| Actions | SP_CorpDevDashboard | BI_DB_First5Actions | COUNT(*) for FA indicator; 0 for others | Tier 2 |
| EOM_AUA_Currencies | SP_CorpDevDashboard | BI_DB_PositionPnL.Amount, BI_DB_PositionPnL.PositionPnL, Dim_Instrument.InstrumentTypeID | SUM(CASE WHEN InstrumentTypeID=1 THEN Amount+PositionPnL ELSE 0 END) for AUA indicator; 0 for others | Tier 2 |
| EOM_AUA_Commodities | SP_CorpDevDashboard | BI_DB_PositionPnL.Amount, BI_DB_PositionPnL.PositionPnL, Dim_Instrument.InstrumentTypeID | SUM(CASE WHEN InstrumentTypeID=2 THEN Amount+PositionPnL ELSE 0 END) for AUA indicator; 0 for others | Tier 2 |
| EOM_AUA_Crypto | SP_CorpDevDashboard | BI_DB_PositionPnL.Amount, BI_DB_PositionPnL.PositionPnL, Dim_Instrument.InstrumentTypeID | SUM(CASE WHEN InstrumentTypeID=10 THEN Amount+PositionPnL ELSE 0 END) for AUA indicator; 0 for others | Tier 2 |
| EOM_AUA_Equities | SP_CorpDevDashboard | BI_DB_PositionPnL.Amount, BI_DB_PositionPnL.PositionPnL, Dim_Instrument.InstrumentTypeID | SUM(CASE WHEN InstrumentTypeID IN(4,5,6) THEN Amount+PositionPnL ELSE 0 END) for AUA indicator; 0 for others | Tier 2 |
| Total_Deposits | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.TotalDeposits | SUM(mp.TotalDeposits) for All indicator; 0 for others | Tier 2 |
| Total_Cashouts | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.TotalCashouts | SUM(mp.TotalCashouts) for All indicator; 0 for others | Tier 2 |
| Total_PnL | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.PnL_Total | SUM(mp.PnL_Total) for All indicator; 0 for others | Tier 2 |
| Liked | SP_CorpDevDashboard | BI_DB_Social_Activity (ActionTypeID=3) | COUNT(DISTINCT RealCID) of funded customers who liked content, via #Like temp table. Populated in Soc indicator only; 0 for others | Tier 2 |
| Shared | SP_CorpDevDashboard | BI_DB_Social_Activity (ActionTypeID=4) | COUNT(DISTINCT RealCID) of funded customers who shared content, via #Share temp table. Populated in Soc indicator only; 0 for others | Tier 2 |
| WereCopied | SP_CorpDevDashboard | BI_DB_Guru_Copiers.ParentCID | COUNT(DISTINCT ParentCID) of funded customers whose trades were copied, via #WereCopied. Populated in Soc indicator only; 0 for others | Tier 2 |
| CopiedOther | SP_CorpDevDashboard | BI_DB_Guru_Copiers.CID | COUNT(DISTINCT CID) of funded customers who copied others, via #CopiedOther. Populated in Soc indicator only; 0 for others | Tier 2 |
| MaxFunded | SP_CorpDevDashboard | BI_DB_CID_MonthlyPanel_FullData.IsFunded_New | SUM(mp.IsFunded_New) for All indicator; 0 for others | Tier 2 |
