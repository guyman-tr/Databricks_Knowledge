# Billing.GetProtocolDetails

> Returns the configured parameter value for a specific payment protocol, depot mode, and parameter name - providing a flexible key/value configuration lookup used to retrieve protocol-specific settings such as API credentials, URLs, or operational parameters.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 Value, DepotModeID from Billing.ProtocolValue JOIN Billing.Parameter WHERE DepotModeID=@DepotModeID AND ProtocolID=@ProtocolID AND Name=@Name ORDER BY DepotModeID DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolDetails` retrieves a single configuration value for a payment protocol by parameter name and depot mode. The Billing schema uses a `ProtocolValue` + `Parameter` pattern to store key/value configuration for each payment protocol - rather than hardcoding settings per protocol, each is stored as named parameters. This procedure is the accessor for that configuration.

The procedure exists to allow the payment infrastructure (likely internal admin tools or configuration management services) to query protocol-specific configuration values at runtime. A caller might ask: "What is the MID (Merchant ID) configured for ProtocolID=42 in DepotMode=1?" or "What API endpoint URL is configured for this protocol?"

The `ORDER BY DepotModeID DESC` with `TOP 1` implements a priority/override pattern: if a parameter has entries for multiple depot modes, the most specific (highest DepotModeID) takes precedence over more general configurations (lower DepotModeID, including global defaults at DepotModeID=0).

Data flows: created PTL-76 (2022-06-30). No direct permission grants found in the SSDT repo's permission files - this suggests the caller may use an application-level role, or the procedure is called from within another stored procedure rather than directly by a service user.

---

## 2. Business Logic

### 2.1 Parameter Name Lookup

**What**: The procedure retrieves a single named parameter value for a protocol/depot-mode combination.

**Columns/Parameters Involved**: `par.Name`, `@Name`

**Rules**:
- `Billing.ProtocolValue` holds the raw values for protocol parameters
- `Billing.Parameter` holds the parameter names (ParameterID -> Name mapping)
- JOIN: `Billing.ProtocolValue JOIN Billing.Parameter ON ParameterID` - resolves ParameterID to a named key
- Filter: `Name = @Name AND ProtocolID = @ProtocolID AND DepotModeID = @DepotModeID`
- Returns: `Value` (the configuration value for that parameter) and `DepotModeID`

### 2.2 Depot Mode Priority (ORDER BY DepotModeID DESC + TOP 1)

**What**: When a parameter is configured at multiple depot mode levels, the highest DepotModeID wins.

**Rules**:
- `ORDER BY DepotModeID DESC` + `TOP 1` = highest DepotModeID returned
- Pattern: DepotModeID=0 is likely a global default; specific modes (1, 2, ...) override it
- The filter `WHERE DepotModeID=@DepotModeID` combined with ORDER BY suggests the join may return duplicate DepotModeID rows if the parameter has multiple values, and TOP 1 + ORDER selects the most specific

**Note**: The filter already pins `DepotModeID=@DepotModeID`, so the ORDER BY may be a guard against multiple rows with the same DepotModeID (tie-breaking), or it is a legacy pattern from when the query allowed broader DepotModeID matching.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProtocolID | INT | NO | - | CODE-BACKED | The payment protocol to query configuration for. FK to Billing.Protocol (or Billing.ProtocolMIDSettings). |
| 2 | @DepotModeID | INT | NO | - | CODE-BACKED | The depot operational mode context. Used to retrieve mode-specific parameter overrides. FK to Billing.Depot-related mode configuration. |
| 3 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | The parameter name to look up (e.g., 'MerchantID', 'ApiUrl', 'SecretKey'). FK to Billing.Parameter.Name. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 4 | Value | Billing.ProtocolValue.Value | CODE-BACKED | The configured value for this protocol+depotmode+parameter combination. Type is likely NVARCHAR - can hold any configuration value (IDs, URLs, keys, numeric strings). |
| 5 | DepotModeID | Billing.ProtocolValue.DepotModeID | CODE-BACKED | The depot mode ID for the returned row. Echoed from the data (always equals @DepotModeID given the WHERE filter). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProtocolID | Billing.ProtocolValue.ProtocolID | Filter | Scopes query to this payment protocol's configuration values |
| @DepotModeID | Billing.ProtocolValue.DepotModeID | Filter | Scopes query to this depot mode's configuration |
| @Name | Billing.Parameter.Name | Filter | Resolves the named parameter to a ParameterID for the JOIN |
| (JOIN) | Billing.Parameter | INNER JOIN | Resolves parameter names to IDs; links ParameterID to Name |
| (JOIN) | Billing.ProtocolValue | INNER JOIN | Source of the Value for the protocol+parameter combination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No permission grants found in SSDT) | - | - | Likely called via application-level role or from within another SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolDetails (procedure)
├── Billing.ProtocolValue (table)
└── Billing.Parameter (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolValue | Table | Primary source of protocol configuration values; filtered by ProtocolID and DepotModeID |
| Billing.Parameter | Table | INNER JOINed to resolve ParameterID to parameter Name; filtered by Name=@Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No callers found in SSDT permission files) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Creation**: PTL-76 (2022-06-30). The `Billing.ProtocolValue` + `Billing.Parameter` pattern provides a generic EAV (Entity-Attribute-Value) store for protocol configuration, avoiding schema changes when new protocol parameters are added. **Callers**: No explicit GRANT EXECUTE found in the SSDT permission files - callers may access this through an application-level role membership rather than individual grants, or it may be called exclusively from within other stored procedures.

---

## 8. Sample Queries

### 8.1 Get a specific protocol parameter
```sql
EXEC [Billing].[GetProtocolDetails]
    @ProtocolID = 42,
    @DepotModeID = 1,
    @Name = 'MerchantID'
```

### 8.2 List all parameters for a protocol and depot mode
```sql
SELECT par.Name, pv.Value, pv.DepotModeID
FROM Billing.ProtocolValue pv WITH (NOLOCK)
INNER JOIN Billing.Parameter par WITH (NOLOCK) ON par.ParameterID = pv.ParameterID
WHERE pv.ProtocolID = 42
  AND pv.DepotModeID = 1
ORDER BY par.Name
```

### 8.3 Find all protocols that have a specific parameter configured
```sql
SELECT pv.ProtocolID, pv.Value, pv.DepotModeID
FROM Billing.ProtocolValue pv WITH (NOLOCK)
INNER JOIN Billing.Parameter par WITH (NOLOCK) ON par.ParameterID = pv.ParameterID
WHERE par.Name = 'MerchantID'
  AND pv.DepotModeID IN (0, 1)
ORDER BY pv.ProtocolID, pv.DepotModeID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-76 (referenced in DDL comment) | Jira | Initial creation of GetProtocolDetails procedure (2022-06-30) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PTL-76 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolDetails.sql*
