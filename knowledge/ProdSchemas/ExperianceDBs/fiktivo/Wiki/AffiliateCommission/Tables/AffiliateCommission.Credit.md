# AffiliateCommission.Credit

> Core entity table storing financial credit events (deposits and chargebacks) for affiliate commission processing, tracking whether each event qualifies for and has been processed into a commission payout.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 6 active (PK clustered + 5 NC including unique and filtered) |

---

## 1. Business Meaning

Credit is the central fact table in the affiliate commission system's credit/deposit domain. Each row represents a financial event - a customer deposit or chargeback - that is evaluated for affiliate commission. When a customer referred by an affiliate deposits money or experiences a payment reversal, a Credit record is created to track that event through the commission pipeline.

This table exists because affiliate commissions on deposits are a key revenue-sharing mechanism. Affiliates earn commissions when their referred customers make deposits (CreditTypeID=1). Chargebacks (CreditTypeID=4,5) reverse commissions when payments are disputed. The system tracks 4.75 million credit events, with 99.7% being deposits. Notably, only 0.14% of deposits are marked as Valid, indicating that commission eligibility is highly selective in this environment.

Data flows into this table via InsertCredit, which uses CreditAccountMapping as a deduplication gateway. The CreditID is actually generated as the IDENTITY value from CreditAccountMapping.CreditInternalID, creating a 1:1 mapping between the account mapping and the credit record. InsertCredit atomically creates Credit + CreditCommission records. After creation, SaveCreditCommission updates the processing state (IsProcessed=1, CommissionDate updated). The table has an explicit FK to Dictionary.CreditType.

---

## 2. Business Logic

### 2.1 Credit Type Classification

**What**: Credits are classified by type, determining commission direction (positive or negative).

**Columns/Parameters Involved**: `CreditTypeID`, `Amount`

