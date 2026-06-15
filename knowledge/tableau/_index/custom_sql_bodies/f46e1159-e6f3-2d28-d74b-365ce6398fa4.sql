SELECT DISTINCT
    bdramt.AlertID,
    bdramt.CID,
    bdramt.Assignee,
    bdramt.ModifiedBy,
    bdramt.Comment,
    bdramt.CreationDate,
    bdramt.ModificationDate,
    bdramt.TicketID,
    bdramt.FundingID,
    f.Name AS FundingType,
    bdramt.ResourceType,
    bdramt.FollowUpDate,
    bdramt.AlertType,
    bdramt.AlertTypeDescription,
    bdramt.CategoryName,
    bdramt.TriggerType,
    bdramt.StatusType,
    bdramt.StatusReason,
    bdramt.[Alert Status Reason],
    bdramt.Tables,
    bdramt.RN,
    bdramt.RN1,

    dm.FirstName + ' ' + dm.LastName AS Agent,
    country.Name AS Country,
    r.Name AS Regulation,
    pl.Name AS Club,
    ps.Name AS PlayerStatus,

    c.FirstName,
    c.LastName,
    c.Email,
    c.UserName,

    /* Current value (reference only) */
    c.VerificationLevelID AS VerificationLevel_Current,

    /* Correct historical value */
    va.VerificationLevelID AS VerificationLevel_AtAlertCreation

FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool bdramt

/* ================= DIMENSIONS ================= */
LEFT JOIN DWH_dbo.Dim_Manager dm
    ON dm.ManagerID = bdramt.ModifiedBy

LEFT JOIN DWH_dbo.Dim_Customer c
    ON c.RealCID = bdramt.CID

LEFT JOIN DWH_dbo.Dim_PlayerStatus ps
    ON ps.PlayerStatusID = c.PlayerStatusID

LEFT JOIN DWH_dbo.Dim_PlayerLevel pl
    ON pl.PlayerLevelID = c.PlayerLevelID

LEFT JOIN DWH_dbo.Dim_Country country
    ON country.CountryID = c.CountryID

LEFT JOIN DWH_dbo.Dim_Regulation r
    ON r.ID = c.RegulationID

LEFT JOIN DWH_dbo.Dim_FundingType f
    ON f.FundingTypeID = bdramt.FundingTypeId

/* ================= SNAPSHOT JOIN (INLINE) ================= */
LEFT JOIN (
    SELECT
        x.AlertID,
        x.VerificationLevelID
    FROM (
        SELECT
            a.AlertID,
            fsc.VerificationLevelID,
            ROW_NUMBER() OVER (
                PARTITION BY a.AlertID
                ORDER BY dr.FromDateID DESC
            ) AS RN
        FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool a
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc
            ON fsc.RealCID = a.CID
        JOIN DWH_dbo.Dim_Range dr
            ON dr.DateRangeID = fsc.DateRangeID
        WHERE
            CONVERT(date, CONVERT(char(8), dr.FromDateID)) <= a.CreationDate
    ) x
    WHERE x.RN = 1
) va
    ON va.AlertID = bdramt.AlertID

WHERE
    bdramt.CreationDate >= '20250101'
    AND bdramt.RN1 = 1