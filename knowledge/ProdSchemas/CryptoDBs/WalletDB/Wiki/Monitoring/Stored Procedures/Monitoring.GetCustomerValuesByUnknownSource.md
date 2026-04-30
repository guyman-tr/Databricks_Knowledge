# Monitoring.GetCustomerValuesByUnknownSource

> Retrieves customer eligibility value changes that were recorded with an unknown source (ValueChangingSourceId = 0), indicating potentially untracked or miscategorized value updates.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customer value change records with unknown source |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetCustomerValuesByUnknownSource is a data quality alert that identifies customer eligibility value changes where the source of the change was not properly recorded. The ValueChangingSourceId column should indicate which system or process modified the customer's value (e.g., manual update, batch job, API call). A value of 0 (unknown) suggests a code path that fails to set the source, potentially a bug or a legacy integration.

Without this procedure, unknown-source value changes would accumulate silently, making it impossible to audit who or what changed a customer's eligibility status. This is important for compliance and traceability requirements.

The procedure simply filters Eligibility.CustomerValues for records with ValueChangingSourceId = 0 within the specified lookback window.

---

## 2. Business Logic

### 2.1 Unknown Source Detection

**What**: Flags value changes that lack proper source attribution.

**Columns/Parameters Involved**: `ValueChangingSourceId`, `@HoursBack`

**Rules**:
- ValueChangingSourceId = 0 indicates the source of the change was not identified
- Only recent changes (within @HoursBack hours) are returned to focus on active issues
- All columns from CustomerValues are returned for investigation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours from current UTC time. Default 24 hours covers a full day of changes. |

**Output Columns:**

Returns all columns from Eligibility.CustomerValues (SELECT *) where ValueChangingSourceId = 0.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Eligibility.CustomerValues | FROM (read) | Filters for unknown-source value changes |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetCustomerValuesByUnknownSource (procedure)
  └── Eligibility.CustomerValues (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.CustomerValues | Table | FROM - source of customer value changes |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetCustomerValuesByUnknownSource;
```

### 8.2 Check last week
```sql
EXEC Monitoring.GetCustomerValuesByUnknownSource @HoursBack = 168;
```

### 8.3 Check distribution of value changing sources
```sql
SELECT ValueChangingSourceId, COUNT(*) AS ChangeCount
FROM Eligibility.CustomerValues WITH (NOLOCK)
WHERE Occured >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ValueChangingSourceId
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetCustomerValuesByUnknownSource | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetCustomerValuesByUnknownSource.sql*
