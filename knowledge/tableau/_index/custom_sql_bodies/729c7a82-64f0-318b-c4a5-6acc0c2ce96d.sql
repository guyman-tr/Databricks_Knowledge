--Money in to eMoney:
-- "eTM_to_IBAN" transaction from the eToro trading platform to the eMoney IBAN account (essentialy a cashout from eToro which is a deposit to eMoney).
-- "EXT_to_IBAN" transaction from an external source to the eMoney IBAN account (essentialy a deposit to emoney).

--Money out from eMoney:
-- "IBAN_to_eTM" transaction from the eMoney IBAN to the eToro trading platform (essentialy a deposit to eToro).
-- "IBAN_to_EXT" transaction from the eMoney IBAN to an external source (could be any bank, etc...)

--Additional Money out, using the card:
--(1) "CardPayment"
--(2) "Contactless"
--(3) "OnlinePayment"
--(4) "CashWithdrawal"
--(13) "DirectDebit"

SELECT dc.RealCID AS CID
      ,dc.GCID
	  ,CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END AS Has_IBAN
	  ,ISNULL(b.TransferReceived,0) AS TP_to_IBAN
	  ,ISNULL(b.PaymentReceived	,0) AS EXT_to_IBAN
	  ,ISNULL(b.Transfer		,0) AS IBAN_to_TP
	  ,ISNULL(b.Payment			,0) AS IBAN_to_EXT
	  ,ISNULL(b.Card			,0) AS Card
	  ,ISNULL(c.Amount,0) AS IBAN_Position_Open
FROM DWH_dbo.Dim_Customer dc 
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON dc.RealCID = mda.CID
LEFT JOIN  ( SELECT fca.RealCID AS 'CID'
             ,SUM(fca.Amount) AS Amount
FROM [DWH_dbo].[Fact_CustomerAction] fca WITH(NOLOCK)
WHERE 1=1
      AND fca.DateID >= <[Parameters].[Parameter 3]>
	  AND fca.DateID <= <[Parameters].[Parameter 2]>
	  AND fca.ActionTypeID=44
	  AND fca.RealCID IN
(
'34177578',
'36230389',
'866030',
'11179333',
'30826821',
'1816194',
'1787701',
'14984994',
'1345794',
'14249762',
'4620077',
'1592309',
'27371434',
'4990478',
'3455213',
'2665438',
'10556218',
'10508332',
'11547486',
'33561317',
'20880968',
'4865535',
'1706353',
'1760513',
'2158938',
'4994390',
'1739352',
'4733860',
'4774205',
'4806128',
'3933474',
'10816073',
'2463749',
'20126196',
'27107781',
'1806305',
'14679532',
'25440502',
'12894937',
'19791110',
'24919223',
'1049208',
'149',
'15922803',
'15911768',
'31893772',
'28559267',
'946144',
'14597271',
'3094886',
'5999272',
'11759679',
'4412185',
'9084669',
'2756014',
'402675',
'11893765',
'7789785',
'3132265',
'248',
'13034539',
'2139464',
'44',
'7742213',
'1802791',
'6446281',
'2176837',
'149',
'3444151',
'10172670',
'24322107',
'8070086',
'4487561'
)
GROUP BY fca.RealCID) c ON c.CID=dc.RealCID
LEFT JOIN (
SELECT mdt.CID
      ,mdt.GCID
	  ,SUM(CASE WHEN mdt.TxTypeID=5 THEN ABS(mdt.USDAmountApprox) ELSE 0 END ) AS TransferReceived
	  ,SUM(CASE WHEN mdt.TxTypeID=7 THEN ABS(mdt.USDAmountApprox) ELSE 0 END ) AS PaymentReceived
	  ,SUM(CASE WHEN mdt.TxTypeID=6 THEN ABS(mdt.USDAmountApprox) ELSE 0 END ) AS 'Transfer'
	  ,SUM(CASE WHEN mdt.TxTypeID=8 THEN ABS(mdt.USDAmountApprox) ELSE 0 END ) AS Payment
	  ,SUM(CASE WHEN mdt.TxTypeID IN (1,2,3,4) THEN ABS(mdt.USDAmountApprox) ELSE 0 END ) AS 'Card'
FROM eMoney_dbo.eMoney_Dim_Transaction mdt WITH(NOLOCK)
WHERE  mdt.IsTxSettled = 1 
       AND mdt.TxStatusModificationDateID >=<[Parameters].[Parameter 3]> 
	   AND mdt.TxStatusModificationDateID <=<[Parameters].[Parameter 2]> 
	   AND mdt.CID IN (
'34177578',
'36230389',
'866030',
'11179333',
'30826821',
'1816194',
'1787701',
'14984994',
'1345794',
'14249762',
'4620077',
'1592309',
'27371434',
'4990478',
'3455213',
'2665438',
'10556218',
'10508332',
'11547486',
'33561317',
'20880968',
'4865535',
'1706353',
'1760513',
'2158938',
'4994390',
'1739352',
'4733860',
'4774205',
'4806128',
'3933474',
'10816073',
'2463749',
'20126196',
'27107781',
'1806305',
'14679532',
'25440502',
'12894937',
'19791110',
'24919223',
'1049208',
'149',
'15922803',
'15911768',
'31893772',
'28559267',
'946144',
'14597271',
'3094886',
'5999272',
'11759679',
'4412185',
'9084669',
'2756014',
'402675',
'11893765',
'7789785',
'3132265',
'248',
'13034539',
'2139464',
'44',
'7742213',
'1802791',
'6446281',
'2176837',
'149',
'3444151',
'10172670',
'24322107',
'8070086',
'4487561'
)
GROUP BY mdt.CID
      ,mdt.GCID
)b ON b.CID=dc.RealCID
WHERE dc.RealCID IN (
'34177578',
'36230389',
'866030',
'11179333',
'30826821',
'1816194',
'1787701',
'14984994',
'1345794',
'14249762',
'4620077',
'1592309',
'27371434',
'4990478',
'3455213',
'2665438',
'10556218',
'10508332',
'11547486',
'33561317',
'20880968',
'4865535',
'1706353',
'1760513',
'2158938',
'4994390',
'1739352',
'4733860',
'4774205',
'4806128',
'3933474',
'10816073',
'2463749',
'20126196',
'27107781',
'1806305',
'14679532',
'25440502',
'12894937',
'19791110',
'24919223',
'1049208',
'149',
'15922803',
'15911768',
'31893772',
'28559267',
'946144',
'14597271',
'3094886',
'5999272',
'11759679',
'4412185',
'9084669',
'2756014',
'402675',
'11893765',
'7789785',
'3132265',
'248',
'13034539',
'2139464',
'44',
'7742213',
'1802791',
'6446281',
'2176837',
'149',
'3444151',
'10172670',
'24322107',
'8070086',
'4487561'
)