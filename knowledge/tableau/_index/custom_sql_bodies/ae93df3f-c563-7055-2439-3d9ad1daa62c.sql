SELECT 
a.AlertID
,a.CID
,a.Assignee
,a.ModifiedBy
,a.Comment
,a.CreationDate
,a.ModificationDate
,a.FundingID
,a.FollowUpDate
,a.AlertType
,a.StatusType
,a.StatusReason
,a.[Alert Status Reason]
,a.SiftScore
,a.Identifier as DepositID
,f.Name as FundingType
,d.ModificationDate as DepositDate
,d.AmountUSD as LatestAmountBeforeAlertTriggered

from 
    BI_DB_dbo.BI_DB_RiskAlertManagementTool a 
LEFT JOIN 
    DWH_dbo.Dim_FundingType f on f.FundingTypeID = a.FundingTypeId1
LEFT JOIN 
    DWH_dbo.Fact_BillingDeposit d on d.DepositID = a.Identifier
where 
    a.AlertType ='SiftScore' 
and year(a.CreationDate) >= 2025