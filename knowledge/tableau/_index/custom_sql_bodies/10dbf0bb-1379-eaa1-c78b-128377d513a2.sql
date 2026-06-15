SELECT CID
	  ,FirstName
	  ,LastName
	  ,MiddleName
	  ,Email
	  ,BirthDate
	  ,Phone
	  ,IP
	  ,Regulation
	  ,Country
	  ,Club
	  ,RegisteredReal
	  ,FirstDepositDate
	  ,Previous_ID
	  ,Previous_PlayerStatus
	  ,Current_ID
	  ,Current_PlayerStatus
	  ,Change_Date
	  ,Previous_ChangeDate
	  ,DaysBetweenChanges
	  ,PlayerStatusReason
	  ,PlayerStatusSubReasonName
	  ,Is_FTD
	  ,Current_Reason_ID
	  ,Previous_PlayerStatus_Reason_ID
	  ,Previous_PlayerStatus_Reason
	  ,Current_Sub_Reason_ID
	  ,PlayerStatusSubReason
	  ,Previous_PlayerStatus_SubReason_ID
	  ,Previous_PlayerStatus_Sub_Reason
	  ,UserName
	  ,UpdateDate
	  ,ROW_NUMBER()OVER(PARTITION BY CID ORDER BY Change_Date DESC) ROW_NUMBER
FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes]