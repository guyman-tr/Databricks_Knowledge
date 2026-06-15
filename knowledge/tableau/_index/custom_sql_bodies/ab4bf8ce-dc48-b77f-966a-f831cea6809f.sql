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
  aa.UpdateDate
from 
(
SELECT row_number() over (partition BY CID order BY mcis.InstanceCreatedDate) AS rnk , mcis.* 
FROM eMoney_dbo.eMoney_Card_Instance_Summary mcis
where mcis.IsValidETM=1 
AND CardCreateDate = InstanceCreatedDate 
) aa 
WHERE aa.rnk=1