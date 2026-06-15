SELECT  
  YEAR(FirstCardOrderDate) AS year,
  MONTH(FirstCardOrderDate) AS month,
  CASE WHEN sub.AccountSubProgram  IN ('Card Premium UK' , 'IBAN LIMITED UK' ,  'Card Standard UK', 'IBAN Standard UK') THEN 'UK' ELSE 'EU' END AS 'UK/EU',
  COUNT(FirstCardOrderDate) AS num_ordered,
  COUNT(InstanceActivationDate) AS num_activated,
  COUNT(CASE WHEN InstanceActivationDate IS NOT NULL AND FMI_Date IS NOT NULL THEN FMI_Date END) AS num_active_and_fmi,  
  COUNT(CASE WHEN TxAfterActivationCount >= 1 THEN TxAfterActivationCount END) AS num_tx1,  
  COUNT(CASE WHEN TxAfterActivationCount >= 2 THEN TxAfterActivationCount END) AS num_tx2  
FROM (

SELECT  
  aa.CID,
  aa.ProviderHolderID,
  aa.FMI_Date,
  aa.DWH_CardID,
  aa.ProviderCardID,
  aa.CardCreateDate AS FirstCardOrderDate,
  aa.IsValidETM,
  aa.GCID_Unique_Count,
  aa.DWH_CardInstanceId,
  aa.MaskedPAN AS FirstInstanceOrdered_MaskedPAN,
  aa.InstanceStatus,
  aa.InstanceCreatedDate,
  aa.InstanceActivationDate,
  aa.InstanceExpirationDate,
  aa.StatusByHighestRNDasc,
  aa.NextActivationDateTime,
  aa.TxAfterActivationCount,
  aa.UpdateDate,
  aa.AccountSubProgram
from  
(
SELECT mda.AccountSubProgram AS AccountSubProgram   , mda.CID AS mda_CID, row_number() over (partition BY  mcis.CID order BY mcis.InstanceCreatedDate) AS rnk , mcis.* FROM eMoney_dbo.eMoney_Card_Instance_Summary mcis
  LEFT JOIN (SELECT mda.CID, mda.AccountSubProgram FROM eMoney_dbo.eMoney_Dim_Account mda WHERE mda.GCID_Unique_Count=1) mda  
  ON mcis.CID=mda.CID
where mcis.IsValidETM=1  
AND CardCreateDate = InstanceCreatedDate  
) aa  
WHERE aa.rnk=1
) AS sub
GROUP BY YEAR(FirstCardOrderDate), MONTH(FirstCardOrderDate),  
CASE WHEN sub.AccountSubProgram  IN ('Card Premium UK' , 'IBAN LIMITED UK' ,  'Card Standard UK', 'IBAN Standard UK') THEN 'UK' ELSE 'EU' END
HAVING YEAR(FirstCardOrderDate) >= 2024