SELECT dc.RealCID AS CID,
       dc.AffiliateID,
	   Name AS Country,
	   CAST(bdfa.FirstDepositDate AS DATE) AS DepositDate,
	   CASE WHEN dc.IsDepositor = 1 THEN 'V' ELSE 'X' END AS Deposit,
	   CASE WHEN bdfa.FirstAction IS NOT NULL THEN 'V'ELSE 'X' END AS Trade,
       CASE WHEN dc.AffiliateID = 113475 THEN 'US' 
	        WHEN dc.AffiliateID = 113482 THEN 'Global'
			END AS 'US/Global',
       CASE WHEN dc1.Name IN ('Australia',
                              'Ausria',
                              'Baharain',
                              'Denmark',
                              'Finland',
                              'France',
                              'Germany',
                              'Irland',
                              'Italy',
                              'Kuwaot',
                              'Liechtenstein',
                              'Luxembourg',
                              'Mexico',
                              'Netherlands',
                              'Norway',
                              'Oman',
                              'Qatar',
                              'Spain',
                              'Sweden',
                              'Switzarland',
                              'United Arab Emirates',
                              'United Kingdom') THEN 'Tier 1'
 WHEN dc1.Name IN ('Andorra',
                      'Argentina',
                      'Brazil',
                      'Bulgaria',
                      'Chile',
                      'Colombia',
                      'Cyprus',
                      'Czech Republic',
                      'Ecuador',
                      'Estonia',
                      'Gibraltar',
                      'Greece',
                      'Hungary',
                      'Jersy Island',
                      'Latvia',
                      'Lituania',
                      'Malta',
                      'Poland',
                      'Romania',
                      'Sait Martin',
                      'Slovakia',
                      'Uruguay') THEN 'Tier 2'
 WHEN dc1.Name IN ('United States') THEN 'Tier'            
 WHEN dc1.Name IN ('Angola',
                       'Azerbaijan',
                       'Bangladesh',
                       'Bolivia',
                       'Cayman Islands',
                       'Costa Rica',
                       'Dominican Republic',
                       'Egypt',
                       'Eritrea',
                       'Guersey',
                       'Isle Of Man',
                       'Kazakhstan',
                       'Kenya',
                       'Peru',
                       'Reunion Islands',
                       'Senegal',
                       'Seychelles',
                       'Wallis and Futuna',
                       'Belgium',
                       'French Guiana',
                       'Guadeloupe',
                       'Hong Kong',
                       'Islands',
                       'Israel',
                       'Macau',
                       'Malaysia',
                       'Martinique',
                       'Monaco',
                       'Philippines',
                       'Portugal',
                       'Singapore',
                       'Slovenia',
                       'South Korea',
                       'Taiwan',
                       'Thailand',
                       'Vietnam') THEN 'Tier 3' ELSE 'Banned' END AS Tier
FROM DWH..Dim_Customer dc
JOIN DWH..Dim_Country dc1
ON dc.CountryID = dc1.CountryID
LEFT JOIN BI_DB..BI_DB_First5Actions bdfa
ON dc.RealCID=bdfa.CID
WHERE dc.IsValidCustomer =1 AND dc.AffiliateID IN (113475,113482) AND dc.IsDepositor = 1