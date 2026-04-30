# Billing.fn_IsUserFromAmericanRegulation

> Inline table-valued function that returns a single-row result (flag=1 or 0) indicating whether a customer is subject to US financial regulation, used to gate US-specific payment routing logic.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE with one row: flag INT (1=US regulated, 0=not) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.fn_IsUserFromAmericanRegulation determines whether a customer falls under US financial regulations (eToroUS, FinCEN, or FinCEN+FINRA) for the purpose of payment routing decisions. It is used to route US-regulated customers through US-compliant payment processing paths that differ from international flows.

The function exists because eToro operates under multiple regulatory jurisdictions, and US regulations (regulated by FinCEN and FINRA) impose different payment restrictions compared to European (CySEC/FCA) or Australian (ASIC) regulation. Payment routing code calls this function to determine if US-specific rules apply before selecting a credit card processing depot.

The regulation determination uses a two-step priority: if the customer has any approved deposit on record (PaymentStatusID=2), the `RegulationID` field on their customer record is used (the actual regulatory assignment based on real activity). If no approved deposit exists, the `DesignatedRegulationID` is used (the intended regulation before first deposit). This ensures new customers are correctly routed even before their first deposit settles.

---

## 2. Business Logic

### 2.1 Regulation Selection Logic (Deposit-Based Priority)

**What**: Chooses between RegulationID and DesignatedRegulationID based on deposit history.

**Columns/Parameters Involved**: `@CID`, BackOffice.Customer.RegulationID, BackOffice.Customer.DesignatedRegulationID, Billing.Deposit.PaymentStatusID

**Rules**:
- If customer has at least one deposit with PaymentStatusID=2 (Approved) -> use `RegulationID` (actual active regulation).
- If no approved deposit exists -> use `DesignatedRegulationID` (pre-assigned regulation).
- US regulation IDs: 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA. Any of these -> flag=1.
- All other regulation IDs (1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=SEBI, etc.) -> flag=0.
- If BackOffice.Customer has no row for @CID (LEFT JOIN): regToUse = NULL -> flag=0 (non-US by default).

**Diagram**:
```
Customer @CID
    |
BackOffice.Customer: RegulationID + DesignatedRegulationID
    |
Has approved deposit?
  YES -> use RegulationID
  NO  -> use DesignatedRegulationID
    |
RegulationID IN (6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA)?
  YES -> flag = 1 (US regulated)
  NO  -> flag = 0 (non-US)
```

---

## 3. Data Overview

N/A for Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID. Used to look up BackOffice.Customer for RegulationID/DesignatedRegulationID and to check Billing.Deposit for approved deposits. |
| RETURN: flag | int | NO | - | VERIFIED | 1=customer is under US financial regulation (RegulationID IN (6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA)), 0=customer is not under US regulation. Always returns exactly one row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer (cross-schema) | Lookup | Reads RegulationID and DesignatedRegulationID for the customer. |
| Billing.Deposit.PaymentStatusID | Billing.Deposit | Lookup | Checks if any approved deposit (PaymentStatusID=2) exists for the CID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.fn_GetCCDepotCountryId | @CID | Caller | Calls this function to determine whether US-specific credit card processing depot logic should apply. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.fn_IsUserFromAmericanRegulation (inline TVF)
├── BackOffice.Customer (table - cross-schema)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table (cross-schema) | Reads RegulationID and DesignatedRegulationID for the CID. |
| Billing.Deposit | Table | Checks for approved deposits (PaymentStatusID=2) to determine which regulation field to use. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.fn_GetCCDepotCountryId | Function | CROSS APPLY / OUTER APPLY caller - determines US regulation status to select the appropriate CC depot routing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Table-Valued Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Always returns 1 row | Design | The `FROM (SELECT 0 AS v) dummy` with LEFT JOIN ensures a result is always returned even if the CID does not exist in BackOffice.Customer. |

---

## 8. Sample Queries

### 8.1 Check if a specific customer is US-regulated

```sql
SELECT flag AS IsUSRegulated
FROM Billing.fn_IsUserFromAmericanRegulation(12345);
-- Returns: 1 if US-regulated, 0 otherwise
```

### 8.2 Use in a join to filter US-regulated customers

```sql
SELECT d.CID, d.Amount, d.FundingTypeID
FROM Billing.Deposit d WITH (NOLOCK)
CROSS APPLY Billing.fn_IsUserFromAmericanRegulation(d.CID) f
WHERE f.flag = 1  -- US-regulated customers only
  AND d.CreateDate >= '2026-01-01'
ORDER BY d.CreateDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
```

### 8.3 Check regulation for multiple customers

```sql
SELECT
    c.CID,
    c.RegulationID,
    f.flag AS IsUSRegulated
FROM BackOffice.Customer c WITH (NOLOCK)
CROSS APPLY Billing.fn_IsUserFromAmericanRegulation(c.CID) f
WHERE f.flag = 1
ORDER BY c.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.fn_IsUserFromAmericanRegulation | Type: Inline Table-Valued Function | Source: etoro/etoro/Billing/Functions/Billing.fn_IsUserFromAmericanRegulation.sql*
