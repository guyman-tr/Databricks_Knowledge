SELECT  CID
      ,AlertID
      ,AlertCategory
      ,AlertType
      ,Total_Alerts_of_TheCategory
      ,AlertDate
      ,Regulation
      ,Country
      ,PlayerStatus
      ,Club
      ,AccountType
      ,RiskScoreName
      ,HasWallet
      ,UpdateDate
, RANK() OVER(PARTITION BY CID, AlertType ORDER BY AlertDate) AS AlertsCount
  FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New
where 
AlertType not in ('AML1013: Student Or Unemployed Withe more than 30KDeposits',
'ALL0001:All Alerts',
'AML1015: POB or Citizenship <> KYC country',
'AML1008: KYC Country<>Withdrawal country',
'OB6US: KYC - Resolve Mismatch Occupation-Income (Student,None)')