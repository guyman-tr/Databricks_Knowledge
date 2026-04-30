# Dictionary.TradingRiskStatus

> Lookup table defining the trading risk level that determines leverage and trading feature access. Value is COMPUTED on BackOffice.Customer from regulatory context (Seychelles, ASIC, CySEC, FCA, MiFID).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TradingRiskStatusID (int, PK CLUSTERED) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.TradingRiskStatus defines the trading risk level that determines what leverage and trading features a customer can access. Unlike stored lookup values, TradingRiskStatusID on BackOffice.Customer is a COMPUTED column derived from regulatory context: RegulationID, DesignatedRegulationID, SeychellesCategorizationID, AsicClassificationID, MifidCategorizationID. The four values are: None (1) = most restricted (default), Pending (2) = awaiting classification, Low (3) = restricted leverage (retail), High (4) = full leverage (professional/wholesale).

For non-production environments (tradonomiQA1, DealingQADEMO, tradonomi, DemoMirrorQA, DemoMirrorDev, STG_tradonomi), TradingRiskStatusID is always 4 (High) to allow unrestricted testing. For production, the CASE logic evaluates regulation and categorization: Seychelles (0→Low, 1→None, 2→High), ASIC regulation 11→Low, ASIC 4/10 with Retail/NULL→Low, CySEC with MiFID Retail→Low, CySEC with MiFID 5→Pending, FCA with MiFID 4→None. This drives margin requirements, instrument availability, and copy trading restrictions.

Data flows through Trade.GetTradingRiskStatus, Trade.GetUserInfo, Trade.GetUserData, Trade.GetOrderForOpenContextData, Trade.GetOrderForCloseContextData, Trade.GetCustomersDataWithRestirctions, Trade.PositionsGuaranteedSLWasNotAligned, UserApiDB Customer.GetRiskInfo, Customer.UpdateRiskInfo, Customer.GetRiskUserInfo, Customer.GetAggregatedInfoByGCID.

---

## 2. Business Logic

### 2.1 Regulatory Derivation of TradingRiskStatusID

**What**: The computed column logic that derives TradingRiskStatusID from regulation and categorization.

**Columns Involved**: `TradingRiskStatusID`, `TradingRiskStatus`

**Rules**:
- **4 (High)**: Full leverage. Assigned for: QA/demo DBs; SeychellesCategorizationID=2 (Professional/Wholesale); ASIC non-retail; CySEC MiFID Retail (1) in some paths; FCA non-MiFID-4.
- **3 (Low)**: Restricted leverage. Assigned for: SeychellesCategorizationID=0; ASIC Regulation 11; ASIC 4/10 with Retail or NULL; CySEC (5) with MiFID Retail (1).
- **2 (Pending)**: Awaiting classification. Assigned for: CySEC (5) with MiFID 5.
- **1 (None)**: Most restricted. Assigned for: SeychellesCategorizationID=1; FCA (1/2) with MiFID 4 (Professional).

**Diagram**:
```
BackOffice.Customer.TradingRiskStatusID (COMPUTED)

  IF db_name() IN (tradonomiQA1, DealingQADEMO, ...) → 4 (High)
  ELSE IF SeychellesCategorizationID = 0 → 3 (Low)
  ELSE IF SeychellesCategorizationID = 1 → 1 (None)
  ELSE IF SeychellesCategorizationID = 2 → 4 (High)
  ELSE IF RegulationID/DesignatedRegulationID = 11 (ASIC) → 3 (Low)
  ELSE IF (Reg 4/10) AND (AsicClassification NULL or Retail) → 3 (Low)
  ELSE IF CySEC (5) AND MifidCategorization = Retail (1) → 3 (Low)
  ELSE IF CySEC (5) AND MifidCategorization = 5 → 2 (Pending)
  ELSE IF FCA (1/2) AND MifidCategorization = 4 → 1 (None)
  ELSE → default (varies by schema)

  Dictionary.TradingRiskStatus
  ├── 1 = None    (most restricted)
  ├── 2 = Pending (awaiting classification)
  ├── 3 = Low    (retail, restricted leverage)
  └── 4 = High   (professional, full leverage)
```

---

## 3. Data Overview

