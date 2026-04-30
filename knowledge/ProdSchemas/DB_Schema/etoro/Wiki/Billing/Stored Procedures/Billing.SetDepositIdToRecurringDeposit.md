# Billing.SetDepositIdToRecurringDeposit

> Links a completed deposit transaction to its recurring deposit schedule record, capturing the DepositID, authentication details, 3DS date, and generation number after successful deposit execution.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE on Billing.RecurringDeposit by RecurringDepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Recurring deposits (auto-invest / scheduled deposits) work in two phases: first the recurring schedule is registered (see `Billing.RegisterRecurringExecution`), then the actual deposit is executed and a real `DepositID` is generated. `Billing.SetDepositIdToRecurringDeposit` is the linkage step: it updates the `Billing.RecurringDeposit` record with the actual `DepositID` once the deposit has been processed, along with authentication and 3D Secure details.

The `Generation` column tracks which iteration of a recurring deposit this is (first execution, second execution, etc.), supporting scenarios where the same recurring schedule triggers multiple deposits over time.

Jira: PAYUS-2979 (initial version 20/05/2021) and PAYIL-10393 (updated 06/11/2025).

---

## 2. Business Logic

### 2.1 Deposit ID Linkage

**What**: Simple UPDATE that binds a real DepositID to a recurring deposit schedule record.

**Columns/Parameters Involved**: `@DepositID`, `@RecurringDepositId`, `@AuthenticationID`, `@3dsDate`, `@Generation`

**Rules**:
- UPDATE Billing.RecurringDeposit WHERE RecurringDepositID = @RecurringDepositId.
- Sets DepositID = @DepositID (the actual deposit transaction that was created).
- Sets ModificationDate = GETUTCDATE() (server-side timestamp).
- Sets AuthId = @AuthenticationID (NULL if not authenticated).
- Sets 3dsDate = @3dsDate (NULL if no 3DS challenge performed).
- Sets Generation = ISNULL(@Generation, 0) (defaults to 0 if NULL passed; 0 = first generation).
- Returns: SELECT @@rowcount AS EffectedRows (1 if RecurringDepositID found, 0 if not).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | The DepositID of the successfully executed deposit. Links Billing.RecurringDeposit to the actual Billing.Deposit transaction record. |
| 2 | @RecurringDepositId | INTEGER | NO | - | CODE-BACKED | PK of the Billing.RecurringDeposit record to update. Identifies which scheduled recurring deposit execution this deposit fulfills. |
| 3 | @AuthenticationID | INT | YES | NULL | CODE-BACKED | Authentication record ID associated with this deposit execution (e.g., 3DS authentication ID). NULL if no authentication was required. |
| 4 | @3dsDate | DATETIME | YES | NULL | CODE-BACKED | Timestamp when 3D Secure challenge was completed for this deposit. NULL if no 3DS was triggered. |
| 5 | @Generation | INT | YES | 0 | CODE-BACKED | Which iteration of this recurring deposit schedule this represents. 0=first execution, 1=second, etc. ISNULL(@Generation,0) protects against NULL input. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | EffectedRows | INT | NO | - | CODE-BACKED | Number of rows updated (1 = RecurringDepositID found and updated; 0 = not found). Used by caller to detect missing RecurringDepositID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RecurringDepositID lookup | Billing.RecurringDeposit | UPDATE | Links DepositID to the recurring deposit schedule record |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the recurring deposit processing application after a scheduled deposit is successfully executed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SetDepositIdToRecurringDeposit (procedure)
└── Billing.RecurringDeposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RecurringDeposit | Table | UPDATE target - links DepositID and auth details to schedule record |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses "N rows affected" messages to avoid interfering with EffectedRows output. |
| ISNULL(@Generation, 0) | Default handling | Guarantees Generation is never NULL in the database, even if caller omits or passes NULL. |
| ModificationDate = GETUTCDATE() | Server-side timestamp | Always uses UTC server time; caller cannot override the modification timestamp. |
| EffectedRows = 0 | Soft miss | Returns 0 without error if @RecurringDepositId not found. Caller must check EffectedRows to detect this. |

---

## 8. Sample Queries

### 8.1 Link a deposit to a recurring schedule

```sql
EXEC Billing.SetDepositIdToRecurringDeposit
    @DepositID = 987654321,
    @RecurringDepositId = 555,
    @AuthenticationID = 1122,
    @3dsDate = '2026-03-18 12:34:56',
    @Generation = 1
-- Returns EffectedRows = 1 if updated, 0 if RecurringDepositID not found
```

### 8.2 Link without 3DS (straightforward recurring deposit)

```sql
EXEC Billing.SetDepositIdToRecurringDeposit
    @DepositID = 987654322,
    @RecurringDepositId = 556
-- @AuthenticationID=NULL, @3dsDate=NULL, @Generation=0 (defaults)
```

### 8.3 Verify the update

```sql
SELECT RecurringDepositID, DepositID, AuthId, [3dsDate], Generation, ModificationDate
FROM Billing.RecurringDeposit WITH (NOLOCK)
WHERE RecurringDepositID = 555
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Jira tickets referenced in SQL comments: PAYUS-2979 (initial version 2021) and PAYIL-10393 (2025 update for Generation column or 3DS support).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SetDepositIdToRecurringDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SetDepositIdToRecurringDeposit.sql*
