SELECT COUNT(DISTINCT dc.RealCID) AS CustomerCount,
dpl.Name
FROM
DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE
dc.IsValidCustomer = 1 -- Only valid customers
AND dc.CountryID = 12 -- Country filter
AND dc.RegulationID = 10 -- ASIC and GAML regulations
AND dc.PlayerStatusID IN (1, 12, 5) -- Normal, Warning, CopyBlock
-- (PI Level defined but not present in data)
AND dc.VerificationLevelID = 3 -- Ver Level 3
AND dc.ScreeningStatusID = 1 -- Screening (PEP) = no match
AND dc.AccountTypeID = 1 -- Private accounts only
AND dc.PhoneVerifiedID IN (1, 2) -- Phone verified (auto/manual)
AND dc.POBCountryID IS NOT NULL -- Place of birth country exists
group BY dpl.Name