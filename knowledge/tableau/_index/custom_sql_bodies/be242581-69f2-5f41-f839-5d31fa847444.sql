SELECT [Submission Date],Type, Count
FROM (SELECT [Submission Date],
       [TRAX1_HELD][Trax_Pnd]
      ,([TRAX1_AREJ]+[TRAX2_AREJ])[Trax_Rej]
      ,([TRAX1_AACK]+[TRAX2_AACK])[Trax_Acc]
      ,[TRAX_Total]
      ,[FCA_RACK][Fca_Acc]
      ,[FCA_RREJ][Fca_Rej]
      ,(([TRAX1_AACK]+ISNULL([TRAX2_AACK],0))-[FCA_RACK])+[FCA_NPND][Fca_Pnd]
      ,[FCA_Total]
    FROM 
[RegReportDB_Prod].[dbo].[TR_MIFID_UK_FCA_TRAX_Response]) p
UNPIVOT
(Count for Type IN
  ( [Trax_Pnd],[Trax_Rej],[Trax_Acc],[TRAX_Total],[Fca_Acc]
,[Fca_Rej],[Fca_Pnd],[FCA_Total])) AS upvt