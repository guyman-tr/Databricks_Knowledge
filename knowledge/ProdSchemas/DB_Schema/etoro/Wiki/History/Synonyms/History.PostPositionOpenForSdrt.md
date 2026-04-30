# History.PostPositionOpenForSdrt

> Synonym aliasing the DB_Logs database table that records position-open events posted for SDRT (Stamp Duty Reserve Tax) processing, providing History-schema code a local reference to the cross-database SDRT notification log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[PostPositionOpenForSdrt] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PostPositionOpenForSdrt` is a synonym pointing to `[DB_Logs].[History].[PostPositionOpenForSdrt]` in the `DB_Logs` database. SDRT (Stamp Duty Reserve Tax) is a UK tax applied to electronic share transfers - when a customer opens a real stock position in a UK-listed company, SDRT liability may be triggered.

This table logs position-open events that were posted for SDRT assessment or reporting. The "PostPositionOpenForSdrt" name indicates that when a qualifying position is opened, an event record is posted here so the SDRT compliance system can process it - calculating the tax liability, generating the required tax records, or notifying reporting systems.

The synonym provides the History schema with a local alias for querying SDRT event data alongside other position history data for compliance reporting and reconciliation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). The SDRT posting logic resides in the trade engine. See `[DB_Logs].[History].[PostPositionOpenForSdrt]` for the event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[PostPositionOpenForSdrt]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table in DB_Logs.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[PostPositionOpenForSdrt] | Synonym | Points to the SDRT position-open event log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PostPositionOpenForSdrt (synonym)
+-- [DB_Logs].[History].[PostPositionOpenForSdrt] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[PostPositionOpenForSdrt] | External Table | Target of this synonym |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query SDRT position open events

```sql
SELECT TOP 10 *
FROM History.PostPositionOpenForSdrt WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'PostPositionOpenForSdrt'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 List all DB_Logs synonyms related to position events

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.base_object_name LIKE '%DB_Logs%'
  AND s.name LIKE '%Position%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PostPositionOpenForSdrt | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.PostPositionOpenForSdrt.sql*
