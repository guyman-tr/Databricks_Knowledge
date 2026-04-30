# Dictionary.AsicClassification

> Lookup table for Australian Securities and Investments Commission (ASIC) client classification. Regulates trading restrictions for Australian-regulated customers — Retail, SophisticatedInvestor, WholesaleInvestor, RetailPending, Pending.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AsicClassificationID (int, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup, FILLFACTOR 90 |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AsicClassification defines the five ASIC client classifications for Australian-regulated customers: RetailPending (1), SophisticatedInvestor (2), WholesaleInvestor (3), Retail (4), and Pending (5). Under ASIC regulations, Australian customers must be classified to determine applicable trading restrictions — leverage limits, instrument access, and risk disclosures. BackOffice.Customer stores AsicClassificationID (nullable) and uses it in the computed TradingRiskStatusID column to drive trading risk status.

Without this lookup, the system could not enforce ASIC-mandated restrictions for Australian customers. The computed TradingRiskStatusID on BackOffice.Customer evaluates AsicClassificationID (alongside RegulationID, DesignatedRegulationID, MifidCategorizationID, SeychellesCategorizationID) — when RegulationID or DesignatedRegulationID indicates ASIC (4 or 10) and AsicClassificationID is NULL or Retail (4), TradingRiskStatusID is set to 3 (Low), meaning restricted leverage. Non-retail classifications allow higher risk trading.

Data flows through BackOffice.UpdateRiskUserInfo and BackOffice.UpdateRiskUserInfoRemote, which update AsicClassificationID on Customer. History.BackOfficeCustomer snapshots include AsicClassificationID. UserApiDB procedures (Customer.RiskUserInfo, Customer.GetRiskInfo, Customer.UpdateRiskUserInfo, Customer.GetAggregatedInfo) read and write this value. RiskCalculation schema uses it for risk classification logic. The computed TradingRiskStatusID CASE expression embeds ASIC-specific rules: Retail or NULL under ASIC regulation → TradingRiskStatus=3 (Low).

---

## 2. Business Logic

### 2.1 ASIC Classification Values

**What**: The five ASIC client categories and their regulatory meaning.

**Columns/Parameters Involved**: `AsicClassificationID`, `Name`

**Rules**:
- **RetailPending (1)**: Customer is Australian and awaiting final retail classification. Interim status until verification completes.
- **SophisticatedInvestor (2)**: Certified sophisticated investor per ASIC requirements. Higher leverage and instrument access allowed.
- **WholesaleInvestor (3)**: Wholesale/professional investor. Elevated limits and reduced disclosure requirements.
- **Retail (4)**: Standard retail customer. Subject to strict leverage caps and product restrictions. Most restrictive.
- **Pending (5)**: General pending state — classification not yet finalized.

**Diagram**:
```
ASIC Classification → Trading Risk Impact:

  Retail (4) or NULL (ASIC reg) ──► TradingRiskStatusID = 3 (Low) — restricted leverage
  SophisticatedInvestor (2) ──────► Higher risk allowed
  WholesaleInvestor (3) ─────────► Higher risk allowed
  RetailPending (1), Pending (5) ─► Interim states — handled per regulation logic
```

### 2.2 TradingRiskStatusID Integration

**What**: How AsicClassificationID feeds the computed TradingRiskStatusID on BackOffice.Customer.

**Columns/Parameters Involved**: `AsicClassificationID` (in Customer)

**Rules**:
- The computed column TradingRiskStatusID includes: `when ([DesignatedRegulationID]=(4) OR [DesignatedRegulationID]=(10)) AND [RegulationID]=(5) AND ([AsicClassificationID] IS NULL OR [AsicClassificationID]=(4)) then (3)`.
- When regulation is ASIC (4 or 10) and AsicClassificationID is NULL or Retail (4), result is 3 (Low risk status = restricted leverage).
- Non-retail AsicClassificationID values allow higher risk under the regulation logic.

---

## 3. Data Overview

| AsicClassificationID | Name | Meaning |
|---|---|---|
| 1 | RetailPending | Australian customer awaiting final retail classification. Interim status; used until KYC/verification completes. |
| 2 | SophisticatedInvestor | Certified sophisticated investor per ASIC. Higher leverage and instrument access; reduced retail protections. |
| 3 | WholesaleInvestor | Wholesale/professional investor. Elevated limits, reduced disclosure; not subject to standard retail caps. |
| 4 | Retail | Standard retail customer. Subject to strict leverage caps and product restrictions. When combined with ASIC regulation, drives TradingRiskStatusID=3 (Low). |
| 5 | Pending | General pending classification. Used when ASIC status is not yet finalized. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AsicClassificationID | int | NO | - | CODE-BACKED | Primary key identifying the ASIC client classification. 1=RetailPending, 2=SophisticatedInvestor, 3=WholesaleInvestor, 4=Retail, 5=Pending. Referenced by BackOffice.Customer (nullable). Used in computed TradingRiskStatusID: Retail (4) or NULL under ASIC regulation → TradingRiskStatus=3 (Low). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable ASIC classification name. Used in BackOffice UI, UserApi, and risk reports. Values match live data (MCP verified). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | AsicClassificationID | Column (nullable) | Customer ASIC classification; feeds TradingRiskStatusID computed column |
| BackOffice.UpdateRiskUserInfo | @AsicClassificationID | Parameter | Updates Customer.AsicClassificationID |
| BackOffice.UpdateRiskUserInfoRemote | @AsicClassificationID | Parameter | Remote proc updates AsicClassificationID |
| History.BackOfficeCustomer | AsicClassificationID | Column | Historical snapshots preserve classification |
| UserApiDB: Customer.RiskUserInfo, GetRiskInfo, UpdateRiskUserInfo | AsicClassificationID | Read/Write | UserAPI procedures expose and update classification |
| RiskCalculation schema | AsicClassificationID | Risk logic | Risk classification and limits |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. Dictionary tables are leaf nodes with no code-level references.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | AsicClassificationID column; TradingRiskStatusID computed column references it |
| BackOffice.UpdateRiskUserInfo | Stored Procedure | Updates AsicClassificationID |
| BackOffice.UpdateRiskUserInfoRemote | Stored Procedure | Updates AsicClassificationID |
| History.BackOfficeCustomer | Table | Historical AsicClassificationID |
| UserApiDB Customer procedures | Stored Procedures | Read/write AsicClassificationID |
| RiskCalculation schema | Procedures/Tables | Risk classification logic |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AsicClassification | CLUSTERED PK | AsicClassificationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AsicClassification | PRIMARY KEY | Unique AsicClassificationID. FILLFACTOR 90, DICTIONARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all ASIC classifications
```sql
SELECT  AsicClassificationID,
        Name
FROM    Dictionary.AsicClassification WITH (NOLOCK)
ORDER BY AsicClassificationID;
```

### 8.2 Customers by ASIC classification
```sql
SELECT  ac.Name                    AS AsicClassification,
        COUNT(*)                    AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
LEFT JOIN Dictionary.AsicClassification ac WITH (NOLOCK)
        ON bc.AsicClassificationID = ac.AsicClassificationID
WHERE   bc.AsicClassificationID IS NOT NULL
GROUP BY ac.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Retail customers under ASIC (TradingRiskStatusID = 3)
```sql
SELECT  bc.CID,
        bc.AsicClassificationID,
        ac.Name                    AS AsicClassification,
        bc.TradingRiskStatusID
FROM    BackOffice.Customer bc WITH (NOLOCK)
LEFT JOIN Dictionary.AsicClassification ac WITH (NOLOCK)
        ON bc.AsicClassificationID = ac.AsicClassificationID
WHERE   bc.AsicClassificationID = 4  -- Retail
   OR   (bc.AsicClassificationID IS NULL AND bc.RegulationID IN (4, 10));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AsicClassification | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AsicClassification.sql*
