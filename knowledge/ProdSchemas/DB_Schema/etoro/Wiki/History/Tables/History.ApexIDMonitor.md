# History.ApexIDMonitor

> Audit log recording when each US customer's Apex Trading account ID was first synced from the Apex broker system into the eToro database, one row per customer.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (CID, ApexID, Occurred) - no PK |
| **Partition** | No (stored on DICTIONARY filegroup) |
| **Indexes** | 1 active (CLUSTERED on CID, ApexID, Occurred) |

---

## 1. Business Meaning

History.ApexIDMonitor records when each US eToro customer received their Apex Trading account ID. Apex Trading is an external US broker used by eToro for US-regulated securities (stocks, dividends) - each US customer must have a corresponding Apex account ID to participate in US stock trading.

The table was created as part of the **"Apex US - Stock dividends for US clients"** initiative (Jira: TRAD-4878, parent TRAD-4445), implemented by the Trading Engines team in August 2021. The sync procedure `Trade.UpdateApexID` runs on a schedule, reading newly available Apex IDs from the sync table `Trade.SynApexTradingUserData`, assigning them to `Customer.CustomerStatic.ApexID` (for customers where ApexID is still NULL), and logging each assignment here via UPDATE...OUTPUT.

**One row per customer**: The 14,470 rows for 14,470 distinct CIDs confirms this is a first-assignment-only log. Once an ApexID is assigned, it is never reassigned (the UPDATE fires only WHERE ApexID IS NULL). The table serves as an audit trail: "when did customer X receive their Apex account ID?"

**Operational context**: The sync is watermark-driven via `Dictionary.UpdateApexID.LastUpdate`, scanning Apex data inserted within the last 3 minutes of the last run. The DICTIONARY filegroup placement reflects treatment as configuration/reference data rather than transactional data.

---

## 2. Business Logic

### 2.1 ApexID First-Assignment Audit

**What**: Logs the first time each US customer's Apex Trading account ID is written into the eToro system.

**Columns/Parameters Involved**: `CID`, `ApexID`, `Occurred`

**Rules**:
- `Trade.UpdateApexID` is the sole writer, running on a schedule
- Source of Apex IDs: `Trade.SynApexTradingUserData` (synced from Apex Trading broker API)
- Assignment condition: `Customer.CustomerStatic.ApexID IS NULL` - only new (unassigned) customers are processed; existing Apex IDs are never overwritten
- The UPDATE...OUTPUT captures: `Inserted.CID` (from CustomerStatic), `Inserted.ApexID` (new value), `GETUTCDATE()` (assignment time)
- `Occurred` captures UTC time of the eToro database update, not the Apex account creation time
- ApexID format: alphanumeric codes (e.g., "3FH74409") assigned by Apex Trading

**Diagram**:
```
Apex Trading broker API
      |
      v (sync job)
Trade.SynApexTradingUserData (GCID, ApexID, InsertDate)
      |
      Trade.UpdateApexID (scheduled job, watermark = Dictionary.UpdateApexID.LastUpdate)
      |
      UPDATE Customer.CustomerStatic SET ApexID = c.ApexID
      WHERE ApexID IS NULL
      |
      OUTPUT Inserted.CID, Inserted.ApexID, GETUTCDATE()
      INTO History.ApexIDMonitor
```

### 2.2 Watermark-Driven Incremental Sync

**What**: The procedure uses a last-update timestamp to avoid reprocessing already-handled Apex records.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- `Dictionary.UpdateApexID.LastUpdate` stores the high-water mark (max InsertDate processed)
- Each run reads Apex data WHERE InsertDate >= LastUpdate - 3 minutes (3-minute lookback for safety margin)
- After processing, LastUpdate is advanced to the max InsertDate in the current batch
- If no new data: @LastUpdate remains NULL, falls back to the previous watermark value (ISNULL(@LastUpdate, @LastUpdate1))

---

## 3. Data Overview

