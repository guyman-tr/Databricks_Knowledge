# DWH_dbo.Dim_ClientWithdrawReason

> Lookup of self-reported reasons customers give when requesting a withdrawal — used in exit surveys and retention analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | ClientWithdrawReasonID (int, CLUSTERED INDEX) |
| **Row Count** | 7 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on ClientWithdrawReasonID ASC |

---

## 1. Business Meaning

`Dim_ClientWithdrawReason` captures the reason a customer selects when initiating a withdrawal. These are client-facing survey options, not operational reasons (see `Dim_CashoutReason` for operational classification).

| ID | Reason |
|----|--------|
| 1 | None of the reasons above |
| 2 | Withdrawing profits |
| 3 | Fulfill other financial commitments |
| 4 | I Have not achieved my trading goals |
| 5 | This platform is not for me |
| 6 | I Would like to close my account |
| 7 | Moving to a competitor |

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.ClientWithdrawReason` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_ClientWithdrawReason` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 1 passthrough, 1 renamed (`Name` → `ClientWithdrawReasonName`), 1 ETL-generated (`UpdateDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ClientWithdrawReasonID | int | YES | Tier 2 | Reason identifier (1–7). |
| 2 | ClientWithdrawReasonName | varchar(50) | YES | Tier 2 | Client-facing reason text. Renamed from source `Name`. |
| 3 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 3 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_ClientWithdrawReason.sql*
