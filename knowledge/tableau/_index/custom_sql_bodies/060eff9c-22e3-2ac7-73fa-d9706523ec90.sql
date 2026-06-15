SELECT *, isnull(ISNULL(CountSuccess,0)/nullif(CAST((CountSuccess + CountFailed) as money),0),0) SuccessPercent 
FROM 
(
SELECT 
    'Redeem' AS Service,
    SUM(CASE WHEN [rr].[etoro - RedeemStatus] = 'TransactionDone' THEN 1 ELSE 0 END) AS CountSuccess,
    SUM(CASE WHEN [rr].[etoro - RedeemStatus] = 'Terminated'  AND rr.[etoro - RedeemReason] != 'CanceledByUser' THEN 1 ELSE 0 END) AS CountFailed,
    CAST(rr.[etoro - RequestDate] AS DATE) Date
 FROM EXW_dbo.EXW_RedeemReconciliation rr with (NOLOCK)
 GROUP BY CAST(rr.[etoro - RequestDate] AS DATE)
) a

union

SELECT *,  isnull(ISNULL(CountSuccess,0)/nullif(CAST((CountSuccess + CountFailed) as money),0),0) SuccessPercent 
from
(
SELECT 
    'conversion' AS Service,
    SUM(CASE WHEN c.ConversionStatus = '3' THEN 1 ELSE 0 END) AS CountSuccess,
    SUM(CASE WHEN c.ConversionStatus = '2' THEN 1 ELSE 0 END) AS CountFailed,
    CAST(c.ToEtoroDate AS DATE) Date
FROM EXW_dbo.EXW_FactConversions c with (NOLOCK)
GROUP BY CAST(c.ToEtoroDate AS DATE)
) b

union
/*
SELECT *,  isnull(ISNULL(CountSuccess,0)/nullif(CAST((CountSuccess + CountFailed) as money),0),0) SuccessPercent 
from
(
SELECT 
    'SentTX(Exl_Conv)' AS Service,
    SUM(CASE WHEN efst.TranStatus = 'Verified' THEN 1 ELSE 0 END) AS CountSuccess,
    SUM(CASE WHEN efst.TranStatus <> 'Verified' THEN 1 ELSE 0 END) AS CountFailed,
    CAST(efst.TranPendingDate AS DATE) Date 
FROM EXW_Wallet.SentTransactions efst with (NOLOCK)
    LEFT JOIN (SELECT DISTINCT TranID from EXW_dbo.EXW_FactTransactions WHERE ActionTypeID = 1 AND IsConversion = 0) eft
        ON efst.TranID = eft.TranID 
GROUP BY CAST(efst.TranPendingDate AS DATE)
) e

union*/
SELECT *,  isnull(ISNULL(CountSuccess,0)/nullif(CAST((CountSuccess + CountFailed) as money),0),0) SuccessPercent 
from

(SELECT 
    'simplex_payments' AS Service,
    SUM(sub.Success) AS CountSuccess,
    SUM(CASE WHEN sub.Failed =1 AND  sub.reason !='User discontinues' 
    THEN 1 ELSE 0 END) AS CountFailed,
    CAST(sub.ModificationDate as Date) Date
 FROM
 
 ( Select
  a.LastStatus
 ,a.PaymentId
 ,a.PaymentStatusId
 ,a.ModificationDate
 , a.RN
 ,a.ProviderPaymentId
 ,b.MoveToEtoroStatus
 ,b.ProviderSubmittedDate
,CASE WHEN a.LastStatus = 'Completed' THEN 1 ELSE 0 END AS 'Success'
,CASE WHEN a.LastStatus != 'Completed' AND b.MoveToEtoroStatus IS NOT null THEN 1 ELSE 0 END AS 'Failed'
 , s.reason
 FROM
(Select
dp.Name AS LastStatus
, ls.PaymentId
, ls.PaymentStatusId
, ls.RN
, ls.ModificationDate
, pp.ProviderPaymentId
from 
(SELECT
 p.PaymentId
,p.PaymentStatusId
,CAST(p.Occurred as datetime) AS ModificationDate
,ROW_NUMBER() OVER (PARTITION BY PaymentId ORDER BY Occurred DESC) AS RN
from EXW_Wallet.PaymentStatuses p)ls -- latest status (desc)
Join EXW_Wallet.Payments pp on pp.Id = ls.PaymentId  AND ls.RN = 1
JOIN EXW_Dictionary.PaymentStatuses dp ON ls.PaymentStatusId = dp.Id 
) a ---latest status
LEFT JOIN 
--The assumption is that if "Provider Submitted" status exists for specific Payment ID 
--that means that Simplex approve us to proceed and tx goes to Etoro side of the process
(SELECT 
 dp.Name as MoveToEtoroStatus
 ,st.[PaymentId]
 ,st.[PaymentStatusId] as ProviderSubmitted
 ,cast(st.Occurred as datetime) AS ProviderSubmittedDate
FROM EXW_Wallet.PaymentStatuses st 
JOIN EXW_Dictionary.PaymentStatuses  dp ON st.PaymentStatusId = dp.Id where st.PaymentStatusId =11
) b--ProviderSubmitted status exists
ON a.PaymentId =b.PaymentId
LEFT JOIN EXW_dbo.EXW_SimplexMapping s on s.long_id= a.ProviderPaymentId) sub

group by CAST(sub.ModificationDate as Date)
)c