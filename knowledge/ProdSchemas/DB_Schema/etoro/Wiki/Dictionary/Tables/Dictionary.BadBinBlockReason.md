# Dictionary.BadBinBlockReason

> Lookup table defining the 5 reasons for blocking credit card BIN numbers — Legal, Risk, Fraud, Country (HRC), and Other — used in the payment fraud prevention system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, no PK constraint) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.BadBinBlockReason categorizes why specific credit card BIN (Bank Identification Number) ranges are blocked from being used for deposits on the platform. When a BIN range is flagged as "bad," a reason code from this table explains which department or policy triggered the block.

This is a fraud prevention measure. The payment system maintains a blocklist of BIN ranges associated with fraud, regulatory restrictions, or compliance issues. Each blocked BIN entry references a BadBinBlockReason to explain why that specific bank/issuer combination is banned. This helps the compliance and risk teams manage the blocklist and understand the basis for each restriction.

The table has no FK references from other tables in the SSDT project (only its own DDL file references it), suggesting the BIN blocklist may be maintained in a separate system or through a table not tracked in the current SSDT project scope.

---

## 2. Business Logic

### 2.1 Block Reason Categories

**What**: Why a credit card BIN range was blocked from deposits.

**Columns/Parameters Involved**: `ID`, `Name`, `Description`

**Rules**:
- **Blocked by Legal (1)**: Compliance/legal department flagged this BIN range. Typically due to regulatory requirements, sanctions, or legal restrictions on accepting cards from certain issuers.
- **Blocked by Risk (2)**: Risk department flagged this BIN range based on risk assessment. Pattern of high-risk transactions, chargebacks, or suspicious activity from cards in this range.
- **Blocked by Fraud (3)**: Fraud detection team identified confirmed fraud activity from cards in this BIN range. Direct evidence of fraudulent transactions.
- **Blocked by Country (4)**: BIN range belongs to a High Risk Country (HRC). Regulatory or policy restriction on accepting deposits from certain jurisdictions regardless of individual customer risk.
- **Other (5)**: Catch-all category for blocks that don't fit the other categories. May include temporary blocks, experimental restrictions, or blocks pending classification.

---

## 3. Data Overview

| ID | Name | Description | Meaning |
|---|---|---|---|
| 1 | Blocked by Legal | Blocked by Complience Requirment | Compliance/legal team mandated the block. BIN range associated with sanctioned entities, restricted jurisdictions, or other legal obligations. |
| 2 | Blocked by Risk | Blocked by Risk Departrment | Risk department identified elevated risk patterns from this BIN range — high chargeback rates, suspicious deposit patterns, or known risk indicators. |
| 3 | Blocked by Fraud | Blocked due to Fraud Activity | Confirmed fraud originating from cards in this BIN range. Strongest justification for blocking — direct evidence of malicious financial activity. |
| 4 | Blocked by Country | Country part of HRC | BIN range issued by banks in a High Risk Country. Blanket block based on country-level risk assessment regardless of individual card characteristics. |
| 5 | Other | Other | Miscellaneous block reasons not covered by the four primary categories. Used for temporary or unclassified restrictions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing identifier for the block reason. Values 1-5. No PK constraint — table is a heap. Used to categorize why a BIN range was added to the blocklist. |
| 2 | Name | nvarchar(100) | NO | - | VERIFIED | Short display name for the block reason (e.g., 'Blocked by Legal', 'Blocked by Fraud'). Used in BackOffice UIs and reports to show why a BIN was blocked. |
| 3 | Description | nvarchar(250) | NO | - | VERIFIED | Extended description explaining the block reason in more detail. Provides context for compliance officers reviewing the blocklist. Note: contains typos in production data ('Complience', 'Departrment'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No FK references found in the SSDT project.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table is a heap on DICTIONARY filegroup.

### 7.2 Constraints

None. No PK, no FK, no unique constraints.

---

## 8. Sample Queries

### 8.1 List all block reasons
```sql
SELECT  ID,
        Name,
        Description
FROM    Dictionary.BadBinBlockReason WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find fraud-related block reasons
```sql
SELECT  ID,
        Name
FROM    Dictionary.BadBinBlockReason WITH (NOLOCK)
WHERE   Name LIKE '%Fraud%';
```

### 8.3 List all reasons with trimmed descriptions
```sql
SELECT  ID,
        Name,
        RTRIM(Description) AS Description
FROM    Dictionary.BadBinBlockReason WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BadBinBlockReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BadBinBlockReason.sql*
