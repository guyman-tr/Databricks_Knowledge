# Apex.TradingApexData

> Trading platform's copy of the Apex account mapping, populated by INSERT trigger on ApexData, providing the trading system with its own read-optimized copy of account identifiers and initial status.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ApexID (VARCHAR(8), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.TradingApexData is the trading platform's local copy of the GCID-to-ApexID mapping. It is automatically populated by the ApexDataInsert trigger on Apex.ApexData whenever a new account is created. This gives the trading platform its own independent table to query without impacting the Apex integration workflow's tables.

This table exists to decouple the trading platform's read operations from the Apex account management tables. The trading system can query TradingApexData freely without locking concerns on the main ApexData table. Note: since the trigger only fires on INSERT (not UPDATE), TradingApexData retains the initial status at account creation time and does not track subsequent status changes.

Data is created automatically by the INSERT trigger on ApexData. The trigger copies ApexID, GCID, StatusID, UpdatedSync, and BeginTime. Deletion is handled by Apex.DeleteTradingApexData.

---

## 2. Business Logic

### 2.1 Trigger-Based Replication (INSERT Only)

**What**: Data is replicated from ApexData via INSERT trigger only - subsequent status updates in ApexData are NOT reflected here.

**Columns/Parameters Involved**: `ApexID`, `GCID`, `StatusID`, `UpdatedSync`, `BeginTime`

**Rules**:
- Trigger ApexDataInsert on Apex.ApexData fires FOR INSERT only
- StatusID in this table reflects the status AT CREATION TIME, not the current status
- Observed data shows StatusID=2 (PENDING) for early records while corresponding ApexData rows show StatusID=12 (COMPLETE)
- This table should be used for GCID/ApexID mapping, not for current status lookups

---

## 3. Data Overview

| ApexID | GCID | StatusID | UpdatedSync | BeginTime | Meaning |
|--------|------|----------|-------------|-----------|---------|
| 3ER05011 | 19533157 | 2 | false | 2022-02-27 08:33 | Early account created during initial migration. StatusID=2 (PENDING) is the status at trigger time - the corresponding ApexData row is now StatusID=12 (COMPLETE). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(8) | NO | - | CODE-BACKED | Apex Clearing account identifier. Primary key. Same value as in Apex.ApexData. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Same value as in Apex.ApexData. |
| 3 | StatusID | int | NO | - | VERIFIED | Account status AT CREATION TIME (not current). Reflects the Apex status when the INSERT trigger fired on ApexData. Does not update when ApexData.StatusID changes. See [Apex Status](_glossary.md#apex-status). |
| 4 | UpdatedSync | bit | NO | - | CODE-BACKED | Sync flag value at creation time. Copied from ApexData by the INSERT trigger. |
| 5 | BeginTime | datetime2(0) | NO | - | CODE-BACKED | Temporal row start time from ApexData at INSERT time. Reflects when the account was initially created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. Data is populated by trigger from Apex.ApexData.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.ApexData (trigger) | ApexDataInsert | Trigger | INSERT trigger copies new account rows here |
| Apex.DeleteTradingApexData | @GCID | Deleter | Removes trading data by GCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no FK dependencies. Data source is Apex.ApexData via trigger.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.DeleteTradingApexData | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradingApexData | CLUSTERED PK | ApexID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradingApexData | PRIMARY KEY | Clustered on ApexID |

---

## 8. Sample Queries

### 8.1 Compare TradingApexData status vs current ApexData status

```sql
SELECT t.ApexID, t.GCID, t.StatusID AS InitialStatus,
       a.StatusID AS CurrentStatus, s.Name AS CurrentStatusName
FROM Apex.TradingApexData t WITH (NOLOCK)
INNER JOIN Apex.ApexData a WITH (NOLOCK) ON a.ApexID = t.ApexID
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = a.StatusID
WHERE t.StatusID <> a.StatusID;
```

### 8.2 Look up a customer's trading apex data

```sql
SELECT ApexID, GCID, StatusID, BeginTime
FROM Apex.TradingApexData WITH (NOLOCK)
WHERE GCID = 19533157;
```

### 8.3 Find accounts by ApexID prefix

```sql
SELECT ApexID, GCID, StatusID, BeginTime
FROM Apex.TradingApexData WITH (NOLOCK)
WHERE ApexID LIKE '3FN%'
ORDER BY BeginTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.TradingApexData | Type: Table | Source: USABroker/Apex/Tables/Apex.TradingApexData.sql*
