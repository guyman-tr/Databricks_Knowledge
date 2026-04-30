# dbo.AddCurrencyBalancesStatuses

> Upsert procedure that records a currency balance status change with source and reason attribution, deduplicating on CurrencyBalancesId + StatusType + EventTimestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatCurrencyBalancesStatuses, returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddCurrencyBalancesStatuses records a currency balance status change event with full attribution (who initiated it and why). Uses timestamp-based deduplication: if a record already exists with the same CurrencyBalancesId, StatusType, and an EventTimestamp >= the incoming one, it returns 0 (skip). Otherwise inserts and returns the new ID.

---

## 2. Business Logic

### 2.1 Timestamp-Based Deduplication with Attribution

**What**: Prevents duplicate/outdated status events while capturing source and reason.

**Rules**:
- Deduplicates on CurrencyBalancesId + StatusType + EventTimestamp (same pattern as AddCardStatus)
- UPDLOCK, HOLDLOCK for concurrency safety
- StatusChangeSourceId and StatusChangeReasonId provide compliance-grade audit trail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyBalancesId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. |
| 2 | @StatusType | int | NO | - | CODE-BACKED | Status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. See [Currency Balance Status](../../_glossary.md#currency-balance-status). |
| 3 | @StatusChangeSourceId | tinyint | NO | - | CODE-BACKED | Who initiated: 0-4. See [Status Change Source](../../_glossary.md#status-change-source). |
| 4 | @StatusChangeReasonId | tinyint | NO | - | CODE-BACKED | Why: 0-19. See [Status Change Reason](../../_glossary.md#status-change-reason). |
| 5 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | When the event occurred (used for dedup). |
| 6 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatCurrencyBalancesStatuses | Read/Write | Dedup + insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddCurrencyBalancesStatuses (procedure)
└── dbo.FiatCurrencyBalancesStatuses (table)
    └── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalancesStatuses | Table | Dedup + insert target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record a balance suspension due to suspected fraud
```sql
EXEC dbo.AddCurrencyBalancesStatuses @CurrencyBalancesId = 2135699, @StatusType = 3,
    @StatusChangeSourceId = 3, @StatusChangeReasonId = 4,
    @EventTimestamp = '2026-04-14T14:00:00', @Created = SYSUTCDATETIME();
```

### 8.2 Record reactivation after positive review
```sql
EXEC dbo.AddCurrencyBalancesStatuses @CurrencyBalancesId = 2135699, @StatusType = 0,
    @StatusChangeSourceId = 1, @StatusChangeReasonId = 1,
    @EventTimestamp = '2026-04-14T15:00:00', @Created = SYSUTCDATETIME();
```

### 8.3 Verify status history
```sql
SELECT StatusType, StatusChangeSourceId, StatusChangeReasonId, EventTimestamp
FROM dbo.FiatCurrencyBalancesStatuses WITH (NOLOCK)
WHERE CurrencyBalancesId = 2135699 ORDER BY EventTimestamp;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddCurrencyBalancesStatuses | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddCurrencyBalancesStatuses.sql*
