# BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions — Column Lineage

> Source-to-target column mapping from `SP_DDR_Fact_Non_Revenue_Generating_Actions`.

## Sources

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Fact_CustomerAction | Table (DWH) | Primary — customer action events |
| DWH_dbo.Dim_ActionType | Table (DWH) | Action type name lookup |
| DWH_dbo.Dim_CompensationReason | Table (DWH) | Compensation reason name lookup |
| DWH_dbo.Dim_Position | Table (DWH) | Position → MirrorID for IsCopyFund |
| DWH_dbo.Dim_Mirror | Table (DWH) | Mirror detection (MirrorTypeID = 4) |
| DWH_dbo.Fact_SnapshotCustomer | Table (DWH) | IsDepositor flag (for login classification) |
| DWH_dbo.Dim_Range | Table (DWH) | Date range lookup for depositor status |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | SP parameter | @dateID | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | ETL-computed |
| Date | SP parameter | @date | passthrough | |
| RealCID | Fact_CustomerAction | RealCID | passthrough | |
| ActionType | Fact_CustomerAction | ActionTypeID + CompensationReasonID | CASE mapping → business string | 20+ action type classifications (see wiki §2.1) |
| Amount | Fact_CustomerAction | Amount | SUM with sign flip | Positive for close/out, negative for open/in; 0 for logins/registrations |
| CountActions | Fact_CustomerAction | COUNT(RealCID) | SUM(COUNT) | Count of individual actions per group |
| UpdateDate | SP | GETDATE() | ETL-computed | Load timestamp |
| IsCopyFund | Dim_Position + Dim_Mirror | MirrorID | CASE WHEN COALESCE(dm.MirrorID, dm1.MirrorID) IS NOT NULL THEN 1 ELSE 0 | MirrorTypeID = 4 (copy fund) |
