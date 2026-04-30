# dbo.FiatCardStatuses

> Event-sourced status history table tracking all card lifecycle changes (NotActivated, Activated, Blocked, Suspended, Risk, Stolen, Lost, Expired, Fraud) for each card and card instance.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

FiatCardStatuses records every lifecycle state change for a card. Each row captures a status event - when a card is activated, blocked, reported stolen, expired, etc. The table links to both the logical card (CardId) and the specific card instance (CardInstanceId), enabling status tracking at the instance level.

Data is created by dbo.AddCardStatus. Risk actions from transaction processing (recorded in FiatTransactionsStatuses) can automatically trigger card status changes.

---

## 2. Business Logic

### 2.1 Card Lifecycle with Instance Tracking

**What**: Card statuses track lifecycle events per card instance.

**Columns/Parameters Involved**: `CardId`, `CardStatusId`, `CardInstanceId`, `ExpirationDate`, `EventTimestamp`

**Rules**:
- CardStatusId: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. See [Card Status](../../_glossary.md#card-status).
- Terminal states: Stolen(5), Lost(6), Expired(7), Fraud(8) - card cannot be reactivated
- CardInstanceId links the status to a specific physical/virtual instance (default 0 for legacy records)
- Backup tables (Bck_FiatStatusesCardInstance) preserved data during the CardInstanceId migration

---

## 3. Data Overview

N/A - querying live card status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | CardId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCards.Id. The logical card whose status changed. |
| 3 | CardStatusId | int | NO | - | CODE-BACKED | Status: 0-8. See [Card Status](../../_glossary.md#card-status). (Dictionary.CardStatuses) |
| 4 | ExpirationDate | datetime2(7) | NO | - | CODE-BACKED | Card expiration date at the time of this status event. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the status change occurred in the source system. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |
| 7 | CardInstanceId | bigint | NO | 0 | CODE-BACKED | Implicit ref to dbo.FiatCardInstances.Id. Which physical/virtual card instance this status applies to. Default 0 for legacy records pre-migration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardId | dbo.FiatCards | FK | The logical card |
| CardStatusId | Dictionary.CardStatuses | Implicit | Status value |
| CardInstanceId | dbo.FiatCardInstances | Implicit | The specific card instance |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddCardStatus | INSERT | Writer | Records card status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatCardStatuses (table)
├── dbo.FiatCards (table)
│   └── dbo.FiatAccount (table)
└── dbo.FiatCardInstances (table) [implicit]
    └── dbo.FiatCards (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCards | Table | FK from CardId |
| dbo.FiatCardInstances | Table | Implicit ref from CardInstanceId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddCardStatus | Stored Procedure | Writes status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatCardStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_FiatCardStatuses_CardId | NONCLUSTERED | CardId ASC | - | - | Active |
| IX_FiatCardStatuses_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatCardStatuses_CardId_FiatCards_Id | FK | CardId -> dbo.FiatCards.Id |
| (default) | DEFAULT | CardInstanceId defaults to 0 |

---

## 8. Sample Queries

### 8.1 Get card status history
```sql
SELECT cs.CardStatusId, ds.Name AS Status, cs.CardInstanceId, cs.EventTimestamp, cs.Created
FROM dbo.FiatCardStatuses cs WITH (NOLOCK)
JOIN Dictionary.CardStatuses ds WITH (NOLOCK) ON ds.Id = cs.CardStatusId
WHERE cs.CardId = 105279 ORDER BY cs.EventTimestamp;
```

### 8.2 Find recently blocked/fraud cards
```sql
SELECT cs.CardId, ds.Name AS Status, cs.EventTimestamp
FROM dbo.FiatCardStatuses cs WITH (NOLOCK)
JOIN Dictionary.CardStatuses ds WITH (NOLOCK) ON ds.Id = cs.CardStatusId
WHERE cs.CardStatusId IN (2, 4, 5, 8) AND cs.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY cs.Created DESC;
```

### 8.3 Current status per card
```sql
SELECT c.CardGuid, ds.Name AS CurrentStatus, cs.EventTimestamp
FROM dbo.FiatCards c WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 * FROM dbo.FiatCardStatuses WITH (NOLOCK) WHERE CardId = c.Id ORDER BY Created DESC) cs
JOIN Dictionary.CardStatuses ds WITH (NOLOCK) ON ds.Id = cs.CardStatusId
WHERE c.AccountId = 748744;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Card status queries documented for FiatCustodianDB: `FiatCUG.CardStatuses WHERE CardId=XXXX` |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCardStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCardStatuses.sql*
