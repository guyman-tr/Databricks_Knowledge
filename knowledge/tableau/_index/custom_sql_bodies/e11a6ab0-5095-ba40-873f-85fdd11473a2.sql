SELECT  s1.GCID, s1.SendDateID, s1.EmailName, s1.CountSend, s1.Delivered ,s1.UniqueOpen, s1.UniqueClicks,SentTime
FROM bi_output.bi_output_marketing_sfmc_sfmc_report s1
WHERE s1.GCID=<[Parameters].[Parameter 1]>

UNION

SELECT  s2.GCID, s2.SendDateID, s2.EmailName, s2.CountSend, s2.Delivered ,s2.UniqueOpen, s2.UniqueClicks,SentTime
FROM bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_sfmc_report_archive s2
WHERE s2.GCID=<[Parameters].[Parameter 1]>