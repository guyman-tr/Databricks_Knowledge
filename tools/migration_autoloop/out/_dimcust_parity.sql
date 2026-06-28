WITH m AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM dwh_daily_process.migration_tables.dim_customer
),
g AS (
  SELECT RealCID, CountryID, LabelID, AccountTypeID, RegulationID, PlayerLevelID, PlayerStatusID, IsValidCustomer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
)
SELECT
  (SELECT COUNT(*) FROM m) AS migration_rows,
  (SELECT COUNT(*) FROM g) AS gold_rows,
  (SELECT COUNT(*) FROM m LEFT ANTI JOIN g USING (RealCID)) AS spurious_rows,
  (SELECT COUNT(*) FROM g LEFT ANTI JOIN m USING (RealCID)) AS gold_only_rows,
  (SELECT COUNT(*) FROM m JOIN g USING (RealCID)
     WHERE m.CountryID <=> g.CountryID AND m.LabelID <=> g.LabelID
       AND m.AccountTypeID <=> g.AccountTypeID AND m.RegulationID <=> g.RegulationID
       AND m.PlayerLevelID <=> g.PlayerLevelID AND m.PlayerStatusID <=> g.PlayerStatusID
       AND m.IsValidCustomer <=> g.IsValidCustomer) AS shared_value_match_rows
