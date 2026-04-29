# BI_DB_dbo.BI_DB_AffiliateLifeCycle

> **DORMANT — 0 rows, no writer SP, fully orphaned.** 33-column monthly affiliate lifecycle segmentation table with cohort analysis, churn detection, activity state transitions, sleep/dormancy indicators, and revenue P&L metrics. Designed for sophisticated affiliate health monitoring — tracking how affiliates transition between activity segments month-over-month. ROUND_ROBIN with CLUSTERED INDEX on YearMonthID. No stored procedure in Synapse SSDT reads or writes this table.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** — no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (YearMonthID ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AffiliateLifeCycle` was designed as an **advanced affiliate health monitoring system** tracking monthly lifecycle state transitions. The table captures:

1. **Affiliate identity & contract**: AffiliateID, LoginName, Channel, SubChannel, ContractName/Type, Group
2. **Performance metrics**: Registrations, FTDs (funnel), TotalCost, RevShare, TotalRevenues, TotalNetRevenues
3. **Lifecycle segmentation**: Segment, SegmentFTDs, NewSegment, NewSegmentFTDs (current vs new classifications)
4. **Dormancy/Sleep indicators**: RegSleep (months since last reg), FTDSleep (months since last FTD)
5. **Activity state machine**: ActivitySegment, PreviousActivitySegment, TrafficActivity, PreviousTrafficActivity, IsChurn
6. **Contract status**: EndCont (end of contract), ToClose (marked for closure)

Each row would represent one affiliate's monthly snapshot with their current and previous activity states — enabling month-over-month transition analysis (e.g., "how many affiliates moved from Active to Sleeping?") and churn prediction.

The table is currently **empty (0 rows)** and has **zero references** in any stored procedure in the Synapse SSDT. Despite being the most sophisticated affiliate analytics table in the schema, it was never populated in Synapse.

---

## 2. Business Logic

### 2.1 Lifecycle State Machine (Inferred)

**What**: Affiliates transition between activity states each month.
**Columns Involved**: ActivitySegment, PreviousActivitySegment, IsChurn
**Rules**:
- ActivitySegment (varchar(9)): Likely values like Active, Sleeping, Churned, New
- PreviousActivitySegment: Last month's state — enables transition tracking
- IsChurn = 1 when affiliate moves to churned state (no activity for N months)

### 2.2 Traffic Activity Classification (Inferred)

**What**: Separate classification based on traffic volume.
**Columns Involved**: TrafficActivity, PreviousTrafficActivity
**Rules**:
- TrafficActivity (varchar(16)): Likely values like High, Medium, Low, Dormant, New
- Enables tracking of traffic degradation before formal churn

### 2.3 Sleep/Dormancy Indicators (Inferred)

**What**: Quantifies how long since last meaningful activity.
**Columns Involved**: RegSleep, FTDSleep
**Rules**:
- RegSleep = integer months since last registration attributed to this affiliate
- FTDSleep = integer months since last FTD from this affiliate's traffic
- Higher values = more dormant affiliate

### 2.4 Revenue P&L (Inferred)

**What**: Financial performance per affiliate per month.
**Columns Involved**: TotalCost, RevShare, TotalRevenues, TotalNetRevenues
**Rules**:
- TotalCost = marketing spend
- RevShare = revenue share commission paid to affiliate
- TotalRevenues = gross revenues from affiliate's customers
- TotalNetRevenues = TotalRevenues - TotalCost (or net after all costs)

### 2.5 Cohort Segmentation (Inferred)

**What**: Dual segmentation based on registrations and FTDs.
**Columns Involved**: Segment, SegmentFTDs, NewSegment, NewSegmentFTDs, CreationPeriod
**Rules**:
- Segment (varchar(15)): Registration volume segment (e.g., 0, 1-5, 6-20, 21-50, 50+)
- SegmentFTDs: FTD volume segment (same bucketing)
- NewSegment/NewSegmentFTDs: Updated segments for this month (detect transitions)
- CreationPeriod: Affiliate onboarding month (for cohort analysis)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on YearMonthID — optimized for monthly time-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Affiliate churn rate | Table is empty — check if lifecycle analysis moved to Databricks or external BI tool |
| Monthly state transitions | Table is empty — no alternative identified in Synapse |

### 3.3 Common JOINs

None active — table is fully orphaned.

### 3.4 Gotchas

- **Table is empty and fully orphaned**: 0 rows, no SP references
- **Most sophisticated affiliate table**: Despite being the richest affiliate analytics table, it was never populated
- **rn column**: Row number — likely a window function artifact from the ETL (dedup or sequencing)
- **All int financial columns**: TotalCost/RevShare/TotalRevenues are int — may have been stored as whole units (no decimals)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from column names, types, and affiliate lifecycle domain knowledge | Medium |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | YearMonthID | varchar(7) | YES | Monthly period key in 'YYYY-MM' format (e.g., '2023-08'). Primary time dimension for lifecycle snapshots. (Tier 4 — inferred from column name and type) |
| 2 | Period | varchar(7) | YES | Reporting period (same format as YearMonthID). May differ from YearMonthID for trailing-window calculations. (Tier 4 — inferred from column name) |
| 3 | CreationPeriod | varchar(7) | YES | Period when the affiliate was onboarded/created. Enables cohort analysis by affiliate vintage. (Tier 4 — inferred from column name) |
| 4 | Channel | nvarchar(50) | YES | Primary marketing channel the affiliate operates in (e.g., web, social, media buying). (Tier 4 — inferred from column name) |
| 5 | SubChannel | varchar(100) | YES | Sub-classification within the channel (e.g., Facebook under social, specific networks). (Tier 4 — inferred from column name) |
| 6 | ContractName | nvarchar(100) | YES | Name of the affiliate's commission contract arrangement. (Tier 4 — inferred from column name) |
| 7 | ContractTypeName | nvarchar(100) | YES | Contract type classification (e.g., CPA, Revenue Share, Hybrid, Tiered CPA). (Tier 4 — inferred from column name) |
| 8 | AffiliateID | int | YES | Affiliate partner identifier from the fiktivo system. (Tier 4 — inferred from column name) |
| 9 | Contact | nvarchar(255) | YES | Affiliate manager or account manager contact person. (Tier 4 — inferred from column name) |
| 10 | LoginName | nvarchar(255) | YES | Affiliate's login username in the partner portal. (Tier 4 — inferred from column name) |
| 11 | AffiliatesGroupsName | nvarchar(50) | YES | Affiliate group/tier classification (e.g., VIP, Standard, Premium). (Tier 4 — inferred from column name) |
| 12 | Registrations | int | NO | Number of customer registrations attributed to this affiliate in the period. (Tier 4 — inferred from column name) |
| 13 | FTDs | int | NO | Number of first-time deposits generated by this affiliate in the period. (Tier 4 — inferred from column name) |
| 14 | rn | bigint | YES | Row number — likely a window function artifact for deduplication or sequencing within the ETL. (Tier 4 — inferred from column name) |
| 15 | Segment | varchar(15) | NO | Current registration-volume segment classification (e.g., '0', '1-5', '6-20', '21-50', '50+'). (Tier 4 — inferred from column name and type) |
| 16 | SegmentFTDs | varchar(15) | NO | Current FTD-volume segment classification (same bucketing logic as Segment). (Tier 4 — inferred from column name) |
| 17 | NewSegment | varchar(15) | NO | Updated registration segment for this period (compared to prior period to detect transitions). (Tier 4 — inferred from column name) |
| 18 | NewSegmentFTDs | varchar(15) | NO | Updated FTD segment for this period (compared to SegmentFTDs for transition detection). (Tier 4 — inferred from column name) |
| 19 | RegSleep | int | NO | Months since the affiliate's last attributed registration. Higher values indicate dormancy. 0 = had registrations this month. (Tier 4 — inferred from column name) |
| 20 | FTDSleep | int | NO | Months since the affiliate's last attributed FTD. Higher values indicate dormancy. 0 = had FTDs this month. (Tier 4 — inferred from column name) |
| 21 | ActivitySegment | varchar(9) | NO | Current monthly activity segment classification (e.g., Active, Sleeping, Churned, New). (Tier 4 — inferred from column name and type) |
| 22 | PreviousActivitySegment | varchar(9) | NO | Prior month's activity segment — enables month-over-month state transition tracking. (Tier 4 — inferred from column name) |
| 23 | IsChurn | int | NO | Churn flag: 1 = affiliate has churned (moved to inactive state), 0 = still active. (Tier 4 — inferred from column name) |
| 24 | TrafficActivity | varchar(16) | NO | Current traffic volume classification (e.g., High, Medium, Low, Dormant, New, Recovering). (Tier 4 — inferred from column name and type) |
| 25 | PreviousTrafficActivity | varchar(16) | NO | Prior month's traffic activity level — enables traffic degradation detection before churn. (Tier 4 — inferred from column name) |
| 26 | EndCont | int | NO | End of contract indicator: 1 = contract has ended, 0 = contract is active. (Tier 4 — inferred from column name) |
| 27 | ToClose | int | NO | Marked for closure flag: 1 = affiliate relationship is scheduled for termination. (Tier 4 — inferred from column name) |
| 28 | TotalCost | int | NO | Total marketing cost/spend for this affiliate in the period (stored as whole units, no decimals). (Tier 4 — inferred from column name) |
| 29 | RevShare | int | NO | Revenue share commission amount paid to this affiliate in the period. (Tier 4 — inferred from column name) |
| 30 | TotalRevenues | int | NO | Total gross revenues generated from this affiliate's customers in the period. (Tier 4 — inferred from column name) |
| 31 | TotalNetRevenues | int | NO | Net revenues after costs (TotalRevenues - TotalCost or after all deductions). (Tier 4 — inferred from column name) |
| 32 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated. (Tier 5 — standard ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No ETL exists — fully orphaned table |

### 5.2 ETL Pipeline

```
Unknown Production Sources (likely aggregation of:
  - fiktivo affiliate system (ID, contract, channel, group, login)
  - Customer registration/FTD facts
  - Revenue/cost aggregations
  - Lifecycle state machine computation)
  |-- [NO ETL PIPELINE EXISTS — FULLY ORPHANED] ---|
  v
BI_DB_dbo.BI_DB_AffiliateLifeCycle (0 rows — DORMANT)

NOTE: Most sophisticated affiliate analytics table in the schema,
      yet never populated in Synapse. Lifecycle analysis likely
      moved to Databricks or external BI tools.
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| AffiliateID | fiktivo affiliate system | Affiliate identifier (theoretical) |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_AffiliateLifeCycle]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 31 T4, 1 T5 | Elements: 32/33 (rn excluded from business logic but included in count) | Logic: 5/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_AffiliateLifeCycle | Type: Table | Production Source: Unknown (dormant, orphaned)*