**Rules**:
- CreditTypeID=1 (Deposit): Positive event, generates affiliate commission. 99.7% of all records.
- CreditTypeID=4 (Chargeback A): Negative event, reverses affiliate commission. Rule set A.
- CreditTypeID=5 (Chargeback B): Negative event, reverses affiliate commission. Rule set B.
- CreditTypeIDs 2,3 (Bonus A/B) exist in Dictionary.CreditType but have zero records here.
- See [Credit Type](../_glossary.md#credit-type) for full definitions.

### 2.2 First Deposit Tracking (FTD)

**What**: The system tracks whether a credit is the customer's first deposit - a critical metric for affiliate performance.

**Columns/Parameters Involved**: `IsFirstDeposit`, `CreditDate`

**Rules**:
- IsFirstDeposit=1 means this is the customer's first-ever deposit on the platform
- 89% of deposits are FTDs in this dataset - indicating the system primarily tracks initial deposits
- FTD status drives CPA (Cost Per Acquisition) commission models where affiliates earn a flat fee per new depositing customer
- A filtered index exists on CreditDate WHERE IsFirstDeposit=1 for fast FTD reporting

### 2.3 Deduplication via CreditAccountMapping

**What**: Credit records are deduplicated through CreditAccountMapping to prevent duplicate commissions.

**Columns/Parameters Involved**: `CreditID`, external AccountTypeID/TransactionID/AccountID

**Rules**:
- InsertCredit first attempts to insert into CreditAccountMapping
- If the combination (AccountTypeID, TransactionID, AccountID, DateCreated) already exists, no new Credit is created
- CreditID is generated as CreditAccountMapping.CreditInternalID (IDENTITY)
- This prevents double-counting when the same deposit event is sent multiple times

### 2.4 Commission Processing Pipeline

**What**: Each credit goes through validation and commission calculation.

**Columns/Parameters Involved**: `IsProcessed`, `Valid`, `CommissionSource`

**Rules**:
- InsertCredit creates the record with IsProcessed from default (0)
- SaveCreditCommission sets IsProcessed=1 and updates CreditDate and CommissionSource
- Valid determines commission eligibility: 1=eligible, 0=not eligible
- CommissionSource tracks which system or rule determined the commission (e.g., "Deposit")
- Only 0.14% of deposits are Valid - commission eligibility is highly selective

---

## 3. Data Overview

| CreditID | CreditDate | CID | CreditTypeID | Amount | IsFirstDeposit | Valid | IsProcessed | Meaning |
|---|---|---|---|---|---|---|---|---|
| 2168476044 | 2026-04-12 13:50 | 25707172 | 1 | 100 | 1 | 0 | 0 | Fresh first deposit of $100. Not yet validated or processed. Country 196. Typical new customer onboarding. |
| 2168476041 | 2026-04-12 13:42 | 25707106 | 1 | 200 | 1 | 0 | 0 | First deposit of $200. Higher initial deposit amount. Country 79. Pending processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Unique identifier for the credit event. NOT auto-generated here - sourced from CreditAccountMapping.CreditInternalID (IDENTITY) via InsertCredit. This design enables deduplication at the mapping layer. |
| 2 | CreditDate | datetime | NO | - | CODE-BACKED | Timestamp of the credit event. Initially set to the actual deposit/chargeback time. Updated by SaveCreditCommission when commissions are recalculated. Part of a unique index (CreditID, CreditDate). |
| 3 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the depositor. Indexed alongside OriginalCID for attribution lookups. |
| 4 | CreditTypeID | tinyint | NO | - | VERIFIED | Type of credit event. FK to Dictionary.CreditType. Values in use: 1=Deposit (99.7%), 4=Chargeback A (0.05%), 5=Chargeback B (0.17%). See [Credit Type](../_glossary.md#credit-type). Indexed for type-based filtering. |
| 5 | Amount | float | NO | - | CODE-BACKED | Dollar amount of the credit event. Positive for deposits, negative for chargebacks. Common values: 100, 200, 500. Uses float for legacy compatibility. |
| 6 | IsFirstDeposit | bit | NO | - | CODE-BACKED | Whether this is the customer's first-ever deposit. 1=FTD, 0=subsequent deposit. 89% of deposits are FTDs. Drives CPA commission models. Filtered index on CreditDate WHERE IsFirstDeposit=1. |
| 7 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider entity for the customer. |
| 8 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. Commonly equals ProviderID (no transfer). |
| 9 | RealProviderID | bigint | NO | - | CODE-BACKED | Actual execution/settlement entity. |
| 10 | CountryID | bigint | NO | - | CODE-BACKED | Customer's registration country. Used in geography-based commission rules. |
| 11 | Valid | bit | NO | - | CODE-BACKED | Commission eligibility flag. 1=eligible for commission, 0=not eligible. Only 0.14% of deposits are valid - eligibility is highly selective (may depend on affiliate status, regulatory requirements, or minimum deposit thresholds). |
| 12 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer in sub-account scenarios. NULL when the deposit is made by the primary account holder (vast majority of cases). |
| 13 | TrackingDate | datetime | NO | - | CODE-BACKED | Timestamp when the credit entered the affiliate tracking system. Used as one of the deduplication keys in CreditAccountMapping. Indexed alongside CreditTypeID. |
| 14 | IsProcessed | bit | NO | 0 | CODE-BACKED | Commission processing completion flag. 0=pending, 1=processed. Set to 1 by SaveCreditCommission. Only 18% of credits are processed, suggesting many credits are too old or invalid for processing. |
| 15 | CommissionSource | varchar(30) | YES | - | CODE-BACKED | Identifier of the commission calculation source/system. Set by SaveCreditCommission. NULL when not yet processed. Tracks which rule engine or method determined the commission amount. |
| 16 | ProductID | varchar(50) | YES | - | CODE-BACKED | Product identifier for multi-product platforms (e.g., ISA MoneyFarm per PART-5458). NULL for standard deposits. Added to support product-specific commission rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID | Dictionary.CreditType | FK (explicit) | Credit type classification: 1=Deposit, 4=Chargeback A, 5=Chargeback B |
| CreditID | AffiliateCommission.CreditAccountMapping | Implicit | CreditID is generated from CreditAccountMapping.CreditInternalID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CreditCommission | CreditID | Implicit FK | Commission records per tier |
| AffiliateCommission.CreditEvent | CreditID | Implicit FK | Event tracking records |
| AffiliateCommission.CreditIDChargeBackID | CreditID | Implicit FK | Chargeback mapping |
| AffiliateCommission.CreditIDDepositID | CreditID | Implicit FK | Deposit mapping |
| AffiliateCommission.AffiliateTraderCreditQueue | CreditID | Implicit FK | Credit processing queue |
| AffiliateCommission.CreditVW | - | View | View on credit data |
| AffiliateCommission.InsertCredit | INSERT | Writer | Creates credit with commission |
| AffiliateCommission.SaveCreditCommission | UPDATE | Modifier | Sets IsProcessed=1, CommissionSource |
| AffiliateCommission.UpdateCreditTracking | UPDATE | Modifier | Marks as processed |
| AffiliateCommission.GetEarnedDepositCommission | SELECT | Reader | Reads deposit commissions |
| AffiliateCommission.GetNumberOfFTDs | SELECT | Reader | Counts first deposits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.Credit (table)
└── Dictionary.CreditType (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CreditType | Table | FK on CreditTypeID - classifies credit events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditCommission | Table | Child records - commission per tier |
| AffiliateCommission.CreditEvent | Table | Event tracking keyed by CreditID |
| AffiliateCommission.CreditIDChargeBackID | Table | Chargeback mapping |
| AffiliateCommission.CreditIDDepositID | Table | Deposit mapping |
| AffiliateCommission.AffiliateTraderCreditQueue | Table | Processing queue |
| AffiliateCommission.InsertCredit | Stored Procedure | Writer |
| AffiliateCommission.SaveCreditCommission | Stored Procedure | Modifier |
| AffiliateCommission.UpdateCreditTracking | Stored Procedure | Modifier |
| AffiliateCommission.UpdateCreditTrackingAffiliate | Stored Procedure | Modifier |
| AffiliateCommission.UpdateCreditTrackingEligibility | Stored Procedure | Modifier |
| AffiliateCommission.ResetCreditTrackingEligibility | Stored Procedure | Modifier |
| AffiliateCommission.RemoveCreditEvent | Stored Procedure | Related cleanup |
| AffiliateCommission.GetEarnedDepositCommission | Stored Procedure | Reader |
| AffiliateCommission.GetNumberOfFTDs | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Credit | CLUSTERED PK | CreditID ASC | - | - | Active |
| IX_Credit_CID_OriginalCID | NC | CID, OriginalCID | - | - | Active |
| IX_Credit_CreditTypeIDCreditDate | NC | CreditTypeID, CreditDate | - | - | Active |
| IX_Credit_CreditTypeIDTrackingDate | NC | CreditTypeID, TrackingDate | - | - | Active |
| IX_FLTR_CreditDate | NC | CreditDate | CreditID | WHERE IsFirstDeposit=1 | Active |
| UQ_Credit_CreditIDCreditDate | UNIQUE NC | CreditID, CreditDate | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Credit | PRIMARY KEY | Clustered on CreditID |
| FK_AffiliateCommission_Credit_CreditTypeID | FOREIGN KEY | CreditTypeID -> Dictionary.CreditType(CreditTypeID) |
| DF_Credit_IsProcessed | DEFAULT | (0) - new credits start as unprocessed |
| UQ_Credit_CreditIDCreditDate | UNIQUE | Ensures CreditID + CreditDate combination is unique |

---

## 8. Sample Queries

### 8.1 Count credits by type and validity
```sql
SELECT ct.Description AS CreditType, c.Valid,
       COUNT(*) AS CreditCount, SUM(c.Amount) AS TotalAmount
FROM AffiliateCommission.Credit c WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON c.CreditTypeID = ct.CreditTypeID
GROUP BY ct.Description, c.Valid
ORDER BY CreditCount DESC;
```

### 8.2 First deposits (FTDs) in the last 30 days
```sql
SELECT CreditID, CreditDate, CID, Amount, CountryID, Valid, IsProcessed
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE IsFirstDeposit = 1
  AND CreditDate >= DATEADD(day, -30, GETUTCDATE())
ORDER BY CreditDate DESC;
```

### 8.3 Unprocessed valid credits pending commission
```sql
SELECT CreditID, CreditDate, CID, CreditTypeID, Amount, TrackingDate
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE IsProcessed = 0 AND Valid = 1
ORDER BY TrackingDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design + CountryID restored (Dec 2023) |
| [PART-5458](https://etoro-jira.atlassian.net/browse/PART-5458) | Jira | ISA MoneyFarm - added ProductID support (Jan 2026) |
| [PART-3405](https://etoro-jira.atlassian.net/browse/PART-3405) | Jira | CreditAccountMapping dedup pattern + CreditID generation redesign (Jan-Feb 2025) |
| [PART-294](https://etoro-jira.atlassian.net/browse/PART-294) | Jira | Fix for FTD events sent multiple times - added return value (Jun 2022) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 4 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.Credit | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.Credit.sql*
