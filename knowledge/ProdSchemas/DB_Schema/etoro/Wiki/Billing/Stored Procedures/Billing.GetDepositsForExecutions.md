# Billing.GetDepositsForExecutions

> Returns deposit details for a set of recurring deposit execution IDs, resolving each ExecutionID through Billing.RecurringDeposit to its associated deposit record with status, risk, gateway, and last payment response information.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deposit rows for each ExecutionID in @ExecutionIDs that has an associated deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositsForExecutions` is the deposit status lookup for the recurring deposit (subscription payment) system. Given a batch of ExecutionIDs, it resolves each one to its associated deposit record and returns a summary of the deposit's current state: status, risk management status, gateway, retry count, and the last payment processor response.

The recurring deposit workflow (auto-debit/subscription) creates execution records in `Billing.RecurringDeposit`; each execution has an `ExecutionID` and, if a deposit was initiated, a linked `DepositID`. This SP is the bridge that answers: "for these recurring payment executions, what happened with the deposit?"

No GRANT EXECUTE found in SSDT permissions files - caller is likely an internal service with elevated DB access or a non-SSDT-tracked account.

---

## 2. Business Logic

### 2.1 ExecutionID-to-Deposit Resolution

**What**: Drives from the caller-provided set of ExecutionIDs and resolves each to its linked deposit via Billing.RecurringDeposit.

**Columns/Parameters Involved**: `@ExecutionIDs`, `Billing.RecurringDeposit.ExecutionID`, `Billing.RecurringDeposit.DepositID`

**Rules**:
- `FROM @ExecutionIDs AS ExecutionID` - table-valued parameter as the outer drive table
- `LEFT JOIN Billing.RecurringDeposit ON ExecutionID.ID = RecurringDeposit.ExecutionID` - one execution may have zero or one recurring deposit record
- `LEFT JOIN Billing.Deposit ON RecurringDeposit.DepositID` - the deposit linked to this recurring execution
- `WHERE Deposit.DepositID IS NOT NULL` - excludes ExecutionIDs with no linked deposit (executions that were created but deposit not yet initiated, or executions with no matching RecurringDeposit row)

### 2.2 Batch Input via Table-Valued Parameter

**What**: Accepts multiple ExecutionIDs in a single call using `BackOffice.IDs` (a user-defined table type with a single `ID INT` column and clustered primary key).

**Rules**:
- `@ExecutionIDs AS BackOffice.IDs READONLY` - caller passes a table variable of INT IDs
- `BackOffice.IDs` is defined as `TABLE ([ID] INT NOT NULL, PRIMARY KEY CLUSTERED (ID ASC))` - enforces uniqueness per call
- READONLY parameter mode - SP cannot modify the input table
- Enables single round-trip bulk lookup instead of N individual SP calls

### 2.3 Payment Response Lookup

**What**: Includes the last payment processor response for each deposit.

**Columns/Parameters Involved**: `History.DepositAction.ResponseID`, `Dictionary.Response.ResponseName`, `ResponseID (output)`, `ResponseName (output)`

**Rules**:
- `LEFT JOIN History.DepositAction ON DepositActionID = DepositID AND ResponseID IS NOT NULL` - joins to ANY DepositAction row where ResponseID is not null
- NOTE: No TOP 1 or ORDER BY on DepositAction - if multiple actions have non-null ResponseIDs, this produces multiple result rows per deposit. Caller must handle potential row multiplication.
- `LEFT JOIN Dictionary.Response ON ResponseID` - resolves to human-readable response name

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of execution IDs to look up. BackOffice.IDs type: single INT column `ID`, clustered PK. Each ID is a Billing.RecurringDeposit.ExecutionID. |
| 2 | DepositID (output) | INT | NO | - | CODE-BACKED | Primary key of the deposit associated with this execution. Never NULL in output (WHERE Deposit.DepositID IS NOT NULL filter). |
| 3 | RetryNumber (output) | INT | YES | - | CODE-BACKED | Retry count for this recurring deposit execution from Billing.RecurringDeposit. 0 for first attempt, increments on each retry. |
| 4 | PaymentDate (output) | DATETIME | YES | - | CODE-BACKED | UTC timestamp when the deposit was submitted (Billing.Deposit.PaymentDate). |
| 5 | ExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate from deposit currency to USD at processing time. |
| 6 | DepotID (output) | INT | YES | - | CODE-BACKED | FK to Billing.Depot - the payment gateway that processed this deposit. |
| 7 | DepotName (output) | VARCHAR | YES | - | CODE-BACKED | Human-readable gateway name from Billing.Depot. |
| 8 | ExecutionID (output) | INT | YES | - | CODE-BACKED | The recurring deposit execution ID from Billing.RecurringDeposit. Mirrors the input @ExecutionIDs. |
| 9 | PaymentStatusName (output) | VARCHAR | YES | - | CODE-BACKED | Human-readable deposit status from Dictionary.PaymentStatus (e.g., 'Approved', 'Pending', 'Declined'). |
| 10 | PaymentStatusID (output) | INT | YES | - | CODE-BACKED | Raw status ID from Billing.Deposit.PaymentStatusID. |
| 11 | RiskManagementStatusID (output) | INT | YES | - | CODE-BACKED | Raw risk management status ID from Billing.Deposit.RiskManagementStatusID. |
| 12 | RiskManagementStatusName (output) | VARCHAR | YES | - | CODE-BACKED | Human-readable risk status from Dictionary.RiskManagementStatus. |
| 13 | ResponseID (output) | INT | YES | - | CODE-BACKED | Last payment processor response ID from History.DepositAction. NULL if no action with a response exists. |
| 14 | ResponseName (output) | VARCHAR | YES | - | CODE-BACKED | Human-readable response name from Dictionary.Response (e.g., 'Approved', 'Declined - Insufficient Funds'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionIDs.ID | Billing.RecurringDeposit.ExecutionID | LEFT JOIN | Resolves execution to recurring deposit record |
| RecurringDeposit.DepositID | Billing.Deposit.DepositID | LEFT JOIN | Resolves recurring deposit to actual deposit |
| Deposit.FundingID | Billing.Funding.FundingID | LEFT JOIN | Resolves to funding instrument (FundingTypeID used implicitly) |
| Funding.FundingTypeID | Dictionary.FundingType | LEFT JOIN | Resolves funding type (not exposed in output) |
| Deposit.DepotID | Billing.Depot.DepotID | LEFT JOIN | Resolves to gateway name |
| Deposit.PaymentStatusID | Dictionary.PaymentStatus | LEFT JOIN | Resolves status name |
| Deposit.RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Resolves risk status name |
| Deposit.DepositID | History.DepositAction.DepositID | LEFT JOIN | Gets payment response |
| DepositAction.ResponseID | Dictionary.Response | LEFT JOIN | Resolves response name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring deposit service | Direct execution | Operational | Bulk lookup of deposit status for recurring payment execution batches; no SSDT GRANT EXECUTE found |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositsForExecutions (procedure)
├── BackOffice.IDs (user-defined table type - TVP)
├── Billing.RecurringDeposit (table)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Dictionary.FundingType (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.RiskManagementStatus (table)
├── History.DepositAction (table)
└── Dictionary.Response (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User-Defined Table Type | TVP declaration for @ExecutionIDs input |
| Billing.RecurringDeposit | Table | NOLOCK LEFT JOIN - maps ExecutionID to DepositID and RetryNumber |
| Billing.Deposit | Table | NOLOCK LEFT JOIN - deposit record |
| Billing.Funding | Table | NOLOCK LEFT JOIN - funding instrument (for type resolution, not in output) |
| Billing.Depot | Table | NOLOCK LEFT JOIN - gateway name |
| Dictionary.FundingType | Table | LEFT JOIN - funding type (not in output) |
| Dictionary.PaymentStatus | Table | LEFT JOIN - status name |
| Dictionary.RiskManagementStatus | Table | LEFT JOIN - risk status name |
| History.DepositAction | Table | NOLOCK LEFT JOIN - response ID from any non-null response action |
| Dictionary.Response | Table | LEFT JOIN - response name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring deposit service | Service | Bulk deposit status lookup for execution batch processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE Deposit.DepositID IS NOT NULL | Filter | Excludes ExecutionIDs with no linked deposit; returns only executions where a deposit was created |
| No TOP 1 on History.DepositAction | Potential Issue | JOIN to DepositAction without TOP 1 can multiply rows if multiple actions have ResponseID IS NOT NULL; caller should be aware of potential row duplication per DepositID |
| READONLY TVP | Design | @ExecutionIDs cannot be modified by the SP; ensures immutability of caller's input set |
| BackOffice.IDs PRIMARY KEY | Performance | Clustered PK on ID ensures efficient join from @ExecutionIDs to RecurringDeposit; duplicate ExecutionIDs are rejected by the TVP type |
| No NOLOCK on Dictionary tables | Mixed | Dictionary.FundingType, Dictionary.PaymentStatus, Dictionary.RiskManagementStatus, Dictionary.Response have no NOLOCK - committed reads for reference data lookups |

---

## 8. Sample Queries

### 8.1 Get deposit details for a set of execution IDs

```sql
DECLARE @ExecIDs BackOffice.IDs;
INSERT @ExecIDs (ID) VALUES (1001), (1002), (1003);

