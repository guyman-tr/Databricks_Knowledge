# AffiliateCommission.CreditAccountMapping

> Deduplication and ID-generation table that maps external account/transaction identifiers to internal CreditIDs, preventing duplicate credit processing and serving as the identity source for Credit records.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | AccountTypeID + TransactionID + AccountID + DateCreated (composite PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + NC on CreditInternalID) |

---

## 1. Business Meaning

CreditAccountMapping is the deduplication gateway and ID generator for the credit commission system. Every credit event must first pass through this table before a Credit record is created. The combination of AccountTypeID, TransactionID, AccountID, and DateCreated forms a natural key that uniquely identifies a financial transaction from the source system.

This table exists to solve a critical business problem: duplicate credit processing. Payment systems can send the same deposit event multiple times (network retries, message replay, etc.). Without deduplication, the same deposit could generate multiple commissions. CreditAccountMapping prevents this by rejecting duplicate inserts on the composite PK.

The table also serves as the ID generator - CreditInternalID (IDENTITY column) becomes the CreditID in the Credit table. InsertCredit first attempts to insert here; if successful, it uses SCOPE_IDENTITY() as the CreditID for the new Credit record. If the mapping already exists (duplicate), no new Credit is created, and the existing CreditInternalID is returned. The table has 3.4 million rows, closely matching the Credit table count.

---

## 2. Business Logic

### 2.1 Deduplication Pattern

**What**: Prevents duplicate credit processing through composite natural key matching.

**Columns/Parameters Involved**: `AccountTypeID`, `TransactionID`, `AccountID`, `DateCreated`

**Rules**:
- InsertCredit attempts INSERT with WHERE NOT EXISTS on (AccountTypeID, TransactionID, AccountID, DateCreated)
- If @@ROWCOUNT > 0: new mapping created, SCOPE_IDENTITY() becomes CreditID, Credit + CreditCommission inserted
- If @@ROWCOUNT = 0: duplicate detected, existing CreditInternalID retrieved via SELECT, no new Credit created
- This is an idempotent pattern - calling InsertCredit with the same transaction details always returns the same CreditID

### 2.2 CreditID Generation

**What**: CreditInternalID (IDENTITY) serves as the source of CreditID for the Credit table.

**Columns/Parameters Involved**: `CreditInternalID`

**Rules**:
- CreditInternalID is an IDENTITY(1,1) column auto-generated on insert
- After successful insert, SCOPE_IDENTITY() is captured as @CreditID
- This @CreditID is used for INSERT INTO Credit and as the OUTPUT parameter
- Design introduced in PART-3405 (Jan-Feb 2025) to replace direct CreditID assignment

---

## 3. Data Overview

| AccountTypeID | TransactionID | AccountID | DateCreated | CreditInternalID | Meaning |
|---|---|---|---|---|---|
| 1 | 10927876 | 25707172 | 2026-04-12 13:50 | 2168476044 | Standard deposit (type 1). TransactionID is the payment system's deposit ID. AccountID matches the CID. CreditInternalID flows to Credit.CreditID. |
| 1 | 10927875 | 25707169 | 2026-04-12 13:43 | 2168476042 | Another standard deposit. Sequential TransactionIDs suggest batch processing from the payment gateway. |
| 1 | 10927872 | 25707106 | 2026-04-12 13:42 | 2168476041 | Standard deposit from a different customer (AccountID 25707106). Gap in TransactionID (872 vs 875) suggests non-deposit transactions interleaved. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountTypeID | int | NO | - | CODE-BACKED | Type of account originating the transaction. Value 1 observed for standard deposits. Part of composite PK for deduplication. Identifies which payment system or account type generated the credit. |
| 2 | TransactionID | varchar(50) | NO | - | CODE-BACKED | Unique transaction identifier from the payment system. Combined with AccountTypeID and AccountID to form the dedup key. String type allows non-numeric IDs from various payment providers. |
| 3 | AccountID | varchar(50) | NO | - | CODE-BACKED | Account identifier from the payment system. Typically matches the CID (customer ID) but stored as varchar to accommodate different account numbering systems. |
| 4 | DateCreated | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the credit event. Part of composite PK - allows the same TransactionID to appear on different dates (though unlikely). Uses datetime2 for sub-millisecond precision from source systems. |
| 5 | CreditInternalID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing internal ID that becomes Credit.CreditID. Generated on successful insert. Retrieved via SCOPE_IDENTITY() by InsertCredit. NC index supports direct lookup by CreditInternalID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.Credit | CreditID | Implicit | Credit.CreditID sourced from CreditInternalID |
| AffiliateCommission.InsertCredit | INSERT/SELECT | Writer/Reader | Dedup check + ID generation |
| AffiliateCommission.CheckDepositExists | SELECT | Reader | Checks if a deposit has been processed |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.InsertCredit | Stored Procedure | Writer - dedup + ID generation |
| AffiliateCommission.CheckDepositExists | Stored Procedure | Reader - existence check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditAccountMapping | CLUSTERED PK | AccountTypeID, TransactionID, AccountID, DateCreated | - | - | Active |
| IX_CreditAccountMapping_CreditInternalID | NC | CreditInternalID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditAccountMapping | PRIMARY KEY | Composite key for deduplication |

---

## 8. Sample Queries

### 8.1 Look up CreditID by transaction details
```sql
SELECT CreditInternalID AS CreditID
FROM AffiliateCommission.CreditAccountMapping WITH (NOLOCK)
WHERE AccountTypeID = 1
  AND TransactionID = '10927876'
  AND AccountID = '25707172';
```

### 8.2 Check for duplicate transactions
```sql
SELECT AccountTypeID, TransactionID, AccountID, COUNT(*) AS Occurrences
FROM AffiliateCommission.CreditAccountMapping WITH (NOLOCK)
GROUP BY AccountTypeID, TransactionID, AccountID
HAVING COUNT(*) > 1;
```

### 8.3 Recent mappings with corresponding Credit records
```sql
SELECT TOP 10 cam.CreditInternalID, cam.AccountTypeID, cam.TransactionID,
       cam.AccountID, cam.DateCreated,
       c.CreditTypeID, c.Amount, c.IsFirstDeposit
FROM AffiliateCommission.CreditAccountMapping cam WITH (NOLOCK)
LEFT JOIN AffiliateCommission.Credit c WITH (NOLOCK) ON cam.CreditInternalID = c.CreditID
ORDER BY cam.CreditInternalID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-3405](https://etoro-jira.atlassian.net/browse/PART-3405) | Jira | CreditAccountMapping dedup pattern and CreditID generation redesign (Jan-Feb 2025) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditAccountMapping | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditAccountMapping.sql*
