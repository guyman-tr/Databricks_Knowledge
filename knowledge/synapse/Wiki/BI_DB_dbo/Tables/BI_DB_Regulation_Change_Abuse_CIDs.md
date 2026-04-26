# BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs

> MERGE-maintained register of 15,956 "regulation abuse" suspects — customers who have changed their regulatory jurisdiction 6 or more times — with a chronological pivot of up to 15 regulation change events (RC1-RC15), current trading metrics, and demographic attributes.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (LAG change detection) + Dim_Customer + Dim_Position + DWH_dbo.V_Liabilities |
| **Refresh** | Daily — SP_Regulation_Change_Abuse @Date; MERGE (UPDATE/INSERT/DELETE — co-authored with BI_DB_Regulation_Change_Abuse_Categories) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_Regulation_Change_Abuse_CIDs` is a rolling register of customers suspected of **regulation abuse** — the practice of deliberately switching regulatory jurisdictions (e.g., CySEC → BVI → CySEC) to exploit differences in trading conditions, leverage limits, or compliance requirements between regulated entities.

The **abuse threshold is 6 regulation changes**. Customers with ≥6 changes from `Fact_SnapshotCustomer` LAG detection are included; those falling below this threshold are deleted via the MERGE DELETE clause. The table holds 15,956 abusers as of 2026-04-13 (single UpdateDate — daily snapshot behavior via MERGE).

Each row provides: the complete demographic profile (current regulation, country, etc.), position statistics (open/closed count, most recent position date), current financial exposure (RealizedEquity, UnRealizedEquity, TotalPositionsAmount), and a chronological pivot of up to 15 regulation changes (RC1 = first change, RC2 = second, etc.).

**Distribution of total changes**: 81% of abusers have exactly 6 changes (the minimum threshold). The distribution drops steeply: 6 changes (12,941), 7 (2,175), 8 (611), 9 (151), 10 (49), 11–16 (26), 21 (1), 28 (1), 46 (1). The extreme outlier (46 changes) warrants manual review.

A common RC pattern observed in live data: `CySEC → BVI → CySEC → BVI → CySEC → FCA` — customers cycling between the less-restrictive BVI regulation and CySEC.

---

## 2. Business Logic

### 2.1 Abuse Threshold (≥6 Regulation Changes)

**What**: Only customers with at least 6 detected regulation changes are included in this table.
**Columns Involved**: `Total_RegChangeCount`, all columns
**Rules**:
- `WHERE Total_RegChangeCount >= 6` applied to #maxchanges (max RegChangeRowNum per CID)
- A regulation change is detected as: `LAG(RegulationID,1,0) OVER(PARTITION BY RealCID ORDER BY UpdateDate) <> RegulationID` in Fact_SnapshotCustomer
- The threshold of 6 is hardcoded in the SP (not configurable via parameter)

### 2.2 RC1–RC15: Chronological Regulation Pivot

**What**: The 15 RC columns record the regulation name for each change event in the order they occurred.
**Columns Involved**: RC1 through RC15
**Rules**:
- RC1 = regulation name of the 1st detected change (earliest)
- RC2 = regulation name of the 2nd detected change, etc.
- RC15 = 15th change (most customers have NULL from RC7 onward; max observed is 46 but only first 15 are captured)
- Each RC contains the Dim_Regulation.Name (descriptive label, e.g., 'CySEC', 'BVI', 'FCA')
- RC columns beyond Total_RegChangeCount are NULL (e.g., if Total_RegChangeCount=6, RC7-RC15 are all NULL)
- NOTE: RC columns capture the regulation MOVED TO on each change event, not the regulation left behind

```
Example (CID with 6 changes):
  RC1='BVI', RC2='CySEC', RC3='BVI', RC4='CySEC', RC5='BVI', RC6='FCA'
  RC7–RC15 = NULL
  Total_RegChangeCount = 6
