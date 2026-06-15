USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_ResultsSourceToTarget_Actions(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_dateid  int;
--declare @date as datetime
--set @date='2018-04-30'
set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int);

	/**/
	delete from dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions where DateID=V_dateid

;
	insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)
		select
		V_dateid AS DateID, 
		a.Category,
		a.NumOfCIDs as TargetAmount,
		b.NumOfCIDs as SourcetAmount,
		0 TargetNumOfActions,
		0 SourceNumOfActions,
		0 TargetCommissionOnOpen,
		0 SourceCommissionOnOpen,
		0 DimPositionCommissionOnOpen,
		0 TargetCommissionOnClose,
		0 SourceCommissionOnClose,
		0 DimPositionCommissionOnClose,
		case when (a.NumOfCIDs <> b.NumOfCIDs)  then 1 else 0 end as Alert,
		current_timestamp() as UpdateDate
		from dwh_daily_process.migration_tables.Val_Target_Regulation_CIDs a  join dwh_daily_process.migration_tables.Val_Source_Regulation_CIDs b on  a.Category = b.Category


;
	   insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)
		select
		V_dateid AS DateID, 
		'Cashout Withdrow' as Category,
		a.CashoutAmount as TargetAmount,
		b.CashoutAmount as SourcetAmount,
		a.CashoutActionsNumber TargetNumOfActions,
		b.CashoutActionsNumber SourceNumOfActions,
		0 TargetCommissionOnOpen,
		0 SourceCommissionOnOpen,
		0 DimPositionCommissionOnOpen,
		0 TargetCommissionOnClose,
		0 SourceCommissionOnClose,
		0 DimPositionCommissionOnClose,
		case when ((a.CashoutAmount <> b.CashoutAmount) or (a.CashoutActionsNumber <> b.CashoutActionsNumber)) then 1 else 0 end as Alert,
		current_timestamp() as UpdateDate
		from dwh_daily_process.migration_tables.Val_Target_Cashout a cross join dwh_daily_process.migration_tables.Val_Source_Cashout b


;
		insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)
		select 
	V_dateid AS DateID
	, 'NumOfValidCustomers' as Category
	, a.NumOfCID as TargetAmount
	, b.NumOfCIDs as SourcetAmount 
		, 0 TargetNumOfActions
		, 0 SourceNumOfActions
		, 0 TargetCommissionOnOpen
		, 0 SourceCommissionOnOpen
		, 0 DimPositionCommissionOnOpen
		, 0 TargetCommissionOnClose
		, 0 SourceCommissionOnClose
		, 0 DimPositionCommissionOnClose
	, case when a.NumOfCID <> b.NumOfCIDs then 1 else 0 end as Alert
	, current_timestamp() as UpdateDate
	from dwh_daily_process.migration_tables.Val_Target_CIDs a,dwh_daily_process.migration_tables.Val_Source_CIDs b



;
	     insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)
	SELECT       
