# History.RiskParameterConfiguration

> System-versioned temporal history table for RiskCalculation.RiskParameterConfiguration, archiving all past states of the risk parameter scoring configuration used by eToro's regulatory compliance and risk classification engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (EndTime, BeginTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on EndTime ASC, BeginTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `RiskCalculation.RiskParameterConfiguration`. SQL Server automatically archives superseded rows here when any configuration row in the source table is updated or deleted.

The source table `RiskCalculation.RiskParameterConfiguration` is the configuration backbone of eToro's **Risk Classification Engine** - the system that assesses each customer's risk profile for KYC/AML/MiFID regulatory compliance. The engine evaluates customer attributes (country of residence, age, income, occupation, screening status, etc.) against configured thresholds and scoring rules. Each row in the source table defines: for a given regulation (`RegulationID`), a given risk parameter (`RiskClassificationParameterID` - e.g., "Country of Residence", "Age of customer", "Annual Income"), and a specific scoring rule instance (`ID`), what value (`Value`) triggers what risk classification (`RiskClassificationID`).

Examples of parameters (from Dictionary.RiskClassificationParameter):
- ID 2: Country of Residence (Onboarding) - source: Customer.CustomerStatic
- ID 5: Age of customer - source: Customer.CustomerStatic
- ID 7: Screening Status - source: external screening service
- ID 8: Main Source of Income - from customer questionnaire answers
- ID 11: Annual Income - from questionnaire
- ID 14: High Risk (sector indicators like Healthcare/Construction occupations)

The history table currently has 0 rows, suggesting the risk parameter configuration has not changed since the system was set up or since the temporal history was last cleared.

---

## 2. Business Logic

### 2.1 Risk Parameter Scoring Configuration

**What**: Each row defines how a specific customer attribute value maps to a risk classification outcome for a given regulatory regime.

**Columns/Parameters Involved**: `RegulationID`, `RiskClassificationParameterID`, `ID`, `Value`, `RiskClassificationID`

**Rules**:
- The composite key (RegulationID + RiskClassificationParameterID + ID) uniquely identifies a scoring rule instance
- `Value` stores the threshold or matching criterion (varchar 500 allows flexible storage of ranges, lists, codes, or thresholds)
- `RiskClassificationID` is the risk class assigned when the customer's attribute matches the `Value` criterion
- `ValidationText` provides a human-readable description of the validation rule for the matching criterion
- Different RegulationIDs allow the same parameters to have different scoring rules per regulatory regime (e.g., EU MiFID rules vs. UK FCA rules)

**Diagram**:
```
Customer attribute evaluation:
  Customer.CountryID -> RiskClassificationParameterID=2 (Country of Residence)
    -> Match against configured Values per RegulationID
    -> Assign RiskClassificationID based on matched rule
    -> Sum/aggregate risk scores across all parameters
    -> Final customer risk score = combined classification
```

---

## 3. Data Overview

The table has no rows in production. No representative rows available.

