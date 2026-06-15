SELECT bdqafre.Age_Group, bdqafrep.Instrument_Type,bdqafre.CID
, bdqafre.Is_Active,CONVERT(date, CONVERT(char(8), bdqafre.Report_End_Date), 112) Report_End_Date
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end bdqafre
JOIN BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions bdqafrep 
ON bdqafre.CID = bdqafrep.CID 
AND bdqafre.Report_End_Date = bdqafrep.Report_End_Date
AND bdqafre.Country = bdqafrep.Country
AND bdqafre.Account_Type_Group = bdqafrep.Account_Type_Group