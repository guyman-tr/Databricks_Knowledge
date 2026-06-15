-- Tableau parameter: <[Parameters].[Enter Date (ALE) (copy)_3282842697893437440]>  -- Type: Date (mandatory)

SELECT f.*
FROM Reporting.FunGetFirmAggregationHWM(
    NULL,                                 -- @CID
    NULL,                                 -- @apexAccountID
    CAST(<[Parameters].[Enter Date (ALE) (copy)_3282842697893437440]> AS date),-- @date
    NULL   --@RegulationID
) AS f