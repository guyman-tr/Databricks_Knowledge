# Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID

> Updates the ProtocolMIDSettingsID on processed (CashoutStatusID=3) WithdrawToFundingAction audit records for a specific withdrawal + funding combination, and returns the row count updated.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @FundingID + CashoutStatusID=3 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID` corrects or sets the MID (Merchant ID) routing configuration reference on historical withdrawal audit records after a payment has been processed. When a withdrawal payment leg reaches `CashoutStatusID=3` (Processed), the specific Protocol MID Settings that was used to route the payment through the provider is recorded in `History.WithdrawToFundingAction`. This procedure allows that routing reference to be updated post-fact.

The use case for a post-processing update arises when MID routing information is not available at the time the action row is created (e.g., the provider assigns a MID after processing, or the routing decision is made asynchronously), but needs to be captured in the audit log for financial reconciliation and reporting purposes.

The procedure only updates rows where `CashoutStatusID = 3` (Processed), ensuring that MID corrections cannot accidentally alter records for still-in-flight payment legs. The procedure returns `@@ROWCOUNT` so the caller can confirm whether the update affected any rows (0 = no matching processed action row found).

Created in PAYIL-1414 (sub-task of PAYIL-1404) on 2020-09-24.

---

## 2. Business Logic

### 2.1 Processed-Only Guard

**What**: The WHERE clause restricts updates to rows where CashoutStatusID=3 (Processed), protecting in-flight payment legs from accidental modification.

**Columns/Parameters Involved**: `CashoutStatusID`, `@WithdrawID`, `@FundingID`

**Rules**:
- Only rows where `CashoutStatusID = 3` are eligible for update
- A payment leg that is still Pending (1), InProcess (2), or Cancelled (4) cannot have its MID settings updated via this procedure
- The combination of @WithdrawID + @FundingID + CashoutStatusID=3 should typically match exactly one row in History.WithdrawToFundingAction

### 2.2 Row Count Return

**What**: Returns `@@ROWCOUNT` to enable caller verification.

**Rules**:
- 0 rows = no matching processed action record found (either wrong IDs, or the payment is not yet in Processed status)
- 1 row = expected success (one action record updated)
- >1 rows = multiple action records matched (unusual - would indicate duplicate action rows for the same withdrawal+funding+processed state)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | Required. The withdrawal request ID. Combined with @FundingID to uniquely identify the payment leg in History.WithdrawToFundingAction. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | Required. The funding instrument ID. Combined with @WithdrawID to identify the specific payment leg whose MID settings should be updated. |
| 3 | @ProtocolMidSettingsID | int | YES | 0 | CODE-BACKED | The Protocol MID Settings ID to record. Default=0 if no specific MID is applicable. FK concept to Billing.ProtocolMIDSettings. |

### Output

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @@ROWCOUNT | int | NO | - | CODE-BACKED | Number of rows updated. 0=no matching processed action record; 1=success; >1=unexpected duplicate. Used by caller for confirmation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID, @FundingID | History.WithdrawToFundingAction | Modifier | Updates ProtocolMIDSettingsID on the matching processed action record |
| @ProtocolMidSettingsID | Billing.ProtocolMIDSettings | Lookup | The MID configuration being referenced (implicit FK - no constraint in the SP) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser (permissions) | - | Execute permission | PayoutUser has EXECUTE rights on this SP per UsersPermissions configuration |
| Payout processing service (application) | @WithdrawID, @FundingID, @ProtocolMidSettingsID | Caller | Called after payment processing to record the MID configuration used for routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID (procedure)
└── History.WithdrawToFundingAction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table | UPDATE target - sets ProtocolMIDSettingsID for matching processed rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout processing service (application) | External application | Caller - updates MID routing reference after payment processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CashoutStatusID=3 guard | Design | Only Processed payment legs can have their ProtocolMIDSettingsID updated. Prevents modification of in-flight or cancelled records. |
| No transaction | Design | No explicit BEGIN TRAN. Single UPDATE statement is auto-committed. |
| No error handling | Design | No TRY/CATCH. Errors (e.g., table unavailable) propagate to caller. |

---

## 8. Sample Queries

### 8.1 Update ProtocolMIDSettingsID for a processed payment leg

```sql
DECLARE @rowsUpdated INT;
EXEC Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ProtocolMidSettingsID = 42;
-- Check output for @@ROWCOUNT
```

### 8.2 Verify the action record before updating

```sql
SELECT
    wfa.WithdrawID,
    wfa.FundingID,
    wfa.CashoutStatusID,
    wfa.ProtocolMIDSettingsID,
    wfa.CreationDate
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.WithdrawID = 1234567
  AND wfa.FundingID = 987654
  AND wfa.CashoutStatusID = 3;
```

### 8.3 Find processed WithdrawToFundingAction rows with missing MID settings

```sql
SELECT TOP 100
    wfa.WithdrawID,
    wfa.FundingID,
    wfa.CashoutStatusID,
    wfa.ProtocolMIDSettingsID,
    wfa.CreationDate
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.CashoutStatusID = 3
  AND (wfa.ProtocolMIDSettingsID = 0 OR wfa.ProtocolMIDSettingsID IS NULL)
ORDER BY wfa.CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-1414 (referenced in DDL comment, sub-task of PAYIL-1404) | Jira | Creation ticket - procedure was created to record Protocol MID Settings used during withdrawal processing for audit/reconciliation |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira (1 ticket referenced in DDL comment) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingActionUpdateProtocolMidSettingsID.sql*
