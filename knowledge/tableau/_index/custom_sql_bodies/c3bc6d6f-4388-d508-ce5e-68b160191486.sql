SELECT 
	dt.[Country (customer)],
	dt.Year,
	dt.YearMonthDay,
	dt.FundingType,
	dt.CardSubType,
	dt.Provider,
	-- Total
	COUNT(DISTINCT dt.CID) [Uniq_Client_count_all],
	COUNT(dt.DepositID) [Deposit_count_all],
	SUM(dt.[Amount in $]) [Deposit_amount_all],

	-- Approved
	COUNT(DISTINCT CASE WHEN dt.PaymentStatus = 'Approved' THEN dt.CID END) [Uniq_Client_count_approved],
	COUNT(CASE WHEN dt.PaymentStatus = 'Approved' THEN dt.DepositID END) [Deposit_count_approved],
	SUM(CASE WHEN dt.PaymentStatus = 'Approved' THEN dt.[Amount in $] ELSE 0 END) [Deposit_amount_approved]

FROM
	#Deposits_tx dt
GROUP BY
	dt.[Country (customer)],
	dt.Year,
	dt.YearMonthDay,
	dt.FundingType,
	dt.CardSubType,
	dt.Provider
--ORDER BY
--	1,2,3,4,5