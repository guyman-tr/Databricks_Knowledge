USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.InsertIntoParquetMetadata(
IN V_TableName STRING,
IN V_SchemaName STRING,
IN V_ColumnName STRING,
IN V_DataType STRING,
IN V_Ord int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



INSERT INTO dwh_daily_process.migration_tables.ParquetMetadata
(TableName  , ColumnName  , DataType ,SchemaName,Id) 
VALUES (V_TableName  , V_ColumnName  , V_DataType, V_SchemaName,V_Ord)
;

END;
