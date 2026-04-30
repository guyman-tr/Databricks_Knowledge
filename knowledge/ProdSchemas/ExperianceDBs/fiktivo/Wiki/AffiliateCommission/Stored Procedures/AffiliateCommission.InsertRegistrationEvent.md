# AffiliateCommission.InsertRegistrationEvent

> Creates a registration event record for commission tracking and re-evaluation, with an idempotency guard that prevents duplicate events for the same registration.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into RegistrationEvent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertRegistrationEvent creates an event record that enables commission re-evaluation for a registration. When a customer registration is processed, an event is created that can later be picked up by GetRegistrationTriggeredEvents when attribution changes require commission recalculation. The WHERE NOT EXISTS guard ensures only one event per RegistrationID.

---

## 2. Business Logic

### 2.1 Idempotent Event Creation

**What**: Creates one event per registration, silently skipping duplicates.

**Columns/Parameters Involved**: `@RegistrationID`

**Rules**:
- INSERT ... WHERE NOT EXISTS (SELECT 1 FROM RegistrationEvent WHERE RegistrationID = @RegistrationID)
- Captures registration snapshot at creation time

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationID | bigint (IN) | NO | - | CODE-BACKED | Registration identifier. Used for idempotency check. |
| 2 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Attributed affiliate. |
| 3 | @RegistrationDate | datetime (IN) | NO | - | CODE-BACKED | When the customer registered. |
| 4 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 5 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider. |
| 6 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 7 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original provider. |
| 8 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. |
| 9 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID. Added PART-3405. |
| 10 | @LastCheckDate | datetime (IN) | YES | NULL | CODE-BACKED | Initial check date. NULL for new events. |
| 11 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationEvent | WRITE (INSERT) + READ (EXISTS check) | Creates event; checks for duplicates |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called after InsertRegistration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertRegistrationEvent (procedure)
+-- AffiliateCommission.RegistrationEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEvent | Table | INSERT with NOT EXISTS guard |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration pipeline) | External | Creates events for commission tracking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a registration event
```sql
EXEC [AffiliateCommission].[InsertRegistrationEvent]
    @RegistrationID = 100, @AffiliateID = 3, @RegistrationDate = '2026-04-12',
    @CountryID = 1, @ProviderID = 1, @RealProviderID = 1,
    @OriginalProviderID = 1, @CID = 12345, @GCID = 67890, @Source = 'Main'
```

### 8.2 Check existing events for a registration
```sql
SELECT ID, RegistrationID, AffiliateID, RegistrationDate, [Source]
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
WHERE RegistrationID = 100
```

### 8.3 Count registration events by source
```sql
SELECT [Source], COUNT(*) AS EventCount
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3405: Added GCID (2025-01-19)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)
- PART-1195: New SP for Registration Commission (2022-02-22)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertRegistrationEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertRegistrationEvent.sql*
