SELECT 
        fca.RealCID  CID
	   ,fca.GCID
       ,fca.Occurred AS 'CreditDate'
	   ,fca.Amount Payment
	   ,fca.CompensationReasonID
	   --,dct.CreditTypeName
	   ,dcr.Name CompensationReason
	  -- ,hc.[Description] AS 'CreditDescription'
	    ,mr.MoveMoneyReason
		, edu.Country
		, edu.Regulation
		,'NA' AS 'CreditDescription'
FROM DWH_dbo.Fact_CustomerAction fca
  JOIN EXW_dbo.EXW_DimUser edu   ON fca.RealCID = edu.RealCID  
  LEFT JOIN DWH_dbo.Dim_CompensationReason dcr        ON fca.CompensationReasonID = dcr.CompensationReasonID
  LEFT JOIN DWH_dbo.Dim_MoveMoneyReason  mr WITH(NOLOCK) ON fca.MoveMoneyReasonID = mr.MoveMoneyReasonID 
WHERE fca.ActionTypeID =36
      AND fca.Occurred >= '2022-05-01'
	  AND fca.CompensationReasonID IN (101,102)