EXEC Billing.GetDepositsForExecutions @ExecutionIDs = @ExecIDs;
```

### 8.2 Inline equivalent for a single execution

```sql
SELECT
    d.DepositID,
    rd.RetryNumber,
    d.PaymentDate,
    d.ExchangeRate,
    dep.DepotID,
    dep.Name AS DepotName,
    rd.ExecutionID,
    ps.Name AS PaymentStatusName,
    ps.PaymentStatusID,
    rms.RiskManagementStatusID,
    rms.Name AS RiskManagementStatusName,
    da.ResponseID,
    r.ResponseName
FROM Billing.RecurringDeposit rd WITH (NOLOCK)
LEFT JOIN Billing.Deposit d WITH (NOLOCK) ON d.DepositID = rd.DepositID
LEFT JOIN Billing.Depot dep WITH (NOLOCK) ON dep.DepotID = d.DepotID
LEFT JOIN Dictionary.PaymentStatus ps ON ps.PaymentStatusID = d.PaymentStatusID
LEFT JOIN Dictionary.RiskManagementStatus rms ON rms.RiskManagementStatusID = d.RiskManagementStatusID
LEFT JOIN History.DepositAction da WITH (NOLOCK) ON da.DepositID = d.DepositID AND da.ResponseID IS NOT NULL
LEFT JOIN Dictionary.Response r ON r.ResponseID = da.ResponseID
WHERE rd.ExecutionID = 1001
  AND d.DepositID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 4/10, Sources: 0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositsForExecutions | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositsForExecutions.sql*
