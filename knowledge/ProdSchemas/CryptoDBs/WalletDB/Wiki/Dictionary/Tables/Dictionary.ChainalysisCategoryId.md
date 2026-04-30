# Dictionary.ChainalysisCategoryId

> Lookup table mapping Chainalysis risk category IDs to their names, used to classify blockchain addresses by the type of activity they are associated with during AML screening.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | categoryId (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table stores the Chainalysis KYT (Know Your Transaction) category taxonomy. When the platform screens a cryptocurrency address through Chainalysis, the response includes one or more category IDs classifying the address by the type of entity or activity it is associated with. This table provides the human-readable names for those category codes.

These categories are fundamental to the platform's AML decision-making. When a customer attempts to send or receive crypto, the address is screened and categorized. Categories like "sanctioned entity", "darknet market", or "ransomware" trigger automatic blocks, while categories like "exchange" or "hosted wallet" are generally benign.

The category IDs are defined by Chainalysis (the external provider) and stored locally for fast lookups during screening workflows. The non-sequential IDs (missing 5, 8, 40) reflect the external provider's taxonomy evolution.

---

## 2. Business Logic

### 2.1 Risk Category Classification

**What**: Categories are implicitly grouped by risk level for AML decision-making.

**Columns/Parameters Involved**: `categoryId`, `CategoryName`

**Rules**:
- **High Risk / Blocked**: child abuse material (1), darknet market (2), sanctioned entity (3), stolen funds (6), ransomware (12), terrorist financing (23), sanctioned jurisdiction (25), fraud shop (28), illicit actor-org (29), malware (35), stolen bitcoins (42), stolen ether (43)
- **Elevated Risk / Review**: no kyc exchange (4), mixing (13), gambling (16), scam (18), special measures (34), online pharmacy (36), seized funds (39)
- **Low Risk / Benign**: mining pool (7), exchange (21), mining (22), hosted wallet (11), merchant services (17), p2p exchange (19), atm (24), lending (26), decentralized exchange (27), bridge (37), nft platform (38)
- **Technical / Neutral**: other (9), ethereum contract (10), erc20 token (15), ico (14), infrastructure as a service (30), token smart contract (31), smart contract (32), protocol privacy (33), unnamed service (41), custom address (999), none (20)

### 2.2 External Provider Taxonomy

**What**: IDs are assigned by Chainalysis, not the eToro platform.

**Columns/Parameters Involved**: `categoryId`

**Rules**:
- ID gaps (5, 8, 40) indicate categories deprecated or restructured by Chainalysis over time
- ID 999 is a custom eToro-specific category for internally tagged addresses
- New categories may be added as Chainalysis expands their taxonomy
- The platform must handle unknown category IDs gracefully

---

## 3. Data Overview

| categoryId | CategoryName | Meaning |
|---|---|---|
| 3 | sanctioned entity | Address belongs to a OFAC/EU/UN sanctioned entity. Highest risk - all transactions automatically blocked. Regulatory reporting required. |
| 6 | stolen funds | Address associated with known stolen cryptocurrency. Transactions blocked; law enforcement may request information. |
| 20 | none | No specific category assigned by Chainalysis. The address has no known associations with any classified entity or activity type. |
| 21 | exchange | Address belongs to a known cryptocurrency exchange (e.g., Binance, Coinbase). Generally low risk as exchanges have their own KYC/AML programs. |
| 999 | custom address | eToro-specific category for internally tagged addresses. Used for addresses that need special handling based on internal compliance decisions rather than Chainalysis classification. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | categoryId | int | NO | - | CODE-BACKED | Chainalysis-assigned category identifier. Values are non-sequential (gaps at 5, 8, 40) as they mirror the external provider's taxonomy. 999 is a custom eToro extension. Used as the join key when resolving Chainalysis screening results to human-readable category names. |
| 2 | CategoryName | varchar(100) | NO | - | CODE-BACKED | Human-readable category name from the Chainalysis taxonomy. All lowercase. Used in compliance dashboards, screening reports, and AML alert descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found in the Wallet schema. Category IDs from Chainalysis screening results are matched against this table by application logic for display and decision-making purposes.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | categoryId ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all Chainalysis categories
```sql
SELECT categoryId, CategoryName
FROM Dictionary.ChainalysisCategoryId WITH (NOLOCK)
ORDER BY categoryId
```

### 8.2 Find all high-risk categories
```sql
SELECT categoryId, CategoryName
FROM Dictionary.ChainalysisCategoryId WITH (NOLOCK)
WHERE CategoryName IN (
  'sanctioned entity', 'darknet market', 'stolen funds',
  'ransomware', 'terrorist financing', 'sanctioned jurisdiction',
  'child abuse material', 'fraud shop', 'illicit actor-org',
  'malware', 'stolen bitcoins', 'stolen ether'
)
ORDER BY categoryId
```

### 8.3 Category name lookup for screening results
```sql
SELECT sv.AddressHash, cc.CategoryName, sv.Created AS ScreeningDate
FROM Wallet.ScreeningValidations sv WITH (NOLOCK)
JOIN Dictionary.ChainalysisCategoryId cc WITH (NOLOCK) ON sv.CategoryId = cc.categoryId
WHERE sv.Created > DATEADD(DAY, -7, GETUTCDATE())
ORDER BY sv.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChainalysisCategoryId | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ChainalysisCategoryId.sql*
