SELECT s.StakingMonth,s.StakingMonthID,s.CID,s.GCID,s.Instrument,s.StakingRewards_USD,s.IsPassRewardMinimum 
FROM EXE.dbo.BI_DB_Staking_Platform_Users_Proposed_Rewards s
WHERE s.IsPassRewardMinimum = 0
and s.UnitsOwnerID =2