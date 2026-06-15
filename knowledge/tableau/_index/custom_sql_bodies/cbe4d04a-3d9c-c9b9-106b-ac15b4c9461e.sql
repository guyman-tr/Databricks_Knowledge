SELECT * 
FROM Dealing_dbo.Dealing_CopierAnalysis dca
WHERE dca.Date>=DATEADD(MONTH,-8,GETDATE())