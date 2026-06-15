select 
	cp.[CardProviderId] AS CardId,
	account.Id as AccountId,
	cast(cs.[ExpirationDate] as date) as ExpirationDate,
	--case when cards.[Created] is not null then cast(cards.[Created] as date) else cast(account.[Created] as date) end as CreatedDate,
cast(cards.[Created] as date) as CardCreatedDate,	
CAST(cs.EventTimeStamp AS DATE) AS EvenTime,
	cs.[CardStatusId],
    cs.[UpdateDate] Status_UpdateDate,
	cardstatus.[Name] as CardStatus,
	cs.Id,
	case when cs.CardId is not null then row_number() over ( partition by cs.CardId order by cs.EventTimeStamp desc) end as RN,
	account.Gcid as GCID,
	mfm.HolderID,
	account.Created as AccountCreatedDate,
	c.RealCID,
    dc.Name as Country,
	CASE WHEN c.PlayerLevelID=7 THEN  '1.Diamond'
		 WHEN c.PlayerLevelID=6 THEN '2.Platinum Plus'
		 WHEN c.PlayerLevelID=2 then '3.Platinum'
		 WHEN c.PlayerLevelID=3 then '4.Gold' 
		 WHEN c.PlayerLevelID=5 then '5.Silver'   
		 WHEN c.PlayerLevelID=1 then '6.Bronze'
		 WHEN c.PlayerLevelID=4 then '7.Internal'
		 ELSE 'N/A' 
		 END as PlayerLevel,
	dr.Name as Regulation,
	CASE WHEN mtu.TestBot = 1 THEN  'TestBots' 
		 WHEN mtu.GCID IS NOT NULL  THEN 'TestUsers'
		 ELSE 'RegularUser' END 'User Type',
	case when account.AccountProgramId=1 then 'Card-UK'
		when account.AccountProgramId=2 then 'IBANO-UK' end Program,
	mcc.Club_At_OrderDate as Club_CardCreated,
	mcc.CardColor,
	manager.FirstName + ' ' + manager.LastName as AccountManager

from eMoney.[dbo].[ETL_FiatAccount] account  with (nolock)
JOIN eMoney_FullMappings mfm ON account.Gcid = mfm.GCID
left join eMoney.[dbo].[ETL_FiatCards] cards with (nolock) on cards.AccountId=account.Id
left join eMoney.[dbo].[ETL_FiatCardStatuses] cs with (nolock) on cards.Id=cs.CardId
left join eMoney.[dbo].[ETL_DictionaryCardStatuses] cardstatus with (nolock) on cardstatus.Id=cs.[CardStatusId]
join DWH.dbo.Dim_Customer c with (nolock) on c.GCID=account.Gcid
left JOIN eMoney_CardColor mcc ON mcc.GCID=account.Gcid AND cs.CardId = mcc.CardID
--join DWH.dbo.Fact_SnapshotCustomer fsc with (nolock) on c.RealCID=fsc.RealCID
--JOIN DWH.dbo.Dim_Range rr with (nolock) ON fsc.DateRangeID = rr.DateRangeID and case when cards.DateID is not null then cards.DateID else account.DateID end BETWEEN rr.FromDateID AND rr.ToDateID
--join DWH.dbo.Dim_PlayerLevel pl with (nolock) on pl.PlayerLevelID=fsc.PlayerLevelID

LEFT JOIN eMoney.[dbo].[ETL_FiatCardsProvidersMapping] cp with (nolock) ON cp.CardId=cs.[CardId]
LEFT JOIN eMoney.[dbo].[ETL_FiatCurrencyBalancesProvidersMapping] bp with (nolock) ON bp.[CurrencyBalanceId]=account.Id
left join DWH.dbo.Dim_Regulation dr with (nolock) on dr.ID=c.RegulationID
left join DWH.dbo.Dim_Country dc with (nolock) on dc.CountryID=c.CountryID
left join DWH.dbo.Dim_Manager manager with (nolock) on manager.ManagerID=c.AccountManagerID
LEFT JOIN eMoney.dbo.eMoney_TestUsers mtu with (nolock) ON account.Gcid = mtu.GCID
 
WHERE 1=1
--and c.PlayerLevelID <>4
and /*cards.[Created]*/ account.[Created] >= <[Parameters].[ToDate(t) (copy)]> 
and account.[Created] <= <[Parameters].[FromCreatedDate (copy)_1490128540595871744]>