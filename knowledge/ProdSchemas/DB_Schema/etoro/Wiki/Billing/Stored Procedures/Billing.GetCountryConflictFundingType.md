# Billing.GetCountryConflictFundingType

> Returns all funding types with their IsCountryConflictActive flag from Dictionary.FundingType. Used to identify which payment methods have country conflict validation enabled. Originally intended to return only active conflicts (WHERE clause was commented out).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountryConflictFundingType` returns the `IsCountryConflictActive` flag for all funding types. A "country conflict" occurs when the customer's registered country differs from the card's issuing country (BIN country) — for example, a UK-registered customer using a US-issued card. When `IsCountryConflictActive=1` for a funding type, the payment system enforces country conflict checks for deposits made with that payment method.

The procedure currently returns ALL rows from Dictionary.FundingType (44 rows), not just those with `IsCountryConflictActive=1`. The original WHERE clause filtering to active conflicts only was commented out: `--WHERE IsCountryConflictActive = 1`. This change makes the caller responsible for filtering, or it may indicate the procedure is now used to load the full matrix rather than just the active set.

---

## 2. Business Logic

### 2.1 Full Funding Type Country Conflict Flag Read

**What**: Returns FundingTypeID and IsCountryConflictActive for all funding types.

**Rules**:
- No parameters, no WHERE clause (filtered version commented out)
- `Dictionary.FundingType` has 44 rows (IDs 1-44, gap at 41)
- `IsCountryConflictActive` is a bit flag: 1 = enforce country-of-registration vs. BIN-country check for this payment method
- Caller determines which funding types have active conflict checking

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Payment method identifier. References Dictionary.FundingType. 44 total rows (IDs 1-44, gap at 41). |
| 2 | IsCountryConflictActive | bit | YES | - | VERIFIED | 1 = country conflict validation is active for this payment method. When enabled, the system checks whether the card's BIN country matches the customer's registered country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID, IsCountryConflictActive | Dictionary.FundingType | Read | Full table scan for country conflict flags. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No explicit GRANT EXECUTE found) | - | Payment routing / deposit validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryConflictFundingType (procedure)
└── Dictionary.FundingType (table)
```

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountryConflictFundingType
-- Returns: all 44 FundingTypeIDs with IsCountryConflictActive flag

-- Filter to only active conflict types:
SELECT FundingTypeID FROM Dictionary.FundingType WITH (NOLOCK)
WHERE IsCountryConflictActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountryConflictFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryConflictFundingType.sql*
