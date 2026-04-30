# Billing.LoadProtocolValues

> Data loader that returns all rows from Billing.ProtocolValue, providing the billing engine with the actual configured values for every protocol parameter per depot mode.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Billing.ProtocolValue table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadProtocolValues is a bulk data loader that returns all rows from Billing.ProtocolValue. This table stores the actual configuration values for each payment protocol parameter (defined in Dictionary.ProtocolParameter), per depot mode (DepotModeID). For example, for the Skrill/MoneyBookers redirect protocol, the "return_url" parameter would have different values for production (DepotModeID=1) vs staging (DepotModeID=2).

Together with LoadProtocols and LoadProtocolParameters, this procedure completes the three-loader protocol configuration sequence. The billing engine loads all three tables at startup to fully configure each payment protocol with its environment-specific parameter values. The ProtocolValueID uniquely identifies each row and is the primary key used for lookups.

---

## 2. Business Logic

### 2.1 Environment-Specific Protocol Configuration

**What**: Each protocol parameter can have different values per depot mode (production vs staging vs test).

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Billing.ProtocolValue via SELECT * WITH (NOLOCK).
- Key: (ParameterID, ProtocolID, DepotModeID) identifies the effective value for a specific parameter in a specific protocol and environment.
- DepotModeID=1: production; DepotModeID=2: staging/test.
- Value field contains the actual parameter value (URLs, API keys, merchant IDs, etc.).
- FunnelID: optional funnel-specific override for A/B testing or funnel-specific routing.
- ProtocolValueID: surrogate PK for direct lookup.

**Diagram**:
```
Dictionary.Protocol [ProtocolID=35 = Skrill Rapid]
    |
    v
Dictionary.ProtocolParameter [ParamID=1 = "return_url"]
    |
    v
Billing.ProtocolValue [ProtocolID=35, ParameterID=1]
  DepotModeID=1 -> "https://www.etoro.com/api/billing/skrillRapid/Postback/..."
  DepotModeID=2 -> "http://52.166.244.157:90/api/skrillRapid/Postback/..."
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Billing.ProtocolValue | READ | Reads all protocol configuration values (environment-specific). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache protocol configuration values. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadProtocolValues (procedure)
└── Billing.ProtocolValue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolValue | Table | SELECT * - reads all protocol parameter values per depot mode. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads protocol values at startup to configure payment processing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader
```sql
EXEC Billing.LoadProtocolValues;
```

### 8.2 Get all configured values for a specific protocol
```sql
SELECT pp.ParamName, pv.Value, pv.DepotModeID, pv.FunnelID
FROM Billing.ProtocolValue pv WITH (NOLOCK)
INNER JOIN Dictionary.ProtocolParameter pp WITH (NOLOCK)
    ON pv.ProtocolID = pp.ProtocolID AND pv.ParameterID = pp.ParamID
WHERE pv.ProtocolID = 8
ORDER BY pp.ParamID, pv.DepotModeID;
```

### 8.3 Compare production vs staging values for a protocol
```sql
SELECT pp.ParamName,
       MAX(CASE WHEN pv.DepotModeID = 1 THEN pv.Value END) AS ProdValue,
       MAX(CASE WHEN pv.DepotModeID = 2 THEN pv.Value END) AS StagingValue
FROM Billing.ProtocolValue pv WITH (NOLOCK)
INNER JOIN Dictionary.ProtocolParameter pp WITH (NOLOCK)
    ON pv.ProtocolID = pp.ProtocolID AND pv.ParameterID = pp.ParamID
WHERE pv.ProtocolID = 35
GROUP BY pp.ParamName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadProtocolValues | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadProtocolValues.sql*
