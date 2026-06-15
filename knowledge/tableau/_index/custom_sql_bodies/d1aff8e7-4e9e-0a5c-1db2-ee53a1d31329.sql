SELECT RealCID, Username, GCID, ActionID, ActionDate, ActionDateID, ActionType, SubTypeName, 
        Channel, Blocked, Club, Country, Gender, PopularInvestor, NumberOfUsersFollowed, State, 
        MessageText, STRING_AGG(extracted_value, ',') AS CashTags
FROM (
    SELECT DISTINCT RealCID, Username, GCID, ActionID, ActionDate, ActionDateID, ActionType, SubTypeName, 
        Channel, Blocked, Club, Country, Gender, PopularInvestor, NumberOfUsersFollowed, State,
        MessageText,
        CASE
            WHEN extracted_value LIKE '[A-Z]%' AND ISNUMERIC(REPLACE(extracted_value, ',', '.')) = 0
                THEN '$' + REPLACE(extracted_value, '''s', '')
            ELSE ''
        END AS extracted_value
    FROM (
        SELECT DISTINCT RealCID, Username, GCID,sa. ActionID, ActionDate, ActionDateID, sta.ActionName AS ActionType, SubTypeName, 
            Channel, Blocked, Club, Country, Gender, PopularInvestor, NumberOfUsersFollowed, State, MessageText,
            CASE
                WHEN CHARINDEX('$', MessageText) > 0
                    THEN SUBSTRING(MessageText, CHARINDEX('$', MessageText) + 1, CASE
                            WHEN CHARINDEX(' ', MessageText, CHARINDEX('$', MessageText) + 1) > 0 THEN CHARINDEX(' ', MessageText, CHARINDEX('$', MessageText) + 1) - CHARINDEX('$', MessageText) - 1
                            WHEN CHARINDEX(',', MessageText, CHARINDEX('$', MessageText) + 1) > 0 THEN CHARINDEX(',', MessageText, CHARINDEX('$', MessageText) + 1) - CHARINDEX('$', MessageText) - 1
                            ELSE LEN(MessageText) - CHARINDEX('$', MessageText)
                        END)
                ELSE ''
            END AS extracted_value
        FROM BI_DB_dbo.BI_DB_Social_Activity sa 
        LEFT JOIN BI_DB_dbo.BI_DB_Social_Activity_Type sta WITH (NOLOCK) ON sa.ActionTypeID = sta.ActionID  AND sa.ActionTypeID <> 5
        JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd WITH (NOLOCK) ON sa.RealCID = fd.CID  
        WHERE sa.ActionDateID >= 20230101 AND fd.Region = 'USA' AND MessageText IS NOT NULL AND MessageText LIKE '%$%'  -- Automatic Post
    ) AS subquery
) AS subquery2
WHERE extracted_value <> ''
GROUP BY RealCID, Username, GCID, ActionID, ActionDate, ActionDateID, ActionType, SubTypeName, 
        Channel, Blocked, Club, Country, Gender, PopularInvestor, NumberOfUsersFollowed, State, MessageText