# DWH_dbo.Dim_CustomerChangeType

> Reference dimension enumerating the 16 customer attribute fields that are tracked for historical change in `Fact_SnapshotCustomer` — each ID maps to a specific Dim_Customer field name (e.g., CountryID, PlayerStatusID, RegulationID).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (via DWH_Migration — frozen one-time migration, data from 2018-10-02) |
| **Refresh** | None — frozen data, no active ETL |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CustomerChangeTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CustomerChangeType` is a lookup dimension that maps integer IDs to the names of customer attribute fields tracked for historical change. The table contains 16 rows — one per trackable Dim_Customer field. When `Fact_SnapshotCustomer` (or a related customer history table) records a change to a customer record, it uses `CustomerChangeTypeID` to identify WHICH field changed (e.g., ID=5 means "PlayerStatusID changed", ID=12 means "RegulationID changed"). The old value and new value are stored as separate columns in the fact table.

This table was migrated from the legacy on-premises DWH SQL Server in September 2024 (`2024_09_16_17_31_03_DWH_Migration.Dim_CustomerChangeType.sql`). All 16 rows bear the same timestamp of 2018-10-02, indicating the lookup was last updated in 2018 and has been frozen since. The JUNK_ migration variant confirms the standard two-pass Synapse migration pattern.

`SP_Fact_SnapshotCustomer` references `CustomerChangeTypeID` in its result query (currently commented out in the SP body) — suggesting this dimension was actively used to decode change events in an earlier version of the customer snapshot pipeline. The table is exported daily to the Gold layer UC table.

---

## 2. Business Logic

### 2.1 Customer Attribute Change Type Mapping

**What**: Each CustomerChangeTypeID identifies a specific Dim_Customer field whose historical value is captured when it changes in the snapshot fact table.

**Columns Involved**: `CustomerChangeTypeID`, `Name`

**Rules**:
- The Name values are Dim_Customer column names (e.g., "CountryID", "PlayerStatusID") — NOT business labels.
- When a change event is stored in Fact_SnapshotCustomer, the `CustomerChangeTypeID` identifies which field changed; the previous and current values of that field are stored as separate columns.
- All 16 rows have been frozen since 2018-10-02. If new customer attributes are tracked in the future, new rows would need to be inserted manually.

**Value Map**:
```
CustomerChangeTypeID | Name (Dim_Customer field that changed)
  1 | CountryID
  2 | LabelID
  3 | LanguageID
  4 | VerificationLevelID
  5 | PlayerStatusID
  6 | RiskStatusID
  7 | RiskClassificationID
  8 | EmployeeAccount
  9 | CommunicationLanguageID
 10 | PremiumAccount
 11 | CertifiedGuru
 12 | RegulationID
 13 | AccountStatusID
 14 | AccountManagerID
 15 | PlayerLevelID
 16 | AccountTypeID
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `CustomerChangeTypeID`. REPLICATE is optimal — 16 rows total. Every compute node gets a full copy, eliminating shuffle costs when joining to Fact_SnapshotCustomer.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is exported daily to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype` as Parquet (full Override load). No partitioning expected for a 16-row reference table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What field changed for a customer event? | `JOIN Dim_CustomerChangeType ON CustomerChangeTypeID` to get the field Name |
| How many RegulationID changes occurred? | `WHERE CustomerChangeTypeID = 12` on Fact_SnapshotCustomer |
| All PlayerStatus change events | `WHERE CustomerChangeTypeID = 5` on Fact_SnapshotCustomer |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotCustomer | ON Fact_SnapshotCustomer.CustomerChangeTypeID = Dim_CustomerChangeType.CustomerChangeTypeID | Decode which Dim_Customer field changed |

### 3.4 Gotchas

- **Name values are field names, not labels**: "PlayerStatusID" refers to the Dim_Customer column being tracked, not a business label like "Player Status Changed".
- **16 rows only**: The table covers the 16 fields tracked as of 2018. Customer data has evolved since then — not all current Dim_Customer fields may be tracked by change events.
- **SP_Fact_SnapshotCustomer comment**: The CustomerChangeTypeID decode query in SP_Fact_SnapshotCustomer is currently commented out. This field may not appear in current Fact_SnapshotCustomer outputs — verify the actual schema before relying on CustomerChangeTypeID in that table.
- **Frozen since 2018**: The UpdateDate of 2018-10-02 for all rows means no new change types have been added in 6+ years.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 2b | DWH_Migration DDL — structural fact from migration source |
| ★★ | Tier 3 | Live data / sampling — verified from actual Synapse table rows |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CustomerChangeTypeID | tinyint | YES | Primary key identifying the type of customer attribute change. Values 1-16, each mapping to a specific Dim_Customer field name. No ID=0 placeholder row exists. Tinyint supports up to 255 — room for future change types. (Tier 3 — live data, DWH_dbo.Dim_CustomerChangeType) |
| 2 | Name | nvarchar(50) | NO | Name of the Dim_Customer field being tracked for changes. Values are field names (e.g., "CountryID", "PlayerStatusID") — see Section 2.1 for the full value map. Use this to understand which customer attribute changed in a fact table change event. (Tier 3 — live data, DWH_dbo.Dim_CustomerChangeType) |
| 3 | UpdateDate | datetime | YES | Timestamp of the last ETL refresh. All rows show 2018-10-02 — the lookup has not been updated since migration from the legacy DWH. No active ETL exists to change this. (Tier 2b — DWH_Migration DDL, legacy DWH SQL Server) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CustomerChangeTypeID | DWH_Migration.Dim_CustomerChangeType | CustomerChangeTypeID | Passthrough |
| Name | DWH_Migration.Dim_CustomerChangeType | Name | Passthrough |
| UpdateDate | DWH_Migration.Dim_CustomerChangeType | UpdateDate | Passthrough (timestamp from 2018-10-02) |

No upstream production wiki. Source: legacy on-premises DWH SQL Server (migrated September 2024, data from 2018). No etoro DB equivalent found in DB_Schema.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server (on-prem, 2018-10-02 snapshot)
  -> One-time DWH_Migration load (2024-09-16)
    -> DWH_Migration.Dim_CustomerChangeType (staging)
      -> DWH_dbo.Dim_CustomerChangeType (16 rows, frozen)
        -> [No active ETL refresh]
        -> Generic Pipeline (daily) -> Gold/sql_dp_prod_we/DWH_dbo/Dim_CustomerChangeType/
          -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype (UC)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | Customer change type reference — 16 fields tracked as of 2018 |
| Migration | DWH_Migration.Dim_CustomerChangeType | Staged 2024-09-16, data from 2018-10-02 |
| ETL | None | No active ETL SP. Table frozen at migration snapshot. |
| Target | DWH_dbo.Dim_CustomerChangeType | 16 rows, REPLICATE distributed |
| Export | Generic Pipeline | DWH -> Gold -> UC dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype (daily) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No foreign key relationships. Leaf reference dimension. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_SnapshotCustomer | CustomerChangeTypeID | Decodes which Dim_Customer field changed in a customer snapshot change event. SP_Fact_SnapshotCustomer references CustomerChangeTypeID in a currently commented-out decode query. |

---

## 7. Sample Queries

### 7.1 View all customer change types

```sql
SELECT CustomerChangeTypeID, Name, UpdateDate
FROM DWH_dbo.Dim_CustomerChangeType
ORDER BY CustomerChangeTypeID
```

### 7.2 Count change events by field type in Fact_SnapshotCustomer

```sql
SELECT
    cct.Name AS ChangedField,
    COUNT(*) AS ChangeCount
FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_CustomerChangeType cct
    ON fsc.CustomerChangeTypeID = cct.CustomerChangeTypeID
GROUP BY cct.Name
ORDER BY ChangeCount DESC
```

### 7.3 Find all RegulationID changes for a specific customer

```sql
SELECT
    fsc.CID,
    cct.Name AS ChangedField,
    fsc.UpdateDate
FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_CustomerChangeType cct
    ON fsc.CustomerChangeTypeID = cct.CustomerChangeTypeID
WHERE fsc.CID = @cid
    AND cct.Name = 'RegulationID'
ORDER BY fsc.UpdateDate
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — frozen migration table from 2018; Jira/Confluence unlikely to contain current actionable metadata.)

---

*Generated: 2026-03-19 | Quality: 7.6/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 1 T2b, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 5/10*
*Object: DWH_dbo.Dim_CustomerChangeType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration, 2018)*
