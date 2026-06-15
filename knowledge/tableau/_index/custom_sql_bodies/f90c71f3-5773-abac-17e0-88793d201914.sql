SELECT 
bd.*,
CASE WHEN YEAR(dc.BirthDate) BETWEEN 1946 AND 1964 THEN 'Baby Boomers'
WHEN YEAR(dc.BirthDate) BETWEEN 1965 AND 1980 THEN 'Generation X'
WHEN YEAR(dc.BirthDate) BETWEEN 1981 AND 2000 THEN 'Millennials'
WHEN YEAR(dc.BirthDate) BETWEEN 2001 AND 2020 THEN 'Generation Z' ELSE 'Others' END AS 'AgeCategories',
bdkqard.AnswerText AS IncomeAnswer,
CASE WHEN bdkqard.AnswerText  IN 
(
'Up to $10K',
'$10K-$50K'
) THEN 'Low Income'
WHEN bdkqard.AnswerText  IN 
('$50K-$200K') THEN 'Middle Income'
WHEN bdkqard.AnswerText  IN 
('Over $1M',
'$200K-$1M',
'$1M-$5M',
'$200K-$500k',
'$500K-$1M') THEN 'Upper Income'
ELSE 'unknown' END AS [IncomeCategories],
dsap.Name AS [State],
CASE WHEN dsap.Name IN 
('Pennsylvania',
'Maine',
'Rhode Island',
'Massachusetts',
'Vermont',
'Connecticut',
'New Jersey',
'New Hampshire') THEN 'Northeast'
WHEN  dsap.Name IN 
('Nebraska',
'North Dakota',
'Minnesota',
'Indiana',
'Iowa',
'Kansas',
'Michigan',
'Ohio',
'Missouri',
'Illinois',
'Wisconsin',
'South Dakota') THEN 'Midwest'
WHEN  dsap.Name IN 
('Tennessee',
'Georgia',
'Mississippi',
'Arkansas',
'South Carolina',
'North Carolina',
'Washington',
'Delaware',
'Louisiana',
'Kentucky',
'Alabama',
'West Virginia',
'District of Columbia',
'Oklahoma',
'Virginia',
'Florida',
'Maryland',
'Texas') THEN 'South'
WHEN  dsap.Name IN (
'Wyoming',
'Hawaii',
'Utah',
'Alaska',
'Washington',
'Montana',
'New Mexico',
'Oregon',
'Colorado',
'Idaho',
'California',
'Nevada',
'Arizona') THEN 'West' ELSE 'Other' END AS [SateCategories]
FROM BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity bd
LEFT JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=bd.CIDEtoro
LEFT JOIN DWH_dbo.Dim_State_and_Province dsap ON dsap.RegionByIP_ID=dc.RegionByIP_ID AND dc.CountryID=dsap.CountryID
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data bdkqard ON dc.GCID = bdkqard.GCID AND bdkqard.QuestionText IN ('What is your net annual income?')