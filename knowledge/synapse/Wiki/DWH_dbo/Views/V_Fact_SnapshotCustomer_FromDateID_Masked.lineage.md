# Column Lineage: DWH_dbo.V_Fact_SnapshotCustomer_FromDateID_Masked

| Property | Value |
|----------|-------|
| **Synapse logical view** | `DWH_dbo.V_Fact_SnapshotCustomer_FromDateID` (`SELECT R.FromDateID, R.ToDateID, SC.* ...`) |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` |
| **Generated** | 2026-05-14 |

## Source Objects

| Object | Role |
|--------|------|
| `Fact_SnapshotCustomer` | All columns except explicit date boundaries originate here — **see canonical** `Fact_SnapshotCustomer.lineage.md` rather than duplicate 52 mappings |
| `Dim_Range` | Supplies decoded `FromDateID`, `ToDateID` |

## Fresh column lineage (non-inherited only)

| View Column | Source Table | Source Column | Transform |
|-------------|--------------|---------------|-----------|
| FromDateID | `DWH_dbo.Dim_Range` | `FromDateID` | JOIN `Fact_SnapshotCustomer.DateRangeID = Dim_Range.DateRangeID` |
| ToDateID | `DWH_dbo.Dim_Range` | `ToDateID` | Same predicate |
| etr_y | UC Gold ingestion | _(synthetic)_ | Partition tag |
| etr_ym | UC Gold ingestion | _(synthetic)_ | Partition tag |
| etr_ymd | UC Gold ingestion | _(synthetic)_ | Partition tag |

> **Inherited block** (`GCID` … `StocksLendingStatusID`): identical transforms to `Fact_SnapshotCustomer` — consult `Tables/Fact_SnapshotCustomer.lineage.md` passthrough/computed rows.
