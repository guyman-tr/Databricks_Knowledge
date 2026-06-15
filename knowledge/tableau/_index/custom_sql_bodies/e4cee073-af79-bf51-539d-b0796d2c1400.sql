-- Tableau parameter: <[Parameters].[Enter Date (HWM) (copy)_1018376510260809728]>   -- Type: Date (mandatory)

SELECT f.*
FROM Reporting.FunStuckOrders(
    NULL,                                 -- @CID
    CAST(<[Parameters].[Enter Date (HWM) (copy)_1018376510260809728]>AS date),-- @lastUpdate
    --NULL,    -- @symbol
    --NULL,    -- @requestOccurred
    NULL    -- @apexAccountID
    --NULL     -- @positionID
) AS f