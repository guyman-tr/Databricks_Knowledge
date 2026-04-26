---
table: BI_DB_dbo.BI_DB_VerificationStatus
schema: BI_DB_dbo
type: lineage
generated_by: batch-37
---

# Lineage: BI_DB_VerificationStatus

## ETL Writer

| Property | Value |
|----------|-------|
| Stored Procedure | `BI_DB_dbo.SP_VerificationStatus` |
| Input Parameters | None (uses GETDATE() internally) |
| ETL Pattern | TRUNCATE TABLE + INSERT (full daily refresh, no incremental) |
| OpsDB Priority | 20 (third wave — depends on P0 and P15 outputs) |
| Schedule | Daily · ProcessType=SQL · SB_Daily |

## Population Window

The table covers a **rolling 6-month FTD cohort** — customers whose first deposit falls within:

```sql
@ftd_sd = DATEFROMPARTS(YEAR, MONTH, 1) of 6 months ago   -- start of month 6 months before today
@ftd_ed = DATEADD(DAY, -15, GETDATE())                    -- 15 days before today
```

Customers with `FirstDepositDate >= @ftd_sd AND FirstDepositDate < @ftd_ed AND IsValidCustomer=1` are included. The 15-day lag ensures that customer data (deposits, cashouts, verification events) has time to settle in the DWH before appearing in this table.

Observed window as of 2026-04-22: 2025-10-01 to ~2026-04-07. Row count: ~223,915.

## Production Source Mapping

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| RealCID | `DWH_dbo.Dim_Customer` | RealCID | Direct passthrough |
| FirstDepositDate | `DWH_dbo.Dim_Customer` | FirstDepositDate | Direct passthrough |
| AffiliateID | `DWH_dbo.Dim_Customer` | AffiliateID | Direct passthrough |
| SubChannel | `DWH_dbo.Dim_Channel` (via Dim_Affiliate) | SubChannel | Passthrough via JOIN Dim_Affiliate.SubChannelID = Dim_Channel.SubChannelID |
| Channel | `DWH_dbo.Dim_Channel` (via Dim_Affiliate) | Channel | Passthrough |
| Country | `DWH_dbo.Dim_Country` | Name | Passthrough — aliased as `Country` |
| Region | `DWH_dbo.Dim_Country` | Region | Passthrough — marketing region label |
| Verified | `DWH_dbo.Fact_SnapshotCustomer` | VerificationLevelID | `MAX(CASE WHEN VerificationLevelID=3 THEN 1 ELSE 0 END)` — 1 if ever fully verified |
| VerificationDate | `DWH_dbo.Fact_SnapshotCustomer` + `Dim_Date` | VerificationLevelID, FullDate | `MIN(FullDate WHERE VerificationLevelID=3)` — first date of full verification |
| PVDate | `DWH_dbo.Fact_SnapshotCustomer` + `Dim_Date` | PlayerStatusID, FullDate | `MIN(FullDate WHERE PlayerStatusID=13)` — first date of "Pending Verification" status |
| DidCO | `DWH_dbo.Fact_CustomerAction` | Amount WHERE ActionTypeID=8 | `MAX(CASE WHEN Amount != 0 THEN 1 ELSE 0 END)` — 1 if any non-zero cashout |
| CO | `DWH_dbo.Fact_CustomerAction` | Amount WHERE ActionTypeID=8 | `ISNULL(SUM(Amount), 0)` — total cashout amount |
| First14DaysDeposit | `DWH_dbo.Fact_CustomerAction` | Amount WHERE ActionTypeID=7 | `SUM(Amount WHERE DATEDIFF(DAY, FirstDepositDate, Occurred) <= 14)` |
| IsAddressProof | `DWH_dbo.Dim_Customer` | IsAddressProof | Passthrough (via #uploaded with same date window) |
| IsIDProof | `DWH_dbo.Dim_Customer` | IsIDProof | Passthrough (via #uploaded) |
| UpdateDate | — | — | `GETDATE()` |
| PendingClosureStatusID | `DWH_dbo.Dim_Customer` | PendingClosureStatusID | Passthrough |
| PlayerStatusReasonID | `DWH_dbo.Dim_Customer` | PlayerStatusReasonID | Passthrough |
| PlayerStatusID | `DWH_dbo.Dim_Customer` | PlayerStatusID | Passthrough |

## ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1, FTD in rolling 6-month window)
  + Dim_Affiliate → Dim_Channel (SubChannel, Channel)
  + Dim_Country (Country=Name, Region)
  → #pop (base population)

Fact_SnapshotCustomer + Dim_Range + Dim_Date
  (WHERE customer in #pop)
  → Verified = MAX(VerificationLevelID=3)
  → VerificationDate = MIN(date when VerificationLevelID=3)
  → PVDate = MIN(date when PlayerStatusID=13)
  → #data

Fact_CustomerAction (ActionTypeID IN 7, 8, DateID >= @ftd_sdID)
  → #fca

#fca (ActionTypeID=8)
  → DidCO = MAX(Amount != 0)
  → CO = SUM(Amount)
  → #co

#fca (ActionTypeID=7, DATEDIFF(Day, FTD, Occurred) <= 14)
  → First14DaysDeposit = SUM(Amount)
  → #t

Dim_Customer (IsIDProof, IsAddressProof)
  → #uploaded

TRUNCATE + INSERT → BI_DB_VerificationStatus
  (SELECT DISTINCT — deduplication applied)
```

## Notes

- The `SELECT DISTINCT` in the final INSERT deduplicates, which can mask duplicate source rows from the multi-JOIN structure (especially the LEFT JOIN to #fca which is not aggregated before the final join).
- IsAddressProof / IsIDProof can be NULL for customers very close to the 15-day cutoff date, due to a slight difference between the #uploaded window and the main population window.
