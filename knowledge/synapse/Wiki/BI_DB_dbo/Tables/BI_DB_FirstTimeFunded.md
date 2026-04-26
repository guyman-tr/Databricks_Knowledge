# BI_DB_dbo.BI_DB_FirstTimeFunded

> 4.72M-row milestone reference table tracking the date each eToro customer first achieved "First Time Funded" status — defined as having completed all three qualifying events: KYC verification (VerificationLevelID=3), first deposit, and first trade. One row per RealCID; dates range from 2012-10-03 to 2025-02-17. Loaded daily by SP_FirstTimeFunded via full TRUNCATE+INSERT with deduplication (changed from incremental after SR-295058).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Position via SP_FirstTimeFunded |
| **Refresh** | Daily (SB_Daily); TRUNCATE+INSERT with ROW_NUMBER deduplication |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC, FirstTimeFundedDateID ASC) |
| **UC Target** | Not migrated — no Generic Pipeline mapping entry |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_FirstTimeFunded` is a milestone lookup table that stores the exact date each eToro customer achieved "First Time Funded" (FTF) status — a key business lifecycle metric. A customer qualifies as First Time Funded only when ALL THREE of the following have occurred (each determined by its earliest date):

1. **KYC Verification** — customer reached `VerificationLevelID = 3` in `Fact_SnapshotCustomer`
2. **First Deposit** — customer had `IsDepositor = 1` for the first time in `Fact_SnapshotCustomer`
3. **First Trade** — customer opened their first position (appears in `Dim_Position`)

The `FirstTimeFundedDateID` is set to the **maximum** (latest) of these three first-event dates — i.e., the day the final qualifying criterion was met. A customer missing any one of the three events will never appear in this table.

The table contains 4.72M rows (one per qualifying customer), with the earliest FTF date of 2012-10-03 covering the full history of the eToro platform. It is consumed by `SP_DDR` to populate the `FTFDate` field across all DDR reporting tables (BI_DB_DDR_CID_Level, BI_DB_DDR_Daily_Aggregated, etc.).

**Operational note**: The SP was originally incremental (new CIDs only), but after bug SR-295058 introduced ~1000 duplicate records that propagated to DDR, it was changed to full TRUNCATE+INSERT with deduplication using `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY RealCID)`.

---

## 2. Business Logic

### 2.1 First Time Funded Milestone Definition

**What**: A customer is "First Time Funded" when they have completed all three lifecycle events — verified, deposited, and traded.

**Columns Involved**: `RealCID`, `FirstTimeFundedDateID`, `FirstTimeFundedDate`

**Rules**:
- All three criteria must be met (non-null) — `HAVING COUNT(RealCID) = 3` in the CTE
- The FTF date is `MAX(first_deposit_date, first_trade_date, first_verified_date)` — the date the LAST criterion was met
- Once a customer qualifies, their FTF date is immutable (new CIDs only added per original design, now full reload)
- `FirstTimeFundedDate` is the calendar-date equivalent of `FirstTimeFundedDateID` (YYYYMMDD int)

### 2.2 Deduplication Protocol (Post SR-295058)

**What**: Full reload with ROW_NUMBER deduplication to prevent duplicate RealCID entries.

**Columns Involved**: `RealCID`

**Rules**:
- UNION ALL of `#ftf` (new qualifiers) + existing `BI_DB_FirstTimeFunded` rows
- `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY RealCID) = 1` keeps only first record per customer
- TRUNCATE + INSERT replaces the full table each run (sacrifices incremental performance for correctness)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN distribution**: Data is spread evenly across distributions. JOIN to this table from a HASH-distributed table (e.g., `BI_DB_DDR_CID_Level` on CID) will cause data movement. For performance, consider CID-to-RealCID equivalence when joining.
- **CLUSTERED INDEX on (RealCID, FirstTimeFundedDateID)**: Efficient for RealCID lookups. Range scans on FirstTimeFundedDateID within a RealCID are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| When did customer X first become funded? | `SELECT * FROM BI_DB_FirstTimeFunded WHERE RealCID = X` |
| How many FTF events happened in a given month? | `GROUP BY YEAR(FirstTimeFundedDate), MONTH(FirstTimeFundedDate)` |
| FTF funnel by cohort | JOIN to Dim_Customer on RealCID, group by FirstTimeFundedDate bucket |
| Count of all-time FTF customers | `SELECT COUNT(*) FROM BI_DB_FirstTimeFunded` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DDR_CID_Level | RealCID = CID | Get FTFDate for DDR CID-level metrics |
| DWH_dbo.Dim_Customer | RealCID = RealCID | Enrich with customer attributes |
| DWH_dbo.Dim_Date | FirstTimeFundedDateID = DateKey | Resolve to full date attributes |

### 3.4 Gotchas

