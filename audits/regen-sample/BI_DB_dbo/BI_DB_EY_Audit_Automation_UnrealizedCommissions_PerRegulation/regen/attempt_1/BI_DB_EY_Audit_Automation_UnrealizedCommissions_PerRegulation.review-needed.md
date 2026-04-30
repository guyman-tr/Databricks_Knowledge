# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation

## Items for Human Review

### 1. InstrumentType Origin (Tier 2)
- **Column**: `InstrumentType`
- **Issue**: The column passes through from `BI_DB_EY_Audit_Opened_Positions`, which is populated by `SP_EY_Audit_Opened_Positions`. The upstream SP code for `SP_EY_Audit_Opened_Positions` was not included in the bundle, so the ultimate production source of InstrumentType could not be traced. It likely derives from `Dim_Instrument.InstrumentType` or a similar classification, but this needs confirmation.
- **Action**: Read `SP_EY_Audit_Opened_Positions` source code to trace InstrumentType origin. If it is a passthrough from Dim_Instrument, upgrade to Tier 1.

### 2. UC Target Not Confirmed
- **Issue**: No entry found in generic pipeline mapping for this table. It may be an internal audit table not exported to Databricks.
- **Action**: Confirm whether this table has a UC target or is Synapse-only.

### 3. No Atlassian Context
- **Issue**: Phase 10 (Jira/Confluence search) was skipped because Atlassian MCP was not available in this regen harness run.
- **Action**: Search Jira for EY audit automation tickets to enrich business context and confirm refresh schedule.

### 4. Unresolved Upstream Tables
- **Issue**: Several intermediate audit tables referenced by the SP (`BI_DB_EY_Audit_Opened_Positions`, `EY_Audit_Automation_LastOpRate`, `EY_Audit_Automation_Opened_Positions_End_2022_Baseline`, `EY_Audit_Automation_Position_Open_Configs`) have no wiki documentation.
- **Action**: Document these tables to complete the audit automation lineage chain.

### 5. PnL Calculation Complexity
- **Issue**: The PnL formula in the SP branches on PnLVersion (1 vs other), IsBuy, SellCurrencyID, and BuyCurrencyID with different USD conversion rate handling. The wiki documents this at a high level but the full formula is ~60 lines of CASE logic. Domain expert review recommended to confirm the business logic section accurately represents current audit methodology.
- **Action**: Have the SP author (Guy Manova) validate the business logic description.
