SELECT bdsce.EventID
	  ,bdsce.EventName
	  ,bdsce.CreatedById
	  ,bdsce.CaseID
	  ,bdsce.EventType
	  ,bdsce.OldStatus
	  ,bdsce.NewStatus
	  ,bdsce.DoneBy
	  ,bdsce.DoneByCSDesk
	  ,bdsce.DoneByRole
	  ,bdsce.UpdatedByAutomaticProcess
	  ,bdsce.FromDate
	  ,bdsce.ToDate
	  ,bdsce.UpdateDate
	  ,bdsce.EventNumber
	  ,bdsce.Touches
	  ,bdsce.IsWorkload
	  ,bdsce.CaseNumber
	  ,bdsce.IsReopen
	  ,CONVERT(DATETIME2,ISNULL(CONVERT(DATETIME2(0),bdsce.FromDate,126)  AT TIME ZONE 'UTC' AT TIME ZONE TimeZone,bdsce.FromDate)) FromDateTimeZone
          ,DATEDIFF(SECOND,'2021-01-01',ISNULL(CONVERT(DATETIME2(0),bdsce.FromDate,126)  AT TIME ZONE 'UTC' AT TIME ZONE TimeZone,bdsce.FromDate))SecondsFrom
FROM BI_DB.dbo.BI_DB_SF_Case_Event bdsce
LEFT JOIN #timezone tz
ON bdsce.DoneBy = tz.Id