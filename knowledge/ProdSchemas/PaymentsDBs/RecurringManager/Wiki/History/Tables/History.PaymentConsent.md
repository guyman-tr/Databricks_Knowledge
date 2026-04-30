# History.PaymentConsent

> Temporal history table storing previous versions of payment consent document records, tracking changes to the legal/regulatory consent documents associated with recurring payments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentConsentId (mirrors PK of Recurring.PaymentConsent) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.PaymentConsent is the system-versioned temporal history table for `Recurring.PaymentConsent`. Each row would represent a previous state of a consent document record - the legal/regulatory document that a customer acknowledges or signs to authorize a recurring payment. The consent links a specific document (by DocumentId and DocTypeId) to a payment, with a timestamp recording when the consent was captured.

This table exists to provide an audit trail of consent document changes. In regulated payment processing, maintaining a history of which consent documents were in effect at any point in time is critical for compliance and dispute resolution. If a consent document is updated (e.g., a new version of terms and conditions), the old version is preserved here.

Data enters this table automatically via SQL Server's temporal mechanism when rows in `Recurring.PaymentConsent` are updated or deleted. The sole procedure that modifies the base table is `Recurring.UpsertPaymentConsent`, which performs an upsert: one consent record per PaymentId. When an existing consent is updated (new DocumentId, DocTypeId, or TimeStemp), the previous version moves to this history table. Currently, the history table contains 0 rows, indicating that no consent records have been modified since the system was deployed.

---

## 2. Business Logic

### 2.1 One-Consent-Per-Payment Pattern

**What**: Each recurring payment has exactly one active consent record at any time, managed via an upsert pattern.

**Columns/Parameters Involved**: `PaymentId`, `DocumentId`, `DocTypeId`, `TimeStemp`

**Rules**:
- `Recurring.UpsertPaymentConsent` checks `WHERE PaymentId = @PaymentId` to determine if a consent exists
- If exists: UPDATE DocumentId, DocTypeId, TimeStemp, and ModificationDate
- If not exists: INSERT a new consent record
- This ensures a 1:1 relationship between Payment and PaymentConsent at any point in time
- When an UPDATE occurs, the old version moves to History.PaymentConsent via temporal versioning

### 2.2 Temporal Versioning

**What**: Automatic audit trail of consent changes via SQL Server system-versioned temporal tables.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, all data columns

**Rules**:
- SysStartTime records when a version became active; SysEndTime records when it was superseded
- Point-in-time queries reconstruct which consent document was in effect at any given date
- The 0-row state indicates all current consent records are still in their original state (never modified)

---

## 3. Data Overview

No historical data exists in this table. The history table contains 0 rows, meaning no consent records in Recurring.PaymentConsent have been modified or deleted since the system was deployed.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentConsentId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Recurring.PaymentConsent. Identifies which consent record this historical version belongs to. |
| 2 | PaymentId | int | NO | - | CODE-BACKED | References the recurring payment this consent is associated with. Links to Recurring.Payment / History.Payment. Used as the lookup key in `Recurring.UpsertPaymentConsent` (`WHERE PaymentId = @PaymentId`), enforcing a 1:1 relationship between payment and consent. |
| 3 | DocumentId | int | NO | - | CODE-BACKED | Identifier of the consent document in an external document management system. Updated via UpsertPaymentConsent when the consent document changes (e.g., new document version signed by the customer). |
| 4 | DocTypeId | int | NO | - | NAME-INFERRED | Classifies the type of consent document (e.g., terms and conditions, payment authorization, regulatory disclosure). No Dictionary lookup table exists within RecurringManager - likely an external document type reference. Updated alongside DocumentId during consent changes. |
| 5 | TimeStemp | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the consent was captured or signed by the customer. Note: column name is a misspelling of "TimeStamp" (preserved as-is in the schema). Passed as @TimeStemp parameter to UpsertPaymentConsent. Nullable - may be NULL if the consent timestamp was not captured. |
| 6 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the consent record was originally created. DEFAULT: getutcdate(). Set automatically on INSERT by the default constraint. Immutable after creation. |
| 7 | ModificationDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent update to the consent record. DEFAULT: getutcdate(). Set to GETUTCDATE() by UpsertPaymentConsent on UPDATE operations. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version became active. Part of the clustered index for efficient temporal queries. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded. Part of the clustered index. Together with SysStartTime defines the validity period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.PaymentConsent | Temporal History | This is the system-versioned history table for Recurring.PaymentConsent |
| PaymentId | Recurring.Payment / History.Payment | Implicit FK | The recurring payment this consent authorizes. 1:1 relationship enforced by UpsertPaymentConsent's WHERE clause |

### 5.2 Referenced By (other objects point to this)

No objects reference this history table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a history table managed by SQL Server's temporal mechanism.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentConsent | Table | This is the temporal history table for that base table (SYSTEM_VERSIONING = ON) |
| Recurring.UpsertPaymentConsent | Stored Procedure | WRITER/MODIFIER - upserts consent records in the base table, generating history on updates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PaymentConsent | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression is enabled.

### 7.2 Constraints

None. The base table (Recurring.PaymentConsent) holds:
- PK_Recurring_PaymentConsent (PK on PaymentConsentId, PAGE compressed)
- DF_Recurring_PaymentConsent_CreateDate (DEFAULT getutcdate())
- DF_Recurring_PaymentConsent_ModificationDate (DEFAULT getutcdate())

---

## 8. Sample Queries

### 8.1 View consent document history for a payment
```sql
SELECT PaymentConsentId, PaymentId, DocumentId, DocTypeId,
       TimeStemp, SysStartTime AS VersionStart, SysEndTime AS VersionEnd
FROM History.PaymentConsent WITH (NOLOCK)
WHERE PaymentId = 100
ORDER BY SysStartTime ASC
```

### 8.2 Reconstruct which consent was in effect at a specific date
```sql
SELECT *
FROM Recurring.PaymentConsent
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
WHERE PaymentId = 100
```

### 8.3 Find all consent changes with before/after comparison
```sql
SELECT h.PaymentId, h.DocumentId AS OldDocumentId, h.DocTypeId AS OldDocType,
       c.DocumentId AS CurrentDocumentId, c.DocTypeId AS CurrentDocType,
       h.SysEndTime AS ChangedAt
FROM History.PaymentConsent h WITH (NOLOCK)
JOIN Recurring.PaymentConsent c WITH (NOLOCK) ON c.PaymentId = h.PaymentId
ORDER BY h.SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 7.5/10 (Elements: 8.9/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PaymentConsent | Type: Table | Source: RecurringManager/History/Tables/History.PaymentConsent.sql*
