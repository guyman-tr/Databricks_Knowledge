SELECT * from openquery ( [AZR-W-REAL-DB-2-BIDBUser],  
  '  
select bw.WithdrawID,      
   bw.CID,       
   bw.RequestDate,       
   sum(bt.Amount) as FundingAmount,       
   bw.CashoutStatusID,       
   dc.Name as CashoutStatus,      
   ft.Name as FundingType,
   dr.Name as Regulation,
   pl.Name as PlayerLevel
 from [etoro].Billing.Withdraw bw  with(NOLOCK)      
 left join       
 [etoro].Billing.vWithdrawToFunding bt  with(NOLOCK)      
 on      
 bw.WithdrawID = bt.WithdrawID    
 left join etoro.Billing.vFunding vf
	on bt.FundingID = vf.FundingID
join etoro.Dictionary.FundingType ft
	on vf.FundingTypeID = ft.FundingTypeID
 join      
 [etoro].[Dictionary].[CashoutStatus] dc  with(NOLOCK)      
 on bw.[CashoutStatusID]=dc.[CashoutStatusID]     
join etoro.BackOffice.Customer bo
	on bw.CID = bo.CID
join etoro.Dictionary.Regulation dr
	on bo.RegulationID = dr.ID
join etoro.Customer.Customer cc
	on bw.CID = cc.CID
join etoro.Dictionary.PlayerLevel pl
	on cc.PlayerLevelID = pl.PlayerLevelID
 where cast(bw.ModificationDate as date) = cast(getdate() as Date)      
     and bw.CashoutStatusID = 3   
	 and bt.CashoutStatusID = 3
     group by bw.WithdrawID, bw.CID, bw.Amount, bw.RequestDate, bw.CashoutStatusID, dc.Name,   ft.Name ,  dr.Name, pl.Name
  '  
)