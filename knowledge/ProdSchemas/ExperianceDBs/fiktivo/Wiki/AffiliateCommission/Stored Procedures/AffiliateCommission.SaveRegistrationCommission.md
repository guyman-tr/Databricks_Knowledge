# AffiliateCommission.SaveRegistrationCommission

> Replaces the commission records for a registration within a transaction (DELETE + INSERT) and marks the registration as processed.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Registration + replaces RegistrationCommission |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

SaveRegistrationCommission is the commission finalization procedure for registrations. It atomically replaces existing registration commission records with new ones when commissions are recalculated due to attribution changes. Created as part of the registration commission support (PART-1195).

---

## 2. Business Logic

### 2.1 Atomic Commission Replacement

**What**: DELETE + INSERT pattern for registration commission rows.

**Columns/Parameters Involved**: `@RegistrationID`, `@RegistrationDate`, `@AffiliateCommission` (TVP)

**Rules**:
- DELETE RegistrationCommission WHERE RegistrationID = @RegistrationID
- UPDATE Registration SET RegistrationDate, IsProcessed = 1
- INSERT new RegistrationCommission from TVP
- All within a single transaction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationID | bigint (IN) | NO | - | CODE-BACKED | The registration whose commissions are being replaced. |
| 2 | @AffiliateCommission | RegistrationCommissionType (IN, TVP) | NO | - | CODE-BACKED | New commission rows (AffiliateID, Commission, Tier, Paid, PaymentID). |
| 3 | @RegistrationDate | datetime (IN) | NO | - | CODE-BACKED | Registration date to update on the Registration record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationCommission | DELETE + INSERT | Replaces commission rows |
| - | AffiliateCommission.Registration | UPDATE | Sets IsProcessed=1, RegistrationDate |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the registration commission engine.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.SaveRegistrationCommission (procedure)
+-- AffiliateCommission.Registration (table)
+-- AffiliateCommission.RegistrationCommission (table)
+-- AffiliateCommission.RegistrationCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | UPDATE IsProcessed, RegistrationDate |
| AffiliateCommission.RegistrationCommission | Table | DELETE + INSERT (full replacement) |
| AffiliateCommission.RegistrationCommissionType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration commission engine) | External | Saves recalculated commissions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRAN | Atomic DELETE + UPDATE + INSERT |

---

## 8. Sample Queries

### 8.1 Save recalculated registration commissions
```sql
DECLARE @CommData AffiliateCommission.RegistrationCommissionType
INSERT @CommData (AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES (3, 10.00, 1, 0, 0)

EXEC [AffiliateCommission].[SaveRegistrationCommission]
    @RegistrationID = 100,
    @AffiliateCommission = @CommData,
    @RegistrationDate = '2026-04-12'
```

### 8.2 Verify registration is processed
```sql
SELECT RegistrationID, IsProcessed, RegistrationDate
FROM [AffiliateCommission].[Registration] WITH (NOLOCK)
WHERE RegistrationID = 100
```

### 8.3 View registration commission breakdown
```sql
SELECT RegistrationID, AffiliateID, Commission, Tier, Paid
FROM [AffiliateCommission].[RegistrationCommission] WITH (NOLOCK)
WHERE RegistrationID = 100
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-1195: New SP for Registration Commission (2022-02-22)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.SaveRegistrationCommission | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.SaveRegistrationCommission.sql*
