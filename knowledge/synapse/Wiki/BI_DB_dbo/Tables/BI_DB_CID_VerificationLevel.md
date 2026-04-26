# BI_DB_dbo.BI_DB_CID_VerificationLevel

> Append-only first-achievement table recording the date each customer first reached each KYC verification level (1, 2, or 3). One row per customer per level achieved — up to 3 rows per customer. 54.2M rows, 24.6M distinct customers, data from 2011-06-07. Sourced from Fact_SnapshotCustomer SCD2 change dates via cross-join with Dim_VerificationLevel.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (VerificationLevelID) + DWH_dbo.Dim_VerificationLevel |
| **Refresh** | Daily — append-only via SP_CID_VerificationLevel (SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP + NONCLUSTERED INDEX on FromDateID ASC |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_VerificationLevel is a first-achievement tracking table that records the date each eToro customer first reached each of the three active KYC verification levels. It does NOT track the current level — for that, use `DWH_dbo.Fact_SnapshotCustomer.VerificationLevelID` or `DWH_dbo.Dim_Customer`. Instead, it answers: **"When did this customer first achieve Level 1/2/3 verification?"**

The verification levels are progressive KYC milestones that gate platform capabilities:

| VerificationLevelID | Meaning | Platform Access |
|--------------------|---------|----------------|
| 1 | Basic verification (email/questionnaire) | Limited trading access |
| 2 | Intermediate (POI submitted) | Moderate trading access |
| 3 | Full KYC (POI + POA confirmed) | Unrestricted access: unlimited withdrawals, all instruments, leveraged trading, real stocks |

Note: Level 0 (unverified) is **not stored** in this table (filtered out in the SP). Only levels 1, 2, and 3 are tracked.

**Coverage**: 54.2M rows across 24.6M distinct customers. Level 1: 24.6M customers have ever reached; Level 2: 19.6M; Level 3: 10.0M. Data from 2011-06-07 to present.

The table is primarily used by compliance, KYC analytics, and customer lifecycle teams to measure verification funnel conversion rates, time-to-verify, and verification completion trends.

---

## 2. Business Logic

### 2.1 First-Achievement Deduplication Pattern

**What**: Only the FIRST time a customer reaches each level is stored.

**Columns Involved**: RealCID, VerificationLevelID, FromDateID

**Rules**:
- The INSERT uses a LEFT JOIN anti-join: `LEFT JOIN BI_DB_CID_VerificationLevel WHERE RealCID = a.RealCID AND VerificationLevelID = a.VerificationLevelID ... WHERE b.RealCID IS NULL`.
- If a customer already has a Level 2 row in the table from a prior date, no new Level 2 row is inserted regardless of future runs.
- Result: each (RealCID, VerificationLevelID) pair appears AT MOST ONCE in the table.

### 2.2 Cross-Join Level Expansion

**What**: A customer at Level N gets rows for all levels 1 through N.

**Columns Involved**: VerificationLevelID

**Rules**:
- SP cross-joins customers with `Dim_VerificationLevel` and filters `VerificationLevelID >= v.ID AND v.ID NOT IN (-1, 0)`.
- Customer at Level 3 on their first day → rows for Level 1, 2, and 3 all with the same FromDateID.
- Customer progressing from Level 1 → Level 2 on separate dates → Level 1 row has older FromDateID; Level 2 row is inserted when the FSC row capturing the Level 2 change is processed.

### 2.3 FromDateID Semantics

**What**: FromDateID records the FSC snapshot change date, not a KYC event timestamp.

**Columns Involved**: FromDateID, FromDate

**Rules**:
- The SP processes only FSC rows with `Dim_Range.FromDateID = @dateID` — rows whose SCD2 record started on @date.
- A customer's Level 2 FromDateID = the date their Fact_SnapshotCustomer SCD2 record first showed VerificationLevelID >= 2, which typically coincides with the day KYC was approved but is derived from the DWH change-detection pipeline, not a direct KYC timestamp.
- If the SP missed a day (gap), those customers' level achievements are NOT captured for the missed day. They will be captured the next time a Fact_SnapshotCustomer change triggers a new row for them.
- This is an approximation — for exact KYC timestamps, use the production source (`BackOffice.VerificationHistory` or equivalent).

### 2.4 DELETE + Insert Pattern (Idempotent Per Day)

**What**: Daily runs are safe to replay.

**Columns Involved**: FromDateID

**Rules**:
- DELETE WHERE FromDateID = @dateID removes any rows from a prior run of this SP for @date.
- Then re-inserts (with the anti-join dedup). This makes the SP idempotent for each date.
- Historical rows (FromDateID < @dateID) are never touched.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN + HEAP with NCI on FromDateID. ROUND_ROBIN means CID-based JOINs require data movement. The NCI on FromDateID supports date-range queries efficiently. For CID lookups, expect broadcast or shuffle joins.

### 3.2 Multi-Row Per Customer

Each customer has up to 3 rows (one per level reached). Always specify which level when querying a single customer:

```sql
-- Get Level 3 first-achievement date for a customer
WHERE RealCID = 12345678 AND VerificationLevelID = 3
```

Or aggregate to get max level achieved:

```sql
SELECT RealCID, MAX(VerificationLevelID) AS MaxLevelAchieved, MIN(FromDate) AS FirstLevelDate
FROM [BI_DB_dbo].[BI_DB_CID_VerificationLevel]
GROUP BY RealCID
```

### 3.3 Level 0 Not Present

The table does not contain Level 0 (unverified customers). Customers with VerificationLevelID=0 in Fact_SnapshotCustomer have zero rows in this table. For Level 0 customers, use `Fact_SnapshotCustomer` directly.

### 3.4 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers reached Level 3? | COUNT(DISTINCT RealCID) WHERE VerificationLevelID=3 |
| Verification funnel counts | GROUP BY VerificationLevelID, COUNT(DISTINCT RealCID) |
| When did customer X get verified? | WHERE RealCID=X ORDER BY VerificationLevelID |
| Level 3 conversions by month | WHERE VerificationLevelID=3, GROUP BY YEAR(FromDate), MONTH(FromDate) |
| Time from Level 1 to Level 3 | Self-JOIN on RealCID, DATEDIFF on Level 1 and Level 3 FromDate |

### 3.5 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Customer attributes |
| DWH_dbo.Fact_SnapshotCustomer | ON RealCID = RealCID (current) | Current verification level |
| DWH_dbo.Dim_VerificationLevel | ON VerificationLevelID = ID | Level name/description |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (T1 - DWH_dbo.Dim_VerificationLevel wiki) |
| *** | Tier 2 - SP code / live data | (T2 - SP_CID_VerificationLevel) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer identifier. FK into DWH_dbo.Dim_Customer. Up to 3 rows per RealCID (one per level achieved). ROUND_ROBIN distributed — CID-based JOINs require data movement. (T2 - SP_CID_VerificationLevel) |
| 2 | VerificationLevelID | int | NO | KYC verification level achieved: 1=Basic (email/questionnaire), 2=Intermediate (POI submitted), 3=Full KYC (POI + POA confirmed, full platform access). Level 0 (unverified) is NOT stored. FK into DWH_dbo.Dim_VerificationLevel. (T1 - DWH_dbo.Dim_VerificationLevel wiki) |
| 3 | FromDateID | int | NO | Date integer (YYYYMMDD) of the Fact_SnapshotCustomer SCD2 row that first showed the customer at this VerificationLevelID or higher. Approximates the date the customer first achieved this KYC level. NCI key — efficient for date-range queries. (T2 - SP_CID_VerificationLevel) |
| 4 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_CID_VerificationLevel (GETDATE()). (T2 - SP_CID_VerificationLevel) |
| 5 | FromDate | date | YES | Date equivalent of FromDateID (CONVERT(DATE, CONVERT(CHAR(8), FromDateID))). Provided for convenience. (T2 - SP_CID_VerificationLevel) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Object | Notes |
|--------|---------------|-------|
| RealCID | DWH_dbo.Fact_SnapshotCustomer | Sourced via SCD2 rows starting on @date |
| VerificationLevelID | Computed | DWH_dbo.Dim_VerificationLevel.ID (1, 2, 3) cross-joined and filtered by customer's current level |
| FromDateID | DWH_dbo.Dim_Range | FromDateID of the FSC SCD2 row |

Full column-level mapping: see `BI_DB_CID_VerificationLevel.lineage.md`.

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (SCD2, VerificationLevelID)
  + DWH_dbo.Dim_VerificationLevel (level IDs 1, 2, 3)
  + DWH_dbo.Dim_Range (FromDateID = @dateID filter)
  -> SP_CID_VerificationLevel(@date)
     [cross-join expand levels, dedup against existing rows]
     [DELETE WHERE FromDateID = @dateID]
     [INSERT new first-achievement records]
  -> BI_DB_dbo.BI_DB_CID_VerificationLevel (append-only except today's date idempotency)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Object | Join Column | Purpose |
|--------|------------|---------|
| DWH_dbo.Fact_SnapshotCustomer | RealCID | Source of VerificationLevelID and customer population |
| DWH_dbo.Dim_VerificationLevel | ID = VerificationLevelID | Level name and KYC tier definition |

### 6.2 Referenced By (other objects point to this)

| Source Object | Use | Description |
|--------------|-----|-------------|
| KYC analytics / compliance reports | RealCID + VerificationLevelID + FromDate | Verification funnel analysis, time-to-verify |
| CRM targeting | RealCID | Segmentation by verification status |

---

## 7. Sample Queries

### 7.1 Verification funnel — count of customers by maximum level reached

```sql
SELECT VerificationLevelID,
       COUNT(DISTINCT RealCID) AS customers_reached
FROM   [BI_DB_dbo].[BI_DB_CID_VerificationLevel]
GROUP BY VerificationLevelID
ORDER BY VerificationLevelID;
```

### 7.2 First verification date per level for a specific customer

```sql
SELECT VerificationLevelID, FromDate AS first_achieved
FROM   [BI_DB_dbo].[BI_DB_CID_VerificationLevel]
WHERE  RealCID = 12345678
ORDER BY VerificationLevelID;
```

### 7.3 Monthly Level 3 (full KYC) new completions

```sql
SELECT YEAR(FromDate) AS yr,
       MONTH(FromDate) AS mo,
       COUNT(*) AS new_full_kyc
FROM   [BI_DB_dbo].[BI_DB_CID_VerificationLevel]
WHERE  VerificationLevelID = 3
GROUP BY YEAR(FromDate), MONTH(FromDate)
ORDER BY yr, mo;
```

### 7.4 Time from Level 1 to Level 3 (KYC completion speed)

```sql
SELECT l1.RealCID,
       DATEDIFF(DAY, l1.FromDate, l3.FromDate) AS days_l1_to_l3
FROM   [BI_DB_dbo].[BI_DB_CID_VerificationLevel] l1
JOIN   [BI_DB_dbo].[BI_DB_CID_VerificationLevel] l3
       ON l1.RealCID = l3.RealCID AND l3.VerificationLevelID = 3
WHERE  l1.VerificationLevelID = 1
   AND l3.FromDate >= l1.FromDate
ORDER BY days_l1_to_l3 DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. KYC verification level documentation may exist in Confluence DATA space under "KYC" or "Verification" pages.

---

*Generated: 2026-04-23 | Quality: 8.5/10 (****) | Phases: 11/14*
*Tiers: 1 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CID_VerificationLevel | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer + Dim_VerificationLevel*
