# BackOffice.GetWithdrawCustomerInformation

> Returns the additional parameters attached to a withdrawal request - a key-value list of supplementary data fields submitted by the customer or payment processor.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (required); returns Billing.WithdrawAdditionalParameters rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawCustomerInformation` is a thin wrapper that retrieves all supplementary data associated with a withdrawal request. The additional parameters in `Billing.WithdrawAdditionalParameters` store variable key-value fields that differ by payment method - for example, bank account numbers, beneficiary names, IBAN codes, routing numbers, or other payment-method-specific fields required to process a withdrawal.

Used by Back Office screens when displaying the full details of a withdrawal request - the core withdrawal data (amount, status, dates) is retrieved via `GetWithdraw` or `GetWithdrawApprove`, while this procedure provides the variable supplementary information.

---

## 2. Business Logic

### 2.1 Direct Lookup by WithdrawID

**What**: Returns all additional parameter rows for a single withdrawal.

**Columns/Parameters Involved**: `@WithdrawID`, `Billing.WithdrawAdditionalParameters.WithdrawID`

**Rules**:
- SELECT ParameterTypeID, ParameterValue FROM Billing.WithdrawAdditionalParameters WHERE WithdrawID = @WithdrawID
- No TOP, no ORDER BY - returns all rows for the withdrawal
- May return 0 rows if no additional parameters were captured for this withdrawal
- May return multiple rows - one per parameter type associated with the withdrawal

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal to retrieve additional parameters for. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParameterTypeID | INT | NO | - | CODE-BACKED | Identifies which type of additional field this row represents (Billing.WithdrawAdditionalParameters.ParameterTypeID). Join to a parameter type dictionary for names. Values are payment-method-specific (e.g., bank account, IBAN, beneficiary). |
| 2 | ParameterValue | NVARCHAR | YES | - | CODE-BACKED | The actual value for this parameter type (Billing.WithdrawAdditionalParameters.ParameterValue). Free-text or structured value depending on ParameterTypeID. May contain PII (bank account numbers, beneficiary names). |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.WithdrawAdditionalParameters | Read (primary) | All additional parameters for the withdrawal |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal detail screens) | @WithdrawID | Application | Supplementary payment details display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawCustomerInformation (procedure)
└── Billing.WithdrawAdditionalParameters (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAdditionalParameters | Table | Direct SELECT - all parameter rows for the withdrawal |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO withdrawal screens for supplementary details. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No join to parameter type dictionary | Design | ParameterTypeID is returned raw - the caller is expected to interpret or join to a type dictionary. This keeps the procedure lightweight. |
| PII considerations | Security | ParameterValue may contain PII (bank account numbers, beneficiary details, routing numbers). Access to this procedure should be restricted to authorized BO personnel. |

---

## 8. Sample Queries

### 8.1 Get all additional parameters for a withdrawal
```sql
EXEC [BackOffice].[GetWithdrawCustomerInformation] @WithdrawID = 123456
```

### 8.2 Direct equivalent query
```sql
SELECT ParameterTypeID, ParameterValue
FROM Billing.WithdrawAdditionalParameters WITH (NOLOCK)
WHERE WithdrawID = 123456
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawCustomerInformation | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawCustomerInformation.sql*
