# Review Sidecar: DWH_dbo.Dim_Customer

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 (Upstream Wiki) | 84 | Columns with descriptions inherited from Customer.CustomerStatic upstream wiki (quality 9.7/10) |
| Tier 2 (SP Code) | 15 | Columns described from ETL SP logic (computed, enriched, renamed) |
| Tier 3 (DDL/Inference) | 8 | Columns described from DDL type and naming patterns |
| Tier 4 (Unverified) | 0 | — |

## Items Requiring Human Review

### 1. RegisteredDemo Source
- **Issue**: The DDL has `RegisteredDemo` (datetime, NULL) but neither `SP_Dim_Customer_DL_To_Synapse` nor `SP_Dim_Customer` populates this column. It does not appear in the INSERT column list.
- **Question**: Is RegisteredDemo populated by a different ETL process, or is it always NULL in the current implementation?

### 2. NumOfGurus / NumOfCopiers / NumOfRAF Source
- **Issue**: These three columns appear in the DDL but are not referenced in either ETL stored procedure for loading or updating. They are not in the INSERT column list or any UPDATE statement.
- **Question**: Are these columns populated by a separate process (e.g., a social trading aggregation ETL), or are they legacy columns that are no longer populated?

### 3. WorldCheckID and WorldCheckResultsUpdated
- **Issue**: The `Ext_Dim_Customer_WorldCheck` staging load is fully commented out in `SP_Dim_Customer_DL_To_Synapse`, and the UPDATE from WorldCheck in `SP_Dim_Customer` is also commented out. These columns are only preserved via `#CustomerInitalIndicaton` (carrying forward the old value).
- **Question**: Are these columns frozen at their last populated value? Is there a new source for screening data that replaces WorldCheck (possibly ScreeningStatusID from ScreeningService)?

### 4. RiskClassificationID DEFAULT=200
- **Issue**: While most FK-type columns use DEFAULT=0, `RiskClassificationID` uses `ISNULL(RiskClassificationID, 200)` in the SP. This was changed per changelog entry "2023-04-03 Nir H - replace isnull on column RiskClassificationID from 0 to 200."
- **Question**: What does RiskClassificationID=200 represent? Is this a valid dimension value in the risk classification lookup?

### 5. Specific CID Exceptions in IsCreditReportValidCB
- **Issue**: The computation includes hardcoded CID exceptions: `CountryID = 250 AND cc.CID NOT IN (3400616,10526243,10842855,11464063,21547142,34537826)`. These specific CIDs are excluded from the CountryID=250 filter.
- **Question**: What is special about these 6 CIDs? This hardcoded list could become stale. Is there a business process to maintain it?

### 6. DocsOK and Bankruptcy
- **Issue**: These columns appear in the DDL but are not in the ETL INSERT or UPDATE lists. Their source is unclear.
- **Question**: Are these populated by a different process or are they legacy columns?

### 7. Synapse MCP Unavailable
- **Issue**: Phases 2 (Live Data Sampling) and 3 (Distribution Analysis) were skipped.
- **Impact**: No live row counts, NULL rate statistics, or value distributions for DWH columns. Production statistics cited are from the upstream Customer.CustomerStatic wiki (18.7M rows in production, but DWH Dim_Customer row count not confirmed).

### 8. SalesForceAccountID Double-Write
- **Issue**: SalesForceAccountID is loaded in two places: (1) in the BOCustomer staging from `SalesForce_DB_Prod_dbo_IdMapTopology` via JOIN, and (2) as a post-load UPDATE from `Ext_Dim_Customer_SF_ID`. The `#CustomerInitalIndicaton` also preserves the old value.
- **Question**: Is this intentional redundancy, or a migration artifact from changing the source?
