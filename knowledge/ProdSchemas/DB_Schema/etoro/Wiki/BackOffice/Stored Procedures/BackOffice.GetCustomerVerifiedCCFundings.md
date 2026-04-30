# BackOffice.GetCustomerVerifiedCCFundings

> Returns the distinct FundingIDs of credit cards for a customer that have an associated Credit Card KYC document on record, identifying which of the customer's cards are document-verified.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DISTINCT FundingID values (one per verified CC) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerVerifiedCCFundings returns the set of credit card FundingIDs for a given customer that have an associated Credit Card document submitted through KYC. A credit card FundingID appears in the result only when three conditions are all true: (1) the customer has a CustomerDocumentToDocumentType record with DocumentTypeID=3 ("Credit Card") that references a FundingID, (2) that FundingID is in Billing.Funding with FundingTypeID=1 (credit card type), and (3) the underlying CustomerDocument was uploaded by or for the given customer (CID match).

The procedure exists to answer "which of this customer's credit cards have been document-verified?" This matters for deposit aggregation rules, withdrawal processing, and compliance checks - in particular, a verified credit card can be subject to different refund limits, chargeback rules, or deposit maximums than an unverified card. It is called from `BackOffice.GetDepositRuleAggregation` (#10 in this batch) to determine which fundings count toward specific deposit rule thresholds.

No Atlassian sources found. The procedure's business context is derivable from its consumer (`GetDepositRuleAggregation`) and from the credit card document verification workflow in BackOffice.

---

## 2. Business Logic

### 2.1 Verified Credit Card Identification

**What**: A three-way join determines which credit card fundings for a customer have been formally documented via the KYC credit card document workflow.

**Columns/Parameters Involved**: `@CID`, `DocumentTypeID=3`, `FundingTypeID=1`, `FundingID`

**Rules**:
- `BackOffice.CustomerDocumentToDocumentType.DocumentTypeID = 3`: Only credit card document classifications (Dictionary.DocumentType: 3 = "Credit Card")
- `BackOffice.CustomerDocumentToDocumentType.FundingID IS NOT NULL`: Only records where a specific funding method is linked to the document
- `Billing.Funding.FundingTypeID = 1`: Confirms the FundingID is actually a credit card type
- `BackOffice.CustomerDocument.CID = @CID`: Scopes to the specified customer
- `SELECT DISTINCT`: De-duplicates in case multiple document records reference the same FundingID
- LEFT JOIN on Billing.Funding (not INNER): A document record with a FundingID that has been deleted from Billing.Funding would still show up unless the FundingTypeID filter eliminates it - the FundingTypeID=1 filter acts as a quasi-INNER JOIN

**Diagram**:
```
Customer @CID uploads credit card photos (CustomerDocument)
         |
         v
BackOffice agent classifies them (CustomerDocumentToDocumentType)
  DocumentTypeID=3 (Credit Card) + FundingID=9999
         |
         v
GetCustomerVerifiedCCFundings checks:
  - DocumentTypeID=3?  YES
  - FundingID set?     YES
  - Billing.Funding[9999].FundingTypeID=1?  YES
         |
         v
Result: FundingID=9999 (this card is document-verified)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID. Scopes the document lookup to a specific customer via BackOffice.CustomerDocument.CID. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | int | NO | - | CODE-BACKED | The FundingID of a credit card that has an associated Credit Card KYC document for this customer. DISTINCT - each FundingID appears at most once. FK to Billing.Funding (FundingTypeID=1 = credit card). Empty result set means the customer has no document-verified credit cards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| bocdtdt | BackOffice.CustomerDocumentToDocumentType | SELECT | Source of FundingID links to credit card documents; filtered to DocumentTypeID=3 and FundingID IS NOT NULL |
| bocd | BackOffice.CustomerDocument | INNER JOIN | Scopes to the given CID; connects documents to the customer |
| bf | Billing.Funding | LEFT JOIN | Confirms FundingTypeID=1 (credit card type) for the linked FundingIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetDepositRuleAggregation | @CID | EXEC | Calls to determine which of the customer's fundings are document-verified CCs for deposit rule aggregation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerVerifiedCCFundings (procedure)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
└── Billing.Funding (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | Primary source - filtered to DocumentTypeID=3 (Credit Card) and FundingID IS NOT NULL |
| BackOffice.CustomerDocument | Table | INNER JOIN on DocumentID to scope results to the given customer (CID) |
| Billing.Funding | Table | LEFT JOIN to confirm FundingTypeID=1 (credit card funding type) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetDepositRuleAggregation | Procedure | READER via EXEC - uses this result to identify document-verified CC fundings for deposit rule calculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. `BackOffice.CustomerDocumentToDocumentType` has a filtered NC index on `FundingID WHERE FundingID IS NOT NULL` which directly optimizes this query's `FundingID IS NOT NULL` filter.

---

## 8. Sample Queries

### 8.1 Get document-verified credit cards for a customer
```sql
EXEC BackOffice.GetCustomerVerifiedCCFundings @CID = 12345
-- Returns FundingIDs of verified credit cards
```

### 8.2 Equivalent ad-hoc query with card details
```sql
SELECT DISTINCT bocdtdt.FundingID,
    bf.PaymentDetails AS BinCode
FROM BackOffice.CustomerDocumentToDocumentType bocdtdt WITH (NOLOCK)
INNER JOIN BackOffice.CustomerDocument bocd WITH (NOLOCK) ON bocd.DocumentID = bocdtdt.DocumentID
LEFT JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bocdtdt.FundingID
WHERE bocdtdt.DocumentTypeID = 3
  AND bocdtdt.FundingID IS NOT NULL
  AND bf.FundingTypeID = 1
  AND bocd.CID = 12345  -- replace with target CID
```

### 8.3 Count customers with at least one verified CC funding
```sql
SELECT COUNT(DISTINCT bocd.CID) AS CustomersWithVerifiedCC
FROM BackOffice.CustomerDocumentToDocumentType bocdtdt WITH (NOLOCK)
INNER JOIN BackOffice.CustomerDocument bocd WITH (NOLOCK) ON bocd.DocumentID = bocdtdt.DocumentID
LEFT JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bocdtdt.FundingID
WHERE bocdtdt.DocumentTypeID = 3
  AND bocdtdt.FundingID IS NOT NULL
  AND bf.FundingTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (consumed by GetDepositRuleAggregation) | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetCustomerVerifiedCCFundings | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerVerifiedCCFundings.sql*
