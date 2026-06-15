SELECT 
    ce.CaseID,
    ce.FromDate,
    dc.[DistinctCaseCount]
FROM [BI_DB].[dbo].[BI_DB_SF_Case_Event] AS ce
INNER JOIN (
    SELECT
        YEAR([FromDate]) AS [Year],
        MONTH([FromDate]) AS [Month],
        COUNT(DISTINCT [CaseID]) AS [DistinctCaseCount]
    FROM [BI_DB].[dbo].[BI_DB_SF_Case_Event]
    WHERE [FromDate] >= '2023-04-01'  -- Filter data from April 2023 onwards
    AND DoneByRole = 'Customer Service'
    GROUP BY YEAR([FromDate]), MONTH([FromDate])
) AS dc ON YEAR(ce.FromDate) = dc.[Year] AND MONTH(ce.FromDate) = dc.[Month]