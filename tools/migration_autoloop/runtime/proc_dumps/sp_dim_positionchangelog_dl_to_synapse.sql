BEGIN



DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_YesterdayID int ;

DECLARE V_CurrentDateID int;
/********************************************************************************************
-- Author:     <Adi  Ferber>
-- Create Date: 2021-09-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_Position_PositionChangeLog_DL_To_Synapse]
 
**************************
** Change History
**************************
Date          Author       Description   
----------   ----------   ------------------------------------
2024-04-30	 Ofir Abudy   remove writing to EXT and add ChangeTypeID 5
2024-11-07	 Inbal BML	  Adding new cloumns to Dim_Instrument for Future project (NewLotCount and PreviousLotCount)
2025-01-05	 Inbal BML    Delete condition "AND ChangeTypeID in (1, 12, 11, 13, 5)"
*********************************************************************************************/
--declare @dt as date = '2025-01-05'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
SET V_YesterdayID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;
SET V_CurrentDateID = CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS int);
--Update Delete Rows ----------------------------
	delete from dwh_daily_process.migration_tables.Dim_PositionChangeLog 
	where OccurredDateID >=V_YesterdayID;
--------------------------------------------------
-- Extract Ext_Dim_Mirror_Real -------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_Dim_PositionChangeLog
	

;
		INSERT INTO dwh_daily_process.migration_tables.Dim_PositionChangeLog
	           (     PositionID
					,CID
					,Occurred
					,OccurredDateID
					,ChangeTypeID
					,PreviousAmount
					,AmountChanged
					,NewAmount
					,PreviousIsSettled
					,IsSettled
					,PreviousStopRate
					,StopRate
					,PreviousAmountInUnits
					,AmountInUnits
					,UpdateDate
					,LotCountDecimal
			        ,PreviousLotCountDecimal 
					)

	  Select
		     PositionID
			,CID
			,Occurred
			,cast(date_format(Occurred, 'yyyyMMdd') AS INT) as OccurredDateID
			,ChangeTypeID
			,PreviousAmount
			,AmountChanged
			,NewAmount
			,cast(PreviousIsSettled as int) as PreviousIsSettled
			,cast(IsSettled as int) as IsSettled
			,PreviousStopRate
			,StopRate
			,PreviousAmountInUnits
			,AmountInUnits
			,current_timestamp() as UpdateDate 
			,LotCountDecimal
			,PreviousLotCountDecimal 
	From dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog
	WHERE Occurred >= V_Yesterday;
		--	AND ChangeTypeID in (1, 12, 11, 13, 5);
END