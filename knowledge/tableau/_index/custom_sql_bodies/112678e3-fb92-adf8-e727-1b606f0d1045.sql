SELECT
mft.GCID,
MIN(CONVERT(date, convert(varchar(10), mft.DateID))
    ) AS first_date

FROM eMoney_Fact_Transactions mft
INNER JOIN eMoney_BetaUsers mbu ON mft.GCID = mbu.GCID
WHERE mft.TransactionStatusId=2 /*AND mft.DateID>='20211125'*/ AND mft.TransactionType IN ('CardPayment', 'Contactless','OnlinePayment','CashWithdrawal')
GROUP BY mft.GCID
HAVING MIN(mft.TransactionLocalTime)>='2021-11-25'