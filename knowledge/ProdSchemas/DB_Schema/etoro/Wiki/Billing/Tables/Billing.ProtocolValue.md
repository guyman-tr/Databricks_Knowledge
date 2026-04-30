# Billing.ProtocolValue

> Configuration store for payment protocol API parameters, holding the named key-value pairs (credentials, endpoints, flags) required by each payment provider integration for deposit and withdrawal operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ProtocolValueID (INT IDENTITY, PK CLUSTERED) - natural key: (ProtocolID, ParameterID, DepotModeID) |
| **Partition** | MAIN filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Billing.ProtocolValue is the API configuration registry for eToro's payment integrations. For each payment protocol (provider), it stores the named parameters needed to connect to and authenticate with the provider's API - including request URLs, credentials, API keys, language codes, command names, credit types, and other provider-specific settings. The billing service loads this configuration at startup via LoadProtocolValues, then uses the parameter values when constructing provider API calls.

455 rows cover 35 distinct protocols and 131 distinct parameter types. DepotModeID distinguishes configuration by operation context: 0=default/common, 1=one mode (deposit?), 2=another mode (withdrawal?). The combination (ProtocolID, ParameterID, DepotModeID) forms the natural key - allowing the same parameter to have different values per protocol per operation mode.

**Security note**: This table contains sensitive API credentials (passwords, API keys, usernames, URLs). Access should be restricted to authorized billing service accounts only. The LoadProtocolValues SP does `SELECT *` with no column filtering.

Example parameters observed (ProtocolID=1, legacy Israeli payment gateway pay.sheseq.co.il): language, version, command, apiUsername, creditType, transactionCode, validation, requestUrl, userName, password.

---

## 2. Business Logic

### 2.1 Protocol Configuration Loading

**What**: LoadProtocolValues loads all protocol configuration in a single SELECT *.

**Columns/Parameters Involved**: `ProtocolID`, `ParameterID`, `Value`, `DepotModeID`

**Rules**:
- LoadProtocolValues: SELECT * FROM Billing.ProtocolValue - returns all 455 rows.
- The billing service caches this in memory and looks up parameters by (ProtocolID, ParameterID, DepotModeID) when constructing API requests.
- FunnelID: NULL for most rows. When non-NULL, the configuration is funnel-specific (different values for different acquisition funnels/campaigns).

### 2.2 DepotModeID Context

**What**: The same parameter can have different values depending on the operation mode.

**Columns/Parameters Involved**: `DepotModeID`, `ParameterID`, `Value`

**Rules**:
- DepotModeID=0: 71 rows - default/shared configuration (applies regardless of operation type).
- DepotModeID=1: 171 rows - mode 1 (likely deposit-specific configuration).
- DepotModeID=2: 213 rows - mode 2 (likely withdrawal/cashout-specific configuration).
- When a parameter exists for a specific DepotModeID, it overrides the DepotModeID=0 default for that operation.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 455 |
| Distinct protocols | 35 |
| Distinct parameters | 131 |
| DepotModeID=0 | 71 rows (common/default config) |
| DepotModeID=1 | 171 rows (mode 1 config) |
| DepotModeID=2 | 213 rows (mode 2 config) |

Parameter types observed: language, version, command, apiUsername, creditType, transactionCode, validation, requestUrl, userName, password (and 121 more).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParameterID | int | NO | - | CODE-BACKED | Configuration parameter type identifier. FK to Billing.Parameter (no constraint declared). 131 distinct values observed. Parameter names (from Billing.Parameter): language, version, command, apiUsername, creditType, requestUrl, userName, password, etc. |
| 2 | ProtocolID | int | NO | - | CODE-BACKED | Payment protocol this configuration belongs to. No FK constraint declared (unlike ProtocolCountry). 35 distinct protocols. The billing service groups parameters by ProtocolID when building API clients. |
| 3 | Value | varchar(250) | YES | - | CODE-BACKED | The configuration value. Content depends on ParameterID: could be a URL (e.g., "https://pay.sheseq.co.il/ssl/Relay"), a credential (username/password), an API key, a language code ("en"), a command name ("doDeal"), or a numeric version ("1000"). **Contains sensitive credentials - restrict access.** |
| 4 | DepotModeID | tinyint | NO | 0 | CODE-BACKED | Operation mode context. Default 0. Values observed: 0=common/default, 1=mode 1 (deposit?), 2=mode 2 (withdrawal?). Allows the same parameter to have different values per operation type. |
| 5 | FunnelID | int | YES | - | CODE-BACKED | Acquisition funnel identifier. NULL for most rows. When non-NULL, this parameter value applies only to deposits/withdrawals originating from a specific marketing funnel or acquisition channel. |
| 6 | ProtocolValueID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. NOT FOR REPLICATION. Business lookups use the combination (ProtocolID, ParameterID, DepotModeID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParameterID | Billing.Parameter | Implicit | References the parameter name/type. No declared FK. |
| ProtocolID | Dictionary.Protocol | Implicit | References the payment provider. No declared FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.LoadProtocolValues | ProtocolID, ParameterID, Value, DepotModeID | SELECT reader | Loads entire configuration table for billing service cache. SELECT *. |
| Billing.GetProtocolDetails | - | SELECT reader | Retrieves protocol details including configuration parameters. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProtocolValue (table)
  -> Billing.Parameter (implicit - ParameterID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Parameter | Table | Defines parameter names (ParameterID -> Name mapping) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.LoadProtocolValues | Stored Procedure | Loads all protocol config values |
| Billing.GetProtocolDetails | Stored Procedure | Reads protocol configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProtocolValue | CLUSTERED PK | ProtocolValueID ASC | - | - | Active (MAIN filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ProtocolValue | PRIMARY KEY | ProtocolValueID clustered |
| DF_ProtocolValue_DepotModeID | DEFAULT | 0 for DepotModeID |

---

## 8. Sample Queries

### 8.1 Get all configuration for a specific protocol

```sql
SELECT pv.ParameterID, bp.Name AS ParamName, pv.Value, pv.DepotModeID, pv.FunnelID
FROM Billing.ProtocolValue pv WITH (NOLOCK)
JOIN Billing.Parameter bp WITH (NOLOCK) ON pv.ParameterID = bp.ParameterID
WHERE pv.ProtocolID = 43  -- Checkout.com
ORDER BY pv.DepotModeID, bp.Name
```

### 8.2 Load all protocol values (as the billing service does)

```sql
EXEC Billing.LoadProtocolValues
```

### 8.3 Find which protocols use a specific parameter

```sql
SELECT pv.ProtocolID, p.Name AS Protocol, pv.DepotModeID, pv.Value
FROM Billing.ProtocolValue pv WITH (NOLOCK)
JOIN Billing.Parameter bp WITH (NOLOCK) ON pv.ParameterID = bp.ParameterID
JOIN Dictionary.Protocol p WITH (NOLOCK) ON pv.ProtocolID = p.ProtocolID
WHERE bp.Name = 'requestUrl'
ORDER BY pv.ProtocolID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Note: Contains sensitive API credentials - access should be restricted to billing service accounts only.*
*Object: Billing.ProtocolValue | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ProtocolValue.sql*
