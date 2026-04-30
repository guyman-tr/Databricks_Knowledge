# Billing.GetDepotMIDSettings

> Returns a single MID setting value for a customer-depot combination, resolving the customer's effective regulatory jurisdiction (with undefined-regulation fallback) before querying the protocol MID settings table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: Value (from Billing.ProtocolMIDSettings) for the resolved regulation, depot, mode, and parameter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepotMIDSettings` resolves the MID (Merchant ID) configuration value for a specific customer processing through a specific depot, mode, and parameter combination. The key business logic is the regulation resolution step: a customer's processing regulation may be "undefined" (not yet assigned), in which case the SP falls back to the customer's designated regulation or a system default.

Created by Ran Ovadia, July 2018 (FB: 52126). No GRANT EXECUTE found in SSDT permissions files - accessed by a service without an SSDT-tracked grant.

The `Billing.ProtocolMIDSettings` table stores per-depot, per-regulation, per-mode configuration parameters (MID values, credentials, gateway settings). This SP abstracts the regulation resolution so callers don't need to implement the undefined-regulation fallback logic themselves.

---

## 2. Business Logic

### 2.1 Customer Regulation Resolution

**What**: Determines the effective processing regulation for the customer, handling the case where the regulation is not yet defined.

**Columns/Parameters Involved**: `BackOffice.Customer.RegulationID`, `BackOffice.Customer.DesignatedRegulationID`, `@UndefinedRegulationID`, `@DefaultRegulationID`, `@ProcessingRegulationID (internal)`

**Rules**:
- Step 1: `SELECT @RegulationID = RegulationID, @DesignatedRegulationID = COALESCE(DesignatedRegulationID, @DefaultRegulationID) FROM BackOffice.Customer WHERE CID = @CID`
  - Gets the customer's assigned regulation
  - Falls back DesignatedRegulationID to @DefaultRegulationID if null
- Step 2: IF @RegulationID = @UndefinedRegulationID:
  - `@ProcessingRegulationID = @DesignatedRegulationID` - use designated (or default) when regulation is "undefined"
- ELSE:
  - `@ProcessingRegulationID = @RegulationID` - use the actual assigned regulation
- The @UndefinedRegulationID value is passed by the caller (not hardcoded in the SP) - the caller knows what ID represents "undefined" in their context

**Diagram**:
```
@CID
  |
  -> BackOffice.Customer.RegulationID + DesignatedRegulationID
     |
     IF RegulationID = @UndefinedRegulationID
       -> ProcessingRegulationID = COALESCE(DesignatedRegulationID, @DefaultRegulationID)
     ELSE
       -> ProcessingRegulationID = RegulationID
     |
     v
SELECT Value FROM Billing.ProtocolMIDSettings
WHERE DepotID = @DepotID
  AND (DepotModeID = @DepotModeID OR DepotModeID = 0)
  AND RegulationID = ProcessingRegulationID
  AND ParameterID = @ParameterID
```

### 2.2 MID Parameter Value Retrieval

**What**: Returns the configuration value for a specific MID parameter, supporting mode-specific and mode-global settings.

**Columns/Parameters Involved**: `@DepotID`, `@DepotModeID`, `@ParameterID`, `Billing.ProtocolMIDSettings.Value`

