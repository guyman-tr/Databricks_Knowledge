# History.vWithdrawToFundingAction

> Thin projection view over History.WithdrawToFundingAction exposing 12 of 25 columns with a built-in NOLOCK hint - provides a stable, lighter-weight interface for querying payment processing action history without exposing sensitive XML, FX, or provider-specific columns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | No PK - view over History.WithdrawToFundingAction |
| **Base Objects** | History.WithdrawToFundingAction |

---

## 1. Business Meaning

History.vWithdrawToFundingAction is a filtered-column view over History.WithdrawToFundingAction (12.8M rows) that exposes the core operational columns while hiding sensitive, large, or provider-specific data. The excluded columns include:

- `WithdrawData` (XML blob with IBAN, bank account, BIC - PII/sensitive routing data)
- `AdditionalInformation`, `MerchantAccountID`, `SchemeId`, `ResponseID`, `RequestExecuteEntryMethodId` (provider integration details)
- `BaseExchangeRate`, `ExchangeRate`, `ExchangeFee`, `RefundAmountInDepositCurrency` (FX details)
- `CashoutTypeID`, `CashoutModeID` (processing classification)

The NOLOCK hint is baked into the view definition, making every query through this view automatically use dirty reads - appropriate for the large-volume, append-only nature of the underlying table.

No SSDT repo objects reference this view (1 file = itself) - likely used by BI tools, external reporting, or application queries that prefer the simpler column set.

---

## 2. Business Logic

### 2.1 Column Projection - Operational Subset

**What**: Selects the 12 most commonly needed operational columns from History.WithdrawToFundingAction, hiding PII routing data and provider-specific integration fields.

**Columns Exposed**: WithdrawToFundingActionID, WithdrawID, FundingID, CashoutStatusID, CashoutActionStatusID, ProcessCurrencyID, ManagerID, Amount, ModificationDate, Remark, BW2F_ID, MatchStatusID

**Columns Hidden**:
- `WithdrawData` (XML with IBAN/BIC/account numbers) - PII routing data
- `AdditionalInformation`, `MerchantAccountID`, `SchemeId`, `ResponseID`, `RequestExecuteEntryMethodId` - provider integration
- `BaseExchangeRate`, `ExchangeRate`, `ExchangeFee`, `RefundAmountInDepositCurrency` - FX details
- `CashoutTypeID`, `CashoutModeID` - processing classification

**Rules**:
- No WHERE clause - all rows of History.WithdrawToFundingAction are accessible
- WITH (NOLOCK) is built into the view - callers get dirty reads automatically
- Full see History.WithdrawToFundingAction documentation for business logic, lifecycle, and distributions

---

## 3. Data Overview

Reflects all 12,828,460+ rows of History.WithdrawToFundingAction. See History.WithdrawToFundingAction documentation for full data profile.

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | WithdrawToFundingActionID | INT | NO | CODE-BACKED | Surrogate PK from History.WithdrawToFundingAction. Sequential action ID. |
| 2 | WithdrawID | INT | NO | CODE-BACKED | The withdrawal request ID. Implicit FK to Billing.Withdraw. |
| 3 | FundingID | INT | NO | CODE-BACKED | Customer payment instrument ID. Implicit FK to Billing.Funding. |
| 4 | CashoutStatusID | INT | NO | CODE-BACKED | Status at time of action. FK to Dictionary.CashoutStatus. 8=RejectedByProvider dominates (62%). |
| 5 | CashoutActionStatusID | INT | NO | CODE-BACKED | Action type: 0=legacy, 1=insert, 2=update. |
| 6 | ProcessCurrencyID | INT | NO | CODE-BACKED | Currency in which payment was processed. FK to Dictionary.Currency. |
| 7 | ManagerID | INT | YES | CODE-BACKED | Manager who triggered action. 0=automated. Implicit FK to BackOffice.Manager. |
| 8 | Amount | MONEY | NO | CODE-BACKED | Withdrawal amount at time of action. |
| 9 | ModificationDate | DATETIME | NO | CODE-BACKED | UTC timestamp of this action. |
| 10 | Remark | VARCHAR(250) | YES | CODE-BACKED | Human-readable note (e.g., "Payout processed by provider"). |
| 11 | BW2F_ID | INT | YES | CODE-BACKED | FK to Billing.WithdrawToFunding.ID - the payment order being tracked. |
| 12 | MatchStatusID | TINYINT | YES | CODE-BACKED | Reconciliation match state. 0=unmatched. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.WithdrawToFundingAction | SELECT (12 of 25 columns, NOLOCK) | Base table providing payment action history. |

### 5.2 Referenced By (other objects point to this)

No SSDT objects reference this view. Consumed by application code or external tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.vWithdrawToFundingAction (view)
  -> History.WithdrawToFundingAction (table) [documented]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table | Base table - all rows, 12 columns projected, NOLOCK |

### 6.2 Objects That Depend On This

None found in SSDT repo.

---

## 7. Technical Details

### 7.1 View Definition

```sql
CREATE VIEW [History].[vWithdrawToFundingAction]
AS
SELECT
    WithdrawToFundingActionID, WithdrawID, FundingID, CashoutStatusID,
    CashoutActionStatusID, ProcessCurrencyID, ManagerID, Amount,
    ModificationDate, Remark, BW2F_ID, MatchStatusID
FROM History.WithdrawToFundingAction WITH (NOLOCK)
```

---

## 8. Sample Queries

### 8.1 Latest actions for a specific withdrawal
```sql
SELECT TOP 10 *
FROM History.vWithdrawToFundingAction
WHERE WithdrawID = 1740274
ORDER BY ModificationDate DESC;
```

### 8.2 Recent rejected payment orders
```sql
SELECT WithdrawID, FundingID, BW2F_ID, Amount, ModificationDate
FROM History.vWithdrawToFundingAction
WHERE CashoutStatusID = 8  -- RejectedByProvider
    AND ModificationDate >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 in SSDT repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.vWithdrawToFundingAction | Type: View | Source: etoro/etoro/History/Views/History.vWithdrawToFundingAction.sql*
