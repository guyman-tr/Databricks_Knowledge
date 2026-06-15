SELECT y.*, x.real_nostro
FROM main.general.gold_lukka_all_transfers y
LEFT JOIN main.sharepoint.silver_sharepoint_account_mapping x
  ON x.account_name = y.Account_Name
  AND (
    (x.Sub_Account_Name IS NULL OR x.Sub_Account_Name = '')
    OR x.sub_account_name = y.Sub_Account_Name
  )
WHERE y.etr_ymd = (SELECT MAX(etr_ymd) FROM main.general.gold_lukka_all_transfers)
  AND CAST(y.Start_Date AS DATE) BETWEEN <[Parameters].[Parameter 1]>
 and <[Parameters].[Parameter 2]>