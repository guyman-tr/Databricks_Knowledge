# Monitoring.IsTribeFilesProcessingDelaying

> Monitors Tribe file processing pipeline for delays by checking if the latest script in FilesScriptHistory is older than the lookback threshold and not yet executed.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Checks MAX(Id) from Tribe.FilesScriptHistory against time threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsTribeFilesProcessingDelaying checks if the Tribe data file processing pipeline is stuck. Gets the latest script from Tribe.FilesScriptHistory, checks if it's older than @LookbackInMinutes (default 1440 = 24 hours). If yes, returns the script details with its current status from Dictionary.TribeScriptStatus. If the pipeline is on schedule, returns no rows.

This is the canary for Tribe data pipeline health. An alert from this SP means new Tribe files are not being processed.

---

## 2. Business Logic

### 2.1 Pipeline Delay Detection

**Rules**:
- Gets MAX(Id) from FilesScriptHistory
- If CreateDate < (now - @LookbackInMinutes): pipeline is delayed
- Returns: ScriptId, DateLookbackThreshold, CreateDate, FileId, IsSchemaRequiresUpdate, FileDocumentName, ScriptStatus
- If not delayed: returns empty result set
- Uses Dictionary.TribeScriptStatus for status name resolution

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LookbackInMinutes | int | YES | 1440 | CODE-BACKED | Minutes threshold. Default 1440 (24 hours). If last script is older than this, alert. |

---

## 5. Relationships

Reads: Tribe.FilesScriptHistory, Tribe.FilesScriptHistoryStatus, Dictionary.TribeScriptStatus.

---

## 6. Dependencies

Depends on: Tribe.FilesScriptHistory, Tribe.FilesScriptHistoryStatus, Dictionary.TribeScriptStatus.

---

## 7-9. Standard.

---

## 8. Sample Queries

### 8.1 Check with default 24-hour threshold
```sql
EXEC Monitoring.IsTribeFilesProcessingDelaying;
-- Empty result = pipeline OK
-- Rows returned = pipeline delayed
```

### 8.2 Check with 1-hour threshold
```sql
EXEC Monitoring.IsTribeFilesProcessingDelaying @LookbackInMinutes = 60;
```

### 8.3 Manual check
```sql
SELECT TOP 1 Id, Created, FileName FROM Tribe.FilesScriptHistory WITH (NOLOCK) ORDER BY Id DESC;
-- If Created is more than 24 hours old, pipeline is delayed
```

---

*Generated: 2026-04-14 | Quality: 9.4/10*
*Object: Monitoring.IsTribeFilesProcessingDelaying | Type: Stored Procedure*
