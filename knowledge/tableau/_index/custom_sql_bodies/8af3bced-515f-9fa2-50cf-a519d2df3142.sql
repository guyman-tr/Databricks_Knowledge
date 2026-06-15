SELECT*, 5 AS T, '40' AS Sig, 'T5S40' AS Params FROM Dealing_Dev.dbo.[Dealing_Dev.dbo.Nixar_Type1StartegyCardT5Sigma40] t5s25
UNION all 
SELECT *, 15 AS T, '40' AS Sig, 'T15S40' AS Params FROM Dealing_Dev.dbo.[Dealing_Dev.dbo.Nixar_Type1StartegyCardT15Sigma40] t15s25
UNION all 
SELECT *, 5 AS T, 'W' AS Sig, 'T5SW' AS Params FROM Dealing_Dev.dbo.[Dealing_Dev.dbo.Nixar_Type1StartegyCardT5SigmaWeighted]  t5sw
UNION all 
SELECT *, 15 AS T, 'W' AS Sig, 'T15SW' AS Params FROM Dealing_Dev.dbo.[Dealing_Dev.dbo.Nixar_Type1StartegyCardT15SigmaWeighted]  t15sw