SELECT
    x.[Date],
    x.new_InstrumentID AS InstrumentID,
    CASE
        WHEN x.USD_InstrumentID IS NOT NULL THEN LEFT(x.Currency, 3)
        ELSE x.Currency
    END AS Currency,
	x.LiquidityBuffer,
    MAX(x.USD_Rate) AS USD_Rate,
    x.Regulation,
    SUM(x.EligibleClients) AS EligibleClients,
    SUM(x.EligibleUnits) AS EligibleUnits,
    SUM(x.EligibleUnits) * MAX(x.USD_Rate) AS EligibleValue,
    SUM(x.OptedInClients) AS OptedInClients,
    SUM(x.OptedInUnits) AS OptedInUnits,
    SUM(x.OptedInUnits) * MAX(x.USD_Rate) AS OptedInValue,
    SUM(x.OptedOutClients) AS OptedOutClients,
    SUM(x.OptedOutUnits) AS OptedOutUnits,
    SUM(x.OptedOutUnits) * MAX(x.USD_Rate) AS OptedOutValue,
    SUM(x.Units_AvailableForStaking) AS Units_AvailableForStaking,
    SUM(x.Units_AvailableForStaking) * MAX(x.USD_Rate) AS Value_AvailableForStaking,
    GETDATE() AS UpdateDate
FROM
(
    SELECT
        a.*,
        b.USD_InstrumentID,
        COALESCE(b.USD_InstrumentID, b.InstrumentID) AS new_InstrumentID
    FROM Dealing_dbo.Dealing_Staking_OptedOut a
    JOIN
    (
        SELECT
            p.*,
            CASE
                WHEN p.InstrumentID = 100456 THEN 100063  -- SOL
                WHEN p.InstrumentID = 100110 THEN 100001  -- ETH
                WHEN p.InstrumentID = 100458 THEN 100017  -- ADA
            END AS USD_InstrumentID
        FROM Dealing_dbo.Dealing_Staking_Parameters p
    ) b
        ON a.InstrumentID = b.InstrumentID
 --    WHERE a.[Date] = CAST(GETDATE() - 1 AS DATE)
) x
GROUP BY
    x.[Date],
    x.new_InstrumentID,
	x.LiquidityBuffer,
    CASE
        WHEN x.USD_InstrumentID IS NOT NULL THEN LEFT(x.Currency, 3)
        ELSE x.Currency
    END,
    x.Regulation