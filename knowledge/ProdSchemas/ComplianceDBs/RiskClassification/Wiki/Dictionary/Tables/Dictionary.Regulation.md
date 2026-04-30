# Dictionary.Regulation

> Lookup table defining the regulatory jurisdictions under which customer accounts operate, mapping each regulation ID to its name, US classification flag, and eToro entity name.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is a core reference table that defines all regulatory jurisdictions recognized by the risk classification system. Every customer is assigned a regulation based on their country of residence and the eToro entity they register with. The regulation determines which risk scoring thresholds, parameter weights, and compliance rules apply.

The table is referenced throughout the database - by `dbo.T_RiskClassification`, `dbo.T_Scores`, `dbo.V_Scores`, `dbo.V_RiskClassification`, `dbo.V_RiskClassificationParameter`, and the CySEC-specific views. It is also the target of three replication stored procedures (`sp_MSdel/ins/upd_DictionaryRegulation`) indicating it is replicated from a source database.

Data is small and stable (14 rows). Changes propagate via transactional replication from the source system.

---

## 2. Business Logic

### 2.1 US vs Non-US Classification

**What**: The `IsUSA` flag partitions regulations into US and non-US jurisdictions.

**Columns/Parameters Involved**: `IsUSA`

**Rules**:
- IsUSA=1: eToroUS (6), FinCEN (7), FinCEN+FINRA (8), FINRAONLY (12), NYDFSFINRA (14)
- IsUSA=0: All others (CySEC, FCA, ASIC, BVI, FSA Seychelles, FSRA, etc.)
- This classification affects which risk scoring model and reporting requirements apply

### 2.2 Jurisdiction Entity Mapping

**What**: `JurisdictionName` maps regulations to eToro legal entities.

**Columns/Parameters Involved**: `JurisdictionName`

**Rules**:
- Only 3 regulations have JurisdictionName set: CySEC="eToro EU", FCA="eToro UK", ASIC/ASIC&GAML="eToro AUS"
- US regulations and smaller jurisdictions have NULL JurisdictionName
- The entity name determines which legal framework governs the customer relationship

---

## 3. Data Overview

| ID | Name | IsUSA | JurisdictionName | Meaning |
|----|------|-------|-----------------|---------|
| 0 | None | 0 | NULL | No regulation assigned. Placeholder for unclassified or legacy accounts. |
| 1 | CySEC | 0 | eToro EU | Cyprus Securities and Exchange Commission. Covers European Economic Area customers. Uses 6-tier risk scale (Low to Unacceptable). |
| 2 | FCA | 0 | eToro UK | Financial Conduct Authority. UK customers. Same 6-tier scale as CySEC. |
| 7 | FinCEN | 1 | NULL | Financial Crimes Enforcement Network. US AML regulation. 4-tier scale (Low to Block). |
| 8 | FinCEN+FINRA | 1 | NULL | Combined FinCEN + FINRA. US customers with both AML and broker-dealer oversight. |

See [Regulation](../_glossary.md#regulation) for complete value map with all 14 entries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | VERIFIED | Regulation identifier. PK. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 14=NYDFSFINRA. ID 13 is skipped. |
| 2 | Name | VARCHAR(50) | YES | - | VERIFIED | Regulation name/abbreviation. E.g., "CySEC", "FCA", "FinCEN+FINRA". Used as display label in views (V_RiskClassification, V_Scores, etc.). |
| 3 | IsUSA | TINYINT | NO | - | VERIFIED | US jurisdiction flag. 1=US regulation (IDs 6,7,8,12,14), 0=non-US. Determines which compliance framework applies. NOT NULL - every regulation must be classified. |
| 4 | JurisdictionName | VARCHAR(30) | YES | - | VERIFIED | eToro legal entity name. Only populated for CySEC="eToro EU", FCA="eToro UK", ASIC/ASIC&GAML="eToro AUS". NULL for US and smaller jurisdictions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a root lookup table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.T_RiskClassification | RegulationID | Implicit FK | Customer's regulatory jurisdiction |
| dbo.T_Scores | RegulationID | Implicit FK | Score's regulatory context |
| dbo.V_Scores | INNER JOIN ON RegulationID=ID | Lookup | Regulation name resolution |
| dbo.V_RiskClassification | INNER JOIN ON RegulationID=ID | Lookup | Regulation name for risk view |
| dbo.V_RiskClassificationParameter | INNER JOIN ON RegulationID=ID | Lookup | Regulation name for config view |
| BackOffice.RiskClassificationParameter | RegulationID | Implicit FK | Scoring rules per regulation |
| RiskClassification.CySecRiskClassificationParameterView | INNER JOIN ON RegulationID=ID | Lookup | CySEC rule regulation name |
| dbo.sp_MSdel_DictionaryRegulationl | DELETE target | Replication | Replication DELETE procedure |
| dbo.sp_MSins_DictionaryRegulation | INSERT target | Replication | Replication INSERT procedure |
| dbo.sp_MSupd_DictionaryRegulation | UPDATE target | Replication | Replication UPDATE procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_Scores | View | INNER JOIN for regulation name |
| dbo.V_RiskClassification | View | INNER JOIN for regulation name |
| dbo.V_RiskClassificationParameter | View | INNER JOIN for regulation name |
| dbo.V_RiskClassificationDataLake | View | INNER JOIN for regulation name |
| RiskClassification.CySecRiskClassificationParameterView | View | INNER JOIN for regulation name |
| dbo.sp_MSdel/ins/upd_DictionaryRegulation | Stored Procedures | Replication target |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Regulation_ID_1 | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Regulation_ID_1 | PRIMARY KEY | ID - unique regulation identifier |

---

## 8. Sample Queries

### 8.1 List all regulations
```sql
SELECT ID, Name, IsUSA, JurisdictionName
FROM Dictionary.Regulation WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find US-only regulations
```sql
SELECT ID, Name
FROM Dictionary.Regulation WITH (NOLOCK)
WHERE IsUSA = 1
ORDER BY ID
```

### 8.3 Customer count per regulation
```sql
SELECT r.ID, r.Name, COUNT(t.GCID) AS Customers
FROM Dictionary.Regulation r WITH (NOLOCK)
LEFT JOIN dbo.T_RiskClassification t WITH (NOLOCK) ON r.ID = t.RegulationID
GROUP BY r.ID, r.Name
ORDER BY Customers DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (replication SPs) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Regulation | Type: Table | Source: RiskClassification/Dictionary/Tables/Dictionary.Regulation.sql*