- **RealCID ≠ CID in all tables**: In SP_DDR, this table is joined with `bdftf.RealCID = fd.RealCID`. Ensure you understand the CID/RealCID equivalence for your use case.
- **Not all customers appear**: Only 4.72M of ~14M+ registered accounts qualify — missing any one of {verified, deposited, traded} excludes a customer permanently.
- **FTF date is the LAST event date, not the first**: A customer who deposited in 2015 but only verified in 2019 gets FTFDate = 2019 (the day verification completed the trio).
- **ROUND_ROBIN join cost**: Joining from a large HASH table without broadcasting will cause data redistribution.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (canonical source) |
| Tier 2 | Derived from ETL SP code analysis (SP_FirstTimeFunded logic) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best-guess — limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstTimeFundedDateID | int | YES | YYYYMMDD integer representing the date the customer achieved First Time Funded status — the MAX of (first KYC verification date, first deposit date, first trade date). Computed by SP_FirstTimeFunded. FK to DWH_dbo.Dim_Date.DateKey. (Tier 2 — SP_FirstTimeFunded) |
| 3 | FirstTimeFundedDate | date | YES | Calendar-date equivalent of FirstTimeFundedDateID. CONVERT(date, CONVERT(varchar(10), MaxDate)). Human-readable FTF milestone date for reporting. (Tier 2 — SP_FirstTimeFunded) |
| 4 | UpdateDate | datetime | YES | GETDATE() timestamp captured at the time SP_FirstTimeFunded executed the TRUNCATE+INSERT. Indicates when the row was last refreshed. Not a business date. (Tier 2 — SP_FirstTimeFunded) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | GROUP BY passthrough |
| FirstTimeFundedDateID | DWH_dbo.Dim_Date (via Dim_Range) + Dim_Position | DateKey / OpenDateID | MAX of (MIN verified date, MIN deposit date, MIN trade date) — all three must be non-null |
| FirstTimeFundedDate | — | — | CONVERT(date, CONVERT(varchar(10), FirstTimeFundedDateID)) |
| UpdateDate | — | — | GETDATE() at SP execution time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (verification + deposit flags)
  + DWH_dbo.Dim_Range + DWH_dbo.Dim_Date
  → #firstVerified  (MIN DateKey WHERE VerificationLevelID=3 per RealCID)
  → #firstDeposited (MIN DateKey WHERE IsDepositor=1 per RealCID)

DWH_dbo.Dim_Position
  → #firstTraded    (MIN OpenDateID per CID)

UNION ALL → #all
  GROUP BY RealCID HAVING COUNT=3 → #ftf (new qualifiers only + dedup)
  UNION ALL existing BI_DB_FirstTimeFunded
  ROW_NUMBER dedup PARTITION BY RealCID

TRUNCATE + INSERT → BI_DB_dbo.BI_DB_FirstTimeFunded
  ↓
SP_DDR reads: JOIN bdftf.RealCID = fd.RealCID → FTFDate
  → BI_DB_DDR_CID_Level (FTFDate)
  → BI_DB_DDR_Daily_Aggregated (FTFDate)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer master dimension |
| FirstTimeFundedDateID | DWH_dbo.Dim_Date.DateKey | Date dimension lookup |

### 6.2 Referenced By (other objects point to this)

| Object | Reference Type | Description |
|--------|---------------|-------------|
| BI_DB_dbo.SP_DDR | Dependency — JOIN on RealCID | Provides FTFDate for DDR_CID_Level and DDR_Daily_Aggregated |
| BI_DB_dbo.BI_DB_DDR_CID_Level | Indirect (via SP_DDR) | FTFDate column |
| BI_DB_dbo.BI_DB_DDR_Daily_Aggregated | Indirect (via SP_DDR) | FTFDate column |

---

## 7. Sample Queries

### When did a specific customer first become funded?

```sql
SELECT RealCID, FirstTimeFundedDate, FirstTimeFundedDateID
FROM [BI_DB_dbo].[BI_DB_FirstTimeFunded]
WHERE RealCID = 123456
```

### Monthly FTF cohort counts (full history)

```sql
SELECT
    YEAR(FirstTimeFundedDate)  AS FTF_Year,
    MONTH(FirstTimeFundedDate) AS FTF_Month,
    COUNT(*)                   AS New_FTF_Customers
FROM [BI_DB_dbo].[BI_DB_FirstTimeFunded]
GROUP BY YEAR(FirstTimeFundedDate), MONTH(FirstTimeFundedDate)
ORDER BY FTF_Year, FTF_Month
```

### FTF customers who first funded in a date range

```sql
SELECT ftf.RealCID, ftf.FirstTimeFundedDate
FROM [BI_DB_dbo].[BI_DB_FirstTimeFunded] ftf
WHERE ftf.FirstTimeFundedDate BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY ftf.FirstTimeFundedDate
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources identified for this table during Phase 10. The SP header comment (Guy Manova, 2023-01-10) references SR-295058 as the deduplication fix ticket.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 1 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_FirstTimeFunded | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer + Dim_Position via SP_FirstTimeFunded*