**Rules**:
- `DepotModeID = @DepotModeID OR DepotModeID = 0` - returns settings specific to the requested mode OR global settings (DepotModeID=0 = applies to all modes)
- Multiple rows may match (both mode-specific and mode-global) - the query returns all matching rows, so typically one row but potentially two if both a mode-specific and a mode-global (DepotModeID=0) row exist
- `ParameterID` is the specific configuration key being queried (e.g., MID number, API key, merchant code)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to look up RegulationID and DesignatedRegulationID from BackOffice.Customer. |
| 2 | @DepotID | INT | NO | - | CODE-BACKED | Payment gateway/depot ID. Filters Billing.ProtocolMIDSettings to settings for this depot. |
| 3 | @DepotModeID | INT | NO | - | CODE-BACKED | Depot mode (e.g., live, test, specific processing mode). Combined with DepotModeID=0 (global fallback) in WHERE clause. |
| 4 | @ParameterID | INT | NO | - | CODE-BACKED | The specific MID configuration parameter to retrieve (e.g., merchant ID, API key). Filters Billing.ProtocolMIDSettings.ParameterID. |
| 5 | @UndefinedRegulationID | INT | NO | - | CODE-BACKED | The RegulationID value that means "not yet assigned". Caller-provided; SP treats customers with this RegulationID as unregulated and falls back to DesignatedRegulationID. |
| 6 | @DefaultRegulationID | INT | NO | - | CODE-BACKED | Ultimate fallback regulation when both RegulationID is undefined AND DesignatedRegulationID is NULL. System-wide default regulation for unassigned customers. |
| 7 | Value (output) | VARCHAR | YES | - | CODE-BACKED | The MID configuration value from Billing.ProtocolMIDSettings. Content depends on ParameterID (e.g., MID number string, credential). NULL if no matching configuration exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer.CID | Lookup | Resolves customer's regulation assignment |
| @ProcessingRegulationID (derived) + @DepotID + @DepotModeID + @ParameterID | Billing.ProtocolMIDSettings | Lookup | Retrieves MID configuration value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment processing service | Direct execution | Operational | No GRANT EXECUTE found in SSDT - accessed by service with elevated DB access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepotMIDSettings (procedure)
├── BackOffice.Customer (table)
└── Billing.ProtocolMIDSettings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | READ NOLOCK - gets RegulationID and DesignatedRegulationID for @CID |
| Billing.ProtocolMIDSettings | Table | READ NOLOCK - returns Value for resolved regulation + depot + mode + parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment processing service | Service | MID parameter resolution during payment processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Undefined regulation fallback | Design | @UndefinedRegulationID is caller-provided; allows the SP to be regulation-system-agnostic (the caller defines what "undefined" means) |
| DepotModeID = 0 as global fallback | Design | Settings with DepotModeID=0 apply to any depot mode; specific mode settings coexist with global settings |
| Multiple rows possible | Design | `OR DepotModeID = 0` can return both mode-specific and global rows; caller receives potentially multiple rows if both exist |
| COALESCE for DesignatedRegulationID | Design | `COALESCE(DesignatedRegulationID, @DefaultRegulationID)` ensures there is always a fallback regulation to use |

---

## 8. Sample Queries

### 8.1 Get MID setting for a customer-depot-mode-parameter combination

```sql
EXEC Billing.GetDepotMIDSettings
    @CID = 12345,
    @DepotID = 4,
    @DepotModeID = 1,
    @ParameterID = 10,
    @UndefinedRegulationID = 0,      -- 0 = "undefined" regulation in this system
    @DefaultRegulationID = 1;        -- system default regulation
```

### 8.2 Inline equivalent for regulation resolution

```sql
DECLARE @RegID INT, @DesignatedRegID INT, @ProcessingRegID INT;

SELECT @RegID = RegulationID,
       @DesignatedRegID = COALESCE(DesignatedRegulationID, 1 /*@DefaultRegulationID*/)
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;

SET @ProcessingRegID = CASE WHEN @RegID = 0 /*@UndefinedRegulationID*/ THEN @DesignatedRegID ELSE @RegID END;

SELECT [Value]
FROM Billing.ProtocolMIDSettings WITH (NOLOCK)
WHERE DepotID = 4
  AND (DepotModeID = 1 OR DepotModeID = 0)
  AND RegulationID = @ProcessingRegID
  AND ParameterID = 10;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Deposit Info Current Structure and Data (Confluence) | Confluence | Context for how MID settings and deposit configuration are structured |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 4/10, Sources: 3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence (search result) + 0 Jira | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepotMIDSettings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepotMIDSettings.sql*
