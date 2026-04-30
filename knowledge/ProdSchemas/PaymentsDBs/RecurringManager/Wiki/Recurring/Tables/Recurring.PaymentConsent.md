# Recurring.PaymentConsent

> Tracks consent/authorization documents associated with recurring payment plans, storing document references and timestamps for regulatory compliance (e.g., SCA/PSD2). Currently empty in production.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | PaymentConsentId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK (PAGE compressed) |

---

## 1. Business Meaning

Recurring.PaymentConsent links consent or authorization documents to recurring payment plans. Each row represents a document (identified by DocumentId and DocTypeId) that proves the customer authorized the recurring payment, along with a timestamp recording when consent was given. This supports regulatory requirements such as PSD2/SCA that mandate explicit customer consent for recurring charges.

This table exists to maintain an auditable record of consent per payment plan. Without it, the system would have no way to prove that a customer authorized a specific recurring payment, which could expose the business to regulatory risk and chargeback liability.

Data enters through Recurring.UpsertPaymentConsent, which performs an upsert by PaymentId - each payment has at most one consent record. If consent is renewed (e.g., card re-authentication), the existing row is updated rather than a new one inserted. System-versioned with History.PaymentConsent for audit trail. The table is currently empty in production, suggesting consent tracking may be handled externally or the feature has not yet been activated.

---

## 2. Business Logic

### 2.1 One Consent Per Payment (Upsert Pattern)

**What**: Each payment plan has at most one active consent record, maintained via upsert semantics.

**Columns/Parameters Involved**: `PaymentId`, `DocumentId`, `DocTypeId`, `TimeStemp`

**Rules**:
- UpsertPaymentConsent checks `WHERE PaymentId = @PaymentId` to determine INSERT vs UPDATE
- On UPDATE: DocumentId, DocTypeId, TimeStemp, and ModificationDate are refreshed
- On INSERT: PaymentId, DocumentId, DocTypeId, and TimeStemp are set; CreateDate/ModificationDate auto-default
- This ensures only the most current consent document is tracked per payment, with history preserved via temporal versioning

---

## 3. Data Overview

Table is currently empty (0 rows). No sample data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentConsentId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. PAGE compressed. |
| 2 | PaymentId | int | NO | - | VERIFIED | FK to Recurring.Payment.PaymentId. Identifies which recurring payment plan this consent belongs to. One consent record per payment (enforced by UpsertPaymentConsent upsert logic). |
| 3 | DocumentId | int | NO | - | CODE-BACKED | External reference to the consent document in a document management system. Updated when consent is renewed via UpsertPaymentConsent. |
| 4 | DocTypeId | int | NO | - | CODE-BACKED | Type of consent document. No Dictionary table exists for this in the database - likely references an external document type system. Updated alongside DocumentId on consent renewal. |
| 5 | TimeStemp | datetime2(7) | YES | - | CODE-BACKED | Timestamp of when the customer provided consent. Note: column name contains a typo ("TimeStemp" vs "TimeStamp"). Nullable, set by application code via UpsertPaymentConsent. |
| 6 | CreateDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the consent record was first created. Auto-set via default constraint. |
| 7 | ModificationDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of the last consent update. Set to GETUTCDATE() by UpsertPaymentConsent on every update. |
| 8 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioning row start time (HIDDEN). Auto-managed by temporal tables. |
| 9 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time (HIDDEN). History stored in History.PaymentConsent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentId | Recurring.Payment | Implicit FK | Links this consent document to the recurring payment plan it authorizes |
| - | History.PaymentConsent | System Versioning | Full audit trail of consent changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.UpsertPaymentConsent | - | Stored Procedure (WRITER/MODIFIER) | Upserts consent records by PaymentId |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.UpsertPaymentConsent | Stored Procedure | WRITER/MODIFIER - upserts consent by PaymentId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_PaymentConsent | CLUSTERED (PAGE compressed) | PaymentConsentId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_PaymentConsent | PRIMARY KEY | Clustered on PaymentConsentId, PAGE compressed |
| DF_Recurring_PaymentConsent_CreateDate | DEFAULT | getutcdate() for CreateDate |
| DF_Recurring_PaymentConsent_ModificationDate | DEFAULT | getutcdate() for ModificationDate |
| DF_PaymentConsent_SysStart | DEFAULT | sysutcdatetime() for SysStartTime |
| DF_PaymentConsent_SysEnd | DEFAULT | CONVERT(datetime2, '9999-12-31 23:59:59.9999999') for SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.PaymentConsent |

---

## 8. Sample Queries

### 8.1 Get consent document for a payment
```sql
SELECT pc.PaymentConsentId, pc.PaymentId, pc.DocumentId, pc.DocTypeId,
       pc.TimeStemp, pc.CreateDate, pc.ModificationDate
FROM Recurring.PaymentConsent pc WITH (NOLOCK)
WHERE pc.PaymentId = @PaymentId
```

### 8.2 Find payments with consent records
```sql
SELECT p.PaymentId, p.Cid, p.Amount, p.CurrencyId,
       pc.DocumentId, pc.DocTypeId, pc.TimeStemp
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Recurring.PaymentConsent pc WITH (NOLOCK) ON p.PaymentId = pc.PaymentId
WHERE p.StatusId = 1
```

### 8.3 Audit consent changes via temporal history
```sql
SELECT pc.PaymentId, pc.DocumentId, pc.DocTypeId, pc.TimeStemp,
       pc.SysStartTime, pc.SysEndTime
FROM History.PaymentConsent pc WITH (NOLOCK)
WHERE pc.PaymentId = @PaymentId
ORDER BY pc.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.PaymentConsent | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.PaymentConsent.sql*
