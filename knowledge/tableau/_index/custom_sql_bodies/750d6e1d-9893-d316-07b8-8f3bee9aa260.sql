SELECT  bddcl.InvestedInCopyIncludingCash,bddcl.CID,bddcl.DateID  
FROM BI_DB_dbo.BI_DB_DDR_CID_Level  bddcl
WHERE bddcl.DateID=<[Parameters].[DateID Parameter]>  
AND bddcl.Regulation='FCA'	
AND InvestedInCopyIncludingCash>0 AND bddcl.IsValidCustomer=1