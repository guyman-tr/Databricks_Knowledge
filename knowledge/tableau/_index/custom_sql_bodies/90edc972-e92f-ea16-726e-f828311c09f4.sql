SELECT  p.GCID, p.RealCID, op.OptionsApexID,
    r.Name as Regulation,
    --Q2_Experience, Q2_AnswerID, 
    Q2_AnswerText AS `Trading Experience`,
    --Q8_Trading_Primary_Purpose, Q8_AnswerID,
    Q8_AnswerText AS `Investment Objective`,
    --Q10_Annual_Income, Q10_AnswerID, 
    Q10_AnswerText AS `Annual Income`, 
    --Q11_Liquid_Assets, Q11_AnswerID, 
    Q11_AnswerText AS `Liquid Net Worth`, 
    --Q15_Sources_of_Income, 
    Q15_AnswerText AS `Source of Income`, 
    --Q18_Occupation, Q18_AnswerID, 
    Q18_AnswerText AS `Occupation`,
    --Q26_Sources_of_Funds, 
    Q26_AnswerText AS `Source of Funds`, 
    Q9_AnswerText AS `Risk Tolerance`,am.OptionLevel

FROM 
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel p  
join 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc  on p.GCID=dc.GCID
                                                                  and dc.IsValidCustomer=1
join 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on p.RegulationID=r.ID
left join 
  main.general.bronze_usabroker_apex_options op  on p.GCID=op.GCID
LEFT JOIN 
  main.general.bronze_sodreconciliation_apex_ext765_accountmaster am on am.AccountNumber=op.OptionsApexID
where 
  p.VerificationLevelID=3 
  AND p.RegulationID IN (6,7,8,12,2)
GROUP BY 
  p.GCID, 
  p.RealCID, 
  r.Name,
  op.OptionsApexID,
  am.OptionLevel,
    Q2_AnswerText, 
    Q8_AnswerText,
    Q10_AnswerText,
    Q11_AnswerText,
    Q15_AnswerText,
    Q18_AnswerText,
    Q26_AnswerText,
    Q9_AnswerText
--HAVING COUNT(GCID) >1