14,470 rows for 14,470 distinct customers, January 2023 to March 2026. One row per customer (no duplicates). ApexIDs are sequentially assigned by the Apex broker. Occurred timestamps show the assignment happening at daily intervals.

| CID | ApexID | Occurred | Meaning |
|---|---|---|---|
| 25481118 | 3FH74409 | 2026-03-19 05:26:00 | Latest ApexID assignment. This US customer received Apex account ID "3FH74409" at 05:26 UTC on March 19 2026. The scheduled job ran and found a new Apex account mapped to this CID. |
| 25467408 | 3FH74406 | 2026-03-18 05:03:00 | Previous day's assignment. Sequential ApexID (4406 vs 4409) and daily cadence suggest Apex Trading assigns IDs in order, and eToro processes them once per day. |
| 25413630 | 3FH74397 | 2026-03-11 05:06:00 | Several days prior. The sequential ApexID progression (4397 -> 4403 -> 4406 -> 4409) across days confirms the daily batch pattern. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | eToro Customer ID (CID) of the US customer who received an Apex account ID. Sourced from Customer.CustomerStatic.CID via the UPDATE...OUTPUT statement. NULL-able in DDL but in practice always populated. Part of the clustered index. |
| 2 | ApexID | varchar(20) | YES | - | CODE-BACKED | The Apex Trading account identifier assigned to this customer. Sourced from Trade.SynApexTradingUserData.ApexID (originally from the Apex broker API). Format: alphanumeric codes (e.g., "3FH74409"). Max 20 characters. NULL-able in DDL but always populated in practice. Part of the clustered index. |
| 3 | Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the ApexID was written to Customer.CustomerStatic. Set to GETUTCDATE() by the Trade.UpdateApexID OUTPUT clause. Represents the eToro-side assignment time, not the Apex account creation time. Part of the clustered index. NULL-able in DDL but always populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The customer whose Apex ID was just assigned. |
| ApexID | Trade.SynApexTradingUserData | Implicit (source) | The ApexID value came from this Apex sync table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateApexID | OUTPUT clause | Writer | Sole writer. UPDATE...OUTPUT captures each new ApexID assignment. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ApexIDMonitor (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No FK constraints or code-level dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateApexID | Stored Procedure | Writer - captures each ApexID assignment via UPDATE...OUTPUT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | CID ASC, ApexID ASC, Occurred ASC | - | - | Active |

**Note**: No primary key defined. All three columns are nullable in the DDL. The clustered index on (CID, ApexID, Occurred) supports customer-centric lookups. Stored on DICTIONARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No PK, FK, or check constraints defined. |

---

## 8. Sample Queries

### 8.1 Look up when a specific customer received their ApexID
```sql
SELECT CID, ApexID, Occurred
FROM History.ApexIDMonitor WITH (NOLOCK)
WHERE CID = 25481118;
```

### 8.2 Daily ApexID assignment volume
```sql
SELECT
    CAST(Occurred AS DATE) AS AssignDate,
    COUNT(*) AS NewApexIDsAssigned
FROM History.ApexIDMonitor WITH (NOLOCK)
WHERE Occurred >= '2026-01-01'
GROUP BY CAST(Occurred AS DATE)
ORDER BY AssignDate DESC;
```

### 8.3 Customers with ApexIDs in a date range
```sql
SELECT CID, ApexID, Occurred
FROM History.ApexIDMonitor WITH (NOLOCK)
WHERE Occurred >= '2026-03-01'
  AND Occurred < '2026-04-01'
ORDER BY Occurred ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRAD-4878: Copy apex account id from US Broker to etoro DB](https://etoro-jira.atlassian.net/browse/TRAD-4878) | Jira Story (Done) | Confirms purpose: sync Apex Trading account IDs from the US broker into eToro's DB for US clients. Parent story: TRAD-4445 "Apex US - Stock dividends for US clients". Implemented by Elad Avraham (Trading Engines), reported by Amit Hadari. Created July 2021, resolved 2022. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ApexIDMonitor | Type: Table | Source: etoro/etoro/History/Tables/History.ApexIDMonitor.sql*
