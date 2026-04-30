# Trade.UpdateApexIDOld

> Legacy scheduled batch procedure that synchronizes Apex Clearing account identifiers from the US Broker database into eToro's customer records; superseded by Trade.UpdateApexID which added an idempotency guard and audit logging.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - parameterless batch job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateApexIDOld is the original (legacy) version of the Apex account ID synchronization procedure. It reads newly inserted Apex user mappings from `Trade.SynApexTradingUserData` (pointing to the US Broker database) and updates `Customer.CustomerStatic.ApexID` for matching customers identified by GCID.

This procedure was superseded by `Trade.UpdateApexID`, which introduced two improvements: (1) an idempotency guard (`WHERE a.ApexID IS NULL`) to prevent overwriting an already-assigned ApexID, and (2) an audit trail via SQL `OUTPUT INTO History.ApexIDMonitor`. The "Old" version updates any matching customer regardless of whether they already have an ApexID, meaning a subsequent Apex record could silently overwrite a valid existing ID.

The same watermark mechanism is used: `Dictionary.UpdateApexID.LastUpdate` is read at start and updated at completion, with a 3-minute overlap buffer to prevent gaps. Created by Ran Ovadia in August 2021 as part of the Apex US project (TRAD-4878, parent: TRAD-4445).

---

## 2. Business Logic

### 2.1 Incremental Watermark Sync (Same as UpdateApexID)

**What**: Uses a high-watermark timestamp to process only new Apex ID assignments since the last run, with a 3-minute lookback buffer.

**Columns/Parameters Involved**: `Dictionary.UpdateApexID.LastUpdate`, `Trade.SynApexTradingUserData.InsertDate`

**Rules**:
- Reads `LastUpdate` from `Dictionary.UpdateApexID`
- Queries SynApexTradingUserData WHERE `InsertDate >= DATEADD(MINUTE, -3, @fromdate)`
- Advances watermark to `MAX(InsertDate)` from the batch; retains prior value via ISNULL if batch is empty
- Shares the same watermark table as `Trade.UpdateApexID` - both procedures read and write `Dictionary.UpdateApexID.LastUpdate`

**Diagram**:
```
Each Run:
  @fromdate = Dictionary.UpdateApexID.LastUpdate
       |
       v
  SynApexTradingUserData
  WHERE InsertDate >= @fromdate - 3min
       |
       v
  #ApexTradingApexData (GCID, ApexID, InsertDate)
       |
       v
  UPDATE Customer.CustomerStatic
  SET ApexID = c.ApexID
  JOIN on GCID
  (NO WHERE ApexID IS NULL - all matching rows updated)
       |
       v
  Dictionary.UpdateApexID.LastUpdate = MAX(InsertDate)
  [No audit log to History.ApexIDMonitor]
```

### 2.2 Key Difference vs Trade.UpdateApexID - No Idempotency Guard

**What**: Unlike the successor procedure, this version updates ALL customers with a matching GCID, including those who already have an ApexID assigned.

**Columns/Parameters Involved**: `Customer.CustomerStatic.ApexID`, `Customer.CustomerStatic.GCID`

**Rules**:
- No `WHERE a.ApexID IS NULL` filter - if a customer has an existing ApexID and a new Apex record appears for their GCID, their ApexID will be overwritten
- No OUTPUT clause - updates are not logged to History.ApexIDMonitor
- This is the primary reason this version was superseded: in normal operation the overwrite is benign (same ApexID from Apex), but in error scenarios it could corrupt an assigned ID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no declared parameters. It operates as a parameterless scheduled batch job.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | Trade.UpdateApexIDOld takes no input parameters. Processing state is derived from Dictionary.UpdateApexID.LastUpdate (watermark) and the source data in Trade.SynApexTradingUserData. |

**Internal temp table `#ApexTradingApexData`** (created and destroyed within each execution):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | (from source) | YES | - | CODE-BACKED | Group Customer ID - cross-product identity key. Used to JOIN against Customer.CustomerStatic.GCID to locate the eToro customer record to update. |
| 2 | ApexID | (from source) | YES | - | CODE-BACKED | The Apex Clearing account identifier to be written into Customer.CustomerStatic.ApexID for US stock order routing. |
| 3 | InsertDate | (from source) | YES | - | CODE-BACKED | Timestamp when the Apex user mapping was inserted in US Broker. Used for incremental filtering and watermark advancement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Trade.SynApexTradingUserData | Read | Reads Apex user-to-GCID mappings from US Broker database, filtered by InsertDate for incremental batch |
| UPDATE target | Customer.CustomerStatic | Modifier | Updates ApexID for all customers with GCID match (no null guard) |
| Watermark read/write | Dictionary.UpdateApexID | Reader/Writer | Reads LastUpdate at start; writes MAX(InsertDate) at end |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - invoked by a SQL Agent job or external scheduler.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateApexIDOld (procedure)
+-- Trade.SynApexTradingUserData (synonym)
|     +-- [USABrokerAzure].[USABroker].[Apex].[TradingUserData] (remote table)
+-- Customer.CustomerStatic (table)
+-- Dictionary.UpdateApexID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynApexTradingUserData | Synonym | SELECT INTO #ApexTradingApexData - source of new Apex ID assignments from US Broker |
| Customer.CustomerStatic | Table | UPDATE target - writes ApexID where GCID matches (all rows, no null guard) |
| Dictionary.UpdateApexID | Table | Reads LastUpdate watermark at start; updates LastUpdate watermark at end |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateApexID | Stored Procedure | Successor/replacement procedure. Not a caller - runs independently and added idempotency guard and audit logging that this procedure lacks. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

Internal temp table `#ApexTradingApexData` is created with:
- `CID` - CLUSTERED index on (GCID, ApexID)
- `IX` - NONCLUSTERED index on (InsertDate)

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Compare with successor to verify no duplicate scheduling
```sql
-- Both procedures share the same watermark - check which ran last
SELECT LastUpdate,
       DATEDIFF(MINUTE, LastUpdate, GETUTCDATE()) AS MinutesSinceSync
FROM   Dictionary.UpdateApexID WITH (NOLOCK);
```

### 8.2 Find customers whose ApexID may have been overwritten
```sql
-- History.ApexIDMonitor only captures Trade.UpdateApexID updates, not this procedure
-- Use history table to identify customers with multiple Apex ID changes
SELECT h.CID, COUNT(*) AS AssignmentCount, MIN(h.Occurred) AS FirstAssigned, MAX(h.Occurred) AS LastAssigned
FROM   History.ApexIDMonitor h WITH (NOLOCK)
GROUP  BY h.CID
HAVING COUNT(*) > 1
ORDER  BY AssignmentCount DESC;
```

### 8.3 Find US customers with an assigned ApexID
```sql
SELECT cs.CID,
       cs.GCID,
       cs.ApexID,
       cs.UserName
FROM   Customer.CustomerStatic cs WITH (NOLOCK)
WHERE  cs.ApexID IS NOT NULL
ORDER  BY cs.CID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRAD-4878 - Copy apex account id from US Broker to etoro DB](https://etoro-jira.atlassian.net/browse/TRAD-4878) | Jira Story | Business context: created Aug 2021 as part of Apex US stocks project; this "Old" version is the original implementation before idempotency and audit improvements |
| [TRAD-4445 - Apex US - Stock dividends for US clients](https://etoro-jira.atlassian.net/browse/TRAD-4445) | Jira Story (parent) | Parent initiative: Apex US integration for US stock dividend and trading operations |

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateApexIDOld | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateApexIDOld.sql*
