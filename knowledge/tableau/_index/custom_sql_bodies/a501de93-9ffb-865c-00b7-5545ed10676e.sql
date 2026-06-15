SELECT
	 StakingMonth
	,StakingMonthID
	,WalletID
	,GCID
	,Club' Club ON Rewards Calculation'
        ,ClubRevShare 
	,RevShare
	,StakingStartDate
--	,MonthlyYield 'Monthly Yield'
	,MonthlyRewards 'User Monthly Rewards' 
	, MonthlyRewards* epd.AvgPrice AS  'User Monthly Rewards USD' 
	,UserYield 'User Monthly Yield'
--	,EligibleRewards
  ,EligibleTransactions  'Eligible Positions'
	,IsTestUser  'IsTestAccount'
	,EOMONTH(StakingStartDate) 'Staking End Date' 
	, epd.AvgPrice 'Staking Reward Price'
/*,(SELECT TOP 1 prr.StakingEndDate 
	                   FROM EXW.EXW.Staking_ETH_Rewards_Parameters prr 
					   WHERE prr.StakingStartDate =r.StakingStartDate ORDER BY prr.ID DESC ) 'Staking End Date'*/
	,(SELECT TOP 1 prr.Rewards
						FROM EXW.EXW.Staking_ETH_Rewards_Parameters prr
						WHERE prr.StakingStartDate =r.StakingStartDate ORDER BY prr.ID DESC ) 'Total Monthly Rewards'
	,(SELECT TOP 1 prr.Rewards
						FROM EXW.EXW.Staking_ETH_Rewards_Parameters prr
						WHERE prr.StakingStartDate =r.StakingStartDate ORDER BY prr.ID DESC ) *epd.AvgPrice  'Total Monthly Rewards USD'
	,(SELECT TOP 1 prr.YieldInDecimal
						FROM EXW.EXW.Staking_ETH_Rewards_Parameters prr
						WHERE prr.StakingStartDate =r.StakingStartDate ORDER BY prr.ID DESC ) 'Total Monthly Yield'
  FROM EXW.EXW.BI_Version_Staking_WalletUserRewards r
 LEFT JOIN EXW.dbo.EXW_PriceDaily epd ON epd.FullDate = EOMONTH(StakingStartDate) AND epd.CryptoID= 2
 WHERE StakingMonthID>202106