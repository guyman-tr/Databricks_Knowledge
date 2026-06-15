SELECT mda.CID
      ,mda.GCID
      ,sub.CardId
      ,b.CardStatus
      ,sub.MaskedPAN
      ,sub.CardExpirationDate AS InstanceExpirationDate
      ,mda.AccountID
      ,mda.AccountSubProgram
      ,CAST(mpfd.CardActivationTime AS DATE) AS CardActivationDATE
      ,mpfd.LastCardSettledTXDate
      ,CASE WHEN mda.CurrencyBalanceStatus IS NULL THEN 'Active' ELSE mda.CurrencyBalanceStatus END AS 'AccountStatus'
      ,mda.ProviderHolderID
      ,CASE WHEN mda.IsValidETM =1 THEN 'Yes' ELSE 'No' END AS IsValidETM
      --,RIGHT(sub.MaskedPAN,4) AS PAN_Number
      ,sub.Name
      ,CASE WHEN sub.CardExpirationDate >GETDATE()-1 THEN 'No' ELSE 'Yes' END AS InstanceExpired
      ,CASE WHEN mda.AccountSubProgram IN ('Card Premium UAE','Card Premium UK','IBAN EU Black') THEN 'Black'
            WHEN mda.AccountSubProgram IN ('Card Standard UK','IBAN EU Green') THEN 'Green'
            ELSE NULL END AS 'Black/Green'
      ,ROW_NUMBER() OVER (PARTITION BY sub.CardId,sub.CardId ORDER BY sub.CardExpirationDate DESC) AS Instance_Number
      --,LAG(sub.MaskedPAN, 1, 0) OVER (PARTITION BY sub.CardId, sub.MaskedPAN ORDER BY sub.CardId,sub.MaskedPAN,sub.CardExpirationDate) AS Replaced_after_expiration
FROM (
SELECT a.Id,a.CardId,a.MaskedPAN,CAST(a.CardExpirationDate AS DATE)CardExpirationDate,fc.AccountId,a.Name
FROM CopyFromLake.FiatDwhDB_dbo_FiatCardInstances a WITH (NOLOCK)  
LEFT JOIN eMoney_dbo.FiatCards fc ON fc.Id=a.CardId
GROUP BY a.Id,a.CardId,a.MaskedPAN,CAST(a.CardExpirationDate AS DATE),fc.AccountId,a.Name ) sub
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda WITH (NOLOCK) ON sub.AccountId = mda.AccountID  AND mda.GCID_Unique_Count=1
LEFT JOIN eMoney_dbo.eMoney_Panel_FirstDates mpfd WITH (NOLOCK) ON mda.GCID = mpfd.GCID
LEFT JOIN (
SELECT a.*
FROM (
SELECT  fcs.CardId
       ,fcs.ExpirationDate
       ,fcs.EventTimestamp
       ,ROW_NUMBER() OVER (PARTITION BY fcs.CardId ORDER BY fcs.EventTimestamp DESC) AS Row_Num
       ,fcs.CardStatusId
       ,mdcs.CardStatus
FROM eMoney_dbo.FiatCardStatuses fcs
INNER JOIN eMoney_dbo.eMoney_Dictionary_CardStatus mdcs ON fcs.CardStatusId = mdcs.CardStatusID)a
WHERE a.Row_Num=1) b ON sub.CardId=b.CardId