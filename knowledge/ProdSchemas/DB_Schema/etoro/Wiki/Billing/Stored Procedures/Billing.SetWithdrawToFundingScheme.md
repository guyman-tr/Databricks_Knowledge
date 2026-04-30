# Billing.SetWithdrawToFundingScheme

> Sets the recurring-payment scheme identifier (SchemeId) on a WithdrawToFunding record, preserving the prior CashoutActionStatus from history to avoid status side-effects.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer makes a credit card deposit using a provider that supports recurring payments (Checkout Service, Worldpay), the provider returns a `SchemeId` - a token that identifies the payment scheme for that deposit. This SchemeId enables the deposit to serve as the "first" in a recurring deposit sequence and is stored on the `Billing.WithdrawToFunding` record for future recurring use.

`Billing.SetWithdrawToFundingScheme` is the DB entry point for persisting this value. It is called by the Billing Service after a deposit is processed when the feature flag `IsGetSchemeIdActive` is enabled. The procedure routes through `Billing.UpdateWithdraw2Funding` (the standard TVP-based update path) to ensure the change is properly logged to `History.WithdrawToFundingAction`.

A key design detail: the procedure reads the second-most-recent history record's `CashoutActionStatusID` via a `LEAD()` window function (over DESC-ordered history rows) and passes it in the TVP. This preserves the correct action status in the history log entry created by `UpdateWithdraw2Funding`, avoiding a false status change to the WithdrawToFunding record just from setting the SchemeId. If the WithdrawToFunding record does not exist, error 60025 is raised.

Initial version created by Shay O. on 24/10/2021 (PAYUS-3900).

---

## 2. Business Logic

### 2.1 SchemeId - Recurring Payment Token

**What**: A provider-issued identifier that links a credit card deposit to a recurring payment scheme, enabling the first deposit to seed future recurring charges without re-entering card details.

**Columns/Parameters Involved**: `@SchemeId`, `@WithdrawToFundingId`

**Rules**:
- SchemeId is received from Checkout Service or Worldpay Service when `IsGetSchemeIdActive` feature flag is ON.
- It is stored on the `Billing.WithdrawToFunding` record for that deposit.
- It is also recorded in `Billing.CreditCardSchemeID` (a separate table) with a flag for whether the deposit used 3DS flow (handled outside this procedure).
- SchemeId is only populated for credit card deposits from supported providers; other payment methods leave it NULL.

**Diagram**:
```
Provider (Checkout/Worldpay)
  --> Returns SchemeId after deposit authorization
      --> Billing Service calls SetWithdrawToFundingScheme
          --> UpdateWithdraw2Funding (TVP path)
              --> Updates Billing.WithdrawToFunding.SchemeId
              --> Inserts History.WithdrawToFundingAction record
```

### 2.2 CashoutActionStatus Preservation via LEAD()

**What**: The procedure reads the prior history record's CashoutActionStatusID to include it in the TVP, preventing `UpdateWithdraw2Funding` from writing an incorrect action status to the history log.

**Columns/Parameters Involved**: `@WTFInfo.CashoutActionStatusID`, `History.WithdrawToFundingAction.CashoutActionStatusID`, `History.WithdrawToFundingAction.WithdrawToFundingActionID`

**Rules**:
- Reads `History.WithdrawToFundingAction` for `BW2F_ID = @WithdrawToFundingId`, ordered by `WithdrawToFundingActionID DESC` (most recent first).
- `LEAD(CashoutActionStatusID, 1, 0) OVER(ORDER BY WithdrawToFundingActionID DESC)` fetches the `CashoutActionStatusID` from the second-most-recent history row (i.e., the value before the most recent action).
- This value is passed as `CashoutActionStatusID` in the TVP alongside `SchemeId`.
- Purpose: ensures the history log entry for this SchemeId update reflects the correct "previous" action status rather than an artificial new status.
- Default value is `0` if only one or zero history rows exist.

