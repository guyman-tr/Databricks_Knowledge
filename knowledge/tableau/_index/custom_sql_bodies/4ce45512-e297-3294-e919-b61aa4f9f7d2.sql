SELECT f.*
FROM Reporting.FunRejectedOrders(
    CONVERT(date, <[Parameters].[Parameter 1]>, 23),
    IIF(<[Parameters].[Parameter 2]> = 1, CONVERT(bit,1), CONVERT(bit,0))
) AS f