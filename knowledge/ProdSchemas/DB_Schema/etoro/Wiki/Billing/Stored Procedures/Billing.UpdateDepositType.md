# Billing.UpdateDepositType

> Sets the DepositTypeID classification on a Billing.Deposit record, used to categorize deposits into types such as Regular, CvvFree, Recurring, MoneyTransfer, or RecurringInvestment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - targets Billing.Deposit.DepositTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateDepositType` sets the `DepositTypeID` classification on a deposit record. The deposit type determines how the deposit is processed, whether it can be the customer's First-Time Deposit (FTD), and which processing rules apply. For example, `MoneyTransfer` (internal transfers) cannot be FTD regardless of deposit history, while `Recurring` and `RecurringInvestment` types drive scheduled investment flows.

Created in October 2016 (ticket 41252 - "Instant payment test data") during the introduction of deposit type classification. The creation context references instant payment test data setup, suggesting the SP was introduced to classify deposits as part of testing instant payment flows.

No explicit EXECUTE grant found in UsersPermissions for this SP; PROD\BIadmins has VIEW DEFINITION only. The EXECUTE permission is likely granted via schema-level permissions or through application role configuration not reflected in the SSDT UsersPermissions files.

---

## 2. Business Logic

### 2.1 Deposit Type Assignment

**What**: Sets the deposit type classification on a specific deposit record.

**Columns/Parameters Involved**: `@DepositID`, `@DepositTypeID`, `Billing.Deposit.DepositTypeID`

**Rules**:
- `UPDATE Billing.Deposit SET DepositTypeID = @DepositTypeID WHERE DepositID = @DepositID`
- No prior-state validation - unconditional assignment
- `DepositTypeID` is nullable in `Billing.Deposit` (NULL = legacy/pre-classification deposits)
- If `@DepositID` does not exist, the UPDATE silently affects 0 rows
- The `DepositTypeID` value affects IsFTD eligibility: `Dictionary.DepositType.ApplyFtd=false` for MoneyTransfer (type 4) means those deposits cannot be flagged as FTD even if they are the customer's first

**DepositTypeID values** (from `Dictionary.DepositType`):

| ID | Type | ApplyFtd | Description |
|----|------|----------|-------------|
| NULL | (legacy) | - | Pre-classification deposits without a type assigned |
| 0 | Unknown | - | Unknown/unclassified type |
| 1 | Regular | Yes | Standard card/e-wallet deposit (43.4% of deposits) |
| 2 | CvvFree | Yes | Card deposit processed without CVV |
| 3 | Recurring | - | Scheduled recurring payment |
| 4 | MoneyTransfer | No | Internal transfer; cannot be FTD |
| 5 | RecurringInvestment | Yes | Recurring investment deposit (0.7% of deposits) |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | Primary key of the deposit to classify. Maps to `Billing.Deposit.DepositID`. If DepositID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @DepositTypeID | INT | NO | - | CODE-BACKED | Deposit type classification to assign. Written to `Billing.Deposit.DepositTypeID` (FK to `Dictionary.DepositType`). Controls FTD eligibility (via `Dictionary.DepositType.ApplyFtd`) and processing rules. Valid values: 0=Unknown, 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer (not FTD-eligible), 5=RecurringInvestment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID | Billing.Deposit | UPDATE | Sets DepositTypeID classification on the target deposit |
| @DepositTypeID | Dictionary.DepositType | FK (on target table) | FK_BD_DepositType enforces valid DepositTypeID values at the table level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No explicit EXECUTE grant found in SSDT. | - | - | Called via schema-level permission or application role not reflected in UsersPermissions files. Originally created for instant payment test data setup (ticket 41252, 2016). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateDepositType (procedure)
`- Billing.Deposit (table) - UPDATE target
   `- Dictionary.DepositType (FK) - enforces valid DepositTypeID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE - sets DepositTypeID WHERE DepositID=@DepositID |
| Dictionary.DepositType | Table | FK constraint enforces valid DepositTypeID values at the table level |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally; no explicit EXECUTE grant found in UsersPermissions. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. FK constraint on `Billing.Deposit.DepositTypeID -> Dictionary.DepositType` enforces valid values at the table level. The business significance of `DepositTypeID=4` (MoneyTransfer) is that `Dictionary.DepositType.ApplyFtd=false` for this type - a deposit with this type will never be marked as the customer's first-time deposit regardless of their deposit history.

---

## 8. Sample Queries

### 8.1 Classify a deposit as Regular type
```sql
EXEC Billing.UpdateDepositType @DepositID = 10780413, @DepositTypeID = 1; -- Regular
```

### 8.2 Classify an internal transfer deposit
```sql
EXEC Billing.UpdateDepositType @DepositID = 10780413, @DepositTypeID = 4; -- MoneyTransfer (not FTD-eligible)
```

### 8.3 Check current deposit type
```sql
SELECT d.DepositID, d.DepositTypeID, dt.Name AS DepositTypeName, d.IsFTD
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK) ON dt.DepositTypeID = d.DepositTypeID
WHERE d.DepositID = 10780413;
```

### 8.4 Distribution of deposit types
```sql
SELECT d.DepositTypeID, dt.Name, COUNT(*) AS Count, CAST(COUNT(*)*100.0/SUM(COUNT(*)) OVER() AS DECIMAL(5,1)) AS Pct
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK) ON dt.DepositTypeID = d.DepositTypeID
GROUP BY d.DepositTypeID, dt.Name
ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comment references ticket 41252 (October 2016) for the original introduction of deposit type classification ("Instant payment test data").

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateDepositType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateDepositType.sql*
