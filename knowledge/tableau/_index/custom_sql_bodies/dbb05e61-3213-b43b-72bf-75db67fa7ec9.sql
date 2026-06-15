SELECT 
       amt.CID, 
       amt.AlertType, 
       amt.StatusReason, 
       amt.[Alert Status Reason], 
       amt.StatusType ,
       amt.CreationDate,
       amt.ModificationDate,
       dm.FirstName  + ' ' + dm.LastName as ModifiedBy
    FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool amt
left join DWH_dbo.Dim_Manager dm on dm.ManagerID=amt.ModifiedBy