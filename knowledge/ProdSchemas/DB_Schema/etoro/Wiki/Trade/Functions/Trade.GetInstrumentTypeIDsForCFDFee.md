# Trade.GetInstrumentTypeIDsForCFDFee

> Returns a table of InstrumentTypeIDs that are subject to CFD fees, loaded from the Maintenance.Feature configuration (FeatureID 115) as a comma-separated list.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE with InstrumentTypeID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentTypeIDsForCFDFee returns the list of instrument types (asset classes) that are subject to CFD-specific fees. The list is stored as a comma-separated string in Maintenance.Feature (FeatureID=115), which allows operations teams to modify the fee-applicable instrument types without code changes.

This function exists because not all asset classes are charged CFD fees - the fee structure varies by instrument type and is configured dynamically. By storing the list in Maintenance.Feature, the platform can add or remove instrument types from CFD fee eligibility at runtime. The function parses the comma-separated value using STRING_SPLIT and returns it as a table for use in JOIN/IN clauses.

---

## 2. Business Logic

### 2.1 Feature-Driven Configuration

**What**: CFD fee-applicable instrument types are loaded from a centralized feature configuration table.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID=115`, `Maintenance.Feature.Value`

**Rules**:
- Reads FeatureID = 115 from Maintenance.Feature (note: code comment says 114 but code uses 115)
- Value is a comma-separated string of InstrumentTypeIDs (e.g., "1,2,3,4,5")
- STRING_SPLIT parses the string into individual rows
- Each value is inserted into the return table as an INT

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID (return) | INT | NO | - | CODE-BACKED | An instrument type ID that is subject to CFD fees. Maps to Dictionary.CurrencyType.CurrencyTypeID: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=115 | Maintenance.Feature | SELECT/WHERE | Reads the comma-separated list of instrument type IDs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentTypeIDsForCFDFee (function)
  └── Maintenance.Feature (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=115 for CFD fee instrument types |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS @tmpInstrumentIDsList TABLE | Return type | Multi-statement TVF returning InstrumentTypeID rows |
| WITH (NOLOCK) | Read hint | NOLOCK on Maintenance.Feature read |
| STRING_SPLIT | Parsing | SQL Server 2016+ function for CSV parsing |

---

## 8. Sample Queries

### 8.1 List all instrument types subject to CFD fees

```sql
SELECT  cfd.InstrumentTypeID,
        ct.Name AS TypeName
FROM    Trade.GetInstrumentTypeIDsForCFDFee() cfd
        LEFT JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON cfd.InstrumentTypeID = ct.CurrencyTypeID;
```

### 8.2 Check if a specific instrument type has CFD fees

```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1 FROM Trade.GetInstrumentTypeIDsForCFDFee() WHERE InstrumentTypeID = 5
        ) THEN 'Yes' ELSE 'No' END AS StocksHaveCFDFees;
```

### 8.3 Find instruments subject to CFD fees

```sql
SELECT  imd.InstrumentID,
        imd.InstrumentDisplayName,
        imd.InstrumentTypeID
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Trade.GetInstrumentTypeIDsForCFDFee() cfd ON imd.InstrumentTypeID = cfd.InstrumentTypeID
WHERE   imd.Tradable = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentTypeIDsForCFDFee | Type: Multi-Statement Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetInstrumentTypeIDsForCFDFee.sql*
