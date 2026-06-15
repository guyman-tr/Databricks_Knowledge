SELECT mpfd.AccountID
, mpfd.Club
, mpfd.AccountCreateDate 'Account Created Date' 
, CAST(mpfd.CardCreateTime AS DATE) 'Card Created Date'
, CAST(mpfd.CardActivationTime as Date ) AS 'Card Activated Date'
FROM eMoney_Panel_FirstDates mpfd
WHERE mpfd.IsValidETM =1 
AND mpfd.AccountProgram ='card'
AND mpfd.Country ='United Kingdom'
AND  mpfd.AccountCreateDate >= '2022-01-01'  --I took since the begining of the year
AND   mpfd.AccountCreateDate <  '2023-01-01' -- I took to end the report at the eoy