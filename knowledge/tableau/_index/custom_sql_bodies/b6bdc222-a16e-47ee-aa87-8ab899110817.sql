SELECT *
FROM OPENQUERY([Compliance],
'SELECT   c.CustomerRequirementOverviewStatusID 
        ,c.GCID
        ,c3.[DisplayName] AS [Requirement]
        ,c.OverviewStatusID
        ,c1.[DisplayName] AS [Status]
        ,c4.DisplayName AS [OwnerID]
    --      ,c2.DisplayName AS [StatusReason]
        ,c5.DisplayName AS Reason 
        ,c.Occurred
        ,CASE WHEN a.Occurred IS NULL THEN  c.Occurred ELSE  a.Occurred END AS OpenDate
   FROM [Compliance].[CustomerRequirementsOverviewStatus] c WITH (NOLOCK)
   INNER JOIN  [Dictionary].[ComplianceOverviewStatus] c1      WITH (NOLOCK)
       ON c.OverviewStatusID = c1.[OverviewStatusID]

   INNER JOIN Compliance.Requirements c3    WITH (NOLOCK)
       ON c.RequirementID=c3.RequirementID    
   INNER JOIN  Dictionary.ComplianceOwner c4 WITH (NOLOCK)
       ON c.OwnerID=c4.OwnerID
LEFT JOIN  [ComplianceStateDB].[Dictionary].ComplianceStatusReason c5    WITH (NOLOCK)
       ON c.OpenReasonID=c5.StatusReasonID
LEFT JOIN (    SELECT distinct CustomerRequirementOverviewStatusID 
                        ,[GCID]

                        ,FIRST_VALUE(Occurred) OVER ( PARTITION BY GCID,CustomerRequirementOverviewStatusID ORDER BY Occurred) Occurred
                    FROM [ComplianceStateDB].History.[CustomerRequirementsOverviewStatus] ch WITH (NOLOCK)
                       where   ch.RequirementID=21 and ch.OpenReasonID=45) a 
ON a.GCID=c.GCID AND a.CustomerRequirementOverviewStatusID=c.CustomerRequirementOverviewStatusID
where   c.RequirementID=21 and c.OpenReasonID=45'

) a