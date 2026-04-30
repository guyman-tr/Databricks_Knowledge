# Dictionary.Bank

> Lookup table defining the banking and payment processing partners used by eToro for fund custody and transaction processing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | BankID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.Bank defines the financial institutions and payment processors that eToro partners with for fund custody, deposit processing, and payment routing. Each bank entry represents an entity that holds client funds or processes payment transactions on behalf of eToro's various regulated entities.

This table is critical to the payments infrastructure. Different eToro jurisdictions (CySEC, FCA, ASIC) use different banking partners for fund segregation, and payment routing must direct transactions to the correct processing partner. Dictionary.Regulation references this table via BankID to map each regulatory entity to its custodian bank.

Bank records are managed by the operations/finance team. The IsActive flag allows decommissioning legacy partners without deleting their records (important for historical transaction audit trails). Active banks are used in payment routing; inactive ones are retained for reporting on past transactions.

---

## 2. Business Logic

### 2.1 Active vs Legacy Banking Partners

**What**: Bank partner lifecycle management — active partners process transactions, inactive ones are retained for history.

**Columns/Parameters Involved**: `BankID`, `Name`, `IsActive`

**Rules**:
- Active banks (IsActive=1): WireCard, PayPal, Wire, Worldpay, Checkout, Nuvei — currently processing transactions
- Inactive banks (IsActive=0): UNKNOWN, CAL, Neteller(1-Pay), Western, LeumiCard, B&S, GCS, Barclay Bank, Adyen — no new transactions routed here
- Bank 0 (UNKNOWN) is a default/null marker for records without a known banking partner
- Payment routing procedures check IsActive before assigning a bank to new transactions

---

## 3. Data Overview

| BankID | Name | IsActive | Meaning |
|---|---|---|---|
| 0 | UNKNOWN | 0 | Default/placeholder for records with no identified banking partner. Used as a null-safe fallback in older data. |
| 7 | LeumiCard | 0 | Historical Israeli banking partner (now decommissioned). Referenced by Regulation.BankID for CySEC and FCA entities — likely the original banking partner before migration to current providers. |
| 11 | Worldpay | 1 | Active payment processor — one of the major global card payment gateways processing eToro credit card deposits. |
| 13 | Checkout | 1 | Active payment processor — Checkout.com, handling card payment processing for eToro. |
| 14 | Nuvei | 1 | Active payment processor — Nuvei payment technology platform, one of eToro's current processing partners. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | int | NO | - | CODE-BACKED | Primary key identifying the banking/payment partner. Referenced by Dictionary.Regulation.BankID to link regulatory entities to their custodian banks. Referenced by Dictionary.CardTypeToBank and Dictionary.BankBin for payment card routing. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable name of the banking partner. UNIQUE constraint ensures no duplicates. Used in payment routing reports and back-office displays. |
| 3 | IsActive | bit | NO | - | CODE-BACKED | Whether this banking partner is currently processing transactions. 1=active (new transactions can be routed), 0=inactive (retained for historical audit only). Payment routing procedures filter on IsActive=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Regulation | BankID | FK | Maps each regulatory entity to its custodian banking partner |
| Dictionary.CardTypeToBank | BankID | FK | Links card types to processing banks |
| Dictionary.BankBin | BankID | FK | Maps BIN ranges to processing banks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Regulation | Table | FK: BankID links regulation to custodian bank |
| Dictionary.CardTypeToBank | Table | FK: BankID for card-to-bank routing |
| Dictionary.BankBin | Table | FK: BankID for BIN-to-bank mapping |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DBNK | CLUSTERED PK | BankID ASC | - | - | Active |
| DBNK_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DBNK | PRIMARY KEY | Unique bank partner identifier |
| DBNK_NAME | UNIQUE | Ensures no duplicate bank partner names |

---

## 8. Sample Queries

### 8.1 List all active banking partners
```sql
SELECT  BankID,
        Name
FROM    [Dictionary].[Bank] WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY Name;
```

### 8.2 Show regulations with their banking partners
```sql
SELECT  r.ID AS RegulationID,
        r.Name AS RegulationName,
        r.JurisdictionName,
        b.Name AS BankPartner,
        b.IsActive AS BankIsActive
FROM    [Dictionary].[Regulation] r WITH (NOLOCK)
LEFT JOIN [Dictionary].[Bank] b WITH (NOLOCK)
        ON r.BankID = b.BankID
ORDER BY r.ID;
```

### 8.3 Find all banks with their dependent objects
```sql
SELECT  b.BankID,
        b.Name,
        b.IsActive,
        (SELECT COUNT(*) FROM [Dictionary].[Regulation] r WITH (NOLOCK) WHERE r.BankID = b.BankID) AS RegulationCount,
        (SELECT COUNT(*) FROM [Dictionary].[BankBin] bb WITH (NOLOCK) WHERE bb.BankID = b.BankID) AS BinCount
FROM    [Dictionary].[Bank] b WITH (NOLOCK)
ORDER BY b.BankID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Bank. Business meaning derived from FK relationships and live data analysis.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Bank | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Bank.sql*
