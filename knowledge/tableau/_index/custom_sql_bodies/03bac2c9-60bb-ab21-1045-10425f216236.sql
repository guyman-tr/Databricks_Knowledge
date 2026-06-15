SELECT PM.*, user_info.Gender, Country.Name AS Country, PlayerLevel.Name AS ClubLevel
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY GCID, DATEFROMPARTS(YEAR(RunDate), MONTH(RunDate), 1) ORDER BY RunDate DESC, LastModifiedDate DESC, createddate DESC) AS rn
    FROM etoro.PiPerformanceMetric_History
) AS PM
JOIN (
    SELECT [GCID], [CID], [PlayerLevelID], [CountryID], [Gender]
    FROM [etoro].[Batch_CustomerCustomer]
) AS user_info
ON PM.GCID = user_info.GCID
LEFT JOIN (
    SELECT [CountryID], [Name], [PhonePrefix]
    FROM [DataPlatform].[Dictionary_etoro_Dictionary_Country]
) AS Country
ON user_info.CountryID = Country.CountryID
LEFT JOIN (
    SELECT [PlayerLevelID], [Name]
    FROM [DataPlatform].[Dictionary_etoro_Dictionary_PlayerLevel]
) AS PlayerLevel
ON PlayerLevel.PlayerLevelID = user_info.PlayerLevelID
WHERE PM.rn = 1