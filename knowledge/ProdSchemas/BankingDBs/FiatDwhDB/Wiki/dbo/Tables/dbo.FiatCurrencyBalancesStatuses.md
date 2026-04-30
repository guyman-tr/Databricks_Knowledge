# dbo.FiatCurrencyBalancesStatuses

> Event-sourced status history table tracking all lifecycle changes for currency balances, including the source and reason for each change.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

FiatCurrencyBalancesStatuses records every status change event for a currency balance. Each row captures when a balance transitioned between states (Active, ReceiveOnly, SpendOnly, Suspended, Blocked), who/what initiated the change, and why. This provides a complete audit trail for compliance and support.

Data is created by dbo.AddCurrencyBalancesStatuses when the operational system reports a balance status change.

---

## 2. Business Logic

### 2.1 Balance Status Lifecycle with Source and Reason

**What**: Complete audit trail of currency balance status changes with attribution.

**Columns/Parameters Involved**: `StatusType`, `StatusChangeSourceId`, `StatusChangeReasonId`, `EventTimestamp`

**Rules**:
- StatusType: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. See [Currency Balance Status](../../_glossary.md#currency-balance-status).
- StatusChangeSourceId: Who initiated - 0=Unknown, 1=ProgramManager, 2=ProviderBO, 3=ProviderSystem, 4=ExternalProvider. See [Status Change Source](../../_glossary.md#status-change-source).
- StatusChangeReasonId: Why - 0=Unknown through 19=UnknownSourceOfFunds. See [Status Change Reason](../../_glossary.md#status-change-reason).
- EventTimestamp vs Created: EventTimestamp is when the event occurred in the source system; Created is when it was recorded in the DWH.

---

## 3. Data Overview

N/A - querying live status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CurrencyBalancesId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. The balance whose status changed. |
| 3 | StatusType | int | NO | - | CODE-BACKED | Balance status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. See [Currency Balance Status](../../_glossary.md#currency-balance-status). (Dictionary.CurrencyBalanceStatuses) |
| 4 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the status change occurred in the source system. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |
| 6 | StatusChangeSourceId | tinyint | YES | - | CODE-BACKED | Who initiated the change: 0-4. See [Status Change Source](../../_glossary.md#status-change-source). (Dictionary.StatusChangeSources). Nullable for legacy records. |
| 7 | StatusChangeReasonId | tinyint | YES | - | CODE-BACKED | Why the change was made: 0-19. See [Status Change Reason](../../_glossary.md#status-change-reason). (Dictionary.StatusChangeReasons). Nullable for legacy records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyBalancesId | dbo.FiatCurrencyBalances | FK | The balance whose status changed |
| StatusType | Dictionary.CurrencyBalanceStatuses | Implicit | Status value |
| StatusChangeSourceId | Dictionary.StatusChangeSources | Implicit | Who initiated |
| StatusChangeReasonId | Dictionary.StatusChangeReasons | Implicit | Why it changed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddCurrencyBalancesStatuses | INSERT | Writer | Records status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatCurrencyBalancesStatuses (table)
└── dbo.FiatCurrencyBalances (table)
    ├── dbo.FiatAccount (table)
    └── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | FK from CurrencyBalancesId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddCurrencyBalancesStatuses | Stored Procedure | Writes status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatCurrencyBalancesStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_FiatCurrencyBalancesStatuses_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatCurrencyBalancesStatuses_CurrencyBalancesId_FiatCurrencyBalances_Id | FK | CurrencyBalancesId -> dbo.FiatCurrencyBalances.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a currency balance
```sql
SELECT s.StatusType, ds.Name AS Status, sc.Name AS Source, sr.Name AS Reason, s.EventTimestamp, s.Created
FROM dbo.FiatCurrencyBalancesStatuses s WITH (NOLOCK)
JOIN Dictionary.CurrencyBalanceStatuses ds WITH (NOLOCK) ON ds.Id = s.StatusType
LEFT JOIN Dictionary.StatusChangeSources sc WITH (NOLOCK) ON sc.Id = s.StatusChangeSourceId
LEFT JOIN Dictionary.StatusChangeReasons sr WITH (NOLOCK) ON sr.Id = s.StatusChangeReasonId
WHERE s.CurrencyBalancesId = 2135699 ORDER BY s.EventTimestamp;
```

### 8.2 Find recently suspended balances with reasons
```sql
SELECT s.CurrencyBalancesId, sr.Name AS Reason, sc.Name AS Source, s.EventTimestamp
FROM dbo.FiatCurrencyBalancesStatuses s WITH (NOLOCK)
LEFT JOIN Dictionary.StatusChangeReasons sr WITH (NOLOCK) ON sr.Id = s.StatusChangeReasonId
LEFT JOIN Dictionary.StatusChangeSources sc WITH (NOLOCK) ON sc.Id = s.StatusChangeSourceId
WHERE s.StatusType = 3 AND s.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY s.Created DESC;
```

### 8.3 Count status changes by reason
```sql
SELECT sr.Name AS Reason, COUNT(*) AS Cnt
FROM dbo.FiatCurrencyBalancesStatuses s WITH (NOLOCK)
JOIN Dictionary.StatusChangeReasons sr WITH (NOLOCK) ON sr.Id = s.StatusChangeReasonId
WHERE s.Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY sr.Name ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCurrencyBalancesStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCurrencyBalancesStatuses.sql*
