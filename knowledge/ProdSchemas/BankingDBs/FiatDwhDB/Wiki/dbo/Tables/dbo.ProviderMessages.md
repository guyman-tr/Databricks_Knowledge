# dbo.ProviderMessages

> Audit log of raw messages received from external payment providers (Tribe), stored for debugging, compliance, and operational support.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, non-IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

ProviderMessages stores raw message payloads received from external payment providers (currently Tribe). Each record captures a single webhook, API response, or event notification as received from the provider, preserving the complete message for audit trail, debugging, and compliance purposes.

This table exists because regulatory and operational requirements demand a complete record of all provider communications. When investigating transaction discrepancies, failed payments, or compliance incidents, support teams need to review the exact messages exchanged with the provider. The data warehouse copy provides read-only access to these messages without impacting the operational database.

Data is created by the dbo.AddProviderMessages stored procedure, which receives batches of provider messages (via the dbo.ProviderMessageType TVP) and inserts them. The Id is pre-assigned (not IDENTITY), suggesting the Id comes from the source operational system.

---

## 2. Business Logic

### 2.1 Provider Message Audit Trail

**What**: Complete audit log of all provider communications for compliance and operational support.

**Columns/Parameters Involved**: `Id`, `ProviderId`, `Message`, `Created`

**Rules**:
- Messages are stored as-is from the provider - no transformation or parsing
- Message content is masked (dynamic data masking) to protect sensitive financial data from non-privileged users
- ProviderId identifies the source provider (currently only 1=Tribe)
- Id is externally assigned (not auto-generated), matching the operational system's message ID for cross-referencing

---

## 3. Data Overview

| Id | ProviderId | Message (preview) | Created | Meaning |
|---|---|---|---|---|
| 28767998 | 1 | xxxx (masked) | 2026-04-14 13:32:58 | Most recent Tribe message - content masked for security |
| 28767997 | 1 | xxxx (masked) | 2026-04-14 13:32:54 | Tribe message from 4 seconds earlier |
| 28767996 | 1 | xxxx (masked) | 2026-04-14 13:32:54 | Two messages at same timestamp - batch of provider events |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Externally assigned message identifier (not IDENTITY). Matches the message ID from the operational system for cross-referencing. Primary key. |
| 2 | ProviderId | smallint | YES | - | CODE-BACKED | Identifies the external provider that sent this message. Currently only 1=Tribe. See [Provider](../../_glossary.md#provider). (Dictionary.Providers) |
| 3 | Message | nvarchar(max) MASKED | NO | - | CODE-BACKED | Raw message content from the provider. Typically JSON or XML payloads from webhooks, API responses, or event notifications. Masked with dynamic data masking for PII/financial data protection. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this message was received/recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.Providers | Implicit | Identifies which provider sent this message (1=Tribe) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddProviderMessages | INSERT | Writer | Bulk inserts provider messages via ProviderMessageType TVP |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddProviderMessages | Stored Procedure | Inserts provider messages in bulk |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProviderMessage | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 Get recent provider messages
```sql
SELECT TOP 20 Id, ProviderId, Created
FROM dbo.ProviderMessages WITH (NOLOCK)
ORDER BY Created DESC;
```

### 8.2 Count messages by provider per day
```sql
SELECT CAST(Created AS DATE) AS MessageDate, ProviderId, COUNT(*) AS MessageCount
FROM dbo.ProviderMessages WITH (NOLOCK)
WHERE Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(Created AS DATE), ProviderId
ORDER BY MessageDate DESC;
```

### 8.3 Find messages by ID range (cross-reference with operational system)
```sql
SELECT Id, ProviderId, Message, Created
FROM dbo.ProviderMessages WITH (NOLOCK)
WHERE Id BETWEEN 28767990 AND 28767998
ORDER BY Id;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | TAI messages are queried from ProviderDataSync.ProviderMessages in FiatCustodianDB; the DWH copy follows the same pattern |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProviderMessages | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.ProviderMessages.sql*
