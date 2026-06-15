SELECT 
		bdidtrcl.Regulation,
		bdidtrcl.DividendID,
		bdidtrcl.InstrumentID,
		bdidtrcl.InstrumentDisplayName,
		bdidtrcl.ISINCode,
		bdidtrcl.PositionType,
		bdidtrcl.IsBuy,
		bdidtrcl.[Currency Name] AS Currency,
		bdidtrcl.TaxCode,
		bdidtrcl.EventType,
		Year(bdidtrcl.PaymentDate) PaymentYear,
		DATEPART(Quarter,bdidtrcl.PaymentDate) PaymentQuarter,
		bdidtrcl.DividendValueInCurrency,
		bdidtrcl.BuyTax,
		bdidtrcl.PaymentDate,
		bdidtrcl.ExDate,
		sum(bdidtrcl.CountPositions) AS CountPosition,
		sum(bdidtrcl.TotalDividendPaid) AS TotalDividendPaid,
		CAST(SUM(CASE WHEN bdidtrcl.IsBuy =0 then bdidtrcl.TotalDividendPaid else bdidtrcl.TotalDividendPaid/(1-bdidtrcl.BuyTax) END)AS NUMERIC(18,10)) Gross_Dividend
FROM BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level bdidtrcl
WHERE bdidtrcl.PaymentDate between   <[Parameters].[Parameter 2]> and <[Parameters].[Parameter 3]>
		AND bdidtrcl.Status not in (0,1) -- Process
		--and bdidtrcl.IsBuy = 1
		and bdidtrcl.IsValidCustomer = 1
GROUP BY 
		bdidtrcl.Regulation,
		bdidtrcl.DividendID,
		bdidtrcl.InstrumentID,
		bdidtrcl.InstrumentDisplayName,
		bdidtrcl.ISINCode,
		bdidtrcl.PositionType,
		bdidtrcl.IsBuy,
		bdidtrcl.[Currency Name] ,
		bdidtrcl.TaxCode,
		bdidtrcl.EventType,
		Year(bdidtrcl.PaymentDate) ,
		DATEPART(Quarter,bdidtrcl.PaymentDate) ,
		bdidtrcl.DividendValueInCurrency,
		bdidtrcl.BuyTax,
		bdidtrcl.PaymentDate,
		bdidtrcl.ExDate