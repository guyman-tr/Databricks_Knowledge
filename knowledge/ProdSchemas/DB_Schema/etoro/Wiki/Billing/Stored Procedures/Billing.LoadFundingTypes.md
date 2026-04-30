# Billing.LoadFundingTypes

> Returns all rows from Dictionary.FundingType - a startup cache loader for the payment method type catalog defining all supported deposit and withdrawal instruments (credit cards, PayPal, wire transfer, crypto, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Dictionary.FundingType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadFundingTypes` is a critical startup cache loader that returns the complete payment method type catalog. The billing service loads this at startup to build an in-memory lookup of all FundingTypeIDs with their names, configurations, and feature flags (IsNewStyle, IsSingleFunding, IsDeposit, IsWithdraw, etc.). This cache drives routing decisions, feature availability checks (e.g., `IsFundingExists` uses IsNewStyle and IsSingleFunding), and display labels throughout the billing domain.

`Dictionary.FundingType` is the master reference for all payment instruments supported by eToro. Key types include: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 34=iDEAL, 35=Trustly, and many others covering the full range of deposit and withdrawal methods.

---

## 2. Business Logic

### 2.1 Full Funding Type Catalog Load

**What**: SELECT * with no filter - returns all rows and all columns from Dictionary.FundingType.

**Rules**:
- No parameters; no filtering; returns entire catalog
- **No WITH (NOLOCK) hint** (unlike most other Load* procedures) - reads with shared lock
- RETURN 0 signals success
- Key flag columns consumed by billing logic: `IsNewStyle` (new-style deduplication), `IsSingleFunding` (single active instrument per customer), `IsDeposit`, `IsWithdraw` (deposit/withdrawal eligibility)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Dictionary.FundingType`. Key columns include: FundingTypeID (PK), FundingTypeName, IsActive, IsDeposit, IsWithdraw, IsNewStyle, IsSingleFunding, and additional configuration flags. Notable values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 34=iDEAL, 35=Trustly.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Dictionary.FundingType | READ | Returns complete payment method type catalog; no NOLOCK hint |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup to populate the funding type lookup cache used throughout billing flow routing and feature flag evaluation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadFundingTypes (procedure)
└── Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Master payment method catalog; all rows returned without NOLOCK |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures. The cached data is used by: `Billing.IsFundingExists` (IsNewStyle+IsSingleFunding), deposit routing logic (IsDeposit/IsWithdraw flags), and display components (FundingTypeName).

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`
- **No WITH (NOLOCK)**: reads with shared lock; acceptable for a small, rarely-written reference table but inconsistent with other Load* procedures that use NOLOCK
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View all funding types with key flags
```sql
SELECT FundingTypeID, FundingTypeName, IsActive, IsNewStyle, IsSingleFunding,
       IsDeposit, IsWithdraw
FROM Dictionary.FundingType WITH (NOLOCK)
ORDER BY FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadFundingTypes | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadFundingTypes.sql*
