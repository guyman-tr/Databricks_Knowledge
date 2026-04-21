-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Position
-- UC Target: main.dwh.dim_position
-- =============================================================================

ALTER TABLE main.dwh.dim_position ALTER COLUMN IsPartialCloseChild COMMENT '1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse)';
