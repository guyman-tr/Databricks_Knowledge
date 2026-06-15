SELECT Country
	  ,Region
	  ,Regulation
	  ,PaymentStatus
	  ,cast(RequestDate AS DATE) AS  'RequestDate'
	  ,AutoApproval
	  ,FundingType
	  ,RedeemInd
            ,CID
	  ,CASE  WHEN SLAHours<=72 AND DATEPART(dw,RequestDate)=6 THEN 1
	   WHEN SLAHours<=48 AND DATEPART(dw,RequestDate)=7 THEN 1
	   WHEN SLAHours<=24 THEN 1 
	   ELSE 0 END AS 'SLA24_Ind'

	  ,CASE WHEN AutoApproval='AutoApproval' AND Preparation='Auto Create' AND ExecutionApproval ='AutoExecuted'
	   AND FundingType='eToroMoney' AND DATEDIFF(MINUTE,RequestDate,ModificationDate)<=15 THEN 1 ELSE 0 END AS 'STP_Ind'
	  ,CASE WHEN  DATEDIFF(MINUTE,RequestDate,ModificationDate)<=2 AND FundingType='eToroMoney' THEN 1 ELSE 0 END AS 'eMoneyInstant_IND'
	  ,Preparation
	  ,ExecutionApproval
	  ,SUM(Amount$Withdraw) AS 	'Amount$Withdraw'
	  ,SUM(Fee) AS 'WithdrawFee'
	  ,SUM(SLAHours) as'SLAHours'
	  ,COUNT(*) AS 'Tranactions'
          
FROM   BI_DB.dbo.BI_DB_Money_Out_New_Management_Dashboard
GROUP BY Country
	  ,Region
	  ,Regulation
	  ,PaymentStatus
	  ,cast(RequestDate AS DATE) 
	  ,AutoApproval
	  ,FundingType
	  ,RedeemInd
            ,CID
	  ,CASE  WHEN SLAHours<=72 AND DATEPART(dw,RequestDate)=6 THEN 1
	   WHEN SLAHours<=48 AND DATEPART(dw,RequestDate)=7 THEN 1
	   WHEN SLAHours<=24 THEN 1 
	   ELSE 0 END
	  ,CASE WHEN AutoApproval='AutoApproval' AND Preparation='Auto Create' AND ExecutionApproval ='AutoExecuted'
	   AND FundingType='eToroMoney' AND DATEDIFF(MINUTE,RequestDate,ModificationDate)<=15 THEN 1 ELSE 0 END
	  ,CASE WHEN  DATEDIFF(MINUTE,RequestDate,ModificationDate)<=2 AND FundingType='eToroMoney' THEN 1 ELSE 0 END
	  ,Preparation
	  ,ExecutionApproval