```

### 2.3 MERGE Upsert Pattern (No Truncate)

**What**: Unlike most BI_DB tables, this table is maintained via MERGE — not TRUNCATE + INSERT.
**Columns Involved**: All
**Rules**:
- `WHEN MATCHED THEN UPDATE`: existing abusers have all columns refreshed daily
- `WHEN NOT MATCHED BY TARGET THEN INSERT`: new abusers (who just reached 6 changes) are added
- `WHEN NOT MATCHED BY SOURCE THEN DELETE`: ex-abusers (change count dropped below 6, or customer no longer in population) are removed
- Historical abuser records are overwritten, not preserved — no audit trail of when a CID was first flagged

### 2.4 Position Statistics (Dim_Position)

**What**: Three columns summarize the customer's full position history across all instruments.
**Columns Involved**: `OpenPositionsCount`, `ClosedPositionsCount`, `MostRecentOpenPosition`
**Rules**:
- Sourced from `DWH_dbo.Dim_Position` — all positions ever (no date filter beyond the join)
- `CloseDateID=0` → position is still open
- `CloseDateID<>0` → position has been closed
- Excludes partial close child positions (`IsPartialCloseChild=0`)
- `MostRecentOpenPosition = MAX(CAST(OpenOccurred AS DATE))` — the date of the most recently opened position, regardless of whether it is currently open or closed

### 2.5 Financial Exposure (V_Liabilities)

**What**: Three columns capture the customer's current financial position as of the SP's run date (@DateID).
**Columns Involved**: `RealizedEquity`, `UnRealizedEquity`, `TotalPositionsAmount`
**Rules**:
- Sourced from `DWH_dbo.V_Liabilities WHERE DateID=@DateID` — point-in-time snapshot
- `RealizedEquity` = `ISNULL(V_Liabilities.RealizedEquity, 0)` — net P&L from all closed positions
- `UnRealizedEquity` = `ISNULL(ActualNWA,0) + ISNULL(Liabilities,0)` — open position unrealized value plus outstanding leverage obligations
- `TotalPositionsAmount` = `ISNULL(TotalPositionsAmount, 0)` — total amount currently invested
- Customers not in V_Liabilities on @DateID get 0 for all three (ISNULL handling). Old/inactive abusers typically show 0.

---

## 3. Query Advisory

### 3.1 Distribution & Index

HASH(CID) with CLUSTERED INDEX(CID ASC). Point-lookups by CID are fast. At 15,956 rows this is a small table — full scans are negligible. Always use `WHERE CID = X` for individual lookups.

### 3.2 RC Columns as a Regulation Timeline

To reconstruct a customer's regulation history:
```sql
SELECT CID, Total_RegChangeCount, RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8
FROM [BI_DB_dbo].[BI_DB_Regulation_Change_Abuse_CIDs]
WHERE CID = X
```
The sequence RC1→RC2→... reads left-to-right chronologically. To find "how many times this customer was in CySEC", count NULLs vs. 'CySEC' across the RC1-RC15 columns.

### 3.3 Current Demographics vs. Historical

Like the sibling Categories table, `Regulation`, `Country`, `AccountType`, etc. reflect the customer's **current** state, not the regulation they were in when they made changes. A customer currently in FCA who cycled between CySEC and BVI will appear under FCA.

### 3.4 Position Counts Include All-Time History

`OpenPositionsCount` and `ClosedPositionsCount` cover the customer's **entire trading history** in Dim_Position — not just positions opened while they were regulation-switching. These metrics show whether the abuser is an active trader or dormant.

### 3.5 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top abusers by change count | `ORDER BY Total_RegChangeCount DESC` |
| CySEC→BVI cycling pattern | `WHERE RC1='BVI' AND RC2='CySEC' OR RC1='CySEC' AND RC2='BVI'` |
| Abusers still actively trading | `WHERE OpenPositionsCount > 0` or `WHERE MostRecentOpenPosition >= DATEADD(month,-3, GETDATE())` |
| New abusers added recently | Join to yesterday's snapshot (not available — MERGE deletes history) |
| Total exposure from abusers | `SUM(TotalPositionsAmount)` — overall financial risk from this population |

---

## 4. Elements

| # | Column | Type | Nullable | Confidence | Tier | Description |
|---|--------|------|----------|------------|------|-------------|
| 1 | CID | int | YES | CODE-BACKED | T1 | eToro production customer ID. MERGE primary key. Minimum 6 regulation changes to appear here. |
| 2 | Total_RegChangeCount | int | YES | CODE-BACKED | T2 | Total number of regulation changes detected from Fact_SnapshotCustomer LAG analysis. Always ≥6. Distribution: 81% have exactly 6 (threshold boundary), max observed 46. |
| 3 | FTDDate | date | YES | CODE-BACKED | T1 | First Time Deposit date. From Dim_Customer.FirstDepositDate. |
| 4 | FTDMonthYear | varchar(50) | YES | CODE-BACKED | T2 | FTD cohort month as text (e.g., 'Jan-2024'). |
| 5 | Regulation | varchar(50) | YES | CODE-BACKED | T1 | Current regulatory jurisdiction name. From Dim_Regulation. Reflects regulation at run time, not at time of change. |
| 6 | Country | varchar(50) | YES | CODE-BACKED | T1 | Customer country name. From Dim_Country. |
| 7 | Region | varchar(50) | YES | CODE-BACKED | T1 | Marketing region label. From Dim_Country. |
| 8 | AccountType | varchar(50) | YES | CODE-BACKED | T1 | Account type name. From Dim_AccountType. |
| 9 | PlayerLevel | varchar(50) | YES | CODE-BACKED | T1 | eToro Club tier. From Dim_PlayerLevel. |
| 10 | PlayerStatus | varchar(50) | YES | CODE-BACKED | T1 | Customer account status. From Dim_PlayerStatus. |
| 11 | OpenPositionsCount | int | YES | CODE-BACKED | T2 | Count of currently open positions (all-time, CloseDateID=0). Excludes partial close children. |
| 12 | ClosedPositionsCount | int | YES | CODE-BACKED | T2 | Count of all-time closed positions (CloseDateID≠0). Excludes partial close children. |
| 13 | MostRecentOpenPosition | date | YES | CODE-BACKED | T2 | Date of most recently opened position (open or closed). Proxy for last trading activity. |
| 14 | RealizedEquity | money | YES | CODE-BACKED | T2 | Net realized P&L from closed positions (ISNULL=0 if not in V_Liabilities). |
| 15 | UnRealizedEquity | decimal(23,4) | YES | CODE-BACKED | T2 | Current unrealized position value: ActualNWA + Liabilities from V_Liabilities (ISNULL=0). |
| 16 | TotalPositionsAmount | money | YES | CODE-BACKED | T2 | Total amount currently invested across all positions (ISNULL=0). |
| 17 | RC1 | varchar(50) | YES | CODE-BACKED | T2 | 1st regulation change in chronological order — regulation name moved TO on first change. |
| 18 | RC2 | varchar(50) | YES | CODE-BACKED | T2 | 2nd regulation change. NULL if Total_RegChangeCount < 2. |
| 19 | RC3 | varchar(50) | YES | CODE-BACKED | T2 | 3rd regulation change. NULL if Total_RegChangeCount < 3. |
| 20 | RC4 | varchar(50) | YES | CODE-BACKED | T2 | 4th regulation change. NULL if Total_RegChangeCount < 4. |
| 21 | RC5 | varchar(50) | YES | CODE-BACKED | T2 | 5th regulation change. NULL if Total_RegChangeCount < 5. |
| 22 | RC6 | varchar(50) | YES | CODE-BACKED | T2 | 6th regulation change. All abusers have RC6 populated (minimum threshold = 6). |
| 23 | RC7 | varchar(50) | YES | CODE-BACKED | T2 | 7th regulation change. NULL for 81% of abusers (those with exactly 6 changes). |
| 24 | RC8 | varchar(50) | YES | CODE-BACKED | T2 | 8th regulation change. NULL if Total_RegChangeCount < 8. |
| 25 | RC9 | varchar(50) | YES | CODE-BACKED | T2 | 9th regulation change. Populated for ~229 customers. |
| 26 | RC10 | varchar(50) | YES | CODE-BACKED | T2 | 10th regulation change. Populated for ~78 customers. |
| 27 | RC11 | varchar(50) | YES | CODE-BACKED | T2 | 11th regulation change. Populated for ~29 customers. |
| 28 | RC12 | varchar(50) | YES | CODE-BACKED | T2 | 12th regulation change. Populated for ~13 customers. |
| 29 | RC13 | varchar(50) | YES | CODE-BACKED | T2 | 13th regulation change. Populated for ~7 customers. |
| 30 | RC14 | varchar(50) | YES | CODE-BACKED | T2 | 14th regulation change. Populated for ~4 customers. |
| 31 | RC15 | varchar(50) | YES | CODE-BACKED | T2 | 15th regulation change. Customers with >15 changes have their 16th+ changes invisible here. |
| 32 | UpdateDate | datetime | YES | CODE-BACKED | T2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Lineage

See `BI_DB_Regulation_Change_Abuse_CIDs.lineage.md` for full source chain.

### ETL Pipeline Summary

```
DWH_dbo.Fact_SnapshotCustomer → LAG change detection → #regulation02
  └── MAX(RegChangeRowNum) >= 6 → #abuserpop (15,956 abusers)

#abuserpop + #regulation02 → CASE PIVOT (RC1-RC15) → #abuser01
#abuserpop + Dim_Position → position counts → #abuser02
#abuserpop + V_Liabilities → financial exposure → #abuser03
#abuserpop + Dim_Customer/dims → demographics → #ftdpop

  └── #finalcid = JOIN of all above

  └── SP_Regulation_Change_Abuse (@Date) — MERGE
        v
BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs (15,956 rows, HASH(CID))
```

---

## 6. Relationships

### Produced By
| SP | Schedule | Priority | Pattern |
|----|----------|----------|---------|
| SP_Regulation_Change_Abuse | Daily | P20 (third wave) | MERGE (UPDATE existing, INSERT new abusers, DELETE ex-abusers — co-written with BI_DB_Regulation_Change_Abuse_Categories) |

### Co-authored With
- `BI_DB_Regulation_Change_Abuse_Categories` — demographic distribution (all depositors). Always consistent with this table since both are populated in the same SP run.

---

## 7. Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Verbatim from upstream wiki (DWH_dbo Dim* docs) |
| T2 | ETL-computed — traced to SP code |

---

*Documented 2026-04-22 — Batch 33 | SP: SP_Regulation_Change_Abuse | Quality target: 8.5+*
