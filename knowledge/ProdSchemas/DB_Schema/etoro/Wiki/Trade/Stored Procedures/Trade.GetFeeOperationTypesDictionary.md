# Trade.GetFeeOperationTypesDictionary

> Returns all rows from Dictionary.FeeOperationTypes. Simple parameterless dictionary loader used to populate fee operation type dropdowns or caches.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All FeeOperationTypes rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the full fee operation types dictionary. Fee operation types classify the kinds of operations (e.g., open, close, copy) that can incur fees. The procedure models "what fee operation types exist in the system" for UI dropdowns, validation, or caching. Without it, callers would query Dictionary.FeeOperationTypes directly. It exists to provide a stable, documented API for loading fee operation types, ensuring consistency across applications that need this reference data. The procedure is called when an application initializes, when a fee configuration UI loads its dropdowns, or when a service caches fee operation types for validation. Data flows directly from Dictionary.FeeOperationTypes with no filtering; all columns are returned via SELECT *.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple SELECT * from dictionary table. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeOperationTypeID | TINYINT | NO | - | CODE-BACKED | Output. Primary key from Dictionary.FeeOperationTypes. Identifies the fee operation type (e.g., 1=Open, 2=Close, 3=All per validation logic). Used for dropdowns and fee config validation. |
| 2 | Name | VARCHAR(100) | NO | - | CODE-BACKED | Output. Human-readable name of the fee operation type from Dictionary.FeeOperationTypes. Used for display in UI dropdowns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.FeeOperationTypes | Table | Single source. All columns read. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFeeOperationTypesDictionary (procedure)
└── Dictionary.FeeOperationTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FeeOperationTypes | Table | SELECT *. Full table read. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Not analyzed in this phase | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Load fee operation types dictionary

```sql
EXEC Trade.GetFeeOperationTypesDictionary;
```

### 8.2 Equivalent inline query

```sql
SELECT * FROM Dictionary.FeeOperationTypes WITH (NOLOCK);
```

### 8.3 Use as reference in a fee configuration query

```sql
-- Assume caller has loaded dictionary and caches it
EXEC Trade.GetFeeOperationTypesDictionary;

-- Subsequent query joins fee config to dictionary for display
SELECT fc.InstrumentID, fc.FeeOperationTypeID, fot.Name
FROM Trade.FeeInPercentageConfigurations fc WITH (NOLOCK)
JOIN Dictionary.FeeOperationTypes fot WITH (NOLOCK) ON fot.FeeOperationTypeID = fc.FeeOperationTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 6.5/10 (Elements: 6/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFeeOperationTypesDictionary | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFeeOperationTypesDictionary.sql*
