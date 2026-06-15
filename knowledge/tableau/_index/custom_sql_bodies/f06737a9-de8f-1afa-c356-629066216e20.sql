SELECT 
 CASE 
when efb.TranDate BETWEEN DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.TranDate ) < 8 THEN 'Week1'
when	efb.TranDate BETWEEN DATEADD(DAY, 8, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.TranDate ) < 15 THEN 'Week2'
when	efb.TranDate BETWEEN DATEADD(DAY, 15, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.TranDate ) < 22 THEN 'Week3'
when	efb.TranDate BETWEEN DATEADD(DAY, 22, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.TranDate ) < 29 THEN 'Week4'
when	efb.TranDate BETWEEN DATEADD(DAY, 29, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.TranDate ) < 31 THEN 'Week5' end 'Week'
 ,efb.GCID
,efb.TranDate
,efb.TranDateID
, efb.AmountUSD
,efb.Amount
,efb.EtoroFees
,efb.EtoroFeesUSD
, efb.IsEtoroFee
, efb.ActionTypeID
, efb.IsRedeem
, efb.IsConversion
,efb.IsPayment
, efb.CryptoId
, efb.CryptoName
 ,dc.Country
	, dc.Regulation
, dc.Username
, dc.IsValidCustomer
,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from [EXW].[dbo].[EXW_FactTransactions] efb with (NOLOCK)  
 JOIN EXW_WalletInventory ew	ON efb.ReciverAddress = ew.PublicAddress  and efb.CryptoId = ew.CryptoID
 JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.GCID=ew.GCID
	WHERE  1=1
AND efb.EtoroFees > 0
AND efb.TransactionTypeID IN (6, 7,0)
and year (efb.TranDate)=year(GETDATE())
and month(efb.TranDate) =month(GETDATE())