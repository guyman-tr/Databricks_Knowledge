SELECT mprm.GCID
,mprm.Amount_Tier_3M
,mprm.Country
,mprm.Club
,mprm.ClubCategory
,mda.AccountCreateDate
,MAX(CASE WHEN mdt.TxTypeID IN (5,6) THEN mdt.TxStatusModificationDate END) AS Last_Emoney_TX
FROM eMoney.dbo.eMoney_Panel_Retention_Monthly mprm
JOIN eMoney.dbo.eMoney_Dim_Transaction mdt ON mdt.GCID=mprm.GCID 
JOIN eMoney.dbo.eMoney_Dim_Account mda ON mdt.GCID = mda.GCID
WHERE mprm.Date_for_Report=(SELECT MAX(mprm.Date_for_Report) FROM eMoney.dbo.eMoney_Panel_Retention_Monthly mprm)
AND mdt.IsTxSettled = 1
GROUP BY mprm.GCID
,mprm.Amount_Tier_3M
,mprm.Country
,mprm.Club
,mprm.ClubCategory
,mda.AccountCreateDate