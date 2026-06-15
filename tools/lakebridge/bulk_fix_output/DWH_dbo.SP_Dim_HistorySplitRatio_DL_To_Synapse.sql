USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_HistorySplitRatio_DL_To_Synapse(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_History_SplitRatio_DL_To_Synapse]
-- =============================================



 --truncate table [DWH_dbo].[History_SplitRatio] ----------------------------

TRUNCATE table dwh_daily_process.migration_tables.Dim_HistorySplitRatio;
--------------------------------------------------
-- --Insert data into [DWH_dbo].[History_SplitRatio] -------------------
	INSERT INTO dwh_daily_process.migration_tables.Dim_HistorySplitRatio
	(
	         ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,UpdateDate 
	  )

	 SELECT
			 ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,current_timestamp() AS UpdateDate
	From dwh_daily_process.daily_snapshot.etoro_History_SplitRatio



;
END;
