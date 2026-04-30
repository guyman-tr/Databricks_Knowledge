# Dictionary.CreditType

> Lookup table classifying the types of financial transactions or credit events in the affiliate commission system, determining how each transaction affects commission calculations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CreditTypeID (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CreditType defines the classification of financial events that trigger affiliate commission processing. Each credit event (deposit, bonus, chargeback) is tagged with a CreditTypeID that determines how the event is handled in the commission calculation pipeline. This is a core table in the affiliate commission domain.

Without this classification, the commission engine would not know whether to credit or debit an affiliate's account. Deposits generate positive commissions, while chargebacks reverse them. The distinction between Type A and Type B variants (IDs 2 vs 3 for bonuses, 4 vs 5 for chargebacks) allows different processing rules for different business scenarios.

CreditType is referenced extensively across commission and reporting procedures. The AffiliateCommission.Credit and AffiliateCommission.CreditEvent tables store CreditTypeID for each financial event. Over 20 stored procedures across reporting, commission calculation, and monitoring schemas reference this value.

---

## 2. Business Logic

### 2.1 Credit Event Classification

**What**: Five transaction types organized into three categories that determine commission direction and processing rules.

**Columns/Parameters Involved**: `CreditTypeID`, `Description`

**Rules**:
- ID=1 (Deposit) is a positive credit event - customer deposited funds, triggering affiliate commission
- IDs 2,3 (Bonus A/B) are positive credit events with two distinct processing rule sets for platform bonuses
- IDs 4,5 (Chargeback A/B) are negative credit events - payment reversals that deduct from affiliate commissions, with two processing variants
- Commission reports filter by CreditTypeID to separate deposit-based revenue from bonus-based revenue and chargeback losses

**Diagram**:
```
Credit Events:
  POSITIVE (generate commission):
    [Deposit (1)] -- Customer cash deposit
    [Bonus A (2)] -- Platform bonus, rule set A
    [Bonus B (3)] -- Platform bonus, rule set B

  NEGATIVE (deduct commission):
    [Chargeback A (4)] -- Payment reversal, rule set A
    [Chargeback B (5)] -- Payment reversal, rule set B
```

---

## 3. Data Overview

| CreditTypeID | Description | Meaning |
|---|---|---|
| 1 | Deposit | Customer made a cash deposit into their trading account. This is the primary revenue-generating event for affiliates - most commission plans pay on deposits |
| 2 | Bonus | Platform bonus applied to customer account (type A). Different processing rules than type B - may have different commission eligibility criteria |
| 3 | Bonus | Platform bonus applied to customer account (type B). Separate processing pipeline from type A despite same display name |
| 4 | Chargeback | Payment reversal or dispute (type A). Deducts from affiliate commissions when a customer's deposit is reversed by their bank or payment provider |
| 5 | Chargeback | Payment reversal or dispute (type B). Distinct chargeback processing rules from type A - may apply to different payment methods or dispute categories |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the credit event type. Values: 1=Deposit, 2=Bonus(A), 3=Bonus(B), 4=Chargeback(A), 5=Chargeback(B). See [Credit Type](../../_glossary.md#credit-type) for full business definitions. Used extensively in commission calculations and reporting to determine payment direction. |
| 2 | Description | nvarchar(100) | NO | - | VERIFIED | Human-readable label for the credit type. Note: IDs 2 and 3 share the label "Bonus", and IDs 4 and 5 share "Chargeback" - the ID is the true differentiator for processing rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.Credit | CreditTypeID | Implicit FK | Stores the type of each commission credit record |
| AffiliateCommission.CreditEvent | CreditTypeID | Implicit FK | Classifies each credit event in the event-driven pipeline |
| AffiliateCommission.InsertCredit | Parameter | Lookup | Commission credit insertion uses CreditTypeID for routing |
| AffiliateReport.ReportSummaryByAffiliate | JOIN/WHERE | Lookup | Reports filter and aggregate by credit type |
| Monitor.CheckCreditChargeBackUpdates | WHERE | Lookup | Monitoring filters for chargeback credit types |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | Stores CreditTypeID for each credit record |
| AffiliateCommission.CreditEvent | Table | Classifies credit events by type |
| AffiliateCommission.InsertCredit | Stored Procedure | WRITER - uses CreditTypeID when inserting credits |
| AffiliateCommission.InsertCreditEvent | Stored Procedure | WRITER - tags events with credit type |
| AffiliateReport.ReportSummaryByAffiliate | Stored Procedure | READER - aggregates by credit type |
| Affiliate.GetUnpaidCommissions | Stored Procedure | READER - filters unpaid commissions |
| Monitor.CheckCreditChargeBackUpdates | Stored Procedure | READER - monitors chargeback activity |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCreditType | CLUSTERED PK | CreditTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all credit types
```sql
SELECT CreditTypeID, Description
FROM Dictionary.CreditType WITH (NOLOCK)
ORDER BY CreditTypeID
```

### 8.2 Sum credits by type for an affiliate
```sql
SELECT ct.CreditTypeID, ct.Description, SUM(c.Amount) AS TotalAmount
FROM AffiliateCommission.Credit c WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON c.CreditTypeID = ct.CreditTypeID
WHERE c.AffiliateID = @AffiliateID
GROUP BY ct.CreditTypeID, ct.Description
ORDER BY ct.CreditTypeID
```

### 8.3 Find chargebacks only (negative events)
```sql
SELECT c.*
FROM AffiliateCommission.Credit c WITH (NOLOCK)
WHERE c.CreditTypeID IN (4, 5)
ORDER BY c.CreditID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CreditType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.CreditType.sql*
