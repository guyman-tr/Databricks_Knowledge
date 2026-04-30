# Billing.WithdrawService_GetWithdrawByID

> Returns full withdrawal request details for a single withdrawal ID, including the associated payment instrument data, for use by the withdrawal service when processing or displaying a specific withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @withdrawID - the withdrawal to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetWithdrawByID` is a single-record lookup procedure that retrieves all details for a specific withdrawal request, including the payment instrument data. The withdrawal service uses this when it needs to process, validate, or display a specific withdrawal - for example, after a customer submits a withdrawal request, the service fetches the record back to confirm what was created and determine next steps.

The procedure extends the basic withdrawal data from `Billing.Withdraw` with `FundingData` from `Billing.Funding` (the payment method's XML data, subject to DDM masking), which the service needs to determine routing and provider-specific handling. The LEFT JOIN on Funding means the procedure returns the withdrawal even if no matching Funding record exists (though in practice, FundingID should always have a corresponding Funding record).

Created November 2020 (MIMOPS-2639, Ran S.) as part of the withdrawal service infrastructure.

---

## 2. Business Logic

### 2.1 Withdrawal + Funding Data in One Call

**What**: Joins withdrawal details with the payment instrument's XML data to avoid a second round-trip.

**Columns/Parameters Involved**: `Billing.Withdraw.FundingID`, `Billing.Funding.FundingData`

**Rules**:
- LEFT JOIN on `Billing.Funding.FundingID = Billing.Withdraw.FundingID` - returns withdrawal even if FundingID has no Funding record (FundingData would be NULL).
- `FundingData` is an XML column subject to Dynamic Data Masking - non-privileged callers receive `xxxx` for sensitive payment data.
- Both `FundingTypeID` (from Withdraw) and `FundingData` (from Funding) are returned, giving the caller both the type classification and the detailed payment instrument data.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @withdrawID | INTEGER | NO | - | CODE-BACKED | The withdrawal to retrieve. FK to `Billing.Withdraw.WithdrawID`. |

**Result Set Columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | WithdrawID | Billing.Withdraw | Primary key of the withdrawal. |
| 2 | CID | Billing.Withdraw | Customer ID who requested the withdrawal. |
| 3 | CashoutStatusID | Billing.Withdraw | Withdrawal status: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 7=Rejected, etc. |
| 4 | RequestDate | Billing.Withdraw | When the withdrawal was submitted. |
| 5 | Amount | Billing.Withdraw | Withdrawal amount. |
| 6 | Commission | Billing.Withdraw | Commission/fee on the withdrawal. |
| 7 | Approved | Billing.Withdraw | Approval flag. |
| 8 | IPAddress | Billing.Withdraw | Customer IP at time of request. |
| 9 | ModificationDate | Billing.Withdraw | Last modification timestamp. |
| 10 | Remark | Billing.Withdraw | Internal remark (e.g., from reversal). |
| 11 | Comment | Billing.Withdraw | Manager or service comment. |
| 12 | Fee | Billing.Withdraw | Additional fee column. |
| 13 | FundingID | Billing.Withdraw | FK to `Billing.Funding` - which payment instrument was designated. |
| 14 | RequestorComments | Billing.Withdraw | Comments provided by the requestor. |
| 15 | SuggestedBonusDeductionAmount | Billing.Withdraw | Suggested bonus deduction calculated at submission time. |
| 16 | FundingTypeID | Billing.Withdraw | Payment method type from the Withdraw record (denormalized). |
| 17 | FundingData | Billing.Funding | XML blob with provider-specific payment instrument data. Subject to DDM masking (non-privileged: `xxxx`). NULL if no matching Funding record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @withdrawID | Billing.Withdraw | FK (read) | Primary lookup table. |
| FundingID | Billing.Funding | LEFT JOIN (read) | Payment instrument XML data. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Called to load a specific withdrawal for processing, validation, or display. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetWithdrawByID (procedure)
├── Billing.Withdraw (table)
└── Billing.Funding (table) - LEFT JOIN for FundingData
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT all result columns WHERE WithdrawID=@withdrawID |
| Billing.Funding | Table | LEFT JOIN on FundingID to get FundingData |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Returns 0 rows if @withdrawID does not exist.

---

## 8. Sample Queries

### 8.1 Retrieve a specific withdrawal with funding data

```sql
EXEC Billing.WithdrawService_GetWithdrawByID @withdrawID = 987654;
```

### 8.2 Check if a withdrawal exists and is in a processable state

```sql
SELECT w.WithdrawID, w.CashoutStatusID, w.Amount, w.FundingTypeID
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = 987654
  AND w.CashoutStatusID IN (1, 2);
```

### 8.3 Get withdrawal with human-readable status

```sql
SELECT
    w.WithdrawID,
    w.CID,
    w.Amount,
    w.RequestDate,
    w.FundingTypeID,
    ft.Name AS FundingTypeName,
    w.CashoutStatusID
FROM Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = w.FundingTypeID
WHERE w.WithdrawID = 987654;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 7.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetWithdrawByID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetWithdrawByID.sql*
