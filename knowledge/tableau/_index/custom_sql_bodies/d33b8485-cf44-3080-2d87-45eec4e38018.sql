SELECT d.*,
  CASE 
        WHEN d.AlertType <> 'NULL' THEN 'Alert'
        WHEN d.FundingTypeRequest = 'WireTransfer' THEN 'WireTransfer'
        WHEN d.FundingTypeRequest IN ('PWMB','GCCInstantBankTransfer') THEN 'Other non-STP MOPs'
        WHEN d.HighCO = 1 THEN 'High Cashout'
        WHEN d.CashoutReason <> 'Requested by User' THEN 'CO not requested by User'
        WHEN d.PlayerStatusAtCashout <> 'Normal' THEN 'Customer Status Not Normal'
        WHEN d.FundingTypeRequest = 'PayPal' AND d.ApprovedMOPewallet = 'No' THEN 'No Approved PP MOP'
    END AS WhyNotSTP
	FROM #details d