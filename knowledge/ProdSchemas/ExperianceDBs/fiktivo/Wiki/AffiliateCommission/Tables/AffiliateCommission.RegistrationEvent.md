# AffiliateCommission.RegistrationEvent

> Event tracking table for customer registrations, storing the full context for each registration event as it flows through the affiliate commission attribution pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | RegistrationID (bigint, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (NC PK + CDX on ID + 2 NC) |

---

## 1. Business Meaning

RegistrationEvent is the event-level tracking table for registration commission processing. While Registration stores the final processed state, RegistrationEvent tracks each registration as it flows through attribution checks. It captures the initial event details, organic/non-organic attribution status (NonOrganicUpdated), and processing metadata (Source, LastCheckDate).

The table currently holds only 176 rows, indicating it contains only actively in-flight events. Processed events are cleaned up by RemoveRegistrationEvent and RemoveRegistrationExpiredEvents. This is the same transient queue pattern used by ClosedPositionEvent (4 rows) and CreditEvent (1.32M rows - higher volume in credit domain).

---

## 2. Business Logic

### 2.1 Registration Attribution Pipeline

**What**: Each registration event goes through organic/non-organic attribution checks.

**Columns/Parameters Involved**: `NonOrganicUpdated`, `LastCheckDate`, `Source`, `AffiliateID`

**Rules**:
- Events are created by InsertRegistrationEvent
- NonOrganicUpdated tracks when the organic vs affiliate check was performed
- After processing, events are deleted (transient storage)
- Source identifies the processing node (e.g., "AzureWestEurope")

---

## 3. Data Overview

N/A - table contains only 176 active in-flight events.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. CDX for ordered processing. |
| 2 | RegistrationID | bigint | NO | - | CODE-BACKED | Registration this event tracks. NC PK. References Registration.RegistrationID. |
| 3 | RegistrationDate | datetime | NO | - | CODE-BACKED | Registration timestamp. |
| 4 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 5 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider. |
| 6 | RealProviderID | bigint | NO | - | CODE-BACKED | Execution entity. |
| 7 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. |
| 8 | CID | bigint | NO | - | CODE-BACKED | Customer ID. Indexed with NonOrganicUpdated. |
| 9 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer in copy-trading. |
| 10 | LastCheckDate | datetime | YES | - | CODE-BACKED | Last pipeline examination timestamp. |
| 11 | Source | nvarchar(50) | YES | - | CODE-BACKED | Processing node identifier. |
| 12 | DateModified | datetime | NO | getutcdate() | CODE-BACKED | Last modification timestamp. |
| 13 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | Non-organic attribution check timestamp. |
| 14 | AffiliateID | int | NO | - | CODE-BACKED | Attributed affiliate. |
| 15 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegistrationID | AffiliateCommission.Registration | Implicit FK | Parent registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.RegistrationEventVW | JOIN | View | Event view with attribution |
| AffiliateCommission.InsertRegistrationEvent | INSERT | Writer |
| AffiliateCommission.RemoveRegistrationEvent | DELETE | Deleter |
| AffiliateCommission.RemoveRegistrationExpiredEvents | DELETE | Deleter |
| AffiliateCommission.GetRegistrationTriggeredEvents | SELECT | Reader |
| AffiliateCommission.UpdateRegistrationEventLastCheckDate | UPDATE | Modifier |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RegistrationEvent (table)
└── AffiliateCommission.Registration (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | RegistrationID references registration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEventVW | View | Reads with RegistrationMetaData |
| AffiliateCommission.InsertRegistrationEvent | Stored Procedure | Writer |
| AffiliateCommission.RemoveRegistrationEvent | Stored Procedure | Deleter |
| AffiliateCommission.RemoveRegistrationExpiredEvents | Stored Procedure | Deleter |
| AffiliateCommission.GetRegistrationTriggeredEvents | Stored Procedure | Reader |
| AffiliateCommission.UpdateRegistrationEventLastCheckDate | Stored Procedure | Modifier |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegistrationEvent | NC PK | RegistrationID ASC | - | - | Active |
| CDX_RegistrationEvent_ID | CLUSTERED | ID ASC | - | - | Active |
| IX_RegistrationEvent_CIDNonOrganicUpdated | NC | CID, NonOrganicUpdated | - | - | Active |
| IX_RegistrationEvent_RegistrationDateSource | NC | RegistrationDate, Source | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RegistrationEvent | PRIMARY KEY | Unique RegistrationID (nonclustered) |
| DF_RegistrationEvent_DateModified | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Active registration events
```sql
SELECT RegistrationID, RegistrationDate, CID, AffiliateID, GCID,
       Source, NonOrganicUpdated, LastCheckDate
FROM AffiliateCommission.RegistrationEvent WITH (NOLOCK)
ORDER BY ID DESC;
```

### 8.2 Events needing organic check
```sql
SELECT RegistrationID, CID, AffiliateID, RegistrationDate
FROM AffiliateCommission.RegistrationEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL;
```

### 8.3 Event with registration context
```sql
SELECT e.RegistrationID, e.RegistrationDate, e.CID, e.AffiliateID,
       r.Valid, r.IsProcessed
FROM AffiliateCommission.RegistrationEvent e WITH (NOLOCK)
JOIN AffiliateCommission.Registration r WITH (NOLOCK) ON e.RegistrationID = r.RegistrationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationEvent | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.RegistrationEvent.sql*
