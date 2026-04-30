# Billing.BI_GetWithdrawProcessingStatus

> Scalar function that maps a withdrawal's CreditType name to a BI reporting label ('CashoutRollback', 'ReverseDeposit', or 'N/A'), used to categorize withdrawal processing events in BI reports.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(50) - withdrawal processing status label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.BI_GetWithdrawProcessingStatus translates a withdrawal's CreditTypeID into a higher-level processing category label for BI reporting. It distinguishes between two types of post-processing events: cashout rollbacks (reversals of a previously processed withdrawal) and reverse deposits (a special processing action), with everything else labeled 'N/A'.

This function exists to provide consistent BI labeling for withdrawal processing events. The CreditType name stored in the database uses internal terminology ('Reversed', 'Partialy Reversed', 'Processed') that is translated here into more meaningful BI report categories ('CashoutRollback', 'ReverseDeposit'). Without this function, BI reports would need to embed these name-to-label mappings inline.

The function is called per withdrawal record in BI reporting procedures, accepting the CreditTypeID of the withdrawal's associated credit event and returning the appropriate display category.

---

## 2. Business Logic

### 2.1 CreditType to Processing Category Mapping

**What**: Maps three specific CreditType names to two BI categories; all others return 'N/A'.

**Columns/Parameters Involved**: `@CreditTypeID`

**Rules**:
- CreditTypeName = 'Reversed' -> 'CashoutRollback' (withdrawal was reversed after processing)
- CreditTypeName = 'Partialy Reversed' -> 'CashoutRollback' (partial reversal of a processed withdrawal; note: "Partialy" is a typo preserved from the original Dictionary entry)
- CreditTypeName = 'Processed' -> 'ReverseDeposit' (the withdrawal was the processing event that reversed a deposit)
- All other CreditType names -> 'N/A' (standard withdrawal processing, not a reversal event)
- Return: COALESCE(@CashoutProcessingStatus, @CreditTypeName) - in practice @CashoutProcessingStatus is always set (to 'N/A' at minimum), so the fallback to @CreditTypeName would only trigger if the CASE expression returns NULL unexpectedly.

**Diagram**:
```
@CreditTypeID -> Dictionary.CreditType.Name ->

'Reversed'         -> 'CashoutRollback'  (full withdrawal reversal)
'Partialy Reversed'-> 'CashoutRollback'  (partial withdrawal reversal)
'Processed'        -> 'ReverseDeposit'   (withdrawal reversed a deposit)
(anything else)    -> 'N/A'              (standard or non-reversal event)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditTypeID | int | NO | - | VERIFIED | CreditType identifier from Dictionary.CreditType. The function looks up the Name for this ID and maps it to a BI category. Only three names yield non-'N/A' results: 'Reversed', 'Partialy Reversed' (both -> 'CashoutRollback'), and 'Processed' (-> 'ReverseDeposit'). |
| RETURN | varchar(50) | - | NO | - | VERIFIED | BI reporting category for the withdrawal processing event. Three possible values: 'CashoutRollback' (withdrawal was reversed), 'ReverseDeposit' (withdrawal reversed a prior deposit), 'N/A' (not a reversal event or unrecognized credit type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditTypeID | Dictionary.CreditType | Lookup | Resolves CreditTypeID to its Name for the category mapping CASE expression. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | CreditTypeID | Caller | Primary consumer - calls this function per withdrawal row in BI deposit/withdrawal state reports. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_GetWithdrawProcessingStatus (function)
└── Dictionary.CreditType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CreditType | Table | Resolves CreditTypeID to name for the mapping CASE expression. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls this function per withdrawal row to categorize processing events. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | Function is NOT schema-bound. |

---

## 8. Sample Queries

### 8.1 Test the function with specific CreditType IDs

```sql
SELECT
    ct.CreditTypeID,
    ct.Name AS CreditTypeName,
    Billing.BI_GetWithdrawProcessingStatus(ct.CreditTypeID) AS ProcessingStatus
FROM Dictionary.CreditType ct WITH (NOLOCK)
ORDER BY ct.CreditTypeID;
```

### 8.2 Get withdrawal processing categories for a date range

```sql
SELECT
    Billing.BI_GetWithdrawProcessingStatus(w.CreditTypeID) AS ProcessingCategory,
    COUNT(*) AS WithdrawCount
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CreateDate >= '2026-01-01'
GROUP BY Billing.BI_GetWithdrawProcessingStatus(w.CreditTypeID)
ORDER BY COUNT(*) DESC;
```

### 8.3 Find all cashout rollback events

```sql
SELECT TOP 100
    w.WithdrawID,
    w.CID,
    w.Amount,
    ct.Name AS CreditTypeName,
    Billing.BI_GetWithdrawProcessingStatus(w.CreditTypeID) AS ProcessingStatus
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = w.CreditTypeID
WHERE Billing.BI_GetWithdrawProcessingStatus(w.CreditTypeID) = 'CashoutRollback'
ORDER BY w.CreateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BI_GetWithdrawProcessingStatus | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.BI_GetWithdrawProcessingStatus.sql*
