# Dictionary.WorldCheck

> Lookup table defining the five outcomes of World-Check screening (Refinitiv's sanctions/PEP database) — from unscreened through PEP Match and Risk Match — used to classify customers by their AML/sanctions screening result.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | WorldCheckID (TINYINT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on WorldCheckID) |

---

## 1. Business Meaning

Dictionary.WorldCheck defines the possible outcomes of screening customers against the Refinitiv World-Check database — a global sanctions, PEP (Politically Exposed Persons), and adverse media screening tool. Every customer goes through World-Check screening as part of the AML (Anti-Money Laundering) compliance process. The result determines whether the customer requires enhanced due diligence, account restrictions, or outright rejection.

Without this table, the platform could not systematically record and act upon screening results. Regulatory obligations (EU AMLD, CySEC, ASIC) mandate that all financial service providers screen customers against sanctions lists and PEP databases. This table's classifications drive automated compliance workflows — PEP matches trigger enhanced monitoring, risk matches may block account operations.

The table is referenced by BackOffice.Customer (storing each customer's screening result) and consumed by 10+ procedures: BackOffice.SetWorldCheckStatus (updates screening status), BackOffice.GetCustomerByCID/GetCustomerByCIDVerification (customer profile display), BackOffice.GetPepReport (PEP reporting), BackOffice.SetRiskClassificationNew (risk scoring includes World-Check status), RiskCalculation.SetRiskClassificationForCySec (regulatory risk classification), and multiple economic/compliance reports. Related synonyms (Dictionary_WorldCheckStatus, WorldCheckStrength, WorldCheckCategories, etc.) expose additional World-Check dimensions.

---

## 2. Business Logic

### 2.1 Screening Result Classification

**What**: Five progressive states of customer World-Check screening, from unscreened to confirmed matches.

**Columns/Parameters Involved**: `WorldCheckID`, `WorldCheckName`

**Rules**:
- ID 0 (empty name) — unscreened/default state. Customer has not yet been submitted to World-Check. May occur for new registrations before the background check runs
- ID 1 (Pending WCH) — screening submitted but results not yet returned. Customer is in a holding state; certain operations may be restricted until results arrive
- ID 2 (No Match) — screening completed with no matches against sanctions lists, PEP databases, or adverse media. Customer is clear for standard operations
- ID 3 (PEP Match) — customer matched against a Politically Exposed Person record. Triggers Enhanced Due Diligence (EDD), ongoing monitoring, and senior management approval for the relationship
- ID 4 (Risk Match) — customer matched against sanctions lists, terrorist financing records, or other high-risk indicators. May trigger immediate account freeze, enhanced investigation, or relationship termination
- The result is stored on BackOffice.Customer.WorldCheckID and persists across the customer lifecycle
- Risk classification procedures (SetRiskClassificationNew, SetRiskClassificationForCySec) incorporate World-Check status as a scoring factor

**Diagram**:
```
World-Check Screening Flow:
  Customer registered
       │
       ▼
  0 = Unscreened (default)
       │
       ▼  Submit to World-Check
  1 = Pending WCH (awaiting results)
       │
       ├─ Clear ──────────► 2 = No Match (standard access)
       │
       ├─ PEP found ──────► 3 = PEP Match (enhanced monitoring)
       │                         └─ EDD + senior approval required
       │
       └─ Risk found ─────► 4 = Risk Match (restrictions/freeze)
                                 └─ Investigation + possible termination
```

---

## 3. Data Overview

| WorldCheckID | WorldCheckName | Meaning |
|---|---|---|
| 0 | (empty) | Unscreened — customer has not been submitted to World-Check yet. Default state for new registrations before the background screening job runs. |
| 1 | Pending WCH | Screening in progress — submitted to Refinitiv World-Check but results not yet received. Some operations may be held pending the result. |
| 2 | No Match | Clear screening — no matches found against sanctions lists, PEP databases, or adverse media. Customer can proceed with standard platform access without additional compliance restrictions. |
| 3 | PEP Match | Politically Exposed Person match — customer's identity matches a PEP record in World-Check. Triggers mandatory Enhanced Due Diligence (EDD), ongoing transaction monitoring, and senior management sign-off for the business relationship. |
| 4 | Risk Match | High-risk match — customer matched against sanctions lists, terrorist financing databases, or other critical risk indicators. May trigger immediate account freeze, escalated investigation by the AML team, or relationship termination depending on severity. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WorldCheckID | tinyint | NO | - | CODE-BACKED | Unique identifier for the World-Check screening outcome: 0=Unscreened, 1=Pending, 2=No Match, 3=PEP Match, 4=Risk Match. Stored on BackOffice.Customer.WorldCheckID and incorporated into risk classification scoring by 10+ compliance and risk procedures. |
| 2 | WorldCheckName | varchar(50) | YES | - | CODE-BACKED | Display label for the screening outcome. ID 0 has an empty string (not NULL). Used in BackOffice customer displays, PEP reports, and compliance dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | WorldCheckID | Implicit | Each customer's World-Check screening result |
| BackOffice.SetWorldCheckStatus | @WorldCheckID | Writer | Updates a customer's screening status after results are received |
| BackOffice.GetCustomerByCID | WorldCheckID | Reader | Returns screening status in customer profile |
| BackOffice.GetCustomerByCIDVerification | WorldCheckID | Reader | Includes status in verification-focused customer view |
| BackOffice.GetPepReport | WorldCheckID | Reader | Filters PEP-matched customers for regulatory reporting |
| BackOffice.SetRiskClassificationNew | WorldCheckID | Reader | Incorporates status into risk classification scoring |
| RiskCalculation.SetRiskClassificationForCySec | WorldCheckID | Reader | CySEC-specific risk classification using World-Check |
| dbo.SP_Economic_Report_new | WorldCheckID | Reader | Economic reporting includes screening status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WorldCheck (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Stores WorldCheckID per customer |
| BackOffice.SetWorldCheckStatus | Stored Procedure | Updates screening status |
| BackOffice.GetPepReport | Stored Procedure | PEP reporting |
| BackOffice.SetRiskClassificationNew | Stored Procedure | Risk scoring factor |
| RiskCalculation.SetRiskClassificationForCySec | Stored Procedure | CySEC risk classification |
| dbo.SP_Economic_Report_new | Stored Procedure | Economic reporting |
| dbo.SP_GDPR | Stored Procedure | GDPR data processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.WorldCheck | CLUSTERED | WorldCheckID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all World-Check screening outcomes
```sql
SELECT  WorldCheckID,
        WorldCheckName
FROM    [Dictionary].[WorldCheck] WITH (NOLOCK)
ORDER BY WorldCheckID;
```

### 8.2 Count customers by screening result
```sql
SELECT  wc.WorldCheckName,
        COUNT(*) AS CustomerCount
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[WorldCheck] wc WITH (NOLOCK)
        ON wc.WorldCheckID = c.WorldCheckID
GROUP BY wc.WorldCheckID, wc.WorldCheckName
ORDER BY wc.WorldCheckID;
```

### 8.3 Find customers with PEP or Risk matches
```sql
SELECT  c.CustomerID,
        wc.WorldCheckName AS ScreeningResult
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[WorldCheck] wc WITH (NOLOCK)
        ON wc.WorldCheckID = c.WorldCheckID
WHERE   c.WorldCheckID IN (3, 4) -- PEP Match or Risk Match
ORDER BY c.CustomerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WorldCheck | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WorldCheck.sql*
