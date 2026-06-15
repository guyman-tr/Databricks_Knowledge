SELECT [Submission Date],Type, Count

FROM (SELECT [Submission Date],
       [TRAX1_HELD][Trax_Pnd]
      ,([TRAX1_AREJ]+[TRAX2_AREJ])[Trax_Rej]
      ,([TRAX1_AACK]+[TRAX2_AACK])[Trax_Acc]
      ,[TRAX_Total]
      ,[CySEC_RACK][CySEC_Acc]
      ,[CySEC_RREJ][CySEC_Rej]
      ,(([TRAX1_AACK]+ISNULL([TRAX2_AACK],0))-[CySEC_RACK])+[CySEC_NPND][CySEC_Pnd]
      ,[CySEC_Total]
    FROM 
[RegReportDB_Prod].[dbo].[TR_MIFID_EU_CySEC_TRAX_Response]) p

UNPIVOT

(Count for Type IN
  ( [Trax_Pnd],[Trax_Rej],[Trax_Acc],[TRAX_Total],[CySEC_Acc]
,[CySEC_Rej],[CySEC_Pnd],[CySEC_Total])) AS upvt