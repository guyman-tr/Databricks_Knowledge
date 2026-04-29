# BI_DB_dbo.BI_DB_PI_StatusPanel — Column Lineage

## Writer SP
`BI_DB_dbo.SP_PI_StatusPanel` — daily UPDATE existing + INSERT new

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | PI population (GuruStatusID!=0, last year), VL change detection via LAG() |
| DWH_dbo.Dim_Range | DWH_dbo | Date range validity |
| DWH_dbo.Dim_GuruStatus | DWH_dbo | GuruStatusName for upgrade/downgrade labels |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | rename |
| LastDowngradeID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | most recent downgrade target (GuruStatusID < PrevGuruStatusID, exclude ID=1) |
| LastDowngradeTo | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup for downgrade target |
| LastDowngradeFromID | DWH_dbo.Fact_SnapshotCustomer | PrevGuruStatusID | LAG() of GuruStatusID |
| LastDowngradeFrom | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup for downgrade source |
| LastDowngradeDate | DWH_dbo.Dim_Range | FromDateID | CONVERT to date |
| LastUpgradeID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | most recent upgrade target (GuruStatusID > PrevGuruStatusID, exclude ID=1) |
| LastUpgradeTo | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup for upgrade target |
| LastUpgradeFromID | DWH_dbo.Fact_SnapshotCustomer | PrevGuruStatusID | LAG() of GuruStatusID |
| LastUpgradeFrom | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup for upgrade source |
| LastUpgradeDate | DWH_dbo.Dim_Range | FromDateID | CONVERT to date |
| LastRemovedDate | DWH_dbo.Dim_Range | FromDateID | MAX date where GuruStatusID=0 AND downgrade |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
