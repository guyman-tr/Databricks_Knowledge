select Type as 'Transaction Type',CID__c as CID,CAST(CRMLastModifiedDate__c AS DATE) as 'transaction_date',SUM(amount__c) as amount
from (
SELECT 
'Deposit' AS Type,
bd.CID AS CID__c,
bd.Credit AS Amount__c,
bd.CrmLastModifiedDate AS CRMLastModifiedDate__c
FROM   etoro.Batch_Deposit bd JOIN
        DataPlatform.Dictionary_etoro_Dictionary_PaymentStatus ps ON bd.PaymentStatusID = ps.PaymentStatusID
WHERE   
CAST(bd.CrmLastModifiedDate as date) = cast(GETDATE() as date)
and ps.Name = 'Approved'




UNION




SELECT   
'Withdrawal' AS Type,
bw.CID AS CID__c,
bw.Amount AS Amount__c,
bw.CrmLastModifiedDate AS CRMLastModifiedDate__c
FROM  etoro.Batch_Withdraw bw LEFT JOIN
			DataPlatform.Dictionary_etoro_Dictionary_CashoutStatus cs ON cs.cashoutstatusID = bw.CashoutStatusID LEFT JOIN
            [DataPlatform].[Dictionary_etoro_Dictionary_ClientWithdrawReason] cwr ON cwr.ClientWithdrawReasonID = bw.ClientWithdrawReasonID
WHERE        
CAST(bw.CrmLastModifiedDate as date) = cast(GETDATE() as date)
and cs.name ='Fully Processed'




UNION




SELECT        
'Compensation' AS Type, 
bac.CID AS CID__c,
bac.Payment AS Amount__c,
bac.CrmLastModifiedDate AS CRMLastModifiedDate__c
FROM    
etoro.Batch_BonusAndCompensation bac 
WHERE        
cast(bac.CrmLastModifiedDate as date) = cast(GETDATE() as date)
and bac.CompensationReasonID IS NOT NULL) b
	group by Type,CID__c,CAST(CRMLastModifiedDate__c AS DATE)