SELECT 
    f.RealCID,
    f.Regulation,
    f.RegisteredReal,
    f.QuestionText,
    f.AnswerText,
    CASE WHEN i.IsFirstTimeInvestor = 1 THEN 'Yes' ELSE 'No' END AS IsFirstTimeInvestor
FROM 
    #first_answers f
JOIN 
    #first_time_investors i ON f.RealCID = i.RealCID