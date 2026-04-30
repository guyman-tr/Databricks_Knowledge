# Billing.LoadProtocolParameters

> Data loader that returns all rows from Dictionary.ProtocolParameter, providing the billing engine with the full list of payment protocol configuration parameter definitions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.ProtocolParameter table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadProtocolParameters is a bulk data loader that returns all rows from Dictionary.ProtocolParameter. This table defines the named configuration parameters that each payment protocol requires - for example, a credit card protocol needs parameters like "command", "version", "language", "transactionType", "creditType", etc.

The parameter names in this table are the schema/keys used in Billing.ProtocolValue, which stores the actual values for each parameter. Together, Dictionary.ProtocolParameter (defines what parameters exist) and Billing.ProtocolValue (stores the values for each parameter per protocol and depot mode) form the payment protocol configuration system. The billing engine loads both tables at startup to fully configure all available payment processing protocols.

---

## 2. Business Logic

### 2.1 Protocol Parameter Schema

**What**: Defines the named configuration parameters for each payment protocol.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Dictionary.ProtocolParameter via SELECT * WITH (NOLOCK).
- Each row defines one parameter slot for a specific protocol: (ParamID, ProtocolID, ParamName).
- The actual values for each parameter are in Billing.ProtocolValue (loaded by Billing.LoadProtocolValues).
- Example parameters for ProtocolID=1 (Xor): "command", "version", "language", "transactionType", "creditType".
- Combination of ProtocolID + ParamID is the key used to look up corresponding values in Billing.ProtocolValue.

**Diagram**:
```
Dictionary.Protocol (loaded by LoadProtocols)
    |
    v [ProtocolID]
Dictionary.ProtocolParameter (loaded by LoadProtocolParameters)
  [ParamID=1, ProtocolID=1, ParamName="command"]
  [ParamID=2, ProtocolID=1, ParamName="version"]
    |
    v [ProtocolID + ParamID]
Billing.ProtocolValue (loaded by LoadProtocolValues)
  [Value="charge", DepotModeID=1]  <- actual value for this parameter
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
| (SELECT *) | Dictionary.ProtocolParameter | READ | Reads all protocol parameter name definitions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache protocol parameter schemas. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadProtocolParameters (procedure)
└── Dictionary.ProtocolParameter (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ProtocolParameter | Table | SELECT * - reads all protocol parameter definitions. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads protocol parameter schema at startup. |

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
EXEC Billing.LoadProtocolParameters;
```

### 8.2 View all parameters for a specific protocol
```sql
SELECT pp.ParamID, pp.ParamName, p.Name AS ProtocolName
FROM Dictionary.ProtocolParameter pp WITH (NOLOCK)
INNER JOIN Dictionary.Protocol p WITH (NOLOCK)
    ON pp.ProtocolID = p.ProtocolID
WHERE pp.ProtocolID = 1
ORDER BY pp.ParamID;
```

### 8.3 Parameters with their configured values (per depot mode)
```sql
SELECT pp.ParamName, pv.Value, pv.DepotModeID
FROM Dictionary.ProtocolParameter pp WITH (NOLOCK)
INNER JOIN Billing.ProtocolValue pv WITH (NOLOCK)
    ON pp.ProtocolID = pv.ProtocolID AND pp.ParamID = pv.ParameterID
WHERE pp.ProtocolID = 1
ORDER BY pp.ParamID, pv.DepotModeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadProtocolParameters | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadProtocolParameters.sql*
