/****************************************************** FINAL table *****************************************************/

SELECT
  mas.*,
	CASE WHEN sto.OptInDate IS NOT NULL THEN 1 ELSE 0 END AS Is_Stocks_Onboard,
	sto.OptInDate AS Stocks_onboard_date,

  CASE WHEN a.CKA_Completion_Date IS NOT NULL THEN 1 ELSE 0 END AS Completed_CKA,
  a.CKA_Completion_Date,
  a.Final_CKA_PassORFail, -- manual result overrides original results
  a.Final_CKA_PassORFail_Date, -- manual result overrides original results

  CASE WHEN b.CAR_Completion_Date IS NOT NULL THEN 1 ELSE 0 END AS Completed_CAR,
  b.CAR_Completion_Date,
  b.Final_CAR_PassORFail, -- manual result overrides original results
  b.Final_CAR_PassORFail_Date, -- manual result overrides original results

	cfd.FirstManualCFDpos_Date,
	cfd.Didtrade_manualCFD,
	es.FirstManualETFpos_Date,
	es.Didtrade_manualETF,
	es.FirstManualStockspos_Date,
	es.Didtrade_manualStocks,
	m.Deposit_Amount,
	m.Cashout_Amount,
	m.NetDeposit_Amount,
	m.ManualStocks_opencount,
	m.ManualETF_opencount,
	m.ManualCFD_opencount,


	reg.Curr_Regulation,
  CASE WHEN reg.Previous_Regulation IN ('BVI','None') THEN 'None' ELSE reg.Previous_Regulation END AS Previous_Regulation,
	reg.Change_Date
--	mas_d.*,
	  ,mas_d.IP_Country
	  ,mas_d.Citizenship_Country
	  ,mas_d.Has_AdditionalCitizenship
      ,mas_d.AdditionalCitizenship_Country
	  ,mas_d.POB_Country

	  ,mas_d.PlayerStatus
	  ,mas_d.PlayerStatusReason
	  ,mas_d.PlayerStatusSubReason
	  ,mas_d.ScreeningStatus
	  ,mas_d.Club

	  ,mas_d.FirstDepositDate
	  ,mas_d.FirstDepositAmount
    
	-- KYC answers
	  ,mas_d.Is_Shareholder
	  ,mas_d.Is_Employed_By_Broker
	  ,mas_d.Is_Public_Official
	  ,mas_d.Is_Vulnerable_Client
	  ,mas_d.Sources_of_Funds
	  ,mas_d.Cash_Liquid_Assets
	  ,mas_d.Net_Annual_Income
	  ,mas_d.Planned_Invested_Amount
	  ,mas_d.Occupation
	  ,mas_d.Employment_Status
	  ,mas_d.Employment_Status_AnsDate

	  -- verification (manual/EV)
	  ,mas_d.EV_MatchStatus
	  ,mas_d.EV_MatchStatusID
	  ,mas_d.EV_MatchStatusDateTime
	  ,mas_d.VendorPOA
		,mas_d.VendorPOI
	  ,mas_d.AutoPassed_Onboarding_selfie
	  ,mas_d.AutoPassed_DocChecks
		,mas_d.AMLComment -- from BO 
		,mas_d.RiskComment -- from BO
		,mas_d.IsEDD
		,mas_d.Risk_Score -- risk score
		,mas_d.Final_Score -- risk score
	  ,current_date() AS UpdateDate
FROM
	pop mas
	LEFT JOIN Stocks_Onboarded sto ON mas.GCID = sto.GCID
	LEFT JOIN CKA_final a ON mas.GCID = a.GCID
	LEFT JOIN CAR_final b ON mas.GCID = b.GCID
	LEFT JOIN FirstTrade_CFD cfd ON mas.CID = cfd.CID
	LEFT JOIN FirstTrade_ETFstocks es ON mas.CID = es.CID
	LEFT JOIN MIMO m ON mas.CID = m.CID 
	LEFT JOIN reg3 reg ON mas.CID = reg.CID
	LEFT JOIN pop_detailed mas_d ON mas.CID = mas_d.CID