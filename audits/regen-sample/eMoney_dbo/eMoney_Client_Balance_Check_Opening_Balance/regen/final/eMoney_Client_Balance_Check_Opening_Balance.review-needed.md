# Review Needed: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

## 1. Column Name Typo

- `Openning_Balance_Gap` contains a double 'n' typo ("Openning" instead of "Opening"). This matches the production DDL and SP code — it is intentional in the sense that it is the deployed column name, but may warrant a rename in a future migration.

## 2. UC Migration Status

- Table is marked `_Not_Migrated`. As a small alert/exception table that is TRUNCATED daily and holds at most 1 row, migration priority is low. Consider whether this alert pattern should be replaced by a Databricks alerting mechanism rather than migrated as a table.

## 3. Historical Data Loss

- The TRUNCATE + INSERT pattern means only the latest run's result is preserved. There is no historical record of which dates had opening balance gaps. If historical tracking is desired, the ETL pattern would need to change to DELETE-by-date + INSERT (similar to eMoneyClientBalance itself).

## 4. Monitoring Integration

- It is unclear how this table is consumed downstream. No Synapse views, SPs, or other objects reference it. It may be polled by an external alerting/dashboard system. Reviewer should confirm the consumption pattern.