**Diagram**:
```
History.WithdrawToFundingAction (for @WithdrawToFundingId):
  Row 1 (newest, ActionID=1005): CashoutActionStatusID=3  <-- TOP 1 row selected
  Row 2 (older, ActionID=1001):  CashoutActionStatusID=2  <-- LEAD() returns this value

TVP populated with: ID=@WithdrawToFundingId, SchemeId=@SchemeId, CashoutActionStatusID=2
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingId | INT | NO | - | CODE-BACKED | FK to `Billing.WithdrawToFunding.ID`. Identifies the deposit's withdraw-to-funding record that will have its SchemeId updated. Error 60025 is raised if no record is found (UpdateWithdraw2Funding returns 0 rows). |
| 2 | @SchemeId | NVARCHAR(255) | NO | - | VERIFIED | The recurring payment scheme identifier received from the payment provider (Checkout Service, Worldpay). Stored on the WithdrawToFunding record to enable future recurring deposits without re-entering card details. (Source: Confluence - "SchemeId for CreditCard", space MG) |

**Internal variables / return:**
| # | Element | Type | Notes |
|---|---------|------|-------|
| @num | INT | Return value from `Billing.UpdateWithdraw2Funding`. 0 = record not found (triggers 60025 error). |
| @WTFInfo | `Billing.TBL_Withdraw2Funding` | TVP populated with @WithdrawToFundingId, @SchemeId, and prior CashoutActionStatusID from history. |
| Return value | INT | Returns @WithdrawToFundingId as a result set (`SELECT @WithdrawToFundingId`) on success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingId | Billing.WithdrawToFunding | Lookup + Update | Identifies and updates the deposit's funding record with the SchemeId |
| (internal) | History.WithdrawToFundingAction | READ | Reads history to derive the prior CashoutActionStatusID for the TVP |
| (delegated) | Billing.UpdateWithdraw2Funding | EXEC | Standard TVP-based update path for WithdrawToFunding changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Service | - | Application call | Called when IsGetSchemeIdActive feature flag is enabled after a credit card deposit is processed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SetWithdrawToFundingScheme (procedure)
├── History.WithdrawToFundingAction (table) [READ - for LEAD() derivation]
└── Billing.UpdateWithdraw2Funding (procedure)
      └── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table | SELECT with LEAD() window function to derive prior CashoutActionStatusID |
| Billing.UpdateWithdraw2Funding | Stored Procedure | EXEC via TVP to apply the SchemeId update to WithdrawToFunding |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Service (application) | Application | Calls this procedure to persist SchemeId when IsGetSchemeIdActive is enabled |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Record existence check | RAISERROR 60025 | If `UpdateWithdraw2Funding` returns 0 (no matching WithdrawToFunding record), raises "WithdrawToFunding does not exists" and returns error code 60025 |

---

## 8. Sample Queries

### 8.1 Set a SchemeId on a WithdrawToFunding record
```sql
-- Persist the recurring payment SchemeId returned by the payment provider
EXEC Billing.SetWithdrawToFundingScheme
    @WithdrawToFundingId = 123456,
    @SchemeId = N'SCH_ABC123DEF456';
```

### 8.2 Verify SchemeId was stored and check history
```sql
SELECT
    wtf.ID                  AS WithdrawToFundingId,
    wtf.SchemeId,
    wtf.CashoutStatusID,
    wtf.ModificationDate,
    h.CashoutActionStatusID AS LatestActionStatus,
    h.WithdrawToFundingActionID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN History.WithdrawToFundingAction h WITH (NOLOCK)
    ON h.BW2F_ID = wtf.ID
WHERE wtf.ID = 123456
ORDER BY h.WithdrawToFundingActionID DESC;
```

### 8.3 Find all deposits with a SchemeId (recurring-enabled deposits)
```sql
SELECT
    wtf.ID                  AS WithdrawToFundingId,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.SchemeId,
    wtf.CashoutStatusID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.SchemeId IS NOT NULL
ORDER BY wtf.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [SchemeId for CreditCard](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/2118254744/SchemeId+for+CreditCard) | Confluence | SchemeId is a provider token (Checkout/Worldpay) enabling recurring deposits; stored in WithdrawToFunding and Billing.CreditCardSchemeID; controlled by IsGetSchemeIdActive feature flag |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 10, 10-Tier2)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.SetWithdrawToFundingScheme | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SetWithdrawToFundingScheme.sql*
