SELECT*, 5 AS T, '25' AS Sig, 'T5S25' AS Params FROM Dealing_Dev.dbo.Nixar_Type4StartegyCardT5Sigma25 t5s25
UNION all 
SELECT *, 15 AS T, '25' AS Sig, 'T15S25' AS Params FROM Dealing_Dev.dbo.Nixar_Type4StartegyCardT15Sigma25 t15s25
UNION all 
SELECT *, 5 AS T, 'W' AS Sig, 'T5SW' AS Params FROM Dealing_Dev.dbo.Nixar_Type4StartegyCardT5SigmaWeighted t5sw
UNION all 
SELECT *, 15 AS T, 'W' AS Sig, 'T15SW' AS Params FROM Dealing_Dev.dbo.Nixar_Type4StartegyCardT15SigmaWeighted t15sw