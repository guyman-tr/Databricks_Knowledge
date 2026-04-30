# Billing.GetUserRegulationAndSuitabiltyTest

> Returns a customer's regulatory jurisdiction (RegulationID), white-label assignment (LabelID), and whether they have passed a suitability test (HasSuitabilityTest=1/0): used by the billing service to enforce regulation-specific and suitability-gated deposit rules.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; returns one row with HasSuitabilityTest, RegulationID, LabelID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetUserRegulationAndSuitabiltyTest (note: "Suitabilty" is a typo in the original name) retrieves the three core compliance attributes needed to apply regulation-specific deposit rules for a customer:

1. **HasSuitabilityTest**: Whether the customer has passed the required suitability assessment. Initially created to check ASIC (Australian Securities and Investments Commission) suitability test status (FB:23188), this flag gates certain deposit or product eligibility decisions.
2. **RegulationID**: The regulatory jurisdiction the customer falls under (from BackOffice.Customer). Determines which regulatory ruleset applies (e.g., CySEC, ASIC, FCA).
3. **LabelID**: The white-label brand the customer is associated with (added FB:23288). Some white-labels have different deposit eligibility or suitability requirements.

The LEFT JOIN to BackOffice.Suitability means HasSuitabilityTest=1 only when a suitability record exists for this CID; 0 otherwise (no row in Suitability = not passed).

Referenced in "Billing Service Database Readonly Separation" (Confluence MG) - part of the read-only billing service API.

---

## 2. Business Logic

### 2.1 Suitability Test Existence Check

**What**: Detects whether the customer has a suitability test record via LEFT JOIN existence pattern.

**Columns/Parameters Involved**: `BackOffice.Suitability.CID`, `HasSuitabilityTest`

**Rules**:
- LEFT JOIN `BackOffice.Suitability BSUT ON BSUT.CID = BCUS.CID`
- `CASE WHEN BSUT.CID IS NOT NULL THEN 1 ELSE 0 END AS HasSuitabilityTest`
- `BSUT.CID IS NOT NULL` = match found in Suitability = test passed
- `BSUT.CID IS NULL` = no Suitability record = test not passed (or not required)
- Originally created for ASIC suitability test gate (FB:23188)

### 2.2 Regulation and Label Fetch

**What**: Returns RegulationID and LabelID from BackOffice.Customer.

**Columns/Parameters Involved**: `BackOffice.Customer.RegulationID`, `BackOffice.Customer.LabelID`

**Rules**:
- `INNER JOIN Customer.Customer CUCU ON CUCU.CID = BCUS.CID` - added FB:23288; validates customer exists in Customer schema before returning data
- `RegulationID` from BackOffice.Customer - regulatory jurisdiction (CySEC, ASIC, FCA, etc.)
- `LabelID` from BackOffice.Customer - white-label brand identifier; added 16 Jul 2014 (FB:23288)
- Returns no row if CID not found in BackOffice.Customer or Customer.Customer (both INNER JOINed)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used as the anchor filter on BackOffice.Customer and joins to Customer.Customer and BackOffice.Suitability. |
| - | HasSuitabilityTest | BIT | NO | - | CODE-BACKED | 1 if the customer has a record in BackOffice.Suitability (suitability test passed or recorded). 0 if no Suitability record exists. Originally for ASIC suitability check (FB:23188). Used to gate deposit eligibility for regulated customers. |
| - | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction identifier from BackOffice.Customer. Determines which deposit rules apply. Common values correspond to CySEC (Cyprus), ASIC (Australia), FCA (UK), etc. |
| - | LabelID | INT | YES | - | CODE-BACKED | White-label brand identifier from BackOffice.Customer. Added FB:23288. Some white-label brands have distinct deposit or product eligibility rules layered on top of regulatory rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, RegulationID, LabelID | BackOffice.Customer | SELECT (anchor) | Source of regulatory jurisdiction and label assignment |
| CID | Customer.Customer | INNER JOIN | Validates customer exists in Customer schema |
| CID | BackOffice.Suitability | LEFT JOIN | Existence check for suitability test record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing service (read-only API) | @CID | EXEC | Regulation and suitability gate for deposit eligibility decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetUserRegulationAndSuitabiltyTest (procedure)
+-- BackOffice.Customer (table) [RegulationID + LabelID]
+-- Customer.Customer (table) [CID validation join]
+-- BackOffice.Suitability (table) [suitability test existence check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Anchor; provides RegulationID and LabelID |
| Customer.Customer | Table | INNER JOIN - ensures customer exists in Customer schema |
| BackOffice.Suitability | Table | LEFT JOIN for HasSuitabilityTest existence check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing service (read-only API) | External | Compliance gate for regulation-specific and suitability-gated deposit flows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Name typo | Naming | "Suitabilty" (missing 'i') is the original SP name - cannot be renamed without changing callers |
| INNER JOIN on Customer.Customer | Design | No row returned if CID does not exist in Customer.Customer (even if in BackOffice.Customer); added FB:23288 |
| NOLOCK throughout | Concurrency | All reads use WITH (NOLOCK) |
| ASIC origin | History | Created for ASIC suitability check (FB:23188, Jul 2014); RegulationID filter applied by caller, not by this SP |

---

## 8. Sample Queries

### 8.1 Check regulation and suitability for a customer

```sql
EXEC [Billing].[GetUserRegulationAndSuitabiltyTest] @CID = 12345
-- Returns: HasSuitabilityTest (0/1), RegulationID, LabelID
```

### 8.2 Equivalent direct query

```sql
SELECT
    CASE WHEN bsut.CID IS NOT NULL THEN 1 ELSE 0 END AS HasSuitabilityTest,
    bcus.RegulationID,
    bcus.LabelID
FROM [BackOffice].[Customer] bcus WITH (NOLOCK)
INNER JOIN [Customer].[Customer] cucu WITH (NOLOCK) ON cucu.CID = bcus.CID
LEFT JOIN [BackOffice].[Suitability] bsut WITH (NOLOCK) ON bsut.CID = bcus.CID
WHERE bcus.CID = 12345
```

### 8.3 Find customers by regulation without suitability test

```sql
-- Customers in a specific regulation who haven't passed suitability
SELECT bcus.CID, bcus.RegulationID
FROM [BackOffice].[Customer] bcus WITH (NOLOCK)
INNER JOIN [Customer].[Customer] cucu WITH (NOLOCK) ON cucu.CID = bcus.CID
LEFT JOIN [BackOffice].[Suitability] bsut WITH (NOLOCK) ON bsut.CID = bcus.CID
WHERE bcus.RegulationID = 3  -- ASIC
  AND bsut.CID IS NULL       -- no suitability record
```

---

## 9. Atlassian Knowledge Sources

**Confluence**:
- "Billing Service Database Readonly Separation" (/spaces/MG) - procedure in read-only billing service API
- "Mapping of deposit errors sent from server side" (/spaces/MG) - regulation/suitability errors in deposit flow context

**Jira**: FB:23188 (created, Jul 2014) - original request for regulation + ASIC suitability check. FB:23288 (Jul 2014) - added LabelID and Customer.Customer join.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 2 Confluence + 2 Jira (FB:23188, FB:23288) | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetUserRegulationAndSuitabiltyTest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetUserRegulationAndSuitabiltyTest.sql*
