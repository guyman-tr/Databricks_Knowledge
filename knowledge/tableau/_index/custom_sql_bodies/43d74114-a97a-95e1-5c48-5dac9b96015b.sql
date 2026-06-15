SELECT  bdsce.EventID,
        bdsce.EventName,
        bdsce.CreatedById,
        bdsce.CaseID,
        bdsce.EventType,
        bdsce.OldStatus,
        bdsce.NewStatus,
        bdsce.DoneBy,
        bdsce.DoneByCSDesk,
        bdsce.DoneByRole,
        bdsce.FromDate,
        bdsce.ToDate,
        bdsce.Touches,
        us.Name,
        us.Site,
		cases.ClubTierAtOpen,
		mc.IsOneTouch

FROM BI_DB.dbo.BI_DB_SF_Case_Event bdsce
INNER JOIN BI_DB.dbo.BI_DB_SF_M_Users us
ON bdsce.DoneBy = us.Id
INNER JOIN BI_DB.dbo.BI_DB_SF_Cases cases
on bdsce.CaseID=cases.TicketID
INNER JOIN BI_DB.dbo.BI_DB_SF_STG_M_Case mc
on mc.CaseID=bdsce.CaseID