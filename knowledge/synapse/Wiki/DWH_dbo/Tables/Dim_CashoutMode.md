# DWH_dbo.Dim_CashoutMode

> Four-value lookup classifying withdrawal processing modes by automation level and priority: Manual, Auto Create, Mass Auto Create, and Instant Withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CashoutModeID (tinyint, CLUSTERED INDEX) |
| **Row Count** | 4 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CashoutModeID ASC |

---

## 1. Business Meaning

`Dim_CashoutMode` classifies how withdrawal requests are processed, ordered by automation level and priority weight:

| CashoutModeID | CashoutModeName | Weight | Description |
|---------------|-----------------|--------|-------------|
| 0 | Manual | 0 | Manually processed by operations staff |
| 1 | Auto Create | 10 | System-initiated automatic withdrawal |
| 2 | Mass Auto Create | 20 | Batch-processed automatic withdrawals |
| 3 | Instant Withdrawal | 30 | Real-time instant processing (highest priority) |

The `CashoutModeWeight` column provides a priority ordering — higher weight = higher automation/priority.

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CashoutMode` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CashoutMode` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 3 passthrough, 1 ETL-generated (`UpdateDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CashoutModeID | tinyint | YES | Tier 2 | Processing mode identifier: 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. |
| 2 | CashoutModeName | varchar(50) | YES | Tier 2 | Human-readable mode name. |
| 3 | CashoutModeWeight | int | YES | Tier 2 | Priority weight — higher values indicate higher automation/priority (0, 10, 20, 30). |
| 4 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10)*
*Confidence: 0 Tier 1, 4 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CashoutMode.sql*
