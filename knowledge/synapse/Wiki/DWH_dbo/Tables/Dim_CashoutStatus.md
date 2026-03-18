# DWH_dbo.Dim_CashoutStatus

> Withdrawal lifecycle status lookup — tracks the state of cashout requests from initiation through processing to completion, reversal, or failure.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CashoutStatusID (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | 18 rows (0=N/A + 17 statuses) |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CashoutStatusID ASC |

---

## 1. Business Meaning

`Dim_CashoutStatus` tracks the lifecycle state of withdrawal requests. Each cashout transaction carries a CashoutStatusID indicating where it is in the processing pipeline.

**Status flow**:
```
Pending (1) → SentToBilling (11) → ReceivedByBilling (12) → InProcess (2)
  → SentToProvider (10) → PendingByProvider (9) → Payment Sent (6) → Processed (3)
  OR → Rejected (7) / RejectedByProvider (8) / Failed (13)
  OR → Canceled (4)
  OR → Partially Processed (5)
  OR → Reversed (16) / Partially Reversed (17)
  Also: Pending Review (14) → Under Review (15) → (resolution)
```

**N/A Placeholder**: Row with `CashoutStatusID = 0` is the DWH default for fact rows with no status.

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CashoutStatus` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CashoutStatus` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) + N/A placeholder row |
| **Column Mapping** | 2 passthrough, 1 redundant copy (`DWHCashoutStatusID`), 3 ETL-generated (`StatusID`, `UpdateDate`, `InsertDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CashoutStatusID | int | NO | Tier 2 | Status identifier. 0=N/A, 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, etc. |
| 2 | Name | varchar(50) | NO | Tier 2 | Status name (e.g., "Pending", "Processed", "Rejected", "Reversed"). |
| 3 | DWHCashoutStatusID | int | YES | Tier 2b | Redundant copy of CashoutStatusID — always equals CashoutStatusID. Legacy DWH artifact. |
| 4 | StatusID | int | YES | Tier 2b | Hardcoded to `1` for all rows. DWH-internal flag with no variation. |
| 5 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |
| 6 | InsertDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. Resets on each truncate-and-reload. |

---

## 4. Sample Data

| CashoutStatusID | Name |
|-----------------|------|
| 0 | N/A |
| 1 | Pending |
| 2 | InProcess |
| 3 | Processed |
| 4 | Canceled |
| 6 | Payment Sent |
| 7 | Rejected |
| 13 | Failed |
| 16 | Reversed |

---

*Generated: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10)*
*Confidence: 0 Tier 1, 4 Tier 2, 2 Tier 2b, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,9b,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CashoutStatus.sql*
