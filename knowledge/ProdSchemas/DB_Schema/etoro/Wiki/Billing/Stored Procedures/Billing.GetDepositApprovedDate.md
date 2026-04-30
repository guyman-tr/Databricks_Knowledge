# Billing.GetDepositApprovedDate

> Returns the earliest date when a deposit was approved (PaymentStatusID=2), searching both the live Billing.Deposit table and the History.Deposit archive to handle deposits that may have been moved out of the live table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: MIN(ModificationDate) for approved status across live + history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositApprovedDate` finds the precise timestamp when a deposit was first marked as approved (status 2). Deposit records are eventually archived from `Billing.Deposit` (live) to `History.Deposit` (archive). A deposit approved years ago may no longer exist in the live table. This procedure searches BOTH tables via UNION ALL and returns the earliest approval timestamp found in either location.

This is useful for compliance reporting, chargeback investigation, SLA calculations, and any scenario where the exact moment of deposit approval must be determined - especially for older deposits that are only in the archive.

It is called by the `DepositUser` service account, indicating it is part of the deposit processing or inquiry flow.

---

## 2. Business Logic

### 2.1 Live-Plus-Archive Union Pattern

**What**: The approval date is searched in both the live deposit table and the history archive to ensure completeness regardless of archival state.

**Columns/Parameters Involved**: `@DepositID`, `Billing.Deposit.ModificationDate`, `History.Deposit.ModificationDate`, `PaymentStatusID`

**Rules**:
- `Billing.Deposit WHERE DepositID=@DepositID AND PaymentStatusID=2` - current live row if still in live table
- `History.Deposit WHERE DepositID=@DepositID AND PaymentStatusID=2` - historical approved-state rows if deposit has been archived or if status transitions were captured
- UNION ALL (not UNION) - both sets are combined without deduplication, then `MIN(ModificationDate)` picks the earliest
- If the deposit exists in both tables with PaymentStatusID=2 (possible during archival window), MIN ensures the actual first approval date is returned
- If neither table has a row with PaymentStatusID=2 for this DepositID, returns NULL
- Note: no explicit SET NOCOUNT ON - row count messages are emitted to the caller

**Diagram**:
```
@DepositID
  |
  +---> Billing.Deposit (live) WHERE DepositID=@DepositID AND PaymentStatusID=2
  |       -> ModificationDate (if record still in live table)
  |
  +---> History.Deposit (archive) WHERE DepositID=@DepositID AND PaymentStatusID=2
  |       -> ModificationDate (if record archived or historical state captured)
  |
  v
UNION ALL (all matching rows from both)
  |
  v
MIN(ModificationDate) -> earliest approval timestamp
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit primary key to look up. Matches Billing.Deposit.DepositID and History.Deposit.DepositID. |
| 2 | (return value) | DATETIME | YES | - | CODE-BACKED | The earliest ModificationDate where PaymentStatusID=2 (Approved) was recorded for this deposit, across both Billing.Deposit (live) and History.Deposit (archive). Returns NULL if the deposit has never been in Approved status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit.DepositID | Lookup | Searches live deposit table for approval timestamp |
| @DepositID | History.Deposit.DepositID | Lookup | Searches archived deposit records for approval timestamp |
| PaymentStatusID=2 | Dictionary.PaymentStatus | Implicit | Hardcoded filter: 2=Approved - only approval status transitions are considered |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Called by the deposit service to retrieve the approval timestamp for a deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositApprovedDate (procedure)
├── Billing.Deposit (table)
└── History.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - searches live deposit records for PaymentStatusID=2 ModificationDate |
| History.Deposit | Table | READ (cross-schema) - searches archived deposit records for PaymentStatusID=2 ModificationDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls to retrieve deposit approval timestamp |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No SET NOCOUNT ON | Absence | Row-count messages are emitted to caller - potential minor noise in result set handling |
| UNION ALL | Design | Not UNION - includes duplicates before MIN aggregation, ensuring both tables contribute regardless of value overlap |

---

## 8. Sample Queries

### 8.1 Get approval date for a specific deposit

```sql
EXEC Billing.GetDepositApprovedDate @DepositID = 987654;
```

### 8.2 Inline equivalent checking both live and history tables

```sql
SELECT MIN(ModificationDate) AS ApprovedDate
FROM (
    SELECT ModificationDate
    FROM Billing.Deposit WITH (NOLOCK)
    WHERE DepositID = 987654 AND PaymentStatusID = 2
    UNION ALL
    SELECT ModificationDate
    FROM History.Deposit WITH (NOLOCK)
    WHERE DepositID = 987654 AND PaymentStatusID = 2
) a;
```

### 8.3 Check whether deposit exists in live vs. history table

```sql
SELECT 'Live' AS Source, DepositID, PaymentStatusID, ModificationDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 987654

UNION ALL

SELECT 'History' AS Source, DepositID, PaymentStatusID, ModificationDate
FROM History.Deposit WITH (NOLOCK)
WHERE DepositID = 987654;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositApprovedDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositApprovedDate.sql*
