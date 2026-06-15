SELECT a.DividendID		
	  ,a.InstrumentID	
	  ,a.InstrumentDisplayName	
	  ,a.TaxCode	
	  ,a.Regulation	
	  ,a.BuyTax	
	  ,a.TotalDividendPaid	
	  ,a.Gross_Dividend	
	  ,SUM(CAST((Gross_Dividend -TotalDividendPaid) AS NUMERIC(18,2))) AS 'Total_Tax_With_held'	
FROM 		
(SELECT --COUNT(bdidtrcl.RealCID) AS CID		
	  bdidtrcl.DividendID	
	  ,bdidtrcl.InstrumentID	
	  ,bdidtrcl.InstrumentDisplayName	
	  ,bdidtrcl.TaxCode	
	  ,bdidtrcl.Regulation	
	  ,bdidtrcl.BuyTax	 
	  --,bdidtrcl.CountPositions	
	  ,SUM(bdidtrcl.TotalDividendPaid) TotalDividendPaid	
	  ,CAST(SUM(CASE WHEN bdidtrcl.IsBuy =0 then bdidtrcl.TotalDividendPaid else bdidtrcl.TotalDividendPaid/(1-bdidtrcl.BuyTax) END)AS NUMERIC(18,2)) Gross_Dividend	
FROM BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level bdidtrcl		
WHERE YEAR(bdidtrcl.PaymentDate) = <[Parameters].[Parameter 1]>		
AND		
bdidtrcl.RealCID NOT IN (SELECT DISTINCT cid FROM [BI_DB_dbo].[External_Fivetran_google_sheets_fivetran_1042_tax])		
AND bdidtrcl.IsValidCustomer =1		
AND bdidtrcl.IsBuy =1		
AND bdidtrcl.TaxCode NOT IN (0,8,996,997,998,999)		
GROUP BY  bdidtrcl.DividendID		
	  ,bdidtrcl.InstrumentID	
	  ,bdidtrcl.InstrumentDisplayName	
	  ,bdidtrcl.Regulation	
	  ,bdidtrcl.BuyTax	
	  ,bdidtrcl.TaxCode	
	  )a	
GROUP BY a.DividendID		
	  ,a.InstrumentID	
	  ,a.InstrumentDisplayName	
	  ,a.TaxCode	
	  ,a.Regulation	
	  ,a.BuyTax	
	  ,a.TotalDividendPaid	
	  ,a.Gross_Dividend