# History.CashoutAction

> Action log recording each lifecycle event (New, Processed) for cashout (withdrawal) requests; each row captures the payment method and amount at the time a cashout was submitted or completed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CashoutActionID - IDENTITY PK NONCLUSTERED |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC indexes on CashoutID, CashoutActionStatusID, FundingTypeID) |

---

## 1. Business Meaning

History.CashoutAction is a legacy action log for eToro's cashout (customer withdrawal) lifecycle. It records one row each time a cashout moves through a key stage: when a customer submits a withdrawal request (status=New) and when the back-office processes the payment (status=Processed). Together with History.Cashout (which tracks Billing.Cashout status transitions), this table provides a parallel action-level audit trail.

The table captures which payment method (FundingTypeID) was used and the withdrawal amount at each lifecycle step. This enables reporting on the distribution of withdrawal methods, volume processing rates, and the processing lag between request submission and completion.

With 5,816 rows spanning March to October 2008, this is a legacy table from eToro's earliest operational period. No new records have been written since 2008. The procedure infrastructure (Billing.CashoutRequestAdd, Billing.CashoutProcess) still references this table, but the cashout workflow has evolved considerably and modern cashout processing appears to use other mechanisms.

---

## 2. Business Logic

### 2.1 Cashout Lifecycle Events

**What**: Two lifecycle events are recorded per cashout request - submission (New) and completion (Processed).

**Columns/Parameters Involved**: `CashoutID`, `CashoutActionStatusID`, `FundingTypeID`, `Amount`, `ActionDate`

**Rules**:
- **Status=1 (New)**: Written by `Billing.CashoutRequestAdd` at cashout creation time. One row per cashout request submitted.
- **Status=2 (Processed)**: Written by `Billing.CashoutProcess` and its payment-method-specific variants (CashoutProcessToCreditCard, CashoutProcessToNeteller, etc.) when the back-office approves and routes the withdrawal.
- **Status=3 (Failed)**: Defined in Dictionary.CashoutActionStatus but never observed in data (0 rows with this status).
- A typical cashout produces exactly 2 rows: one New at creation, one Processed at completion.
- Amount is the integer amount in the smallest currency unit (consistent with Billing.Cashout.Amount pattern).
- FundingTypeID records the payment channel used at each step - may differ between New and Processed if the payment method was changed during processing.

**Diagram**:
```
Customer submits withdrawal:
  Billing.CashoutRequestAdd(@CashoutID, @FundingTypeID, ...)
    -> INSERT Billing.Cashout (status = New)
    -> INSERT History.Cashout (state transition log)
    -> INSERT History.CashoutAction (CashoutActionStatusID=1=New)

Back-office processes withdrawal:
  Billing.CashoutProcess(@CashoutID, @FundingTypeID, ...)
    -> UPDATE Billing.Cashout (status -> Processed)
    -> INSERT History.Cashout (state transition log)
    -> INSERT History.CashoutAction (CashoutActionStatusID=2=Processed)
```

---

## 3. Data Overview

5,816 rows spanning March 2008 to October 2008 (legacy data, no new writes since 2008):

| CashoutActionStatusID | Name | Count | % |
|---|---|---|---|
| 1 | New | 5,088 | 87.5% |
| 2 | Processed | 728 | 12.5% |

| FundingTypeID | Name | Count |
|---|---|---|
| 3 | PayPal | 2,208 |
| 1 | CreditCard | 1,954 |
| 2 | WireTransfer | 732 |
| 4 | BankDraft | 667 |
| 7 | NetellerOnePay | 151 |
| 6 | Neteller | 103 |
| 5 | WesternUnion | 1 |

