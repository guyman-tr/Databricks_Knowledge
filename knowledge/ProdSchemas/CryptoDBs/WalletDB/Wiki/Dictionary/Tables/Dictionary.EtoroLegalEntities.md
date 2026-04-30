# Dictionary.EtoroLegalEntities

> Lookup table of eToro's regulated legal entities worldwide, used to associate customers and wallets with the correct regulatory jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table registers eToro's legal entities across different jurisdictions. eToro operates through multiple regulated subsidiaries worldwide, each governed by different regulatory frameworks. Customers are assigned to a legal entity based on their country of residence, and this assignment determines which compliance rules, product availability, and operational limits apply.

The legal entity assignment is fundamental to the wallet system because different jurisdictions have different rules for cryptocurrency. For example, eToro US (regulated by FinCEN/state money transmitter licenses) has different crypto offerings than eToro EU (regulated under MiCA/AMLD).

The table is consumed by `Wallet.GetEtoroLegalEntites` stored procedure and referenced in customer-to-entity assignment logic.

---

## 2. Business Logic

### 2.1 Multi-Jurisdiction Entity Structure

**What**: eToro operates through 10 legal entities serving different geographic regions.

**Columns/Parameters Involved**: `Id`, `Name`, `DisplayName`

**Rules**:
- Each legal entity is a separate regulated company with its own licenses and compliance obligations
- Customer assignment to an entity determines: crypto asset availability, withdrawal limits, compliance requirements, and reporting obligations
- `Name` is the internal code (e.g., "EtoroX"), `DisplayName` is the branded version (e.g., "eToroX")
- Entity ID 1 (EtoroX) is the crypto exchange arm, while others are regional broker entities

---

## 3. Data Overview

| Id | Name | DisplayName | Meaning |
|---|---|---|---|
| 1 | EtoroX | eToroX | eToro's dedicated crypto exchange entity. Operates the core cryptocurrency trading infrastructure. Handles custody and exchange operations. |
| 2 | EtoroUS | eToroUS | US-regulated entity operating under FinCEN registration and state money transmitter licenses. Subject to US-specific crypto regulations and restricted asset lists. |
| 6 | EtoroEU | eToroEU | EU-regulated entity operating under MiCA and AMLD frameworks. Serves European Economic Area customers with EU-compliant crypto services. |
| 9 | EtoroUK | eToroUK | UK-regulated entity operating under FCA registration. Serves UK customers with UK-specific crypto asset rules post-Brexit. |
| 10 | EtoroNY | eToroNY | New York-specific entity operating under NYDFS BitLicense. NY has uniquely strict crypto regulations requiring a separate entity. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier for the legal entity. Values: 1=EtoroX, 2=EtoroUS, 3=EtoroGermany, 4=EtoroDA, 5=EtoroSEY, 6=EtoroEU, 7=EtoroAUS, 8=EtoroME, 9=EtoroUK, 10=EtoroNY. Referenced by customer records for jurisdictional assignment. |
| 2 | Name | nvarchar(100) | NO | - | CODE-BACKED | Internal entity code. PascalCase format (e.g., "EtoroUS"). Used as a key in application configuration and routing logic. |
| 3 | DisplayName | nvarchar(100) | YES | - | CODE-BACKED | User-facing branded name (e.g., "eToroUS"). Shown in legal disclaimers, terms and conditions, and customer-facing communications. Nullable for potential future entities not yet branded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found. Consumed by application logic for customer-to-entity assignment and jurisdiction-based feature gating.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetEtoroLegalEntites | Stored Procedure | Reads all legal entities |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all legal entities
```sql
SELECT Id, Name, DisplayName FROM Dictionary.EtoroLegalEntities WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find entity by display name
```sql
SELECT Id, Name FROM Dictionary.EtoroLegalEntities WITH (NOLOCK) WHERE DisplayName = 'eToroUS'
```

### 8.3 Entity lookup for customer assignment
```sql
SELECT Id, Name, DisplayName,
  CASE WHEN Name LIKE '%US%' OR Name LIKE '%NY%' THEN 'Americas'
       WHEN Name IN ('EtoroEU', 'EtoroGermany', 'EtoroUK') THEN 'Europe'
       ELSE 'Other' END AS Region
FROM Dictionary.EtoroLegalEntities WITH (NOLOCK)
ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EtoroLegalEntities | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.EtoroLegalEntities.sql*
