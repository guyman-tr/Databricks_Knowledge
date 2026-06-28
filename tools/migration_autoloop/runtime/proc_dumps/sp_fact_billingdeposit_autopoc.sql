BEGIN


DECLARE V_dateID int  ;

DECLARE V_dt1 TIMESTAMP 
;
DECLARE V_dt2 TIMESTAMP 
;
DECLARE V_flag int;
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-07-05
Description: Create SP_Fact_BillingDeposit
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
*********************************************************************************************/
--declare @date date = cast(getdate()-1 as date)

SET V_dateID = cast(date_format(V_date, 'yyyyMMdd') AS INT)
;
SET V_flag = 0    
;
WHILE V_flag < 0    
DO
set V_flag=0;
----Flag 1-------------------------------------- 
SET V_dt1 = (
SELECT
MAX(UpdateDate) FROM dwh_daily_process.migration_tables.Dim_CountryBin

 LIMIT 1);
SELECT V_dt1    
   
	;
IF V_dt1>=cast( current_timestamp() as date) THEN
SET V_flag=V_flag+1;
END IF;
SELECT V_flag;

----Flag 2-------------------------------------- 
SET V_dt2 = (
SELECT
MAX(UpdateDate) FROM dwh_daily_process.migration_tables.Dim_Country

 LIMIT 1);
SELECT V_dt2   
   
	;
IF V_dt2>=cast( current_timestamp() as date) THEN
SET V_flag=V_flag+1;
END IF;
SELECT V_flag

;
-- [stub] IF V_flag = 2 BREAK ELSE -> collapsed (WHILE condition exits naturally)
call dwh_daily_process.migration_tables.WaitforSeconds(60);
END WHILE;


--DROP TABLE IF EXISTS #MOPCountry
DROP VIEW IF EXISTS TEMP_TABLE_MOPCountry;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_MOPCountry  
 AS
SELECT fbd.DepositID
      ,mopcountrynum.Name MOPCountry1
      ,mopcountryabb.Name MOPCountry2
      ,mopcountryabb1.Name MOPCountry3
FROM dwh_daily_process.migration_tables.Fact_BillingDeposit fbd
left join dwh_daily_process.migration_tables.Dim_Country mopcountrynum
    on mopcountrynum.CountryID= CASE WHEN CASE WHEN `CountryIDAsString` not rlike '[^0-9]' THEN 1 ELSE 0 END =1 THEN fbd.`CountryIDAsString` ELSE NULL END
left join dwh_daily_process.migration_tables.Dim_Country mopcountryabb
    on mopcountryabb.`LongAbbreviation`=CASE WHEN CASE WHEN `CountryIDAsString` not rlike '[^0-9]' THEN 1 ELSE 0 END =0 THEN fbd.`CountryIDAsString` ELSE NULL END
left join dwh_daily_process.migration_tables.Dim_Country mopcountryabb1
    on mopcountryabb1.`Abbreviation`=CASE WHEN CASE WHEN `CountryIDAsString` not rlike '[^0-9]' THEN 1 ELSE 0 END =0 THEN fbd.`CountryIDAsString` ELSE NULL END
WHERE 1=0;

--create Clustered Index #MOPCountry on #MOPCountry (DepositID)
DROP VIEW IF EXISTS TEMP_TABLE_MOPCountryFinal;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_MOPCountryFinal  
 AS
SELECT t.DepositID
      ,case when MOPCountry1 is not null then MOPCountry1
            when MOPCountry2 is not null then MOPCountry2
            else MOPCountry3 end as MOPCountry
FROM TEMP_TABLE_MOPCountry t 
where 
	case when MOPCountry1 is not null then MOPCountry1
         when MOPCountry2 is not null then MOPCountry2
         else MOPCountry3 
	end is not null;


MERGE INTO dwh_daily_process.migration_tables.Fact_BillingDeposit fbw_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Fact_BillingDeposit fbw
INNER JOIN dwh_daily_process.migration_tables.Dim_CountryBin cb ON TRY_CAST(fbw.BinCodeAsString AS INT) = cb.BinCode
QUALIFY ROW_NUMBER() OVER (PARTITION BY fbw.BinCodeAsString ORDER BY 1) = 1
)
ON fbw_TGT.ModificationDateID = V_dateID AND 
COALESCE(fbw.BinCodeAsString::string,'__NULL__') = COALESCE(fbw_TGT.BinCodeAsString::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
BankName = cb.IssuingBank ,
CardCategory = cb.CardCategory;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_MOPCountry;
DROP VIEW IF EXISTS TEMP_TABLE_MOPCountryFinal;
END