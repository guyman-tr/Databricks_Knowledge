# Billing.GetCustomersWithSameMeanOfPayment

> Fraud detection check: returns the most recent OTHER customer (CID) who made an approved deposit using the same FundingID, excluding cases where the funding is marked as a third-party arrangement for that other customer. Used to detect shared payment instruments between accounts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomersWithSameMeanOfPayment` is a fraud detection probe. It answers the question: "Has any OTHER customer (not @CID) made an approved deposit using this same payment instrument (@FundingID), where it was NOT flagged as a third-party funding for them?"

If another customer has used the same credit card, bank account, or other payment instrument and that usage was NOT pre-authorized as a third-party arrangement (e.g., a corporate card or shared account), it may indicate:
- Multi-account fraud (the same person operating multiple accounts)
- Unauthorized use of a stolen payment instrument by multiple users
- Account sharing or collusion

The `BackOffice.CustomerToThirdPartyFundings` check is the key discriminator: if a funding instrument is registered as a third-party instrument for a CID (meaning "this customer is allowed to use someone else's card"), that CID is excluded from the results. Only "unexpected" sharing - where no third-party arrangement exists - is flagged.

Returns `TOP 1 CID` - the most recently depositing other user of this funding instrument. Returns 0 rows if no other customers have used it without a third-party exception.

Note: There is also a `BackOffice.GetCustomersWithSameMeanOfPayment` SP (same name, different schema) - a parallel implementation granted to BusinessRuleUserForEtoro. The Billing version has no explicit EXECUTE grant in UsersPermissions - called by application services via their own DB users.

---

## 2. Business Logic

### 2.1 Shared Funding Detection with Third-Party Exclusion

**What**: Finds other customers who used the same FundingID for approved deposits, excluding those with a third-party exception.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `BackOffice.CustomerToThirdPartyFundings.FundingID`

**Rules**:
- `WHERE BDEP.CID <> @CID`: Exclude the requesting customer's own deposits.
- `AND BDEP.FundingID = @FundingID`: Match only the specific funding instrument.
- `AND BDEP.PaymentStatusID = 2`: Only approved deposits count (not declined/pending attempts).
- `LEFT JOIN BackOffice.CustomerToThirdPartyFundings BCT3P ON BCT3P.FundingID = BDEP.FundingID AND BCT3P.CID = BDEP.CID`: Attempts to find a third-party exception for the OTHER customer (BDEP.CID) using this specific funding.
- `AND BCT3P.FundingID IS NULL`: The LEFT JOIN + IS NULL pattern filters OUT rows where a third-party exception exists. If BCT3P.FundingID IS NULL, no third-party arrangement is registered for this CID+FundingID combination.
- `TOP 1 ... ORDER BY BDEP.PaymentDate DESC`: Returns the most recent other user of this funding (most relevant for fraud timing).
- No NOLOCK hints on the main query (consistent data reads for fraud decisions).

**Diagram**:
```
@FundingID (target instrument)
     |
Billing.Deposit BDEP
  WHERE FundingID = @FundingID
    AND CID <> @CID          (exclude self)
    AND PaymentStatusID = 2  (approved only)
     |
LEFT JOIN BackOffice.CustomerToThirdPartyFundings BCT3P
  ON BCT3P.FundingID = BDEP.FundingID
  AND BCT3P.CID = BDEP.CID
     |
WHERE BCT3P.FundingID IS NULL  (no third-party exception for this CID+FundingID)
     |
ORDER BY PaymentDate DESC
     |
TOP 1 -> most recent other CID who used this funding without third-party exception
         (or 0 rows if no such CID exists)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer to perform the check FOR. This customer's own deposits are excluded from the search. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | The payment instrument to check. FK to Billing.Funding. Identifies the specific card/bank account/wallet to scan for other users. |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CID | INT | NO | CODE-BACKED | The CID of the most recently depositing OTHER customer who used @FundingID without a third-party exception. Returns 0 rows if no match found (no shared funding detected). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, FundingID, PaymentStatusID, PaymentDate | Billing.Deposit | Direct read (TOP 1) | Source of deposit records to find other customers who used the same funding |
| FundingID, CID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN (exclusion filter) | Third-party funding exceptions; rows here exempt a CID from the fraud flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | No explicit EXECUTE grant in Billing schema permissions; called via service DB user |
| BackOffice.GetCustomersWithSameMeanOfPayment | Parallel implementation | Related SP | Separate SP with same name in BackOffice schema; BusinessRuleUserForEtoro has EXECUTE on that version |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomersWithSameMeanOfPayment (procedure)
├── Billing.Deposit (table)
└── BackOffice.CustomerToThirdPartyFundings (table - third-party exception check)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of approved deposits by @FundingID, excluding @CID's own deposits |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN to identify and exclude CIDs with third-party exceptions for this FundingID |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by application services via their own DB users.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Returns 0 or 1 rows | TOP 1 with ORDER BY PaymentDate DESC - either returns the most recent other user or 0 rows |
| No NOLOCK | Unlike most read SPs, no NOLOCK hint on Billing.Deposit - consistent reads for fraud decision accuracy |
| LEFT JOIN + IS NULL pattern | Efficient anti-join pattern to exclude rows with third-party exceptions |

---

## 8. Sample Queries

### 8.1 Check if a funding instrument is shared

```sql
-- Returns CID of most recent other user, or empty if not shared
EXEC [Billing].[GetCustomersWithSameMeanOfPayment]
    @CID = 1234567,
    @FundingID = 9876543
-- Non-empty result: another customer used this card without third-party exception - potential fraud
-- Empty result: no other customers used this card, or all usages are third-party exceptions
```

### 8.2 See all other users of a funding (without TOP 1 limit)

```sql
-- Direct query to see all other customers using the same funding:
SELECT BDEP.CID, BDEP.PaymentDate, BDEP.Amount
FROM [Billing].[Deposit] BDEP
LEFT JOIN [BackOffice].[CustomerToThirdPartyFundings] BCT3P
    ON BCT3P.FundingID = BDEP.FundingID AND BCT3P.CID = BDEP.CID
WHERE BDEP.FundingID = 9876543
    AND BDEP.CID <> 1234567
    AND BDEP.PaymentStatusID = 2
    AND BCT3P.FundingID IS NULL
ORDER BY BDEP.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomersWithSameMeanOfPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomersWithSameMeanOfPayment.sql*
