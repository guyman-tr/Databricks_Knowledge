# DWH_dbo.Dim_CompensationReason

> Hierarchical catalog of reasons for customer compensation (credit adjustments) — organized by department (Accounting/Ops, R&D, Marketing, Custom). Used with BackOffice compensation workflows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CompensationReasonID (int, CLUSTERED INDEX) |
| **Row Count** | ~30+ rows (with N/A placeholder) |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CompensationReasonID ASC |

---

## 1. Business Meaning

`Dim_CompensationReason` classifies why a financial compensation (credit adjustment) was issued to a customer account. The table has a two-level hierarchy via `ParentID`:

**Root categories** (ParentID = NULL):
- Custom (1), Marketing (4), Accounting/Ops (9), R&D (10)

**Child reasons** (ParentID references a root):
- Position lost (2, under 23), Technical Problems (3, under R&D), Chargeback (6, under Accounting), Deposit Adjustment (7, under Accounting), etc.

**N/A Placeholder**: Row with `CompensationReasonID = 0` for fact rows with no compensation reason.

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.BackOffice.CompensationReason` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_BackOffice_CompensationReason` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) + N/A placeholder row |
| **Column Mapping** | 3 passthrough, 1 redundant copy (`DWHCompensationID`), 1 hardcoded (`StatusID = 1`), 2 ETL-generated |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CompensationReasonID | int | YES | Tier 2 | Reason identifier. 0 = N/A placeholder. |
| 2 | ParentID | int | YES | Tier 2 | Self-referential hierarchy — root categories have NULL, child reasons reference a root ID. |
| 3 | Name | varchar(100) | YES | Tier 2 | Reason description (e.g., "Technical Problems", "Chargeback", "Deposit Adjustment"). |
| 4 | DWHCompensationID | int | YES | Tier 2b | Redundant copy of CompensationReasonID. Always equal. Legacy DWH artifact. |
| 5 | StatusID | int | YES | Tier 2b | Hardcoded to `1` for all rows. |
| 6 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |
| 7 | InsertDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.6/10 | Confidence: 0 Tier 1, 5 Tier 2, 2 Tier 2b | Phases: 1,2,8,9b,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CompensationReason.sql*
