USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Validation_Cycle_Gap_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_Yesterday  date
;
DECLARE V_CurrentDate  date
;
DECLARE V_PrevYesterday  date
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: <2021-09-27>
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Validation_Cycle_Gap_DL_To_Synapse] '20220122'
-- =============================================

SET V_Yesterday= CAST(V_dt as date) ;
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
SET V_PrevYesterday = DATEADD(DAY, -1, V_Yesterday);
-- Ext Val_FCV_OpeningBalance ---------------------------

TRUNCATE TABLE dwh_daily_process.migration_tables.Val_FCV_OpeningBalance

;
	INSERT INTO dwh_daily_process.migration_tables.Val_FCV_OpeningBalance
	SELECT
		 CID
		,Liabilities
		,PositionPnL
		,TotalCash
		,TotalPositionsAmount
		,BonusCredit
		,ActualNWA
		,InProcessCashouts
	FROM dwh_daily_process.migration_tables.V_Liabilities a
	WHERE a.DateID = date_format(V_PrevYesterday, 'yyyyMMdd');
-----------------------------------------------------
-- Ext Val_FCV_ClosingBalance -----------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Val_FCV_ClosingBalance

;
	INSERT INTO dwh_daily_process.migration_tables.Val_FCV_ClosingBalance
	SELECT 
		 CID
		,Liabilities
		,PositionPnL
		,TotalCash
		,TotalPositionsAmount
		,BonusCredit
		,ActualNWA
		,InProcessCashouts
	FROM dwh_daily_process.migration_tables.V_Liabilities a
	WHERE a.DateID= date_format(V_Yesterday, 'yyyyMMdd');
-----------------------------------------------------
-- Ext Val_FCV_MovementSum --------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Val_FCV_MovementSum

;
	INSERT INTO dwh_daily_process.migration_tables.Val_FCV_MovementSum
	SELECT 
		 RealCID
		 ,sum(
			case 
				when CategoryID=17 then NetProfit 
				when CategoryID=4 then -1*Amount 
				when CategoryID=19 then  -1*Commission 
				else  Amount 
			end) as Amount
	FROM dwh_daily_process.migration_tables.Fact_CustomerAction a
	JOIN dwh_daily_process.migration_tables.Dim_ActionType b
	ON(a.ActionTypeID=b.ActionTypeID)
	WHERE a.DateID = date_format(V_Yesterday, 'yyyyMMdd') 
	AND CategoryID in(2,4,6,7,8,12,17,20,21,/*23,*/19)/*Only MINO movements*/
	GROUP BY RealCID;
-----------------------------------------------------
-- Ext Val_FCV_COMovements ------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Val_FCV_COMovements

;
	INSERT INTO dwh_daily_process.migration_tables.Val_FCV_COMovements
	SELECT 
		 RealCID
		,SUM(Direction *(Amount + Commission))as COMovements
		FROM
			(
				SELECT 
					 RealCID
					,Category
					,CASE WHEN b.CategoryID = 5 THEN 1.00 WHEN b.CategoryID IN (4, 19, 23) THEN -1.00  END AS Direction   
					,Sum(CASE WHEN b.CategoryID IN (4,5,23) THEN ABS(Amount) ELSE 0 END) Amount
					,Sum(CASE WHEN b.CategoryID IN (5,19,23) THEN ABS(Commission) ELSE 0 END) Commission 
				FROM dwh_daily_process.migration_tables.Fact_CustomerAction a
				JOIN dwh_daily_process.migration_tables.Dim_ActionType b					
				ON a.ActionTypeID=b.ActionTypeID
				WHERE a.DateID = date_format(V_Yesterday, 'yyyyMMdd') 
				AND b.CategoryID IN (4,5,19,23)
				group by 
					 RealCID
					,Category
					,Case	
						when b.CategoryID = 5 then 1.00 
						when b.CategoryID IN (4, 19, 23) then -1.00
					end
			) a
		GRoup by RealCID;
-----------------------------------------------------
-- Delete Rows for Process Date - Util_ResultsLiabilities_Cycle
	DELETE FROM dwh_daily_process.migration_tables.Util_ResultsLiabilities_Cycle 
	where DateID= date_format(V_Yesterday, 'yyyyMMdd');
-----------------------------------------------------
-- Execute SP_Test_Liabilities_Cycle ----------------
call dwh_daily_process.migration_tables.SP_Test_Liabilities_Cycle(V_Yesterday , 1);
END;
