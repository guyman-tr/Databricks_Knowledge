# Trade.UpdateApexID

> Scheduled batch procedure that synchronizes Apex Clearing account identifiers from the US Broker database into eToro's customer records, assigning ApexIDs to newly registered US customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - parameterless batch job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateApexID is a scheduled batch procedure that propagates Apex Clearing account identifiers from the US Broker database (USABrokerAzure) into eToro's core customer records. Apex Clearing is the third-party clearing firm used for US equity (stock) trading. Each US customer who registers on eToro's US brokerage platform is assigned an ApexID by the Apex system - this procedure transfers those IDs into `Customer.CustomerStatic.ApexID` so that trade execution, order routing, and position management can reference the clearing identity.

Without this procedure, newly registered US customers would have no `ApexID` in the eToro database, making it impossible to route their US stock orders to Apex's clearing and settlement infrastructure. A missing or stale ApexID would cause order submission failures for US equity positions.

The procedure is designed to run repeatedly on a schedule. It uses a watermark (`Dictionary.UpdateApexID.LastUpdate`) to process only incremental records since the last run, with a 3-minute overlap buffer to prevent gaps caused by clock skew or processing delays. All updates are audit-logged via SQL Server's `OUTPUT` clause into `History.ApexIDMonitor`. Created by Ran Ovadia in August 2021 for the Apex US project (TRAD-4878, parent: TRAD-4445 Apex US - Stock dividends for US clients).

---

## 2. Business Logic

### 2.1 Incremental Watermark Sync with Overlap Buffer

**What**: Uses a high-watermark timestamp to process only new Apex ID assignments since the last run, with a 3-minute lookback to prevent gaps.

**Columns/Parameters Involved**: `Dictionary.UpdateApexID.LastUpdate`, `Trade.SynApexTradingUserData.InsertDate`

**Rules**:
- Reads `LastUpdate` from `Dictionary.UpdateApexID` (single-row watermark table)
- Queries SynApexTradingUserData for rows where `InsertDate >= DATEADD(MINUTE, -3, @fromdate)` - the 3-minute buffer ensures records inserted near the boundary of the last run are not missed
- After processing, advances watermark to `MAX(InsertDate)` from the batch - only if new records were found; if no new records, retains the previous `LastUpdate` (null-safe via ISNULL)
- Runs as a pure incremental sync - does not reprocess previously seen Apex records

**Diagram**:
```
Each Run:
  @fromdate = Dictionary.UpdateApexID.LastUpdate (last watermark)
       |
       v
  SynApexTradingUserData
  WHERE InsertDate >= @fromdate - 3min
       |
       v (batch of new Apex assignments)
  #ApexTradingApexData (temp: GCID, ApexID, InsertDate)
  [Clustered: GCID+ApexID | NC: InsertDate]
       |
       v
  UPDATE Customer.CustomerStatic
  SET ApexID = c.ApexID
  WHERE a.ApexID IS NULL  (only new assignments)
  JOIN on GCID
       |
       v (audit trail)
  History.ApexIDMonitor (CID, ApexID, Occurred)
       |
       v
  Dictionary.UpdateApexID.LastUpdate = MAX(InsertDate)
```

### 2.2 Idempotent Assignment - Only Updates Null ApexID

**What**: The UPDATE is guarded by `WHERE a.ApexID IS NULL`, meaning it only assigns an ApexID to customers who do not yet have one. This prevents overwriting a valid ApexID with a stale or duplicate Apex record.

**Columns/Parameters Involved**: `Customer.CustomerStatic.ApexID`, `Customer.CustomerStatic.GCID`, `Trade.SynApexTradingUserData.GCID`

**Rules**:
- JOIN condition: `Customer.CustomerStatic.GCID = SynApexTradingUserData.GCID` (GCID is the cross-product identity key linking eToro to Apex)
- Only rows with `ApexID IS NULL` are updated - customers with an existing ApexID are skipped
- This means the procedure can safely re-run over the same time window without corrupting already-assigned IDs
- All successful updates are output to `History.ApexIDMonitor` for auditing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no declared parameters. It operates as a parameterless scheduled batch job.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | Trade.UpdateApexID takes no input parameters. All processing state is derived from Dictionary.UpdateApexID.LastUpdate (watermark) and the source data in Trade.SynApexTradingUserData. |

