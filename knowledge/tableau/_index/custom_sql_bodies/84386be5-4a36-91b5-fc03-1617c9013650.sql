SELECT DISTINCT
    MasterAccountCID,
    STRING_AGG(CAST(CID AS VARCHAR), '-') AS CIDs
FROM 
     #cids 
GROUP BY 
    MasterAccountCID