| RegulationID | RiskClassificationParameterID | ID | Value | RiskClassificationID | BeginTime | EndTime | Meaning |
|---|---|---|---|---|---|---|---|
| (no rows) | - | - | - | - | - | - | Table is empty; risk parameter configuration has not changed since temporal history was initialized |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | int | NO | - | NAME-INFERRED | Identifier for the regulatory regime this configuration applies to (e.g., EU MiFID, UK FCA, ASIC). Different regulations may require different risk scoring thresholds for the same customer attributes. Part of the composite primary key in the source table. No explicit FK in the source table DDL. |
| 2 | RiskClassificationParameterID | int | NO | - | VERIFIED | The customer risk attribute being parameterized. FK to Dictionary.RiskClassificationParameter (defined on source table). Examples: 2=Country of Residence (Onboarding), 3=Country of Residence (Existing), 4=Place of Birth, 5=Age of customer, 7=Screening Status, 8=Main Source of Income, 11=Annual Income, 14=High Risk Sector. Determines which customer attribute is being scored. |
| 3 | ID | int | NO | - | CODE-BACKED | Sequential or external identifier for the specific scoring rule instance within a (RegulationID, RiskClassificationParameterID) pair. Allows multiple scoring rules per parameter per regulation (e.g., different age ranges each have their own ID). Part of the composite primary key in the source table. |
| 4 | Value | varchar(500) | YES | - | NAME-INFERRED | The threshold or matching criterion value for this scoring rule. The flexible varchar(500) type accommodates different formats: country codes, age ranges (e.g., "21-65"), income brackets, questionnaire answer IDs, or other parameter-specific representations. When a customer's attribute matches this Value, the associated RiskClassificationID is applied. |
| 5 | RiskClassificationID | int | YES | - | NAME-INFERRED | The risk classification (risk level/score) assigned when the customer's attribute matches the configured Value. Nullable - some rules may be informational without assigning a specific classification level. Implicit FK to Dictionary.RiskClassification or similar lookup table. |
| 6 | ValidationText | varchar(100) | YES | - | CODE-BACKED | Human-readable description of the validation rule or criterion stored in Value. Provides context for operators reviewing or modifying risk scoring configurations. Example from Dictionary.RiskClassificationParameter descriptions: "Q15 Main income A89/90/105=Social security/Family financial support/Other". |
| 7 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this risk parameter configuration became active in `RiskCalculation.RiskParameterConfiguration`. Automatically managed by SQL Server temporal system versioning (GENERATED ALWAYS AS ROW START). Nanosecond precision. |
| 8 | EndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this configuration was superseded by an update or delete. Automatically set by SQL Server. Leading key of the clustered index. Default '9999-12-31' in source table represents "currently active" rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit (FK on source) | The customer attribute type being parameterized: 2=Country of Residence, 5=Age, 7=Screening Status, 8=Main Income, 11=Annual Income, etc. |
| RegulationID | Regulation lookup (not identified) | Implicit | Regulatory regime identifier; exact lookup table not confirmed from available SSDT. |
| RiskClassificationID | Risk classification lookup | Implicit | The risk level assigned when a customer matches this parameter value; exact lookup table not confirmed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RiskCalculation.RiskParameterConfiguration | HISTORY_TABLE | Temporal History | Active source table - SQL Server automatically archives expired rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RiskParameterConfiguration (table)
  (temporal history - no code-level dependencies; populated automatically by SQL Server)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RiskCalculation.RiskParameterConfiguration | Table | Source table; all expired configuration rows archived here automatically. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RiskParameterConfiguration | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival/audit data. |

---

## 8. Sample Queries

### 8.1 View all historical risk parameter configuration changes
```sql
SELECT
    h.RegulationID,
    h.RiskClassificationParameterID,
    dcp.Name AS ParameterName,
    h.ID,
    h.Value,
    h.RiskClassificationID,
    h.ValidationText,
    h.BeginTime AS ValidFrom,
    h.EndTime AS ValidTo
FROM [History].[RiskParameterConfiguration] h WITH (NOLOCK)
JOIN [Dictionary].[RiskClassificationParameter] dcp WITH (NOLOCK)
    ON dcp.RiskClassificationParameterID = h.RiskClassificationParameterID
ORDER BY h.EndTime DESC, h.RegulationID, h.RiskClassificationParameterID
```

### 8.2 Check risk configuration for a specific parameter as of a past date
```sql
-- Uses temporal query on source (SQL Server reads History automatically)
SELECT RegulationID, RiskClassificationParameterID, ID, Value, RiskClassificationID, ValidationText
FROM [RiskCalculation].[RiskParameterConfiguration]
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00'
WHERE RiskClassificationParameterID = @ParameterID
ORDER BY RegulationID, ID
```

### 8.3 Track configuration changes for a specific regulation and parameter
```sql
SELECT
    h.ID,
    h.Value,
    h.RiskClassificationID,
    h.ValidationText,
    h.BeginTime AS EffectiveFrom,
    h.EndTime AS EffectiveTo
FROM [History].[RiskParameterConfiguration] h WITH (NOLOCK)
WHERE h.RegulationID = @RegulationID
  AND h.RiskClassificationParameterID = @ParameterID
ORDER BY h.BeginTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 7.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RiskParameterConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.RiskParameterConfiguration.sql*
