# DWH_dbo.Dim_EvMatchStatus

> Identity verification match status dimension - maps numeric status codes to descriptive labels for the eToro EV (eVerification) identity matching process.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.Dictionary.EvMatchStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (EvMatchStatusID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_EvMatchStatus` is a small dictionary table (4 rows) mapping integer codes to human-readable labels for the EV (eVerification) identity matching process. "EV" refers to the automated document/identity verification matching pipeline used by eToro to satisfy KYC (Know Your Customer) regulatory requirements. The four statuses indicate whether a customer's identity documents have been matched against a verification provider: 0=None (no match attempted), 1=PartiallyVerified, 2=Verified, 3=NotVerified.

The data originates from `UserApiDB.Dictionary.EvMatchStatus` on the `UserApiDB-REAL` production server. UserApiDB is the eToro user/customer API backend database. The Generic Pipeline does not appear to export this specific dictionary table to the Bronze lake directly; instead, the DWH staging table `DWH_staging.UserApiDB_Dictionary_EvMatchStatus` is loaded via a separate mechanism, then consumed by `SP_Dictionaries_DL_To_Synapse`.

`SP_Dictionaries_DL_To_Synapse` runs the ETL: TRUNCATE `Dim_EvMatchStatus`, then INSERT from staging. `UpdateDate` is set to `GETDATE()` at load time. The table was last refreshed on 2026-03-11 (as of batch execution date), which is consistent with a known SP_Dictionaries staleness issue (~7 days behind schedule as of 2026-03-19).

---

## 2. Business Logic

### 2.1 EV Match Status Values

**What**: The four-state identity verification matching outcome for a customer account.

**Columns Involved**: `EvMatchStatusID`, `EvMatchStatusName`

**Rules**:
- ID 0 = None: No EV match has been attempted. New or pre-KYC customers.
- ID 1 = PartiallyVerified: EV match ran but produced partial results. Some identity attributes matched, others did not.
- ID 2 = Verified: Full EV match passed. Customer identity confirmed against the verification provider.
- ID 3 = NotVerified: EV match ran but identity could not be confirmed.

**Diagram**:
```
Customer registration
        |
        v
   [None (0)] --- EV process triggered --> [PartiallyVerified (1)]
                                                    |
                                           +--------+--------+
                                           |                 |
                                    [Verified (2)]   [NotVerified (3)]
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (4 rows - ideal for replication). The CLUSTERED INDEX on `EvMatchStatusID` supports efficient point lookups. Since the table is replicated across all nodes, joins from large fact tables (`Fact_SnapshotCustomer`, `Dim_Customer`) incur no data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is exported to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus` (Gold layer). With only 4 rows, no partitioning or Z-ORDER is needed. Broadcast join is automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode EvMatchStatusID in a customer query | `LEFT JOIN DWH_dbo.Dim_EvMatchStatus ON EvMatchStatusID` |
| Count customers by verification status | `GROUP BY ev.EvMatchStatusName` after joining to Dim_Customer |
| Find fully verified customers | `WHERE EvMatchStatusID = 2` (Verified) |
| Find customers not yet verified | `WHERE EvMatchStatusID IN (0, 3)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.EvMatchStatusID = Dim_EvMatchStatus.EvMatchStatusID | Decode EV match status on customer records |
| DWH_dbo.Fact_SnapshotCustomer | ON Fact_SnapshotCustomer.EvMatchStatusID = Dim_EvMatchStatus.EvMatchStatusID | Decode EV status in daily customer snapshots |

### 3.4 Gotchas

- **ID=0 exists in production data** (unlike many other DWH Dim tables that use ID=0 as an ETL placeholder with N/A). The 0=None value represents customers who have not undergone the EV process.
- **Only 4 rows** - if a JOIN returns NULLs for the status name, the source `EvMatchStatusID` value is not in this dimension (data quality issue upstream, not a new status value).
- **Staleness**: UpdateDate reflects the SP_Dictionaries run time, not the production data change time. As of 2026-03-19 this table is ~8 days stale.
- **No ID=0 placeholder insert** in SP_Dictionaries for this table - the 0 value comes directly from production data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| **** | Tier 1 | Upstream wiki verbatim (no upstream wiki found for UserApiDB) |
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EvMatchStatusID | int | YES | Primary key. Integer code identifying the EV (eVerification) identity match status. Values: 0=None, 1=PartiallyVerified, 2=Verified, 3=NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | EvMatchStatusName | varchar(30) | YES | Human-readable label for the EV match status. Renamed from `Name` in the production source. Values: None, PartiallyVerified, Verified, NotVerified. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Does not reflect production source update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| EvMatchStatusID | UserApiDB.Dictionary.EvMatchStatus | EvMatchStatusId | None (passthrough, case rename only: Id->ID) |
| EvMatchStatusName | UserApiDB.Dictionary.EvMatchStatus | Name | Rename: Name -> EvMatchStatusName |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
UserApiDB.Dictionary.EvMatchStatus -> Staging pipeline -> DWH_staging.UserApiDB_Dictionary_EvMatchStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_EvMatchStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | UserApiDB.Dictionary.EvMatchStatus | EV match status dictionary on UserApiDB-REAL production server |
| Staging | DWH_staging.UserApiDB_Dictionary_EvMatchStatus | Raw import (EvMatchStatusId, Name). HEAP/ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Name->EvMatchStatusName. Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_EvMatchStatus | 4-row REPLICATE dictionary. Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | — | No foreign key references to other DWH objects. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | EvMatchStatusID | Customer's current EV identity match status |
| DWH_dbo.Fact_SnapshotCustomer | EvMatchStatusID | Daily snapshot of customer's EV match status |
| DWH_dbo.V_Dim_Customer | EvMatchStatusID | Customer view including EV status |

---

## 7. Sample Queries

### 7.1 Count customers by EV verification status

```sql
SELECT
    ev.EvMatchStatusName,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer c
LEFT JOIN DWH_dbo.Dim_EvMatchStatus ev ON c.EvMatchStatusID = ev.EvMatchStatusID
GROUP BY ev.EvMatchStatusName
ORDER BY CustomerCount DESC
```

### 7.2 Find fully verified customers

```sql
SELECT c.CID, c.RegistrationDate
FROM DWH_dbo.Dim_Customer c
WHERE c.EvMatchStatusID = 2  -- Verified
```

### 7.3 Daily snapshot with decoded EV status

```sql
SELECT
    s.SnapshotDate,
    ev.EvMatchStatusName,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Fact_SnapshotCustomer s
LEFT JOIN DWH_dbo.Dim_EvMatchStatus ev ON s.EvMatchStatusID = ev.EvMatchStatusID
WHERE s.SnapshotDate >= '2026-01-01'
GROUP BY s.SnapshotDate, ev.EvMatchStatusName
ORDER BY s.SnapshotDate, ev.EvMatchStatusName
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.8/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_EvMatchStatus | Type: Table | Production Source: UserApiDB.Dictionary.EvMatchStatus*
