-- Tableau parameter:<[Parameters].[Enter Date (Stuck) (copy)_1018376510263664641]>   -- Type: Date (mandatory)

SELECT f.*
FROM Reporting.FunDelayedOrdersOvernight(
    NULL,                                 -- @CID
    CAST(<[Parameters].[Enter Date (Stuck) (copy)_1018376510263664641]>AS date),-- @lastUpdate
    --NULL,    -- @symbol
    --NULL,    -- @requestOccurred
    NULL   -- @apexAccountID
    --NULL     -- @positionID
) AS f