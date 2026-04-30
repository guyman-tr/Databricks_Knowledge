# SalesForce.GetFiatAccountStatuses

> Watermark-based incremental extraction procedure that retrieves new dbo.FiatAccountStatuses records since the last sync for SalesForce integration.

| Property | Value |
|----------|-------|
| **Schema** | SalesForce |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Watermark SELECT from dbo.FiatAccountStatuses WHERE Id > @Last AND Id <= MAX(Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

SalesForce.GetFiatAccountStatuses is an incremental data extraction procedure for the SalesForce CRM integration. It uses a watermark pattern: the caller provides the last-synced Id (@LastFiatAccountsStatusesID), the procedure computes the current MAX(Id) as the new watermark, and returns all rows in the range (@LastFiatAccountsStatusesID, @MaxWatermarkValue]. The caller stores the returned @MaxWatermarkValue for the next sync cycle.

This enables efficient delta syncs - only new records since the last sync are returned, avoiding full table scans.

---

## 2. Business Logic

### 2.1 Watermark-Based Incremental Extraction

**What**: Returns only new records since last sync using Id-based watermarking.

**Parameters**: `@LastFiatAccountsStatusesID` (last synced Id), `@MaxWatermarkValue` (OUTPUT - new watermark)

**Rules**:
- First: `SELECT @MaxWatermarkValue = MAX(Id) FROM [FiatAccountStatuses]`
- Then: `SELECT ... FROM [FiatAccountStatuses] WHERE Id > @LastFiatAccountsStatusesID AND Id <= @MaxWatermarkValue`
- Caller stores @MaxWatermarkValue for next invocation
- Returns: AccountId, StatusType, Created

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastFiatAccountsStatusesID | bigint | NO | - | CODE-BACKED | Last synced Id from previous extraction. Use 0 for initial sync. |
| 2 | @MaxWatermarkValue | bigint | NO | OUTPUT | CODE-BACKED | New high-water mark. Caller stores this for next sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatAccountStatuses | Read | Source table for extraction |

### 5.2 Referenced By (other objects point to this)

Not analyzed. Called by SalesForce integration pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
SalesForce.GetFiatAccountStatuses (procedure)
+-- dbo.FiatAccountStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccountStatuses | Table | Source for extraction |

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
EXEC SalesForce.GetFiatAccountStatuses @LastFiatAccountsStatusesID = 0, @MaxWatermarkValue = @watermark OUTPUT;
SELECT @watermark AS NewWatermark;
```

### 8.2 Incremental sync
```sql
DECLARE @watermark BIGINT;
EXEC SalesForce.GetFiatAccountStatuses @LastFiatAccountsStatusesID = 2135000, @MaxWatermarkValue = @watermark OUTPUT;
SELECT @watermark AS NewWatermark;
```

### 8.3 Check source table max
```sql
SELECT MAX(Id) AS CurrentMax FROM dbo.FiatAccountStatuses WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Object: SalesForce.GetFiatAccountStatuses | Type: Stored Procedure | Source: FiatDwhDB/SalesForce/Stored Procedures/SalesForce.GetFiatAccountStatuses.sql*
