SELECT CID
		,CreditID
		,CreditType
		,Reason
		,Occurred
		,Amount
		,Status
		,DepositID
		,WithdrawID
		,Decline_Reason
		,Withdrawal_Type__c
		,Funding_Method__c
		,IsFTD
		,CreatedDate
		,UpdateDate
		,ExchangeRate
		,CurrencyID
		,FundingID	 
  FROM [SalesForce_DB_Prod].[dbo].[CashierHistory]
where CID=<[Parameters].[Parameter 1]>