The 87.5% New vs 12.5% Processed ratio reflects that most early cashout requests were either cancelled, pending, or processed via mechanisms that did not write a Processed action record.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutActionID | int | NO | IDENTITY | VERIFIED | Surrogate PK. Auto-incremented IDENTITY(1,1) NOT FOR REPLICATION. |
| 2 | CashoutID | int | NO | - | VERIFIED | FK to Billing.Cashout. Identifies the cashout (withdrawal) request this action belongs to. Indexed (HCSA_CASHOUT) for efficient lookup of all actions for a cashout. |
| 3 | CashoutActionStatusID | int | NO | - | VERIFIED | The lifecycle stage of this action. FK to Dictionary.CashoutActionStatus: 1=New (submission), 2=Processed (completion), 3=Failed (never observed). Indexed (HCSA_CASHOUTACTIONSTATUS). |
| 4 | FundingTypeID | int | NO | - | VERIFIED | Payment method used for this cashout action. Implicit FK to Dictionary.FundingType: 1=CreditCard, 2=WireTransfer, 3=PayPal, 4=BankDraft, 5=WesternUnion, 6=Neteller, 7=NetellerOnePay. Indexed (HCSA_FUNDINGTYPE). |
| 5 | Amount | int | NO | - | CODE-BACKED | Withdrawal amount in the smallest currency unit at the time of this action (consistent with Billing.Cashout.Amount). Not a money/decimal type - integer representation of the value. |
| 6 | ActionDate | datetime | NO | - | CODE-BACKED | Timestamp when this cashout action was recorded (GETDATE() at INSERT time). Represents when the cashout was submitted (New) or when the back-office completed processing (Processed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutID | Billing.Cashout | FK (FK_BCSH_HCSA) | The cashout request this action belongs to |
| CashoutActionStatusID | Dictionary.CashoutActionStatus | FK (FK_DCAS_HCSA) | Lifecycle stage of this action |
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method used |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CashoutRequestAdd | CashoutID, CashoutActionStatusID=1 | Writer | Inserts New action on cashout creation |
| Billing.CashoutProcess | CashoutID, CashoutActionStatusID=2 | Writer | Inserts Processed action on cashout completion |
| Billing.CashoutProcessToCreditCard | CashoutID | Writer | Payment-method-specific variant |
| Billing.CashoutProcessToNeteller | CashoutID | Writer | Payment-method-specific variant |
| Billing.CashoutProcessToPayPal | CashoutID | Writer | Payment-method-specific variant |
| Billing.CashoutProcessToWesternUnion | CashoutID | Writer | Payment-method-specific variant |
| Billing.CashoutProcessToWireTransfer | CashoutID | Writer | Payment-method-specific variant |
| BackOffice.InProcessPaymentsToSendPCIVersion | CashoutID | Reader | Back-office reporting |
| BackOffice.WithdrawRequestSetCommission | CashoutID | Reader/Writer | Commission assignment on withdrawal |
| BackOffice.WithdrawToFundingAdd | CashoutID | Reader | Funding routing |
| Billing.BI_Cashout_State_Report | CashoutID | Reader | BI reporting on cashout state |
| Billing.BI_WithdrawRollback_PIPS_Report | CashoutID | Reader | Rollback audit reporting |
| Billing.GetMIDDescription / GetMIDDescriptionV2 | CashoutID | Reader | MID (merchant ID) description lookup |
| Billing.CustomerRemove | CashoutID | Reader | Customer removal validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutActionStatus
Dictionary.FundingType
Billing.Cashout
  -> History.CashoutAction (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | FK - parent cashout request record |
| Dictionary.CashoutActionStatus | Table | FK - lifecycle stage lookup |
| Dictionary.FundingType | Table | Implicit - payment method lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRequestAdd | Stored Procedure | Writer - inserts New action |
| Billing.CashoutProcess | Stored Procedure | Writer - inserts Processed action |
| Billing.BI_Cashout_State_Report | Stored Procedure | Reader - BI cashout reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HCSA | NONCLUSTERED PK | CashoutActionID ASC | - | - | Active |
| HCSA_CASHOUT | NONCLUSTERED | CashoutID ASC | - | - | Active |
| HCSA_CASHOUTACTIONSTATUS | NONCLUSTERED | CashoutActionStatusID ASC | - | - | Active |
| HCSA_FUNDINGTYPE | NONCLUSTERED | FundingTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCSA | PRIMARY KEY | CashoutActionID - surrogate PK |
| FK_BCSH_HCSA | FOREIGN KEY | CashoutID -> Billing.Cashout(CashoutID) |
| FK_DCAS_HCSA | FOREIGN KEY | CashoutActionStatusID -> Dictionary.CashoutActionStatus(CashoutActionStatusID) |

Storage: ON [HISTORY] filegroup with FILLFACTOR = 90.

---

## 8. Sample Queries

### 8.1 Get all actions for a specific cashout
```sql
SELECT ca.CashoutActionID, ca.CashoutActionStatusID, cas.Name AS StatusName,
       ca.FundingTypeID, ca.Amount, ca.ActionDate
FROM [History].[CashoutAction] ca
JOIN [Dictionary].[CashoutActionStatus] cas ON ca.CashoutActionStatusID = cas.CashoutActionStatusID
WHERE ca.CashoutID = @CashoutID
ORDER BY ca.ActionDate ASC
```

### 8.2 Processing rate by funding type
```sql
SELECT ca.FundingTypeID, COUNT(*) AS TotalActions,
       SUM(CASE WHEN ca.CashoutActionStatusID = 2 THEN 1 ELSE 0 END) AS Processed
FROM [History].[CashoutAction] ca
GROUP BY ca.FundingTypeID
ORDER BY TotalActions DESC
```

### 8.3 Date range analysis of cashout activity
```sql
SELECT CAST(ActionDate AS date) AS ActionDay,
       CashoutActionStatusID, COUNT(*) AS EventCount
FROM [History].[CashoutAction]
WHERE ActionDate BETWEEN @StartDate AND @EndDate
GROUP BY CAST(ActionDate AS date), CashoutActionStatusID
ORDER BY ActionDay DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Billing.CashoutRequestAdd, Billing.CashoutProcess) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CashoutAction | Type: Table | Source: etoro/etoro/History/Tables/History.CashoutAction.sql*
