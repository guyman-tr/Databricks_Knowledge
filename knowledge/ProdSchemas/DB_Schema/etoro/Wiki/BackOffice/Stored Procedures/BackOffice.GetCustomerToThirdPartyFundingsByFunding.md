# BackOffice.GetCustomerToThirdPartyFundingsByFunding

> Returns 1 if a given FundingID has any associated third-party customer relationship on record, 0 if not - used by the Withdrawal Service to detect third-party funding before processing withdrawals.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single scalar: 1 (exists) or 0 (not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerToThirdPartyFundingsByFunding is a boolean existence check: given a FundingID, it answers whether that payment method is registered in `BackOffice.CustomerToThirdPartyFundings` as a known third-party funding instrument (i.e., used by more than one customer). The return value is always exactly one row with a single column: `1` if any (FundingID, CID) pair exists for the given FundingID, `0` if none.

The procedure exists to give the Withdrawal Service a fast, lightweight gate check. Before processing a withdrawal, the withdrawal service queries this procedure to determine whether the customer's funding method has a known third-party relationship. A result of `1` flags the withdrawal for additional review or a hold, since withdrawing to a card or account that is shared with another customer raises AML/fraud concerns. A result of `0` means the funding method is clean from a third-party perspective.

Created in July 2022 (MIMOPSA-7300) as part of the "AMOP - Find existing funding" initiative (MIMOPSA-7168). The `GRANT EXECUTE ON ... TO WithdrawalServiceUser` comment in the DDL confirms the intended caller: the automated withdrawal processing service account.

---

## 2. Business Logic

### 2.1 Existence Check Pattern

**What**: Uses a CASE/EXISTS pattern to return a boolean integer instead of a result set.

**Columns/Parameters Involved**: `@FundingID`, `BackOffice.CustomerToThirdPartyFundings.FundingID`

**Rules**:
- Returns `1` if `EXISTS(SELECT * FROM CustomerToThirdPartyFundings WHERE FundingID = @FundingID)`
- Returns `0` if no rows exist for that FundingID
- Uses `WITH(NOLOCK)` for non-blocking read - withdrawal service checks do not require read consistency
- Always returns exactly one row with one column (no empty result set - callers can safely read the scalar value)

**Diagram**:
```
@FundingID = 9999
        |
        v
CustomerToThirdPartyFundings
  FundingID=9999, CID=1001 <- exists?
        |
  YES: return 1 (flag for review)
  NO:  return 0 (clean, proceed)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | The FundingID of the payment method to check. Corresponds to Billing.Funding.FundingID (the card, e-wallet, or bank account identifier). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | (unnamed) | INT | NO | - | CODE-BACKED | Boolean result: 1 if the FundingID has any row in BackOffice.CustomerToThirdPartyFundings (third-party relationship exists - withdrawal requires review), 0 if not (clean). Always returns exactly one row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | BackOffice.CustomerToThirdPartyFundings | EXISTS check | Checks whether this FundingID has any approved third-party association |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalService (WithdrawalServiceUser) | @FundingID | EXEC | Withdrawal service checks this before processing withdrawals to flag third-party funding situations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerToThirdPartyFundingsByFunding (procedure)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToThirdPartyFundings | Table | EXISTS check on FundingID - the third-party funding registry |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal Service (WithdrawalServiceUser DB account) | External | READER - calls to gate withdrawal processing based on third-party funding status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: DDL includes a commented-out GRANT statement: `GRANT EXECUTE ON [BackOffice].[GetCustomerToThirdPartyFundingsByFunding] TO WithdrawalServiceUser` - indicating the procedure requires explicit permission for the withdrawal service DB account.

---

## 8. Sample Queries

### 8.1 Check if a FundingID has a third-party relationship
```sql
EXEC BackOffice.GetCustomerToThirdPartyFundingsByFunding @FundingID = 9999
-- Returns 1 (has third-party) or 0 (clean)
```

### 8.2 Equivalent ad-hoc check
```sql
SELECT CASE WHEN EXISTS(
    SELECT 1 FROM BackOffice.CustomerToThirdPartyFundings WITH(NOLOCK)
    WHERE FundingID = 9999
) THEN 1 ELSE 0 END AS HasThirdPartyRelationship
```

### 8.3 List all third-party relationships for a FundingID
```sql
SELECT ctpf.FundingID, ctpf.CID, ctpf.CreationDate,
       cc.UserName
FROM BackOffice.CustomerToThirdPartyFundings ctpf WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = ctpf.CID
WHERE ctpf.FundingID = 9999  -- replace with target FundingID
ORDER BY ctpf.CreationDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-7300](https://etoro-jira.atlassian.net/browse/MIMOPSA-7300) | Jira | Procedure created by Kate Michael (Jul 2022) for WithdrawalService as part of "AMOP - Find existing funding" (MIMOPSA-7168); tagged AutomationAPI |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers (WithdrawalServiceUser = external service account) | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetCustomerToThirdPartyFundingsByFunding | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerToThirdPartyFundingsByFunding.sql*
