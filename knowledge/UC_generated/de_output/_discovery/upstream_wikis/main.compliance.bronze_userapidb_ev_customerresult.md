# Ev.CustomerResult

> Stores the outcome of each Electronic Verification attempt per user, including provider, status, and transaction details.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Table |
| **Key Identifier** | CustomerEvResultId (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + 2 NC on GCID) |

---

## 1. Business Meaning

Ev.CustomerResult records the outcome of every Electronic Verification attempt for each user. Multiple results may exist per GCID (multiple verification attempts). Each row links to an EV provider, EV status (pass/fail/partial), and optionally a provider transaction ID. History.EvRequest stores the detailed XML request/response for each result.

---

## 2. Business Logic

No complex multi-column business logic. EV attempt result store.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerEvResultId | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. EV result record ID. Referenced by History.EvRequest. |
| 2 | GCID | int | NO | - | CODE-BACKED | User who was verified. Multiple results per user. |
| 3 | EvStatusId | int | YES | - | CODE-BACKED | FK to Dictionary.EvStatus. Outcome: 0=None, 1=One Source, 2=Two Sources, 5=Approved, 6=Rejected. See [EV Status](_glossary.md#ev-status). |
| 4 | EvProviderId | int | YES | - | CODE-BACKED | FK to Dictionary.EvProvider. Which provider performed this verification. See [EV Provider](_glossary.md#ev-provider). |
| 5 | TransactionID | varchar(250) | YES | - | CODE-BACKED | Provider's transaction/reference ID for this verification attempt. |
| 6 | TransactionDate | datetime | YES | - | CODE-BACKED | When the verification transaction occurred. |
| 7 | VerificationType | int | YES | - | CODE-BACKED | Type of verification performed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EvStatusId | Dictionary.EvStatus | Explicit FK | Verification outcome |
| EvProviderId | Dictionary.EvProvider | Explicit FK | Provider used |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.EvRequest | CustomerEvResultId | Explicit FK | Detailed request/response |
| Ev.CreateCustomerResultAndHistory | CustomerEvResultId | SP writes | Creates result + history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.CustomerResult (table)
  +-- Dictionary.EvStatus (table) [done]
  +-- Dictionary.EvProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvStatus | Table | FK: EvStatusId |
| Dictionary.EvProvider | Table | FK: EvProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.EvRequest | Table | FK: CustomerEvResultId |
| Ev.CreateCustomerResultAndHistory | SP | INSERT INTO |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EvCustomerResult | CLUSTERED PK | CustomerEvResultId | - | - | Active (PAGE compressed) |
| Idx_CustomerResult_GCID | NC | GCID, CustomerEvResultId | EvStatusId, EvProviderId | - | Active (PAGE compressed) |
| Idx_CustomerResult_GCID_Covered | NC | GCID | EvStatusId, EvProviderId, TransactionID, TransactionDate, VerificationType | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EvCustomerResultEvStatus | FOREIGN KEY | EvStatusId -> Dictionary.EvStatus |
| FK_EvCustomerResultProvider | FOREIGN KEY | EvProviderId -> Dictionary.EvProvider |

---

## 8. Sample Queries

### 8.1 EV results for a user
```sql
SELECT cr.CustomerEvResultId, es.Name AS Status, ep.Name AS Provider, cr.TransactionDate
FROM Ev.CustomerResult cr WITH (NOLOCK)
LEFT JOIN Dictionary.EvStatus es WITH (NOLOCK) ON cr.EvStatusId = es.EvStatusId
LEFT JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON cr.EvProviderId = ep.EvProviderId
WHERE cr.GCID = @GCID ORDER BY cr.CustomerEvResultId DESC
```

### 8.2 Latest result for a user
```sql
SELECT TOP 1 * FROM Ev.CustomerResult WITH (NOLOCK) WHERE GCID = @GCID ORDER BY CustomerEvResultId DESC
```

### 8.3 Results by status
```sql
SELECT es.Name, COUNT(*) FROM Ev.CustomerResult cr WITH (NOLOCK)
JOIN Dictionary.EvStatus es WITH (NOLOCK) ON cr.EvStatusId = es.EvStatusId GROUP BY es.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Ev.CustomerResult | Type: Table | Source: UserApiDB/UserApiDB/Ev/Tables/Ev.CustomerResult.sql*
