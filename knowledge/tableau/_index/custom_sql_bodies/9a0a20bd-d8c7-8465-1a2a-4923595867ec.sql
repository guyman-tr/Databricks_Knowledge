SELECT erm.*
      ,mda.RegCountry
	  ,pfd.FMI_Date
FROM eMoney.dbo.eMoney_Panel_Retention_Monthly erm WITH(NOLOCK)
LEFT JOIN eMoney.dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON erm.GCID = mda.GCID
LEFT JOIN eMoney.dbo.eMoney_Panel_FirstDates pfd WITH(NOLOCK) ON mda.GCID = pfd.GCID