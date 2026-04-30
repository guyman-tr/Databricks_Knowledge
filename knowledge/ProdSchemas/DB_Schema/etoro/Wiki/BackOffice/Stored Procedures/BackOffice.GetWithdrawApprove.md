# BackOffice.GetWithdrawApprove

> Returns all data needed to render the withdrawal approval screen for a single withdrawal - customer identity, account details, funding method, amounts, and manager assignment.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @CID (both required); returns TOP 1 row from Billing.Withdraw with enrichments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawApprove` loads the complete context a Back Office manager needs to make an approval decision on a withdrawal request. It combines the withdrawal record with customer identity (GCID from Customer.CustomerStatic), the specific funding method used (FundingTypeID from Billing.Funding), and key financial amounts. The GCID is needed for cross-system lookups during the approval process.

The `AmountInUSD` column is named for approval UI purposes but currently returns `BW.Amount` directly without currency conversion - this is a known placeholder (commented `--TBD` in the DDL).

The `ManagerID` is returned twice: once as `ModifiedBy` and once as `CreatedBy` - both columns reflect the same manager, suggesting the procedure was simplified from a more complex version that differentiated between creator and last modifier.

---

## 2. Business Logic

### 2.1 TOP 1 Lookup

**What**: Returns at most one row for the specified withdrawal.

**Columns/Parameters Involved**: `@WithdrawID`, `@CID`, `BW.WithdrawID`, `BW.CID`

**Rules**:
- SELECT TOP 1 ... WHERE BW.WithdrawID = @WithdrawID AND BW.CID = @CID
- Both @WithdrawID and @CID required - validates ownership (prevents returning another customer's withdrawal data by WithdrawID alone)
- No ORDER BY with TOP 1 - assumes unique (WithdrawID, CID) combination in Billing.Withdraw

### 2.2 AmountInUSD Placeholder

**What**: Returns the withdrawal amount labeled as USD amount, but currency conversion is not implemented.

**Columns/Parameters Involved**: `AmountInUSD`, `BW.Amount`

**Rules**:
- BW.Amount AS [AmountInUSD] (with `--TBD` DDL comment)
- Does NOT convert using exchange rate - returns Amount as-is
- Callers should be aware this is the amount in the withdrawal's native currency (BW.CurrencyID), not guaranteed USD
- Retained as-is for display compatibility

### 2.3 Funding Type Resolution

**What**: Resolves the payment method type for the withdrawal.

**Columns/Parameters Involved**: `FundingTypeID`, `BW.FundingID`, `Billing.Funding.FundingTypeID`

**Rules**:
- LEFT JOIN Billing.Funding BF ON BF.FundingID = BW.FundingID
- Returns BF.FundingTypeID (NULL if no matching funding record)
- FundingID on Billing.Withdraw links to the specific payment method instance

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal to retrieve approval data for. Required. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Validates that the withdrawal belongs to this customer. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerId | INT | NO | - | CODE-BACKED | Customer ID (Billing.Withdraw.CID). |
| 2 | GCID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic.GCID. Used for cross-system lookups during approval. NULL if no CustomerStatic record. |
| 3 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (Billing.Withdraw.WithdrawID). |
| 4 | CashoutStatusID | INT | NO | - | CODE-BACKED | Current status of the withdrawal (Billing.Withdraw.CashoutStatusID). Raw ID - join Dictionary.CashoutStatus for name. |
| 5 | Amount | MONEY | YES | - | CODE-BACKED | Requested withdrawal amount in the withdrawal's native currency (Billing.Withdraw.Amount). |
| 6 | AmountInUSD | MONEY | YES | - | NAME-INFERRED | Withdrawal amount - currently returns BW.Amount without currency conversion (DDL comment: --TBD). May not be in USD if CurrencyID != 1. |
| 7 | FundingTypeID | INT | YES | - | CODE-BACKED | Payment method type ID from Billing.Funding (via BW.FundingID). NULL if no funding record. |
| 8 | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the withdrawal amount (Billing.Withdraw.CurrencyID). Links to Dictionary.Currency. |
| 9 | AccountCurrencyID | INT | YES | - | CODE-BACKED | Currency of the customer's account (Billing.Withdraw.AccountCurrencyID). May differ from CurrencyID. |
| 10 | RequestDate | DATETIME | YES | - | CODE-BACKED | When the customer submitted the withdrawal request (Billing.Withdraw.RequestDate). |
| 11 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager who last processed this withdrawal (Billing.Withdraw.ManagerID). |
| 12 | ModifiedBy | INT | YES | - | CODE-BACKED | Same as ManagerID (Billing.Withdraw.ManagerID aliased). Last manager to modify this withdrawal. |
| 13 | CreatedBy | INT | YES | - | CODE-BACKED | Same as ManagerID (Billing.Withdraw.ManagerID aliased again). Indicates the same manager field is reused - true creation manager not separately tracked. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BW.WithdrawID + BW.CID | Billing.Withdraw | Read (primary) | Withdrawal record |
| BW.CID | Customer.CustomerStatic | LEFT JOIN | GCID for cross-system lookups |
| BW.FundingID | Billing.Funding | LEFT JOIN | FundingTypeID for payment method |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal approval screen) | @WithdrawID / @CID | Application | Loads approval screen context for manager decision |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawApprove (procedure)
├── Billing.Withdraw (table)
├── Customer.CustomerStatic (table) - GCID
└── Billing.Funding (table) - FundingTypeID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary - withdrawal data, all financial fields |
| Customer.CustomerStatic | Table | LEFT JOIN - GCID for cross-system identity |
| Billing.Funding | Table | LEFT JOIN - FundingTypeID from FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO withdrawal approval screens. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AmountInUSD = BW.Amount (no conversion) | Known Limitation | The --TBD DDL comment indicates currency conversion was intended but not implemented. Callers receiving this column should check CurrencyID to determine if conversion is needed. |
| ManagerID returned as both ModifiedBy and CreatedBy | Implementation | Both aliases point to the same Billing.Withdraw.ManagerID column. True creation manager is not separately tracked in Billing.Withdraw. |
| TOP 1 with both CID and WithdrawID | Security | Dual-key filter prevents returning another customer's withdrawal if only WithdrawID is known. Both parameters must be provided for data ownership validation. |

---

## 8. Sample Queries

### 8.1 Get withdrawal approval data
```sql
EXEC [BackOffice].[GetWithdrawApprove]
    @WithdrawID = 123456,
    @CID = 789012
```

### 8.2 Direct equivalent query
```sql
SELECT TOP 1
    BW.CID AS CustomerId,
    CSS.GCID,
    BW.WithdrawID,
    BW.CashoutStatusID,
    BW.Amount,
    BW.Amount AS AmountInUSD, -- TBD: no conversion
    BF.FundingTypeID,
    BW.CurrencyID,
    BW.AccountCurrencyID,
    BW.RequestDate,
    BW.ManagerID,
    BW.ManagerID AS ModifiedBy,
    BW.ManagerID AS CreatedBy
FROM Billing.Withdraw BW WITH (NOLOCK)
LEFT JOIN Customer.CustomerStatic CSS WITH (NOLOCK) ON CSS.CID = BW.CID
LEFT JOIN Billing.Funding BF WITH (NOLOCK) ON BF.FundingID = BW.FundingID
WHERE BW.WithdrawID = 123456
AND BW.CID = 789012
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawApprove | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawApprove.sql*
