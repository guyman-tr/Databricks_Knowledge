# Tribe.CardsSnapshots_CardSnapshot-140457

> Primary child table storing detailed card snapshot records from Tribe, including card status, program, holder details, limits, and activation dates.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

CardsSnapshots_CardSnapshot-140457 is the primary data child table for card snapshots. Contains 30+ columns covering card details: program, product, holder, card number/status/expiration, activation dates, status change info, and limits. Parent: CardsSnapshots-890718.

Key columns include: HolderId, CardNumber, CardNumberId, IsVirtual, CardStatusCode, CardStatusCodeDescription, CardStatusChangeSource/ReasonCode/Note, CardExpirationDate, CardCreationDate, CardActivationDate, LimitsGroupName/Id, ProgramName/Id, ProductName/Id.

---

## 2. Business Logic

### 2.1 Card State Snapshot

**What**: Point-in-time capture of card configuration and status.

**Key Column Groups**:
- Identity: HolderId, CardNumber, CardNumberId, CardRequestId
- Program: ProgramName, ProgramId, ProductName, ProductId, SubProductId
- Status: CardStatusCode, CardStatusCodeDescription, CardStatusDate
- Status Change: CardStatusChangeSource, CardStatusChangeReasonCode, CardStatusChangeNote, CardStatusChangeOriginatorId
- Dates: CardCreationDate, CardActivationDate, CardExpirationDate
- Limits: LimitsGroupName, LimitsGroupId

---

## 3. Data Overview

N/A - raw provider snapshot data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @CardsSnapshots@Id-890718 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | HolderId | nvarchar(4000) | YES | - | CODE-BACKED | Tribe holder ID. |
| 5 | CardStatusCode | nvarchar(4000) | YES | - | CODE-BACKED | Card status code from Tribe. |
| 6 | CardStatusCodeDescription | nvarchar(4000) | YES | - | CODE-BACKED | Human-readable status description. |
| 7 | IsVirtual | nvarchar(4000) | YES | - | CODE-BACKED | Whether virtual card. |
| 8 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(30+ additional columns - see DDL for full list)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardsSnapshots@Id-890718 | Tribe.CardsSnapshots-890718 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.CardsSnapshots_CardSnapshot-140457 (table)
└── Tribe.CardsSnapshots-890718 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.CardsSnapshots-890718 | Table | Parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK | CLUSTERED | @Id ASC | - | - | Active |
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent snapshots with status
```sql
SELECT TOP 10 [@Id], HolderId, CardStatusCode, CardStatusCodeDescription, IsVirtual, Created
FROM Tribe.[CardsSnapshots_CardSnapshot-140457] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Find cards by holder
```sql
SELECT CardStatusCode, CardStatusCodeDescription, CardExpirationDate, CardActivationDate
FROM Tribe.[CardsSnapshots_CardSnapshot-140457] WITH (NOLOCK)
WHERE HolderId = '12345' ORDER BY Created DESC;
```

### 8.3 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.HolderId, c.CardStatusCode, c.ProgramName
FROM Tribe.[CardsSnapshots-890718] p WITH (NOLOCK)
JOIN Tribe.[CardsSnapshots_CardSnapshot-140457] c WITH (NOLOCK) ON c.[@CardsSnapshots@Id-890718] = p.[@Id]
ORDER BY c.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.CardsSnapshots_CardSnapshot-140457 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.CardsSnapshots_CardSnapshot-140457.sql*
