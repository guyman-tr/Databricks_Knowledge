select vl.CID
	,dc.GCID
	,vl.Credit  'Credit_30.04.24'		
	, dm.FirstName+' '+dm.LastName AS Manager
	FROM  DWH_dbo.V_Liabilities vl WITH (NOLOCK)
	INNER JOIN [DWH_dbo].Dim_Customer dc WITH (NOLOCK)
	ON dc.RealCID=vl.CID
	INNER JOIN DWH_dbo.Dim_Country dc1
	ON dc1.CountryID=dc.CountryID
	LEFT JOIN DWH_dbo.Dim_Manager dm
ON dc.AccountManagerID=dm.ManagerID
	WHERE vl.DateID=20240430
	AND dc.IsValidCustomer=1
	AND PlayerLevelID NOT IN (1)
	AND dc1.Name  NOT IN ('Afghanistan', 'Aland Islands', 'Albania', 'Anguilla', 'Bahamas', 'Barbados', 'Belarus', 'Bhutan', 'Bosnia and Herzegovina', 'Botswana',
'Burundi', 'Cambodia', 'Canada', 'Cape Verde', 'Central African Republic', 'China', 'Congo', 'Congo Republic', 'Cook Islands', 
'Cuba', 'East Timor', 'Equatorial Guinea', 'Ethiopia', 'Fiji', 'French Southern and Antarctic Territories', 'Gabon', 'Ghana', 'Grenada', 'Guam',
'Guinea', 'Guinea-Bissau', 'Guyana, Haiti', 'Iran', 'Iraq', 'Israel', 'Jamaica', 'Japan', 'Kiribati', 'Laos', 'Lebanon', 'Liberia', 'Libya', 'Macedonia',
'Mali', 'Marshall Islands', 'Martinique', 'Mauritania', 'Moldova', 'Montenegro', 'Montserrat', 'Myanmar', 'Namibia', 'Nauru','New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'Niue', 'North Korea', 'Northern Marianas', 'Pakistan', 'Palau', 'Panama', 'Papua New Guinea',
'Saint Kitts and Nevis', 'Saint Pierre', 'Saint Vincent', 'Samoa', 'Sierra Leone', 'Solomon Islands', 'Somalia', 'Switzerland', 'Sri Lanka',
'Sudan', 'Syria', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Uganda', 'United States of America', 'Vanuatu', 'Venezuela', 'Chile', 'Yemen',
'Zimbabwe','Cote d''Ivoire')