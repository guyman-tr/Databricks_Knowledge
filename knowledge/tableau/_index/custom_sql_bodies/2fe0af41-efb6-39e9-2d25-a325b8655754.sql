SELECT b.GCID
	  ,b.Date
	  ,b.Ident_Name
	  ,Max(CASE WHEN p.OpenOccurred>='20070101' THEN 1 ELSE 0 end) AS 'Crypto_Open'
from
		(SELECT a.GCID
		--	  ,a.Status
			  ,a.Date
			  ,'Bank_Ident' AS 'Ident_Name'
		FROM (
				SELECT bi.gcid AS GCID
					  ,bi.GlobalStatus AS 'Status' 
					  ,CAST(bi.CreatedAt AS DATE) as 'Date'
					  ,ROW_NUMBER()OVER(PARTITION BY bi.gcid ORDER BY CAST(bi.CreatedAt AS DATE) DESC) RN	 
				FROM general.SolarisBankIdentDb_SolarisBankIdent bi 
				
				WHERE CAST(bi.CreatedAt AS DATE)>=dateadd(DAY,-10, GETDATE()) AND bi.GlobalStatus='successful'
			 ) a
		WHERE a.RN=1
		
		union
		SELECT a1.GCID
		--	  ,a.Status
			  ,a1.Date
		
			  ,'Video_Ident' AS 'Ident_Name'
		from
			(
		
				SELECT 	 vi.gcid AS GCID
					    ,CAST(vi.CreatedOn AS DATE) AS Date 
						,vi.Status
						,ROW_NUMBER()OVER(PARTITION BY vi.gcid ORDER BY CAST(vi.CreatedOn AS DATE) DESC) RN
				FROM general.VideoIdentDb_VideoIdent vi
				WHERE CAST(vi.CreatedOn AS DATE)>=dateadd(DAY,-10, GETDATE()) AND vi.Status='Success'
			 ) a1
		WHERE RN=1 )b
INNER JOIN DWH_dbo.Dim_Customer dc ON b.GCID=dc.GCID
LEFT JOIN (SELECT dp.*
		FROM  DWH_dbo.Dim_Position dp 
           LEFT JOIN  DWH_dbo.Dim_Instrument di ON di.InstrumentID=dp.InstrumentID AND di.InstrumentTypeID=10)p 
		   ON dc.RealCID=p.CID	AND p.OpenOccurred>=b.Date AND p.OpenOccurred<= DATEADD(DAY,1, b.Date)
GROUP BY b.GCID
	  ,b.Date
	  ,b.Ident_Name