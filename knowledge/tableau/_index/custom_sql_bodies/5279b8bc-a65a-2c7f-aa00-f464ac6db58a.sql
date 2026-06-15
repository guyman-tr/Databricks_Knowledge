-- Tableau parameter: <[Parameters].[Enter CID (copy)_1191765095616462850]>   -- Type: Date (mandatory)

SELECT f.*
FROM Reporting.FunGetAleErrorReportNew(
    NULL,                                 -- @CID
    CAST(<[Parameters].[Enter CID (copy)_1191765095616462850]> AS date)-- @date
    --NULL,                                 -- @symbol
    --NULL,                                 -- @instrumentID
    --NULL,                                 -- @isBuy
    --NULL,                                 -- @ExternalID
    --NULL,                                 -- @apexAccountID
    --NULL                                  -- @AleMessageType
) AS f