V_dateid AS DateID, 
Category, 
TargetAmount, 
SourcetAmount, 
TargetNumOfActions, 
SourceNumOfActions, 
TargetCommissionOnOpen, 
SourceCommissionOnOpen,
DimPositionCommissionOnOpen, 
TargetCommissionOnClose, 
SourceCommissionOnClose, 
DimPositionCommissionOnClose, 
Alert, 
current_timestamp() AS UpdateDate
FROM            
	(
		SELECT        
		COALESCE(x.Category, y.Category) AS Category, 
		x.Amount AS TargetAmount, 
		y.Payment AS SourcetAmount, 
		x.NumOf AS TargetNumOfActions, 
		y.NumOf AS SourceNumOfActions,
		CASE WHEN y.CategoryID = 18 THEN COALESCE(x.Commission, 0) ELSE 0 END AS TargetCommissionOnOpen, 
		CASE WHEN y.CategoryID = 18 THEN COALESCE(y.Commission, 0) ELSE 0 END AS SourceCommissionOnOpen, 
		CASE WHEN y.CategoryID = 18 THEN COALESCE(f.Commission, 0) ELSE 0 END AS DimPositionCommissionOnOpen,
		CASE WHEN y.CategoryID = 17 THEN COALESCE(x.CommissionOnClose, 0) ELSE 0 END AS TargetCommissionOnClose, 
		CASE WHEN y.CategoryID = 17 THEN COALESCE(y.CommissionOnClose, 0) ELSE 0 END AS SourceCommissionOnClose, 
		CASE WHEN y.CategoryID = 17 THEN COALESCE(e.CommissionOnClose, 0) ELSE 0 END AS DimPositionCommissionOnClose,
		CASE WHEN y.CategoryID = 18 AND NOT (x.Commission <=> y.Commission) THEN 1 
			WHEN y.CategoryID = 17 AND NOT (x.CommissionOnClose <=> y.CommissionOnClose) THEN 1 
			WHEN y.CategoryID NOT IN (17, 18) AND abs(COALESCE(x.Amount, 0)) <> abs(COALESCE(y.Payment, 0)) THEN 1 ELSE 0 END AS Alert
		FROM            
		(
			SELECT        
			b.Category, 
			a.Amount, 
			a.NumOf, 
			a.Commission, 
			a.CommissionOnClose,
			b.CategoryID
			FROM  dwh_daily_process.migration_tables.Val_Target_FCA_All AS a 
			INNER JOIN
				  dwh_daily_process.migration_tables.Val_Match AS b ON a.CategoryID = b.CategoryID
			WHERE        (b.CategoryID IN (1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 14, 16, 17, 18, 20, 21, 22, 23, 24))
		) AS x 
			FULL OUTER JOIN
				(
					SELECT        
					b.Category, 
					a.Payment, 
					a.TotalCashChange, 
					a.NumOf, 
					a.Commission, 
					a.CommissionOnClose, 
					b.CategoryID
					FROM dwh_daily_process.migration_tables.Val_Source AS a 
					INNER JOIN
					dwh_daily_process.migration_tables.Val_Match AS b ON b.CreditTypeID = a.CreditTypeID
					WHERE b.CategoryID IN (1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 14, 16, 17, 18, 20, 21, 22, 23, 24)
				) AS y ON x.CategoryID = y.CategoryID 
				LEFT OUTER JOIN
					(
						SELECT        
						17 AS CategoryID, 
						SUM(Commission) AS Commission, 
						SUM(CommissionOnClose) AS CommissionOnClose
						FROM dwh_daily_process.migration_tables.Val_Target_ClosePosition
					) AS e ON e.CategoryID = y.CategoryID 
					LEFT OUTER JOIN
					(
						SELECT        
						18 AS CategoryID, 
						Sum(Commission) as Commission
						FROM dwh_daily_process.migration_tables.Val_Target_OpenPosition
					) AS f ON f.CategoryID = y.CategoryID
	) AS a_1


;
	     insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)
	SELECT V_dateid as DateID
       ,'RegulationTransfer' as Category
      ,Null as TargetAmount
      ,Null as SourcetAmount
      ,a.NumOfChangeRegulation as TargetNumOfActions
      ,b.NumOfChangeRegulation as SourceNumOfActions
      ,Null as TargetCommissionOnOpen
      ,Null as SourceCommissionOnOpen
      ,Null as DimPositionCommissionOnOpen
      ,Null as TargetCommissionOnClose
      ,Null as SourceCommissionOnClose
      ,Null as DimPositionCommissionOnClose
      ,case when a.NumOfChangeRegulation <> b.NumOfChangeRegulation then 1 else 0 end as Alert 
      ,current_timestamp() as UpdateDate
  FROM 
  dwh_daily_process.migration_tables.Val_Target_RegulationTransfer as a,dwh_daily_process.migration_tables.Val_Source_RegulationTransfer b

;
	     insert into dwh_daily_process.migration_tables.Util_ResultsSourceToTarget_Actions
(DateID
												,Category
												,TargetAmount
												,SourcetAmount
												,TargetNumOfActions
												,SourceNumOfActions
												,TargetCommissionOnOpen
												,SourceCommissionOnOpen
												,DimPositionCommissionOnOpen
												,TargetCommissionOnClose
												,SourceCommissionOnClose
												,DimPositionCommissionOnClose
												,Alert
												,UpdateDate)

	  SELECT V_dateid as DateID
       ,'LackNumOfCustomer' as Category
      ,Null as TargetAmount
      ,Null as SourcetAmount
      ,COALESCE(LackNumOfCustomer, 0) as TargetNumOfActions
      ,0 as SourceNumOfActions
      ,Null as TargetCommissionOnOpen
      ,Null as SourceCommissionOnOpen
      ,Null as DimPositionCommissionOnOpen
      ,Null as TargetCommissionOnClose
      ,Null as SourceCommissionOnClose
      ,Null as DimPositionCommissionOnClose
      ,case when COALESCE(LackNumOfCustomer, 0) <> 0 then 1 else 0 end as Alert 
      ,current_timestamp() as UpdateDate
  FROM 
  (
		Select Count(*) as LackNumOfCustomer
		from
		dwh_daily_process.migration_tables.Fact_CustomerAction
		where RealCID not in 
		(
		Select distinct RealCID
		from
		dwh_daily_process.migration_tables.Dim_Customer
		)
		and
		DateID=V_dateid
  ) a



;
END;
