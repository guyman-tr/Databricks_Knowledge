# SalesForce.GetFiatCardStatuses

> Watermark-based incremental extraction procedure that retrieves new dbo.FiatCardStatuses records since the last sync for SalesForce integration.

| Property | Value |
|----------|-------|
| **Schema** | SalesForce |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Watermark SELECT from dbo.FiatCardStatuses WHERE Id > @Last AND Id <= MAX(Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

SalesForce.GetFiatCardStatuses is an incremental data extraction procedure for the SalesForce CRM integration. It uses a watermark pattern: the caller provides the last-synced Id (@LastFiatCardStatusesID), the procedure computes the current MAX(Id) as the new watermark, and returns all rows in the range (@LastFiatCardStatusesID, @MaxWatermarkValue]. The caller stores the returned @MaxWatermarkValue for the next sync cycle.

This enables efficient delta syncs - only new records since the last sync are returned, avoiding full table scans.

---

## 2. Business Logic

### 2.1 Watermark-Based Incremental Extraction

**What**: Returns only new records since last sync using Id-based watermarking.

**Parameters**: `@LastFiatCardStatusesID` (last synced Id), `@MaxWatermarkValue` (OUTPUT - new watermark)

**Rules**:
- First: `SELECT @MaxWatermarkValue = MAX(Id) FROM [FiatCardStatuses]`
- Then: `SELECT ... FROM [FiatCardStatuses] WHERE Id > @LastFiatCardStatusesID AND Id <= @MaxWatermarkValue`
- Caller stores @MaxWatermarkValue for next invocation
- Returns: CardId, CardStatusId, Created

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastFiatCardStatusesID | bigint | NO | - | CODE-BACKED | Last synced Id from previous extraction. Use 0 for initial sync. |
| 2 | @MaxWatermarkValue | bigint | NO | OUTPUT | CODE-BACKED | New high-water mark. Caller stores this for next sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatCardStatuses | Read | Source table for extraction |

### 5.2 Referenced By (other objects point to this)

Not analyzed. Called by SalesForce integration pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
SalesForce.GetFiatCardStatuses (procedure)
+-- dbo.FiatCardStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardStatuses | Table | Source for extraction |

### 6.2 Objects That Depend On This

SalesForce integration pipeline (external).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Initial sync (first run)
```sql
DECLARE @watermark BIGINT;
EXEC SalesForce.GetFiatCardStatuses @LastFiatCardStatusesID = 0, @MaxWatermarkValue = @watermark OUTPUT;
SELECT @watermark AS NewWatermark;
```

### 8.2 Incremental sync
```sql
DECLARE @watermark BIGINT;
EXEC SalesForce.GetFiatCardStatuses @LastFiatCardStatusesID = 2135000, @MaxWatermarkValue = @watermark OUTPUT;
SELECT @watermark AS NewWatermark;
```

### 8.3 Check source table max
```sql
SELECT MAX(Id) AS CurrentMax FROM dbo.FiatCardStatuses WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Object: SalesForce.GetFiatCardStatuses | Type: Stored Procedure | Source: FiatDwhDB/SalesForce/Stored Procedures/SalesForce.GetFiatCardStatuses.sql*
