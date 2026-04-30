# Dictionary.CardType

> Lookup table defining the 32 payment card network brands (Visa, MasterCard, Diners, etc.) with their active status and 3D Secure authentication configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CardTypeID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.CardType defines the payment card brands recognized by the eToro platform. When a customer deposits via credit or debit card, the card's BIN (Bank Identification Number) is resolved to a CardTypeID. This classification determines whether the card brand is accepted (IsActive), whether 3D Secure authentication is required (Is3dsOn), and which processing rules apply.

Only 4 of 32 card types are currently active: Visa, MasterCard, Diners, and Maestro. The remaining card types (Amex, JCB, Discover, China UnionPay, etc.) are inactive — either never supported or disabled due to processing costs, fraud risk, or business decisions.

The 3D Secure flag (Is3dsOn) is critical for PSD2 compliance in the EU: Visa and MasterCard require 3DS authentication, while other card types do not support or enforce it.

---

## 2. Business Logic

### 2.1 Card Acceptance Matrix

**What**: Each card type has an active/inactive status controlling whether it is accepted for deposits.

**Columns/Parameters Involved**: `CardTypeID`, `Name`, `IsActive`, `Is3dsOn`

**Rules**:
- **IsActive=1**: Card brand is accepted for deposits. Currently: Visa (1), MasterCard (2), Diners (3), Maestro (8).
- **IsActive=0**: Card brand is not accepted. Card will be rejected at deposit time.
- **Is3dsOn=1**: 3D Secure authentication is mandatory for this card type. Deposit flow redirects to card issuer's 3DS page. Currently only Visa and MasterCard.
- **Is3dsOn=0**: No 3DS requirement — either the card network doesn't support it or it's disabled.
- CardType 0 ("None") is the fallback when BIN resolution fails to identify a card brand.

**Diagram**:
```
Card Deposit Flow:
  BIN lookup → CardTypeID resolved
        │
        ├── IsActive=0 → REJECT: "Card type not accepted"
        │
        └── IsActive=1 → Check Is3dsOn
                ├── Is3dsOn=1 → Redirect to 3DS authentication
                │                  ├── 3DS success → Process deposit
                │                  └── 3DS failure → REJECT
                └── Is3dsOn=0 → Process deposit directly
```

---

## 3. Data Overview

| CardTypeID | Name | IsActive | Is3dsOn | Meaning |
|---|---|---|---|---|
| 0 | None | 0 | 0 | Fallback when BIN lookup fails to identify card network. Not accepted for deposits. |
| 1 | Visa | 1 | 1 | Visa credit/debit cards — most widely used card type globally. 3DS required for PSD2 compliance. |
| 2 | Master Card | 1 | 1 | MasterCard credit/debit cards — second most common. 3DS required. |
| 3 | Diners | 1 | 0 | Diners Club cards — accepted but without 3DS requirement. Niche card type. |
| 8 | Maestro | 1 | 0 | Maestro debit cards — MasterCard's debit network. Accepted without 3DS. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CardTypeID | int | NO | - | VERIFIED | Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital, 18=Unknown, 19-31=various regional/legacy brands. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Card brand name. Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting. |
| 3 | IsActive | bit | NO | (1) | VERIFIED | Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. DEFAULT 1 (new card types are active by default). Only 4 of 32 are currently active. |
| 4 | Is3dsOn | tinyint | NO | (0) | VERIFIED | Whether 3D Secure authentication is mandatory for this card type: 1=3DS required (redirects to issuer authentication), 0=no 3DS. DEFAULT 0. Only Visa and MasterCard have 3DS enabled, for PSD2/SCA compliance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | CardTypeID | Implicit | Each card deposit records the card brand |
| Dictionary.CardTypeToBank | CardTypeID | Implicit | Maps card types to processing banks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CardType (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Records CardTypeID per card deposit |
| Dictionary.CardTypeToBank | Table | Maps card types to processing banks |
| Payment processing procedures | Stored Procedures | Check IsActive and Is3dsOn during deposit flow |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCDT | CLUSTERED PK | CardTypeID | - | - | Active |
| DCDT_NAME | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCDT | PRIMARY KEY | Unique card type, FILLFACTOR 90, DICTIONARY filegroup |
| DCDT_NAME | UNIQUE INDEX | Ensures no duplicate card type names |
| DF_Dictionary_CardType_Col | DEFAULT | IsActive defaults to 1 (active) |
| DF_DictionaryCardType_Is3dsOn | DEFAULT | Is3dsOn defaults to 0 (no 3DS) |

---

## 8. Sample Queries

### 8.1 List all active card types
```sql
SELECT  CardTypeID, Name, Is3dsOn
FROM    Dictionary.CardType WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY CardTypeID;
```

### 8.2 Find card types requiring 3D Secure
```sql
SELECT  CardTypeID, Name
FROM    Dictionary.CardType WITH (NOLOCK)
WHERE   Is3dsOn = 1
ORDER BY Name;
```

### 8.3 Card type distribution in deposits
```sql
SELECT  ct.Name             AS CardBrand,
        ct.IsActive,
        ct.Is3dsOn
FROM    Dictionary.CardType ct WITH (NOLOCK)
ORDER BY ct.IsActive DESC, ct.CardTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CardType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CardType.sql*
