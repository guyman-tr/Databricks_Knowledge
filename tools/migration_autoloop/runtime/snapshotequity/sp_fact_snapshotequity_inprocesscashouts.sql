BEGIN


DECLARE V_auxdate  TIMESTAMP
;
--this procedure is for DWH
---Declare @TargetDate Datetime = '20180130'

set V_auxdate=DATEADD(day, 1, V_TargetDate);

--DROP TABLE IF EXISTS #ProcessingDates
DROP VIEW IF EXISTS TEMP_TABLE_ProcessingDates;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ProcessingDates AS
Select  
    WithdrawID

From    
    dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction 
Where    
    CashoutStatusID in (3,4,5,6)
    AND ModificationDate < V_auxdate
Group By 
    WithdrawID;

---Create Clustered index #ProcessingDates on #ProcessingDates(WithdrawID)  -- Boris Disable Clustered index #ProcessingDates

--DROP TABLE IF EXISTS #a
DROP VIEW IF EXISTS TEMP_TABLE_a;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_a AS
Select 
    CID
    , sum(Amount) InProcessCashouts
    , sum(Fee) Fee
     
    From    
    dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw as Withdraw 
    LEFT JOIN 
            TEMP_TABLE_ProcessingDates ProcessingDates
        On ProcessingDates.WithdrawID = Withdraw.WithdrawID
    WHERE    
        RequestDate < V_auxdate
        and (ProcessingDates.WithdrawID Is Null)
        and (not (CashoutStatusID in (3,4,5,6) And ModificationDate < V_auxdate))
    Group By CID;

-------- Partially

--DROP TABLE IF EXISTS #b
DROP VIEW IF EXISTS TEMP_TABLE_b;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_b AS
SELECT CID
     , SUM(PartiallyProcessedAmount) PartiallyProcessedAmount
     , SUM(PartiallyInProcessAmount) PartiallyInProcessAmount
     , SUM(Fee) Fee

FROM (
    SELECT
            CID,
            SUM(PaymentAmount) PartiallyProcessedAmount,
			WithdrawID,--added BY Nir sh. 27.01.15
            RequestAmount - SUM(PaymentAmount) PartiallyInProcessAmount,
            AVG(Fee) Fee
    FROM
    (
    SELECT BWDR.CID
            , PaymentsStatusFromHistory.StatusFromHistory
            , BWDR.Amount RequestAmount
			,BWDR.WithdrawID
            , BWTF.Amount PaymentAmount
            , BWDR.Fee
    FROM
        (
            SELECT HWTFA.BW2F_ID
                , HWTFA.CashoutStatusID StatusFromHistory
                , row_number() OVER (PARTITION BY HWTFA.BW2F_ID ORDER BY HWTFA.ModificationDate DESC, HWTFA.WithdrawToFundingActionID DESC) AS Rank
                , HWTFA.WithdrawID
            FROM
                (
                SELECT BWDR.WithdrawID
                    , HWDA.CashoutStatusID StatusFromHistory
					,row_number() OVER (PARTITION BY HWDA.WithdrawID ORDER BY HWDA.WithdrawActionID DESC) AS Rank
                   -- , row_number() OVER (PARTITION BY HWDA.WithdrawID ORDER BY HWDA.ModificationDate DESC, HWDA.WithdrawActionID DESC) AS Rank -- use from 2018.04.23 by Boris 
					--, row_number() OVER (PARTITION BY HWDA.WithdrawID ORDER BY HWDA.WithdrawActionID DESC) AS Rank -- 2018-02-13 -- not in use from 2018.04.23 by Boris
                FROM
                    dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw BWDR 
                    JOIN
                        dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction HWDA 
                        ON BWDR.WithdrawID = HWDA.WithdrawID
                WHERE
                    HWDA.ModificationDate < V_auxdate
                ) RequestsStatusFromHistory
                JOIN
                    dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawToFundingAction HWTFA 
                    ON RequestsStatusFromHistory.WithdrawID = HWTFA.WithdrawID
                    AND RequestsStatusFromHistory.StatusFromHistory in (5,2) -- 2018-01-31 workaround add Status 2 Katy F
                    AND RequestsStatusFromHistory.Rank = 1
            WHERE
                HWTFA.ModificationDate < V_auxdate
        ) PaymentsStatusFromHistory
        JOIN
            dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw BWDR 
            ON BWDR.WithdrawID = PaymentsStatusFromHistory.WithdrawID
            AND PaymentsStatusFromHistory.Rank = 1
            AND PaymentsStatusFromHistory.StatusFromHistory = 3
        JOIN
            dwh_daily_process.migration_tables.Ext_FSE_Billing_WithdrawToFunding BWTF 
            ON BWTF.ID = PaymentsStatusFromHistory.BW2F_ID
            ) PartiallyProcessedWithdrawIDs
      GROUP BY
            PartiallyProcessedWithdrawIDs.CID,
            PartiallyProcessedWithdrawIDs.RequestAmount,WithdrawID--,--added BY Nir sh. 27.01.15
) a
Group By CID


;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_InProcessCashouts
           (CID
           ,InProcessCashouts
           ,DateModified)
Select  a.CID
		, COALESCE(InProcessCashouts, 0) + COALESCE(PartiallyInProcessAmount, 0)+COALESCE(Fee1, 0) + COALESCE(Fee2, 0) as  InProcessCashouts
		,V_TargetDate as TargetDate

From (
    Select COALESCE(TEMP_TABLE_a.CID, TEMP_TABLE_b.CID) CID
            , InProcessCashouts
            , PartiallyInProcessAmount         
            , TEMP_TABLE_a.Fee Fee1
            , TEMP_TABLE_b.Fee Fee2
    From TEMP_TABLE_a full join TEMP_TABLE_b on TEMP_TABLE_a.CID = TEMP_TABLE_b.CID
        ) a
WHERE COALESCE(InProcessCashouts, 0) + COALESCE(PartiallyInProcessAmount, 0)+COALESCE(Fee1, 0) + COALESCE(Fee2, 0) <> 0.00;  -- 2018-01-31 workaround to pull only <> 0
--Order By 1
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_ProcessingDates;
DROP VIEW IF EXISTS TEMP_TABLE_a;
DROP VIEW IF EXISTS TEMP_TABLE_b;
END