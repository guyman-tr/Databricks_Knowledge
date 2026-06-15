SELECT InstrumentID
, CASE WHEN MAX(StartDate) IS NULL THEN '1900-01-01'
	   ELSE MAX(StartDate)
	   END AS VisibleOnStartDate
FROM
(
SELECT 
CASE WHEN InstrumentTypeID = 10 AND AllowBuy = 0 AND OldValue = '1' AND NewValue = '0' AND RN_VisibleOnPlatformASC = 1 AND RN_PerDate = 1 THEN Date
	 WHEN OldValue = '1' AND NewValue = '0' AND RN = 1 AND RN_PerDate = 1 AND ((InstrumentTypeID = 10 AND AllowBuy = 1) OR InstrumentTypeID <> 10) THEN Date
	 WHEN OldValue IS NULL AND NewValue = '1' AND RN = 1 AND RN_PerDate = 1 THEN NULL
	 WHEN OldValue = '1' AND NewValue = '0' AND RN_VisibleOnPlatform = 1 AND RN_PerDate = 1 AND ((InstrumentTypeID = 10 AND AllowBuy = 1) OR InstrumentTypeID <> 10) THEN Date
	 ELSE NULL
	 END AS StartDate
, i.InstrumentTypeID
, i.AllowBuy
,a.*
FROM
(
SELECT 
CAST(AuditDate AS DATE) AS Date
, TRY_CAST(SUBSTRING(PK_Value, CHARINDEX(',', PK_Value) + 1, LEN(PK_Value)) AS INT) AS InstrumentID
, CASE WHEN OldValue = '1' AND NewValue = '0' THEN DENSE_RANK() OVER (PARTITION BY TRY_CAST(SUBSTRING(PK_Value, CHARINDEX(',', PK_Value) + 1, LEN(PK_Value)) AS INT) ORDER BY (CASE WHEN OldValue = '1' AND NewValue = '0' THEN CAST(AuditDate AS DATE) ELSE '1900-01-01' END) DESC) ELSE NULL END AS RN_VisibleOnPlatform
, CASE WHEN OldValue = '1' AND NewValue = '0' THEN DENSE_RANK() OVER (PARTITION BY TRY_CAST(SUBSTRING(PK_Value, CHARINDEX(',', PK_Value) + 1, LEN(PK_Value)) AS INT) ORDER BY (CASE WHEN OldValue = '1' AND NewValue = '0' THEN CAST(AuditDate AS DATE) ELSE '9999-12-31' END) ASC) ELSE NULL END AS RN_VisibleOnPlatformASC
, ROW_NUMBER() OVER (PARTITION BY TRY_CAST(SUBSTRING(PK_Value, CHARINDEX(',', PK_Value) + 1, LEN(PK_Value)) AS INT) ORDER BY AuditDate DESC) AS RN
, ROW_NUMBER() OVER (PARTITION BY TRY_CAST(SUBSTRING(PK_Value, CHARINDEX(',', PK_Value) + 1, LEN(PK_Value)) AS INT), CAST(AuditDate AS DATE) ORDER BY AuditDate DESC) AS RN_PerDate
, *
FROM [Dealing_staging].External_etoro_History_AuditHistory
WHERE ColumnName = 'VisibleInternallyOnly' 
) a
JOIN DWH_dbo.Dim_Instrument i ON a.InstrumentID = i.InstrumentID
) b
GROUP BY InstrumentID