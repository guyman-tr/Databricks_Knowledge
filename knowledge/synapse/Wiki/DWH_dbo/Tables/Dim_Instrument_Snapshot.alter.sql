-- =============================================================================
-- ALTER Script: DWH_dbo.Dim_Instrument_Snapshot
-- UC Target:    Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
-- Resolution:   Wiki property table
-- Generated:    2026-03-22
-- Source Wiki:   knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument_Snapshot.md
-- Quality:      8.6/10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLE COMMENT
-- ---------------------------------------------------------------------------
ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Instrument_Snapshot` is a daily append table that captures the state of nine futures-relevant columns from `DWH_dbo.Dim_Instrument` as of each calendar date. Because futures instrument configuration (Multiplier, ProviderMarginPerLot, eToroMarginPerLot, SettlementTime) can be updated in production at any time, `Dim_Instrument` itself always reflects the current state only. The snapshot table bridges this gap: by recording the exact configuration values observed on each ETL run, it enables analysts to reconstruct what the futures parameters were on any historical date. The snapshot was introduced 2024-12-22 (by Inbal BML). As of 2026-03-10, it holds 5,311,079 rows across 444 daily snapshots. Each snapshot contains one row per instrument in `Dim_Instrument` at the time of the ETL run (~15,707 rows per day, growing over time as new instruments are added). The ETL is driven by `SP_Dim_Instrument_Snapshot`, which is called at the end of `SP_Dim_Instrument` (the master instrument ETL). It deletes the...'
);

-- ---------------------------------------------------------------------------
-- 2. TABLE TAGS
-- ---------------------------------------------------------------------------
ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
SET TAGS (
    'domain' = 'DWH',
    'object_type' = 'Table',
    'synapse_schema' = 'DWH_dbo',
    'synapse_object_name' = 'Dim_Instrument_Snapshot',
    'refresh_frequency' = 'Daily (Append -- new date partition added each day)',
    'source_system' = 'DWH_dbo.Dim_Instrument (daily snapshot; data originates from Trade.ProviderToInstrument + Trade.FuturesMetaData)',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX (DateID ASC, InstrumentID ASC)',
    'uc_format' = 'delta',
    'pipeline' = 'Generic Pipeline (daily export)',
    'semantic_grade' = '8.6',
    'semantic_wiki' = 'DWH_dbo/Tables/Dim_Instrument_Snapshot.md',
    'uc_partitioned_by' = 'None (Append strategy; partitioned logically by DateID)'
);

-- ---------------------------------------------------------------------------
-- 3. COLUMN COMMENTS
-- ---------------------------------------------------------------------------

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN DateID COMMENT 'Snapshot date in yyyymmdd integer format -- represents "yesterday" relative to the ETL run date. The daily snapshot for business date 20260310 is loaded by the ETL run on 2026-03-11. FK to DWH_dbo.Dim_Date (DateID). Part of the natural composite key (DateID + InstrumentID). (Tier 2 -- SP_Dim_Instrument_Snapshot)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN InstrumentID COMMENT 'Instrument identifier -- FK to DWH_dbo.Dim_Instrument(InstrumentID). Includes all instruments present in Dim_Instrument on the load date, including non-futures (IsFuture=0). Range: 0 (placeholder) to ~21M allocated IDs. (Tier 2 -- SP_Dim_Instrument_Snapshot)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN Multiplier COMMENT 'Futures contract size multiplier from Dim_Instrument.Multiplier. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments (IsFuture=0). Example values: 2.0 (InstrumentID=998), 100.0 (InstrumentID=999), 5.0 (InstrumentID=200000+). (Tier 3 -- live data)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN ProviderID COMMENT 'Liquidity provider ID from Dim_Instrument.ProviderID. Identifies which external market maker prices this instrument. NULL for ID=0 placeholder only. Most instruments have ProviderID=1. (Tier 3 -- live data)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN ProviderMarginPerLot COMMENT 'Provider''s initial margin requirement per lot from Dim_Instrument.ProviderMarginPerLot. NULL for non-futures instruments and for futures instruments without a FuturesInstrumentsInitialMarginByProviderMapping entry. Example range: 1,711 to 2,354 (in instrument currency units). (Tier 3 -- live data)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN eToroMarginPerLot COMMENT 'eToro''s internal margin per lot in asset currency from Dim_Instrument.eToroMarginPerLot. NULL for non-futures instruments. May differ from ProviderMarginPerLot due to eToro''s own risk parameters. Example range: 1,993 to 3,130. (Tier 3 -- live data)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN SettlementTime COMMENT 'Settlement datetime combining the snapshot date with the instrument''s TIME-valued settlement time from Dim_Instrument. Computed in SP: `CONVERT(DATETIME, yyyymmdd_string + '' '' + HH:MM:SS_string)`. The date portion = @dt (snapshot date); the time portion = actual settlement time. Example: 2026-03-10 22:00:00 means settlement was at 22:00 UTC on the snapshot date. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument_Snapshot)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN IsFuture COMMENT 'Flag indicating if the instrument is a futures contract: 1=futures (243 instruments as of 2026-03-10), 0=non-futures (15,463), NULL=placeholder (ID=0). Copied from Dim_Instrument.IsFuture. Meaningful futures analysis requires filtering WHERE IsFuture = 1. (Tier 3 -- live data)';

ALTER TABLE Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/ (uc_table not assigned)
ALTER COLUMN UpdateDate COMMENT 'ETL run timestamp -- GETDATE() at load time. Differs from DateID by ~1 day (e.g., UpdateDate 2026-03-11 02:08 for DateID 20260310). Use DateID for business date identification; UpdateDate reflects the actual load time. (Tier 2 -- SP_Dim_Instrument_Snapshot)';

-- ---------------------------------------------------------------------------
-- 4. COLUMN PII TAGS
-- ---------------------------------------------------------------------------
-- No PII-sensitive columns detected for this object.

-- =============================================================================
-- END OF ALTER SCRIPT
-- =============================================================================
