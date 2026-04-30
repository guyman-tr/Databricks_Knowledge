# dbo.ProviderMessageType

> User-defined table type for bulk insertion of raw provider messages into dbo.ProviderMessages.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type mirroring dbo.ProviderMessages structure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ProviderMessageType is a table-valued parameter type that mirrors the structure of dbo.ProviderMessages. It enables bulk insertion of raw messages received from external payment providers (currently Tribe) for audit logging and debugging purposes.

This type exists because the fiat platform receives high volumes of provider messages (webhooks, API responses, event notifications) that need to be stored as an audit trail. Bulk insertion through a TVP is significantly more efficient than individual INSERT statements, especially during high-throughput payment processing periods.

Data flows through this type when the application service layer receives batches of provider messages and needs to persist them. The AddProviderMessages procedure accepts this type and inserts all messages into dbo.ProviderMessages in a single operation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a data-transfer type for audit log bulk insertion.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | YES | - | CODE-BACKED | Pre-assigned identifier for the message record. Nullable to allow the consuming procedure or database to assign IDs if not provided by the caller. |
| 2 | ProviderId | smallint | YES | - | CODE-BACKED | Identifies which external provider sent the message. Currently only 1=Tribe. See [Provider](../../_glossary.md#provider). (Dictionary.Providers) |
| 3 | Message | nvarchar(max) | YES | - | CODE-BACKED | Raw message content from the provider. Typically contains JSON or XML payloads from webhooks, API responses, or event notifications. Stores the full unmodified message for audit and debugging. |
| 4 | Created | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the message was received or recorded. Nullable for flexible TVP population. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.Providers | Implicit | Identifies which external provider sent the message |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddProviderMessages | Parameter | Parameter Type | Accepts batch of provider messages for bulk insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddProviderMessages | Stored Procedure | TVP parameter type for bulk provider message insertion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate with a provider message
```sql
DECLARE @Messages dbo.ProviderMessageType;
INSERT INTO @Messages (Id, ProviderId, Message, Created)
VALUES (1001, 1, '{"event":"card.activated","cardId":"xyz123"}', SYSUTCDATETIME());
EXEC dbo.AddProviderMessages @ProviderMessages = @Messages;
```

### 8.2 Populate with multiple messages from a batch
```sql
DECLARE @Messages dbo.ProviderMessageType;
INSERT INTO @Messages (Id, ProviderId, Message, Created)
VALUES (2001, 1, '{"event":"transaction.authorized","amount":50.00}', SYSUTCDATETIME()),
       (2002, 1, '{"event":"transaction.settled","amount":50.00}', SYSUTCDATETIME()),
       (2003, 1, '{"event":"card.blocked","reason":"risk"}', SYSUTCDATETIME());
EXEC dbo.AddProviderMessages @ProviderMessages = @Messages;
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'ProviderMessageType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProviderMessageType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.ProviderMessageType.sql*
