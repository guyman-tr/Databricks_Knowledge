# AffiliateCommission.RegistrationCommissionType

> Table-valued parameter type used to pass registration commission records in bulk to stored procedures that save affiliate commissions earned from customer registrations.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | CID + Tier (composite logical key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RegistrationCommissionType is a table-valued parameter (TVP) that defines the shape of registration-based commission data passed to stored procedures. It models the commission earned by affiliates when a customer they referred registers on the platform. Each row represents one commission record for a specific registration at a specific tier level.

This type exists because a single registration can generate commissions for multiple affiliates in a multi-tier referral chain. The TVP allows the application to batch all tier commissions into a single procedure call, ensuring transactional atomicity. This is the newest of the three commission TVPs, created in February 2022 (PART-1195) to support the registration commission model.

The type is consumed by SaveRegistrationCommission and InsertRegistration. SaveRegistrationCommission receives the TVP, deletes existing commissions for the registration, updates the Registration record's processing state and date, and inserts the new commission rows - all within a single transaction. Note that the CID column in this TVP is NOT used by SaveRegistrationCommission (which takes @RegistrationID as a scalar parameter); CID is used by InsertRegistration for customer identification.

---

## 2. Business Logic

### 2.1 Registration-Based Commission Model

**What**: Affiliates earn commissions when referred customers complete platform registration.

**Columns/Parameters Involved**: `CID`, `AffiliateID`, `Tier`, `Commission`

**Rules**:
- Registration commissions are simpler than credit or position commissions - they fire once per customer registration
- CID (Customer ID) links the commission to the specific customer who registered
- Multi-tier: Tier 1 = direct referrer, Tier 2+ = upstream affiliates in the chain

**Diagram**:
```
Customer registers on platform
       |
       v
  [Registration Event]
       |
       +-- Tier 1: Direct affiliate -> Commission $5.00
       +-- Tier 2: Master affiliate  -> Commission $1.00
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type, not a persisted table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the newly registered customer. Used by InsertRegistration to link the commission to the customer. SaveRegistrationCommission does not use this column (it uses @RegistrationID scalar parameter instead). |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Identifier of the affiliate earning this registration commission. References the affiliate system (dbo.tblaff_Affiliates). Inserted directly into RegistrationCommission.AffiliateID. |
| 3 | Commission | float | NO | - | CODE-BACKED | Dollar amount of commission earned for this registration event. Uses float type for consistency with the registration commission storage in RegistrationCommission table. |
| 4 | Tier | int | NO | - | CODE-BACKED | Level in the multi-tier affiliate referral chain. 1 = direct referrer, 2+ = upstream affiliates. Combined with RegistrationID, forms the composite PK in the target RegistrationCommission table. |
| 5 | Paid | bit | NO | - | CODE-BACKED | Whether this commission has been paid out to the affiliate. 0 = unpaid/pending, 1 = paid. Newly inserted commissions are typically unpaid (0). |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Identifier of the payment batch in which this commission was or will be paid. 0 when unpaid; populated with the payment batch ID during affiliate payout processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | AffiliateCommission.Registration | Implicit | Links commission to the registered customer (via CID lookup) |
| - | AffiliateCommission.RegistrationCommission | Implicit | TVP rows are inserted into RegistrationCommission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Identifies the affiliate earning commission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.SaveRegistrationCommission | @AffiliateCommission | Parameter Type | TVP parameter carrying registration commission rows to save |
| AffiliateCommission.InsertRegistration | @AffiliateCommission | Parameter Type | TVP parameter carrying commission rows during registration insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.SaveRegistrationCommission | Stored Procedure | READONLY parameter for bulk commission insert |
| AffiliateCommission.InsertRegistration | Stored Procedure | READONLY parameter for commission insert during registration creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Table types do not support constraints beyond NOT NULL.

---

## 8. Sample Queries

### 8.1 Declare and populate for testing
```sql
DECLARE @Commissions AffiliateCommission.RegistrationCommissionType;
INSERT INTO @Commissions (CID, AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES
    (55001, 100, 5.00, 1, 0, 0),
    (55001, 200, 1.00, 2, 0, 0);
```

### 8.2 Pass to SaveRegistrationCommission
```sql
EXEC AffiliateCommission.SaveRegistrationCommission
    @RegistrationID = 7890,
    @AffiliateCommission = @Commissions,
    @RegistrationDate = '2026-01-15';
```

### 8.3 Inspect TVP contents before saving
```sql
SELECT CID, AffiliateID, Commission, Tier,
       CASE Paid WHEN 1 THEN 'Paid' ELSE 'Pending' END AS PaymentStatus
FROM @Commissions
ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-1195](https://etoro-jira.atlassian.net/browse/PART-1195) | Jira | Initial creation of registration commission support - new SP and TVP (Feb 2022) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationCommissionType | Type: User Defined Type | Source: fiktivo/AffiliateCommission/User Defined Types/AffiliateCommission.RegistrationCommissionType.sql*
