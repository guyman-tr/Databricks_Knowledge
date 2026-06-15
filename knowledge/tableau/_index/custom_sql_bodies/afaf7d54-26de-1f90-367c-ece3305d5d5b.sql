SELECT *, CountSuccess/NULLIF(CAST((CountSuccess + CountFailed) as money),0) SuccessPercent 
FROM 
(
SELECT 
	'Redeem' AS Service,
	SUM(CASE WHEN [rr].[etoro - RedeemStatus] = 'TransactionDone' THEN 1 ELSE 0 END) AS CountSuccess,
	SUM(CASE WHEN [rr].[etoro - RedeemStatus] = 'Terminated'  AND rr.[etoro - RedeemReason] != 'CanceledByUser' THEN 1 ELSE 0 END) AS CountFailed
 FROM EXW_dbo.EXW_RedeemReconciliation rr with (NOLOCK)
) a

union

SELECT *, CountSuccess/NULLIF(CAST((CountSuccess + CountFailed) as money),0) SuccessPercent 
from
(
SELECT 
	'conversion' AS Service,
	SUM(CASE WHEN c.ConversionStatus = '3' THEN 1 ELSE 0 END) AS CountSuccess,
	SUM(CASE WHEN c.ConversionStatus = '2' THEN 1 ELSE 0 END) AS CountFailed
FROM EXW_dbo.EXW_FactConversions c with (NOLOCK)
) b

union

SELECT *, CountSuccess/NULLIF(CAST((CountSuccess + CountFailed) as money),0) SuccessPercent 
from
(
SELECT 
	'simplex_payments' AS Service,
	SUM(CASE WHEN pr.PaymentStatus = 'Completed' THEN 1 ELSE 0 END) AS CountSuccess,
	SUM(CASE WHEN pr.PaymentStatus != 'Completed' AND pr.PaymentStatus IS NOT null THEN 1 ELSE 0 END) AS CountFailed
FROM EXW_dbo.EXW_PaymentReconciliation pr with (NOLOCK)
) c

union

SELECT *, CountSuccess/NULLIF(CAST((CountSuccess + CountFailed) as money),0) SuccessPercent 
from
(
SELECT 
	'simplex_Users_Success' AS Service,
	count(DISTINCT (CASE WHEN pr.PaymentStatus = 'Completed' THEN pr.RealCID ELSE 0 END)) AS CountSuccess,
	count(DISTINCT (CASE WHEN pr.PaymentStatus != 'Completed' AND pr.PaymentStatus IS NOT null THEN pr.RealCID ELSE 0 END)) AS CountFailed
FROM EXW_dbo.EXW_PaymentReconciliation pr with (NOLOCK)
) d