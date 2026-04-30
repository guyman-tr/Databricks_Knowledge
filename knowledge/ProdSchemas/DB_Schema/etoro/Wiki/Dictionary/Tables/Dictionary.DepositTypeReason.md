# Dictionary.DepositTypeReason

> Lookup table defining the 8 reasons why a deposit was classified with a specific type — covering approval outcomes, declines, restrictions, and user/BackOffice actions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a customer's payment method (funding source) is assigned a deposit type in `Billing.CustomerToFunding`, a reason is also recorded explaining why that type was assigned. This table enumerates those reasons: first-time deposit approval (FtdApproved), various decline scenarios (Declined, CvvRefused, CountryRestriction, CardTypeRestriction, NameConflict), and manual actions (ByBO = by BackOffice, ByUser = by the user).

Without this table, the billing system would have no way to explain why a particular deposit type was applied to a customer's payment method. The reason helps customer service understand why a card was restricted, helps compliance trace manual interventions, and helps analytics measure decline rates by cause.

The table is referenced by `Billing.CustomerToFunding` which stores the deposit type reason for each customer-funding link.

---

## 2. Business Logic

### 2.1 Deposit Type Reason Categories

**What**: Reasons explain the outcome of the deposit type classification process.

**Columns/Parameters Involved**: `ReasonID`, `Reason`

**Rules**:
- FtdApproved (1) — first-time deposit was approved, determining the deposit type for future deposits
- Declined (2) — generic decline by the payment processor
- CvvRefused (3) — card verification value check failed
- CountryRestriction (4) — the payment method's country is restricted for this deposit type
- ByBO (5) — BackOffice manually set the deposit type (compliance or risk override)
- ByUser (6) — the user themselves changed the deposit type preference
- CardTypeRestriction (7) — the card brand/type is not accepted for this deposit type
- NameConflict (8) — the cardholder name doesn't match the account holder name

---

## 3. Data Overview

| ReasonID | Reason | Meaning |
|---|---|---|
| 1 | FtdApproved | First-time deposit was successfully processed and approved — the deposit type for this payment method is now set based on the FTD outcome |
| 2 | Declined | The payment processor declined the transaction — the deposit type assignment reflects a failed attempt |
| 5 | ByBO | A BackOffice operator manually set or overrode the deposit type — typically done by compliance or risk teams to force a specific classification |
| 7 | CardTypeRestriction | The card brand or type (e.g., prepaid, virtual) is restricted for this deposit type — the system automatically classified the rejection reason |
| 8 | NameConflict | The name on the payment method does not match the registered account holder — this triggers enhanced verification requirements and may restrict the deposit type |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | VERIFIED | Primary key identifying the deposit type reason. 1=FtdApproved, 2=Declined, 3=CvvRefused, 4=CountryRestriction, 5=ByBO, 6=ByUser, 7=CardTypeRestriction, 8=NameConflict. Referenced by Billing.CustomerToFunding.DepositTypeReasonID. |
| 2 | Reason | varchar(50) | YES | - | VERIFIED | Human-readable reason label. Nullable in DDL but all 8 rows have values populated. Used in BackOffice UI and billing reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CustomerToFunding | DepositTypeReasonID | Implicit | Stores the reason why the deposit type was assigned to each customer-funding link |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositTypeReason (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | References — stores deposit type reason per funding link |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DepositTypeReason | CLUSTERED | ReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all deposit type reasons
```sql
SELECT  ReasonID,
        Reason
FROM    Dictionary.DepositTypeReason WITH (NOLOCK)
ORDER BY ReasonID
```

### 8.2 Classify reasons by outcome type
```sql
SELECT  ReasonID,
        Reason,
        CASE
            WHEN ReasonID = 1 THEN 'Approved'
            WHEN ReasonID IN (5, 6) THEN 'Manual Override'
            ELSE 'Decline/Restriction'
        END AS Category
FROM    Dictionary.DepositTypeReason WITH (NOLOCK)
ORDER BY ReasonID
```

### 8.3 Resolve deposit type reason for customer funding records
```sql
SELECT  cf.CID,
        cf.FundingID,
        dtr.Reason AS DepositTypeReason
FROM    Billing.CustomerToFunding cf WITH (NOLOCK)
        JOIN Dictionary.DepositTypeReason dtr WITH (NOLOCK) ON cf.DepositTypeReasonID = dtr.ReasonID
WHERE   cf.CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositTypeReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositTypeReason.sql*
