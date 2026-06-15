SELECT * 
FROM 	
(SELECT bdapsc.CID
	  ,bdapsc.Regulation
	  ,bdapsc.Country
	  ,bdapsc.Club
	  ,bdapsc.RegisteredReal
	  ,bdapsc.FirstDepositDate
	  ,bdapsc.Previous_ID
	  ,bdapsc.Previous_PlayerStatus
	  ,bdapsc.Current_ID
	  ,bdapsc.Current_PlayerStatus
	  ,bdapsc.Change_Date
	  ,bdapsc.Previous_ChangeDate
	  ,bdapsc.DaysBetweenChanges
	  ,bdapsc.UpdateDate
	  ,bdapsc.FirstName
	  ,bdapsc.LastName
	  ,bdapsc.MiddleName
	  ,bdapsc.Email
	  ,bdapsc.BirthDate
	  ,bdapsc.Phone
	  ,bdapsc.IP
	  ,bdapsc.PlayerStatusReason
	  ,bdapsc.PlayerStatusSubReasonName
	  ,bdapsc.Is_FTD
	  ,bdapsc.Current_Reason_ID
	  ,bdapsc.Previous_PlayerStatus_Reason_ID
	  ,bdapsc.Previous_PlayerStatus_Reason
	  ,bdapsc.Current_Sub_Reason_ID
	  ,bdapsc.PlayerStatusSubReason
	  ,bdapsc.Previous_PlayerStatus_SubReason_ID
	  ,bdapsc.Previous_PlayerStatus_Sub_Reason
	  ,bdapsc.UserName
	  ,ROW_NUMBER()OVER(PARTITION BY bdapsc.CID ORDER BY bdapsc.Change_Date DESC) RN
FROM BI_DB.dbo.BI_DB_AML_PlayerStatus_Changes bdapsc)a
WHERE a.RN =1