SELECT [InstrumentType]					
      ,[Region]					
      , dsap.ShortName AS  [US_StateShortname]
	  , dsap.Name AS  [US_StateName]
	  , dcr.FullDate
	  --, dateadd(quarter, datediff(quarter, 0, dcr.FullDate) + 1, -1) quarter_end_date				
	  , SUM(dcr.Commissions) Commissions 				
	,SUM([CommissionOnOpen]) [CommissionOnOpen]				
	,SUM([CommissionOnCloseAdjustment]) [CommissionOnCloseAdjustment]				
	,SUM([CommissionOnClose]) [CommissionOnClose]				
	,SUM([RealizedCommission]) [RealizedCommission]				
	,SUM(UnrealizedCommissionChange) UnrealizedCommissionChange				
  FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport] dcr 					
  JOIN DWH_dbo.Dim_Customer dc					
		ON dcr.RealCID = dc.RealCID--	AND dc.IsCreditReportValidCB=1 AND dc.DesignatedRegulationID IN (6,7,8) AND dc.RegulationID IN (6,7,8) AND dc.CountryID=219 AND dc.IsValidCustomer=1		
 JOIN DWH_dbo.Dim_State_and_Province dsap					
		ON dc.RegionID = dsap.RegionByIP_ID			
  WHERE [DateID] >= 20220101 AND dcr.Region='USA'		
  AND InstrumentTypeID=10					
  AND dcr.[RegulationID] IN (6,7,8) AND dcr.[CountryID]=219					
  AND dcr.[IsValidCustomer]=1 AND dcr.IsCreditReportValidCB=1									
  GROUP BY  [InstrumentType]					
      ,[Region]					
      ,dsap.ShortName			
	  , dsap.Name
	 , dcr.FullDate