| TradingRiskStatusID | TradingRiskStatus | Meaning |
|---|---|---|
| 1 | None | Most restricted. Typically FCA professional or Seychelles category 1. Minimal leverage. |
| 2 | Pending | Awaiting final classification. Typically CySEC MiFID 5. Interim restrictions. |
| 3 | Low | Restricted leverage. Retail under ASIC, CySEC, or Seychelles category 0. |
| 4 | High | Full leverage. Professional/wholesale, or QA/demo environments. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradingRiskStatusID | int | NO | - | VERIFIED | Primary key identifying the trading risk level. 1=None, 2=Pending, 3=Low, 4=High. Referenced by BackOffice.Customer.TradingRiskStatusID (COMPUTED column). Used by Trade.GetTradingRiskStatus, Trade.GetUserInfo, Trade.GetUserData, Trade.GetOrderForOpenContextData, Trade.GetOrderForCloseContextData, Trade.GetCustomersDataWithRestirctions, Trade.PositionsGuaranteedSLWasNotAligned, UserApiDB Customer procs. |
| 2 | TradingRiskStatus | varchar(20) | YES | - | VERIFIED | Human-readable label. Values: None, Pending, Low, High. Used for UI and reporting when resolving TradingRiskStatusID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | TradingRiskStatusID | COMPUTED / Lookup | Derived from regulation + categorization |
| Trade.GetTradingRiskStatus | — | Returns | Reads TradingRiskStatusID |
| Trade.GetUserInfo, Trade.GetUserInfoSlim | — | Returns | Includes TradingRiskStatusID in output |
| Trade.GetUserData | — | Join | Resolves TradingRiskStatus for display |
| Trade.GetOrderForOpenContextData | — | Returns | TradingRiskStatusID in order context |
| Trade.GetOrderForCloseContextData | — | Returns | TradingRiskStatusID in close context |
| Trade.GetCustomersDataWithRestirctions | — | Returns | TradingRiskStatusID for restriction logic |
| Trade.GetCustomersDataWithCopyRestirctions | — | Returns | Copy restriction by TradingRiskStatusID |
| Trade.PositionsGuaranteedSLWasNotAligned | — | Filter | Excludes High (4) for certain countries |
| UserApiDB: Customer.RiskUserInfo, Customer.GetRiskInfo, Customer.UpdateRiskInfo | — | Read/Write | Risk info API |
| Customer.GetRiskUserInfo | — | Returns | TradingRiskStatusID in risk info |
| Customer.GetAggregatedInfoByGCID | — | Returns | Aggregated risk info |

---

## 6. Dependencies

### 6.0 Dependency Chain

Dictionary.TradingRiskStatus has no dependencies. BackOffice.Customer computed column depends on RegulationID, DesignatedRegulationID, SeychellesCategorizationID, AsicClassificationID, MifidCategorizationID.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | COMPUTED column references this lookup |
| Trade.GetTradingRiskStatus | Stored Procedure | Returns TradingRiskStatusID |
| Trade.GetUserInfo, Trade.GetUserData | Stored Procedure | Includes in user context |
| Trade.GetOrderForOpenContextData | Stored Procedure | Order context |
| Trade.GetOrderForCloseContextData | Stored Procedure | Close context |
| Trade.GetCustomersDataWithRestirctions | Stored Procedure | Restriction logic |
| Trade.PositionsGuaranteedSLWasNotAligned | Stored Procedure | SL alignment check |
| UserApiDB Customer procedures | Stored Procedure | Risk info API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_TradingRiskStatus | CLUSTERED PK | TradingRiskStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_TradingRiskStatus | PRIMARY KEY | Unique TradingRiskStatusID. FILLFACTOR 95 on PRIMARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all trading risk statuses
```sql
SELECT  TradingRiskStatusID,
        TradingRiskStatus
FROM    Dictionary.TradingRiskStatus WITH (NOLOCK)
ORDER BY TradingRiskStatusID;
```

### 8.2 Resolve customer trading risk to label
```sql
SELECT  bc.CID,
        bc.TradingRiskStatusID,
        dtrs.TradingRiskStatus
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.TradingRiskStatus dtrs WITH (NOLOCK)
        ON bc.TradingRiskStatusID = dtrs.TradingRiskStatusID
WHERE   bc.CID = 12345;
```

### 8.3 Count customers by trading risk level
```sql
SELECT  dtrs.TradingRiskStatus,
        COUNT(*) AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.TradingRiskStatus dtrs WITH (NOLOCK)
        ON bc.TradingRiskStatusID = dtrs.TradingRiskStatusID
GROUP BY dtrs.TradingRiskStatus
ORDER BY dtrs.TradingRiskStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10+ analyzed | BackOffice.Customer computed column | Corrections: 0 applied*
*Object: Dictionary.TradingRiskStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradingRiskStatus.sql*