**Internal temp table `#ApexTradingApexData`** (created and destroyed within each execution):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | (from source) | YES | - | CODE-BACKED | Group Customer ID - the cross-product identity key. Used to JOIN against Customer.CustomerStatic.GCID to locate the eToro customer record to update. Sourced from Trade.SynApexTradingUserData. |
| 2 | ApexID | (from source) | YES | - | CODE-BACKED | The Apex Clearing account identifier to be written into Customer.CustomerStatic.ApexID. This is the external broker-assigned ID used for US stock order routing. |
| 3 | InsertDate | (from source) | YES | - | CODE-BACKED | Timestamp when the Apex user mapping was inserted in the US Broker database. Used to filter the incremental batch (WHERE InsertDate >= @fromdate - 3min) and to advance the watermark (MAX(InsertDate)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Trade.SynApexTradingUserData | Read | Reads Apex user-to-GCID mappings from the US Broker database (via synonym). Filtered by InsertDate for incremental processing. |
| UPDATE target | Customer.CustomerStatic | Modifier | Updates ApexID column for customers with GCID match and null ApexID. |
| Watermark read/write | Dictionary.UpdateApexID | Reader/Writer | Reads LastUpdate at start; writes MAX(InsertDate) at end to advance the watermark. |
| Audit write (OUTPUT) | History.ApexIDMonitor | Writer | Every successful ApexID assignment is logged here via SQL OUTPUT clause with CID, ApexID, and UTC timestamp. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - this procedure is invoked by a SQL Agent job or external scheduler, not by other stored procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateApexID (procedure)
+-- Trade.SynApexTradingUserData (synonym)
|     +-- [USABrokerAzure].[USABroker].[Apex].[TradingUserData] (remote table)
+-- Customer.CustomerStatic (table)
+-- Dictionary.UpdateApexID (table)
+-- History.ApexIDMonitor (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynApexTradingUserData | Synonym | SELECT INTO #ApexTradingApexData - source of new Apex ID assignments from US Broker |
| Customer.CustomerStatic | Table | UPDATE target - writes ApexID where GCID matches and ApexID is null |
| Dictionary.UpdateApexID | Table | Reads LastUpdate watermark at start; updates LastUpdate watermark at end |
| History.ApexIDMonitor | Table | Receives audit rows for every ApexID assignment via OUTPUT clause |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateApexIDOld | Stored Procedure | Legacy version of the same sync logic - runs against same dependencies. Not a caller of this procedure. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

Internal temp table `#ApexTradingApexData` is created with:
- `CID` - CLUSTERED index on (GCID, ApexID) for JOIN performance against CustomerStatic
- `IX` - NONCLUSTERED index on (InsertDate) for watermark filtering

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check the current Apex sync watermark
```sql
SELECT LastUpdate,
       DATEDIFF(MINUTE, LastUpdate, GETUTCDATE()) AS MinutesSinceLastSync
FROM   Dictionary.UpdateApexID WITH (NOLOCK);
```

### 8.2 Find customers recently assigned an ApexID (audit log)
```sql
SELECT TOP 100
       h.CID,
       h.ApexID,
       h.Occurred,
       cs.GCID,
       cs.UserName
FROM   History.ApexIDMonitor h WITH (NOLOCK)
JOIN   Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = h.CID
ORDER  BY h.Occurred DESC;
```

### 8.3 Find US customers still missing an ApexID
```sql
SELECT cs.CID,
       cs.GCID,
       cs.UserName,
       cs.InsertDate AS RegistrationDate
FROM   Customer.CustomerStatic cs WITH (NOLOCK)
WHERE  cs.ApexID IS NULL
  AND  cs.GCID IS NOT NULL
ORDER  BY cs.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRAD-4878 - Copy apex account id from US Broker to etoro DB](https://etoro-jira.atlassian.net/browse/TRAD-4878) | Jira Story | Business context: created Aug 2021 as part of Apex US stocks project to copy Apex account IDs from US Broker into eToro DB for US client stock operations |
| [TRAD-4445 - Apex US - Stock dividends for US clients](https://etoro-jira.atlassian.net/browse/TRAD-4445) | Jira Story (parent) | Parent initiative: Apex US integration for US stock dividend and trading operations |
| [TRAD-4879 - DB - Copy apex account id from US Broker to etoro DB](https://etoro-jira.atlassian.net/browse/TRAD-4879) | Jira Sub-DB | DB implementation subtask for TRAD-4878 - confirms this procedure is the DB artifact for the Apex ID copy feature |

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateApexID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateApexID.sql*
