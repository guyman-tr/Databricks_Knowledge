SELECT A.*,  
    CASE WHEN DATEDIFF(DAY, CreatedDate, date) < 1 THEN 'In SLA' ELSE 'Out of SLA' END AS SLA,
    DATEDIFF(DAY, CreatedDate, date) AS DaysToResolve
FROM (
    SELECT 
        ncs.CID AS CID,
        ncs.CaseNumber AS CaseNumber,
        ncs.CreatedDate AS CreatedDate,
        ncs.ClosedDate AS Date,
        ncs.Origin AS Source,
        ncs.ClubLevel AS ClubTier,
        ncs.Status AS TicketStatus,
        ncs.ActionType AS ActionType,
        ncs.Type AS Type,
        ncs.Sub_Type AS SubType,
        ncs.Sub_Type_2 AS SubType2,
        ncs.Priority AS Priority,
        ncs.Product AS Product,
        ncs.SLA_Score__c AS SLAScore,
        ncs.NumberOfTouches AS NumberOfTouches,
        ncs.Regulation AS RegulationAtOpen,
        CONCAT(us.FirstName, ' ', us.LastName) AS FullName,
        us.Department AS Department,
        ncs.OwnerRoleName AS UserRole,
        us.SubRole AS SubRole,
        csat.cSATLast AS LastCsat,
        us.Team AS Team,
        ncs.OwnerRoleName AS TicketRole,
        ncs.OwnerSubRole AS TicketSubRole,
hw.HasWallet,
        CASE WHEN ncs.Origin IN ('Manually','Manual','BO') THEN 'Opened By eToro' ELSE 'Opened By client' END AS OpenedBy,
        ROW_NUMBER () OVER (PARTITION BY  ncs.CaseNumber ORDER BY ncs.ClosedDate DESC) AS RN,
        CASE WHEN ncs.Status IN ('Closed','Solved') THEN 'Solved' ELSE 'Other Statuses' END AS OpenClosedTicketStatus 
    FROM main.bi_output.bi_output_customer_customer_support_case ncs
    LEFT JOIN main.bi_output.bi_output_customer_customer_support_agent_user us ON ncs.OwnerId = us.ID AND YEAR(us.ToDate) = '9999'
    LEFT JOIN main.bi_output.bi_output_customer_customer_support_csat csat ON csat.CaseNumber = ncs.CaseNumber
left join (select RealCID,HasWallet from main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked ) hw on hw.RealCID=ncs.CID
    WHERE ncs.CreatedDate >= DATEADD(MONTH, -7, DATEADD(MONTH, DATEDIFF(MONTH, '1900-01-01', GETDATE()), '1900-01-01'))
) A
WHERE RN = 1