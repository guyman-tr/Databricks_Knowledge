# DWH_dbo.Dim_GuruStatus

> Popular Investor (Guru) status dimension - maps integer codes to eToro Popular Investor program tier labels, from "No" (not enrolled) through Cadet, Rising Star, Champion, Elite, and Elite Pro, plus Removed and Rejected states.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.GuruStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (GuruStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_GuruStatus` is a 9-row dictionary classifying eToro customers in the **Popular Investor (PI) program** (internally called "Guru"). The PI program allows experienced traders to earn income by being copied; status reflects their tier and program standing.

The status ladder (active tiers):
- 0 = No: Customer is not enrolled in the Popular Investor program
- 1 = Certified: Entry-level PI certification
- 2 = Cadet: First active tier of the PI program
- 3 = Rising Star: Second tier - growing following
- 4 = Champion: Third tier
- 5 = Elite: Fourth tier - top performers
- 6 = Elite Pro: Highest active tier - professional Popular Investors

Negative states:
- 7 = Removed: Previously enrolled, now removed from the program
- 8 = Rejected: Applied but rejected from the program

**GuruStatusID=0 (No)** serves as both the "not enrolled" value and the null-safe join sentinel: SP_Dim_Customer uses `ISNULL(GuruStatusID, 0)` to coerce NULLs to 0.

The data originates from `etoro.Dictionary.GuruStatus` via `DWH_staging.etoro_Dictionary_GuruStatus`. ETL: TRUNCATE + INSERT, `Name` renamed to `GuruStatusName`.

Consumers: `Dim_Customer` (each customer's current PI status), `Fact_SnapshotCustomer` (daily PI status snapshot), `Fact_CustomerAction_DL_To_Synapse` (PI status at action time).

---

## 2. Business Logic

### 2.1 Popular Investor Tier Ladder

**What**: Active PI statuses represent a progression from entry-level to elite.

**Columns Involved**: `GuruStatusID`, `GuruStatusName`

**Rules**:
```
Tier progression (active):
  No (0) -> Certified (1) -> Cadet (2) -> Rising Star (3)
         -> Champion (4) -> Elite (5) -> Elite Pro (6)

Negative states (off-ladder):
  Removed (7): was in program, exited
  Rejected (8): applied, not accepted
```

**For analysis**: GuruStatusID > 0 AND < 7 = currently active in PI program. GuruStatusID = 0 = regular customer.

### 2.2 Null-Sentinel Pattern

**What**: GuruStatusID=0 (No) absorbs NULL values from Dim_Customer.

**Columns Involved**: `GuruStatusID`

**Rules**:
- SP_Dim_Customer: `ISNULL(GuruStatusID, 0) AS GuruStatusID` (customers with no PI enrollment get ID 0)
- SP_Dim_Customer change detection: `OR ISNULL(dc.GuruStatusID, 0) <> ISNULL(a.GuruStatusID, 0)`
- Meaning: NULL and 0 are semantically equivalent (not in PI program)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (9 rows - appropriate). CLUSTERED INDEX on GuruStatusID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 9 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode GuruStatusID to name | `LEFT JOIN DWH_dbo.Dim_GuruStatus ON GuruStatusID` |
| Find active Popular Investors | `WHERE GuruStatusID BETWEEN 1 AND 6` |
| Exclude regular customers | `WHERE GuruStatusID > 0 AND GuruStatusID < 7` |
| Count customers by PI tier | `GROUP BY GuruStatusName ORDER BY GuruStatusID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GuruStatusID | Customer's current Popular Investor status |
| DWH_dbo.Fact_SnapshotCustomer | ON GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | ON GuruStatusID | PI status at time of action |

### 3.4 Gotchas

- **ID=0 is NOT null**: GuruStatusID=0 means "No" (not in PI program). It is the semantic null sentinel. Do not filter it out when showing all customers - it represents the majority.
- **Active PI filter**: To find active Popular Investors, use `GuruStatusID BETWEEN 1 AND 6`. IDs 7 (Removed) and 8 (Rejected) are ex-PI or rejected applicants and should be excluded from "active PI" counts.
- **Tiers imply rank**: GuruStatusID 1-6 form a meaningful rank ordering (lower = less established). Use ORDER BY GuruStatusID for tier comparisons.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| **** | Tier 1 | Upstream Dictionary wiki (DB_Schema), verbatim |
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GuruStatusID | int | NO | Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. (Tier 1 — Dictionary.GuruStatus) |
| 2 | GuruStatusName | varchar(50) | NO | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — Dictionary.GuruStatus) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GuruStatusID | etoro.Dictionary.GuruStatus | GuruStatusID | passthrough |
| GuruStatusName | etoro.Dictionary.GuruStatus | Name | rename: Name -> GuruStatusName |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.GuruStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_GuruStatus -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 718) -> DWH_dbo.Dim_GuruStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.GuruStatus | Guru/PI status dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/GuruStatus/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_GuruStatus | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Name -> GuruStatusName rename. UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_GuruStatus | 9-row REPLICATE/CLUSTERED PI status dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | GuruStatusID | Customer's current Popular Investor tier |
| DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | GuruStatusID | PI status at time of customer action |

---

## 7. Sample Queries

### 7.1 All Guru status values

```sql
SELECT GuruStatusID, GuruStatusName
FROM DWH_dbo.Dim_GuruStatus
ORDER BY GuruStatusID
```

### 7.2 Count active Popular Investors by tier

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
WHERE dc.GuruStatusID BETWEEN 1 AND 6
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

### 7.3 PI tier distribution across all customers

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount,
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS Pct
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.Dim_GuruStatus | Type: Table | Production Source: etoro.Dictionary.GuruStatus*
