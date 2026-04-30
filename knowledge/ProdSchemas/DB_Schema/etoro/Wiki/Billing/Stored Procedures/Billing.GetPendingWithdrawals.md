# Billing.GetPendingWithdrawals

> Returns a customer's pending withdrawal requests (CashoutStatusID=1) as a Base64-encoded XML document, providing the cashier/trading platform with the list of active withdrawal requests in a wire-format suitable for the older platform integration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns XML result set (FOR XML RAW) from Billing.Withdraw for @CID where CashoutStatusID=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPendingWithdrawals` retrieves all pending withdrawal requests for a specific customer from `Billing.Withdraw` and returns them as a Base64-encoded XML document. The XML format (`FOR XML RAW('WithdrawData')... ROOT('WithdrawList')`) is the legacy wire format used by the older eToro trading platform to receive pending withdrawal data.

The procedure exists to answer the question "what pending withdrawals does this customer have?" in a format the cashier/trading platform can parse directly. It is called from `Billing.GetCustomerDepositInfo` as part of the customer account state assembly, and is also available to BI admins.

Data flows: the procedure is called during deposit flow or account state checks to understand if the customer already has pending withdrawals (which may affect deposit eligibility or balance checks). Originally (2021) it accessed a History in-memory table (`History.ActiveCreditRecentMemoryBucket`) for additional balance context, but this dependency was removed in July 2022 (PAYUA-3770) to simplify the procedure.

---

## 2. Business Logic

### 2.1 XML Output Format (Legacy Integration)

**What**: Results are returned as XML rather than a standard result set, using the older FOR XML syntax required by the legacy trading platform.

**Columns/Parameters Involved**: All selected columns

**Rules**:
- `FOR XML RAW('WithdrawData')` - each row becomes a `<WithdrawData>` element with columns as attributes
- `BINARY BASE64` - binary data encoded as Base64 (applies if any binary columns present)
- `ELEMENTS` - columns as sub-elements within each row element
- `TYPE` - result is returned as XML datatype (not varchar)
- `ROOT('WithdrawList')` - wraps all rows in a `<WithdrawList>` root element
- The caller receives XML like: `<WithdrawList><WithdrawData><WithdrawID>...</WithdrawID>...</WithdrawData></WithdrawList>`

### 2.2 Amount Scaling (x100 Integer Conversion)

**What**: Amount is multiplied by 100 and cast to INTEGER before serialization.

**Columns/Parameters Involved**: `BWDR.Amount` -> `CAST(Amount*100 AS INTEGER)`

**Rules**:
- The legacy platform receives amounts in cents/pips (integer units) rather than decimal dollars
- `CAST(Amount*100 AS INTEGER)` - truncates any sub-cent precision
- Fee is returned as-is (ISNULL(Fee, 0) - 0 if NULL)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer identifier. Filters `Billing.Withdraw` to this customer's pending withdrawal requests. |

**Return columns (as XML elements in each WithdrawData node):**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | WithdrawID | Billing.Withdraw.WithdrawID | CODE-BACKED | PK of the withdrawal request. |
| 3 | CurrencyID | Billing.Withdraw.CurrencyID | CODE-BACKED | Requested withdrawal currency. FK to Dictionary.Currency. |
| 4 | FundingTypeID | Billing.Withdraw.FundingTypeID | CODE-BACKED | Payment method type for this withdrawal. FK to Dictionary.FundingType. |
| 5 | RequestDate | Billing.Withdraw.RequestDate | CODE-BACKED | Timestamp when the customer submitted the withdrawal request. |
| 6 | Amount | CAST(Billing.Withdraw.Amount * 100 AS INTEGER) | CODE-BACKED | Withdrawal amount scaled to integer cents/pips (x100). Legacy platform convention. |
| 7 | Fee | ISNULL(Billing.Withdraw.Fee, 0) | CODE-BACKED | Withdrawal processing fee; 0 if no fee recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Withdraw.CID | Filter | Returns pending withdrawals (CashoutStatusID=1) for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCustomerDepositInfo | EXEC | Caller | Called as part of customer account state assembly during deposit flow |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPendingWithdrawals (procedure)
└── Billing.Withdraw (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Filtered SELECT by CID and CashoutStatusID=1; amount scaled x100 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Procedure | Calls this to get pending withdrawals as part of customer state |
| PROD_BIadmins | DB Security Principal | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Change history**:
- 2021 (Shay Oren): Initial version included access to `History.ActiveCreditRecentMemoryBucket` in-memory table for active credit balance context
- 2022-07-21 (Denys M., PAYUA-3770): Removed History schema dependency, simplified to direct Billing.Withdraw query

---

## 8. Sample Queries

### 8.1 Get pending withdrawals for a customer (XML format)
```sql
EXEC [Billing].[GetPendingWithdrawals] @CID = 12345678
```

### 8.2 Equivalent direct query (non-XML, for debugging)
```sql
SELECT
    WithdrawID,
    CurrencyID,
    FundingTypeID,
    RequestDate,
    CAST(Amount * 100 AS INTEGER) AS AmountScaled,
    ISNULL(Fee, 0) AS Fee
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CID = 12345678
  AND CashoutStatusID = 1
```

### 8.3 Check how many customers have pending withdrawals
```sql
SELECT COUNT(DISTINCT CID) AS CustomersWithPendingWithdrawals,
       COUNT(*) AS TotalPendingWithdrawals
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CashoutStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-3770 (referenced in code comment) | Jira | July 2022: Removed History.ActiveCreditRecentMemoryBucket dependency to simplify the procedure |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYUA-3770 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPendingWithdrawals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPendingWithdrawals.sql*
