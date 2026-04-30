# Billing.GetFundingIDByDepositID

> Resolves the FundingID associated with a given deposit record, returning it as an output parameter for use in downstream payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A deposit transaction (Billing.Deposit) is always linked to a specific payment method (Billing.Funding via FundingID). When processing deposit-related operations - such as chargebacks, refunds, or regulatory inquiries - other services need to know which funding method was used for a specific deposit without querying the Deposit table directly.

This procedure provides a lightweight, single-purpose lookup: given a DepositID, return the FundingID via an OUTPUT parameter. The OUTPUT parameter pattern (rather than a result set) indicates this is typically called inline within other stored procedures or tightly coupled application code that can capture the output directly.

---

## 2. Business Logic

### 2.1 Deposit-to-Funding Resolution

**What**: Simple primary key lookup on Billing.Deposit to resolve the funding method used for a deposit.

**Rules**:
- `SELECT @FundingID = BD.FundingID FROM Billing.Deposit WHERE DepositID = @DepositID`
- If the DepositID doesn't exist, @FundingID will retain its initial value (NULL by default)
- The OUTPUT pattern means the caller must declare @FundingID before the EXEC call
- NOLOCK hint used for read performance (non-blocking read)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | Primary key of Billing.Deposit. Identifies the specific deposit whose funding method is being resolved. |
| 2 | @FundingID | INT | OUT | - | CODE-BACKED | OUTPUT parameter. Receives the FundingID from Billing.Deposit.FundingID for the given DepositID. NULL if no matching deposit found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | Lookup | Resolves DepositID -> FundingID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application refund/chargeback services | @DepositID + @FundingID | EXEC | Used to find which funding method was used for a deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingIDByDepositID (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT FundingID WHERE DepositID = @DepositID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get FundingID for a deposit

```sql
DECLARE @FundingID INT;
EXEC Billing.GetFundingIDByDepositID
    @DepositID = 12345678,
    @FundingID = @FundingID OUTPUT;
SELECT @FundingID AS ResolvedFundingID;
```

### 8.2 Direct lookup equivalent

```sql
SELECT FundingID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 12345678;
```

### 8.3 Get full funding details after resolving FundingID

```sql
DECLARE @FundingID INT;
EXEC Billing.GetFundingIDByDepositID @DepositID = 12345678, @FundingID = @FundingID OUTPUT;
SELECT f.FundingID, f.FundingTypeID, f.FundingData
FROM Billing.Funding f WITH (NOLOCK)
WHERE f.FundingID = @FundingID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingIDByDepositID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingIDByDepositID.sql*
