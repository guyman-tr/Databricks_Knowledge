SELECT yy.*, CD.Country,
CD.NewMarketingRegion Region
, CASE WHEN 	yy.CompensationReasonID = 96 THEN 'Churn' else 'FAN' end as AirdropType		
	FROM [Dealing_staging].[etoro_Trade_AdminPositionLog] yy	
        JOIN BI_DB_dbo.BI_DB_CIDFirstDates CD ON CD.CID=yy.CID
	WHERE (yy.CompensationReasonID = 96 OR yy.CompensationReasonID = 97)
	AND yy.FailReason IS NULL
        AND
        ExecutionOccurred>= CONVERT(CHAR(8),dateadd(MONTH, -13, getdate() - datepart(DAY, getdate()) + 1),112)