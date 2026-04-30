# Dictionary.DepositDRStatus

> Lookup table defining the lifecycle states of deposit dispute resolution (DR) cases — from initial filing through rejection or completion.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DepositDRStatusID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a deposit is disputed (typically through a chargeback initiated by the cardholder or their bank), a dispute resolution (DR) case is created. This table defines the four states of that dispute process: not applicable (NA), pending review (Pending), dispute rejected (Rejected), and dispute resolved (Completed).

Without this table, the platform would have no way to track the current stage of deposit disputes. Dispute resolution is a critical financial operations process — pending disputes represent potential liability, rejected disputes mean the deposit stands, and completed disputes result in funds being returned.

No procedures or views in the etoro SSDT project reference this table directly, suggesting it is consumed by application-layer payment dispute workflows or external PSP integration services.

---

## 2. Business Logic

### 2.1 Dispute Resolution Lifecycle

**What**: Deposit disputes follow a linear lifecycle from filing to resolution.

**Columns/Parameters Involved**: `DepositDRStatusID`, `Name`

**Rules**:
- NA (0) means no dispute has been filed for this deposit — the default state
- Pending (1) means a dispute has been filed and is awaiting review by the payment team
- Rejected (2) means the dispute was reviewed and denied — the original deposit stands
- Completed (3) means the dispute was resolved (typically in the cardholder's favor) — funds are returned

**Diagram**:
```
NA (0) ──► Pending (1) ──► Rejected (2)   [dispute denied, deposit stands]
                        └─► Completed (3)  [dispute upheld, funds returned]
```

---

## 3. Data Overview

| DepositDRStatusID | Name | Meaning |
|---|---|---|
| 0 | NA | No dispute resolution case exists for this deposit — the deposit has not been challenged by the cardholder or their bank |
| 1 | Pending | A dispute/chargeback has been filed and is under review — the payment team is gathering evidence to represent the transaction or accept the dispute |
| 2 | Rejected | The dispute was reviewed and rejected (either by the payment team internally or by the card network arbitration) — the original deposit is confirmed valid |
| 3 | Completed | The dispute process is complete — the disputed amount has been resolved, typically resulting in a chargeback debit to eToro's merchant account |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositDRStatusID | int | NO | - | CODE-BACKED | Primary key identifying the dispute resolution status. 0=NA (no dispute), 1=Pending, 2=Rejected, 3=Completed. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable dispute status name. Nullable in DDL but all 4 rows have values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct SQL consumers found in the etoro SSDT project. Likely consumed by application-layer payment dispute management services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositDRStatus (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DepositDRStatus_ID | CLUSTERED | DepositDRStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all dispute resolution statuses
```sql
SELECT  DepositDRStatusID,
        Name
FROM    Dictionary.DepositDRStatus WITH (NOLOCK)
ORDER BY DepositDRStatusID
```

### 8.2 Find deposits with active disputes (conceptual)
```sql
SELECT  d.DepositID,
        d.CID,
        drs.Name AS DisputeStatus
FROM    Billing.Deposit d WITH (NOLOCK)
        JOIN Dictionary.DepositDRStatus drs WITH (NOLOCK) ON d.DepositDRStatusID = drs.DepositDRStatusID
WHERE   d.DepositDRStatusID = 1  -- Pending
```

### 8.3 Dispute resolution outcome distribution (conceptual)
```sql
SELECT  drs.Name AS DisputeStatus,
        COUNT(*) AS DisputeCount
FROM    Billing.Deposit d WITH (NOLOCK)
        JOIN Dictionary.DepositDRStatus drs WITH (NOLOCK) ON d.DepositDRStatusID = drs.DepositDRStatusID
WHERE   d.DepositDRStatusID > 0  -- Exclude NA
GROUP BY drs.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositDRStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositDRStatus.sql*
