SELECT
    bdsce.EventID,
    bdsce.EventName,
    bdsce.CreatedById,
    bdsce.CaseID,
    bdsce.EventType,
    bdsce.OldStatus,
    bdsce.NewStatus,
    bdsce.DoneBy,
    bdsce.DoneByCSDesk,
    bdsce.DoneByRole,
    bdsce.UpdatedByAutomaticProcess,
    bdsce.FromDate,
    bdsce.ToDate,
    bdsce.UpdateDate,
    bdsce.EventNumber,
    bdsce.Touches,
    bdsce.IsWorkload,
    bdsce.CaseNumber,
    bdsce.IsReopen,
    CONVERT(DATETIME2, ISNULL(CONVERT(DATETIME2(0), bdsce.FromDate, 126) AT TIME ZONE 'UTC' AT TIME ZONE TimeZone, bdsce.FromDate)) AS FromDateTimeZone,
    DATEDIFF(SECOND, '2021-01-01', ISNULL(CONVERT(DATETIME2(0), bdsce.FromDate, 126) AT TIME ZONE 'UTC' AT TIME ZONE TimeZone, bdsce.FromDate)) AS SecondsFrom,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY bdsce.CaseID ORDER BY bdsce.EventID) = 1 THEN 1 ELSE 0 END AS IsFirstUniqueCaseID
FROM BI_DB.dbo.BI_DB_SF_Case_Event bdsce
LEFT JOIN #timezone tz ON bdsce.DoneBy = tz.Id
where Cast(FromDate as DATE) >'01-01-2023'