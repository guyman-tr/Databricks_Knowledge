# Billing.GetCustomerTotalWithdrawalsAmount

> Returns the total sum of all PROCESSED (CashoutStatusID=3) withdrawals for a customer from Billing.Withdraw. Used by back-office tools, the funding service, and the withdrawal service to check a customer's total historical withdrawal amount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cid (scalar SUM output named "TotalWithdrawals") |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerTotalWithdrawalsAmount` computes the total amount a customer has successfully withdrawn from their eToro account. It sums only PROCESSED withdrawals (CashoutStatusID=3) - excluding pending, in-process, cancelled, and other non-final states.

This total is used for:
- **Withdrawal eligibility checks**: Comparing total deposited vs. total withdrawn to enforce withdrawal restrictions (e.g., minimum trading requirements before withdrawal).
- **Back-office account reviews**: Understanding how much money has flowed out of a customer's account historically.
- **Risk assessment**: A high total withdrawal amount may indicate an account draining pattern.
- **Funding service calculations**: When processing a new withdrawal, the service may check cumulative withdrawals against deposit totals.

CashoutStatusID=3 = Processed (from Billing.Withdraw documentation). The Amount column in Billing.Withdraw is the withdrawal amount; SUM returns NULL if no qualifying rows exist (SQL SUM of empty set behavior) - though SELECT @Cid pattern ensures 0 wouldn't be returned for NULL.

Called by BO_User (back-office), FundingUser (funding service), and WithdrawalServiceUser (withdrawal service).

---

## 2. Business Logic

### 2.1 Processed-Only Withdrawal Sum

**What**: SUM(Amount) for all Billing.Withdraw records with CashoutStatusID=3 (Processed).

**Columns/Parameters Involved**: `@Cid`, `CashoutStatusID=3`, `Amount`, `SUM`

**Rules**:
- `WHERE CID = @Cid AND CashoutStatusID = 3`: Filters to completed/processed withdrawals only.
- CashoutStatusID=3 = Processed (final successful withdrawal state). Does NOT include:
  - 1=Pending (not yet processed)
  - 2=InProcess (in the workflow)
  - 4=Cancelled (rejected/cancelled)
  - Other specialized statuses (5, 7, 8, 14, 16, 17)
- `SUM(Amount) AS TotalWithdrawals`: Returns a single scalar value. Returns NULL if the customer has no processed withdrawals.
- `SET NOCOUNT ON`: Suppresses row count messages.
- No NOLOCK hint: consistent read for financial calculations.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | NO | - | CODE-BACKED | Customer ID whose total processed withdrawal amount to compute. Filters Billing.Withdraw.CID. Note: parameter is named @Cid (mixed case), not @CID. |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | TotalWithdrawals | MONEY/DECIMAL | YES | CODE-BACKED | Sum of all processed (CashoutStatusID=3) withdrawal amounts for this customer. NULL if the customer has no processed withdrawals. In the same currency unit as Billing.Withdraw.Amount (typically USD). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CashoutStatusID=3, Amount | Billing.Withdraw | Direct read (SUM aggregate) | Source of processed withdrawal records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BO_User | EXECUTE grant | Permission | Back-office user tool for account review |
| FundingUser | EXECUTE grant | Permission | Funding service checks total withdrawal history |
| WithdrawalServiceUser | EXECUTE grant | Permission | Withdrawal service uses this during withdrawal processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerTotalWithdrawalsAmount (procedure)
└── Billing.Withdraw (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SUM(Amount) WHERE CID = @Cid AND CashoutStatusID = 3 |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by BO_User, FundingUser, and WithdrawalServiceUser application services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| NULL return | SUM of empty set returns NULL (no rows match). Callers must handle NULL for customers with no processed withdrawals. ISNULL(@result, 0) would be needed in the calling code to treat "no withdrawals" as 0. |
| No NOLOCK | Billing.Withdraw is read WITHOUT NOLOCK - consistent read. Financial aggregate operations typically avoid NOLOCK. |
| CashoutStatusID=3 only | Only counts PROCESSED (final) withdrawals. In-progress or cancelled withdrawals are excluded. |
| Parameter case | @Cid (not @CID) - note mixed case differs from other SPs in the schema that use @CID. |

---

## 8. Sample Queries

### 8.1 Get total processed withdrawals for a customer

```sql
-- Returns total or NULL (no processed withdrawals)
EXEC [Billing].[GetCustomerTotalWithdrawalsAmount] @Cid = 1234567
```

### 8.2 Handle NULL for customers with no withdrawals

```sql
-- Direct equivalent with NULL protection:
SELECT ISNULL(SUM(Amount), 0) AS TotalWithdrawals
FROM [Billing].[Withdraw]
WHERE CID = 1234567 AND CashoutStatusID = 3
```

### 8.3 Compare total deposits vs. total withdrawals

```sql
-- Total deposits approved (from Billing.Deposit):
SELECT SUM(Amount) AS TotalDeposited
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE CID = 1234567 AND PaymentStatusID = 2

-- Total withdrawals processed (via SP equivalent):
SELECT ISNULL(SUM(Amount), 0) AS TotalWithdrawn
FROM [Billing].[Withdraw]
WHERE CID = 1234567 AND CashoutStatusID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerTotalWithdrawalsAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerTotalWithdrawalsAmount.sql*
