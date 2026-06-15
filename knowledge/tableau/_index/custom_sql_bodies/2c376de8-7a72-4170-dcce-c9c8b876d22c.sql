SELECT COALESCE(reg.Reg_Date, ftd.FTD_Date, v1.V1_Date, v2.V2_Date, v3.V3_Date, funded.FirstFunded_Date, firstaction.FirstAction_Date) Date,
       reg.Reg,
	   ftd.FTDs,
	   v1.V1,
	   v2.V2,
	   v3.V3,
	   funded.Funded,
	   firstaction.First_action
FROM (SELECT CAST(bdcd.registered AS DATE) AS Reg_Date,
             COUNT(DISTINCT bdcd.CID) AS Reg
      FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
      WHERE bdcd.registered>=(GETDATE()-58) AND bdcd.registered<GETDATE()
      GROUP BY CAST(bdcd.registered AS DATE)) reg
FULL OUTER JOIN (SELECT CAST(bdcd.FirstDepositDate AS DATE) AS FTD_Date ,
                        COUNT(DISTINCT bdcd.CID) AS FTDs
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.FirstDepositDate>=(GETDATE()-58) AND bdcd.FirstDepositDate<GETDATE()
                 GROUP BY CAST(bdcd.FirstDepositDate AS DATE)) ftd ON ftd.FTD_Date=reg.Reg_Date
FULL OUTER JOIN (SELECT CAST(bdcd.VerificationLevel1Date AS DATE) AS V1_Date ,
                        COUNT(DISTINCT bdcd.CID) AS V1
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.VerificationLevel1Date>=(GETDATE()-58) AND bdcd.VerificationLevel1Date<GETDATE()
                 GROUP BY CAST(bdcd.VerificationLevel1Date AS DATE)) v1 ON reg.Reg_Date=v1.V1_Date
FULL OUTER JOIN (SELECT CAST(bdcd.VerificationLevel2Date AS DATE) AS V2_Date ,
                        COUNT(DISTINCT bdcd.CID) AS V2
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.VerificationLevel2Date>=(GETDATE()-58) AND bdcd.VerificationLevel2Date<GETDATE()
                 GROUP BY CAST(bdcd.VerificationLevel2Date AS DATE)) v2 ON reg.Reg_Date=v2.V2_Date

FULL OUTER JOIN (SELECT CAST(bdcd.VerificationLevel3Date AS DATE) AS V3_Date ,
                        COUNT(DISTINCT bdcd.CID) AS V3
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.VerificationLevel3Date>=(GETDATE()-58) AND bdcd.VerificationLevel3Date<GETDATE()
                 GROUP BY CAST(bdcd.VerificationLevel3Date AS DATE)) v3 ON reg.Reg_Date=v3.V3_Date

FULL OUTER JOIN (SELECT CAST(bdcd.FirstNewFundedDate AS DATE) AS FirstFunded_Date ,
                        COUNT(DISTINCT bdcd.CID) AS Funded
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.FirstNewFundedDate>=(GETDATE()-58) AND bdcd.FirstNewFundedDate<GETDATE()
                 GROUP BY CAST(bdcd.FirstNewFundedDate AS DATE)) funded ON funded.FirstFunded_Date=reg.Reg_Date
FULL OUTER JOIN (SELECT  CAST(bdcd.FirstPosOpenDate AS DATE) AS FirstAction_Date ,
                        COUNT(DISTINCT bdcd.CID) AS First_action
                 FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
                 WHERE bdcd.FirstPosOpenDate>=(GETDATE()-58) AND bdcd.FirstPosOpenDate<GETDATE()
                 GROUP BY CAST(bdcd.FirstPosOpenDate AS DATE)) firstaction ON reg.Reg_Date=firstaction.FirstAction_Date