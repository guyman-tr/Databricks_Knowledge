# dbo.EligibilityRulesType

> User-defined table type that represents a batch of eligibility rule configurations for bulk insertion into dbo.EligibilityRules.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type mirroring dbo.EligibilityRules structure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

EligibilityRulesType is a table-valued parameter type that mirrors the structure of dbo.EligibilityRules and enables bulk insertion of eligibility rule configurations. Each row defines a rule that controls which customers are eligible for a specific fiat sub-program based on their regulation, country, and club membership.

This type exists to support efficient batch updates of eligibility rules. When the business changes which customer segments can access specific sub-programs (e.g., enabling IBAN EU Green for a new country), the rules are assembled as a batch and passed through this type to the AddEligibilityRules procedure.

Data flows through this type when configuration changes are deployed. The application constructs a set of EligibilityRulesType rows and calls AddEligibilityRules, which performs a MERGE or INSERT operation to synchronize the rules with the dbo.EligibilityRules table.

---

## 2. Business Logic

### 2.1 Eligibility Rule Configuration

**What**: Rules that determine which customer segments can access specific fiat sub-programs.

**Columns/Parameters Involved**: `FiatId`, `DesignatedRegulationId`, `CountryId`, `ClubId`, `SubProgramId`, `RolloutPercentage`, `RegulationId`, `Priority`

**Rules**:
- Each rule targets a specific sub-program (SubProgramId) and defines the customer criteria to match
- RolloutPercentage controls gradual rollout (0-100%) for new programs or features
- Priority determines which rule wins when multiple rules match the same customer
- The combination of regulation, country, and club creates a targeting matrix

**Diagram**:
```
Customer Attributes                   Eligibility Rule
+-----------------------+             +---------------------------+
| RegulationId          | <-------->  | RegulationId              |
| CountryId             | <-------->  | CountryId                 |
| ClubId                | <-------->  | ClubId                    |
+-----------------------+             | DesignatedRegulationId    |
                                      | SubProgramId -> SubProgram|
                                      | RolloutPercentage (0-100) |
                                      | Priority (tiebreaker)     |
                                      +---------------------------+
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FiatId | int | NO | - | NAME-INFERRED | Internal identifier for the fiat configuration context. Links the rule to a specific fiat platform instance. |
| 2 | DesignatedRegulationId | tinyint | NO | - | NAME-INFERRED | Target regulatory jurisdiction for this rule. Determines which regulatory framework applies to the eligible customer. |
| 3 | CountryId | tinyint | NO | - | NAME-INFERRED | Country filter for the rule. Restricts eligibility to customers in a specific country. |
| 4 | ClubId | tinyint | NO | - | NAME-INFERRED | eToro club tier filter. Restricts eligibility to customers at a specific club level. |
| 5 | SubProgramId | tinyint | NO | - | CODE-BACKED | Target sub-program that customers matching this rule become eligible for. FK to dbo.SubPrograms (1=Card Premium UK, 2=Card Standard UK, etc.). See [Sub-Program](../../_glossary.md#sub-program). |
| 6 | RolloutPercentage | decimal(18,1) | NO | - | CODE-BACKED | Percentage of matching customers who should be enrolled (0.0-100.0). Used for gradual rollout of new sub-programs or features. |
| 7 | RegulationId | tinyint | NO | - | NAME-INFERRED | Source regulatory jurisdiction of the customer. Used to match customers by their current regulation. |
| 8 | UpdateTime | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this rule configuration was last modified. Used for tracking configuration change history. |
| 9 | Priority | smallint | NO | - | CODE-BACKED | Priority rank for rule evaluation. When multiple rules match a customer, the highest priority (lowest number) wins. Default 0 in target table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SubProgramId | dbo.SubPrograms | Implicit | Identifies which sub-program the eligibility rule targets |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddEligibilityRules | @EligibilityRules parameter | Parameter Type | Accepts a batch of eligibility rules for bulk insertion/merge |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddEligibilityRules | Stored Procedure | TVP parameter type for bulk eligibility rule configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate with a single eligibility rule
```sql
DECLARE @Rules dbo.EligibilityRulesType;
INSERT INTO @Rules (FiatId, DesignatedRegulationId, CountryId, ClubId, SubProgramId, RolloutPercentage, RegulationId, UpdateTime, Priority)
VALUES (1, 1, 10, 1, 6, 100.0, 1, SYSUTCDATETIME(), 0);
EXEC dbo.AddEligibilityRules @EligibilityRules = @Rules;
```

### 8.2 Populate with multiple rules for a gradual rollout
```sql
DECLARE @Rules dbo.EligibilityRulesType;
INSERT INTO @Rules (FiatId, DesignatedRegulationId, CountryId, ClubId, SubProgramId, RolloutPercentage, RegulationId, UpdateTime, Priority)
VALUES (1, 2, 5, 1, 7, 50.0, 2, SYSUTCDATETIME(), 1),
       (1, 2, 5, 2, 7, 75.0, 2, SYSUTCDATETIME(), 2);
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'EligibilityRulesType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.6/10 (Elements: 7.8/10, Logic: 7/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.EligibilityRulesType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.EligibilityRulesType.sql*
