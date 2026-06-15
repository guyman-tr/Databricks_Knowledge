SELECT distinct c.*, dc1.Name as Country,
dc1.Region as Region1, ft.Name as FundingType,
case when Regulation in ('ASIC & GAML') THEN 'ASIC' 
when Regulation in ('eToroUS','FinCEN+FINRA') THEN 'FinCEN' ELSE Regulation end as Regulation1
,CASE WHEN c.HoursBetween<=2 THEN 'A: <=2 hrs'
WHEN c.HoursBetween<=4 THEN 'B: <=4 hrs'
WHEN c.HoursBetween<=6 THEN 'C: <=6 hrs'
WHEN c.HoursBetween<=8 THEN 'D: <=8 hrs'
WHEN c.HoursBetween<=10 THEN 'E: <=10 hrs'
WHEN c.HoursBetween<=12 THEN 'F: <=12 hrs'
WHEN c.HoursBetween<=16 THEN 'G: <=16 hrs'
WHEN c.HoursBetween<=18 THEN 'H: <=18 hrs'
WHEN c.HoursBetween<=20 THEN 'I: <=20 hrs'
WHEN c.HoursBetween<=22 THEN 'J: <=22 hrs'
WHEN c.HoursBetween<=24 THEN 'K: <=24 hrs'
ELSE 'L: >24 Hrs' END AS HoursDistribution,
 STRING_AGG(s.ExecutionApproval, ', ') WITHIN GROUP (ORDER BY c.RequestDate) AS ExecutionApproval,
 STRING_AGG(s.AutoApproval, ', ') WITHIN GROUP (ORDER BY c.RequestDate) AS AutoApproval,
   STRING_AGG(s.Preparation, ', ') WITHIN GROUP (ORDER BY c.RequestDate) AS Preparation
,BW.WithdrawPaymentID,
BW.CashoutStatusID_Funding
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts c
LEFT JOIN BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard s on s.WithdrawID = c.WithdrawID and s.Amount$Withdraw=c.Amount
LEFT JOIN (Select DISTINCT WithdrawID,WithdrawPaymentID, Amount_WithdrawToFunding,CashoutStatusID_Funding from  DWH_dbo.Fact_BillingWithdraw )BW ON BW.WithdrawID=s.WithdrawID AND s.WithdrawPaymentID=BW.WithdrawPaymentID and BW.Amount_WithdrawToFunding=c.Amount
join DWH_dbo.Dim_Customer dc on c.CID = dc.RealCID
join DWH_dbo.Dim_Country dc1 on dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=c.FundingTypeID
WHERE 
	cast(c.ModificationDate as date) >= '2025-01-01'

GROUP BY c.ModificationDateID,
c.UpdateDate,
c.ModCyTime,
c.RequestDay,
c.WithdrawID,
c.CurrencyID,
c.FundingTypeID,
c.CID,
c.ManagerID,
c.CashoutStatusID,
c.RequestDate,
c.Amount,
c.Commission,
c.Approved,
c.IPAddress,
c.ModificationDate,
c.Remark,
c.Comment,
c.Fee,
c.FundingID,
c.RequestorComments,
c.SessionID,
c.CashoutReasonID,
c.SuggestedBonusDeductionAmount,
c.ActualBonusDeductionAmount,
c.ActualBonusDeductionAmount,
c.ClientWithdrawReasonID,
c.ClientWithdrawReasonComment,
c.ReqCyTime,
c.VerificationLevelID,
c.RequestDate,
c.Month,
c.Year, 
c.UserFeedbackIssue,
c.Region,
c.Regulation,
c.ProcessMonth,
c.ProcessYear,
c.ProcessDay,
c.HoursBetween,
c.SLA,
c.SLA48,
c.WD_ID_SLA,
c.WD_ID_SLA48,
c.SLA5days,
c.WD_ID_SLA5days,
c.ModificationDate,
dc1.Name ,
dc1.Region, ft.Name ,
case when Regulation in ('ASIC & GAML') THEN 'ASIC' 
when Regulation in ('eToroUS','FinCEN+FINRA') THEN 'FinCEN' ELSE Regulation end
,CASE WHEN c.HoursBetween<=2 THEN 'A: <=2 hrs'
WHEN c.HoursBetween<=4 THEN 'B: <=4 hrs'
WHEN c.HoursBetween<=6 THEN 'C: <=6 hrs'
WHEN c.HoursBetween<=8 THEN 'D: <=8 hrs'
WHEN c.HoursBetween<=10 THEN 'E: <=10 hrs'
WHEN c.HoursBetween<=12 THEN 'F: <=12 hrs'
WHEN c.HoursBetween<=16 THEN 'G: <=16 hrs'
WHEN c.HoursBetween<=18 THEN 'H: <=18 hrs'
WHEN c.HoursBetween<=20 THEN 'I: <=20 hrs'
WHEN c.HoursBetween<=22 THEN 'J: <=22 hrs'
WHEN c.HoursBetween<=24 THEN 'K: <=24 hrs'
ELSE 'L: >24 Hrs' END,
BW.WithdrawPaymentID,
BW.CashoutStatusID_Funding