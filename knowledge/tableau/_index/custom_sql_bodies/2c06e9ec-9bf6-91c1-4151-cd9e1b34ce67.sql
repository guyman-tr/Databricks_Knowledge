SELECT
    e.AccountSubProgram,
    l.InstanceStatus,

    DATEFROMPARTS(
        YEAR(l.InstanceExpirationDate),
        MONTH(l.InstanceExpirationDate),
        1
    ) AS ExpiryMonth,

    COUNT(*) AS TotalCards

FROM #latest_instance l

JOIN eMoney_dbo.eMoney_Dim_Account e
    ON e.ProviderHolderID = l.ProviderHolderID

WHERE
    l.rn = 1
    AND l.InstanceExpirationDate >= DATEADD(MONTH, 1, GETDATE())
    AND e.CardID IS NOT NULL

GROUP BY
    e.AccountSubProgram,
    l.InstanceStatus,
    DATEFROMPARTS(
        YEAR(l.InstanceExpirationDate),
        MONTH(l.InstanceExpirationDate),
        1
    )