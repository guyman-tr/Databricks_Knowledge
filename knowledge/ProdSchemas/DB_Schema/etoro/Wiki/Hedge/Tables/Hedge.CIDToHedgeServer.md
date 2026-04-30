# Hedge.CIDToHedgeServer

> Customer-level override table that forces specific customer accounts to a designated hedge server and optionally bypasses normal hedge exposure limits; used for special-case routing of large, internal, or problematic accounts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | CID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Hedge.CIDToHedgeServer is an exception/override table for the hedge routing system. In the normal flow, customer positions are routed to hedge servers based on instrument type and default server configuration (via Hedge.InstrumentTypeConfiguration and Maintenance.Feature). This table allows operations to bypass that default routing for specific customers, forcing a named customer (identified by CID) onto a specific HedgeServerID. Additionally, the IgnoreLimit flag can suppress normal hedge exposure limit enforcement for that customer's positions.

The table holds 2 rows in the current environment, both inserting specific high-volume CIDs onto HedgeServerID 1 with IgnoreLimit=true. The Occurred column records the UTC datetime of the override's effective time (defaulting to GETUTCDATE() at insert).

This approach superseded an older XML-based mechanism: `Internal.GetCustomerToHedgeServer` reads a CID-to-HedgeServer mapping from an XML blob stored in `Maintenance.Feature` (FeatureID=9). The current DB table approach provides row-level auditability (who was mapped and when) that the XML approach lacked.

A companion history table, `History.CIDToHedgeServerMapping`, stores point-in-time XML snapshots of prior mapping states for audit/rollback purposes.

The CEP UI (user `PROD\CEP_UI_USER`) has SELECT access to this table, suggesting it is surfaced in an internal operations UI for viewing and managing customer routing exceptions.

---

## 2. Business Logic

### 2.1 Customer-Specific Hedge Server Override

**What**: A row in this table causes all hedge activity for a specific customer to be routed to the designated HedgeServerID, overriding the default instrument-type-based routing.

**Columns/Parameters Involved**: `CID`, `HedgeServerID`

**Rules**:
- One row per CID (PK). Only one override per customer is allowed.
- When a customer has a row here, the hedge system routes their positions to `HedgeServerID` instead of the default server for their instrument type.
- HedgeServerID FK to Trade.HedgeServer - only active hedge servers are valid targets.
- Occurred defaults to GETUTCDATE() - records when the override was established. Not modified by subsequent changes.
- Typical use cases: large institutional clients assigned to a dedicated server, internal/test accounts isolated from production flow, accounts under investigation requiring controlled routing.

### 2.2 IgnoreLimit Flag

**What**: When set, the normal hedge exposure limit checks are bypassed for this customer's positions.

**Columns/Parameters Involved**: `IgnoreLimit`

**Rules**:
- IgnoreLimit = 0 (false): Normal limit enforcement applies. The hedge server respects configured exposure boundaries.
- IgnoreLimit = 1 (true): Hedge exposure limits are ignored for this customer's positions. Both current rows have IgnoreLimit=true.
- This flag is used for accounts where normal risk limits are not applicable - for example, internal eToro accounts used for testing or liquidity management that should not trigger hedging limit alerts.

### 2.3 Migration from XML-Based Routing

**What**: This table replaces a legacy XML-based CID-to-HedgeServer mapping stored in Maintenance.Feature FeatureID=9.

**Rules**:
- `Internal.GetCustomerToHedgeServer` reads CID mappings from an XML blob at `Maintenance.Feature` where FeatureID=9, using OPENXML. This procedure represents the old approach.
- `History.CIDToHedgeServerMapping` stores timestamped XML snapshots of prior states, providing a historical audit trail for the XML-era mappings.
- The current DB table approach provides per-row auditability: each override records the exact Occurred timestamp.
- Both mechanisms may coexist during a transition period; the DB table is the authoritative current state.

---

## 3. Data Overview

2 rows as of 2026-03-19.

| CID | HedgeServerID | IgnoreLimit | Occurred | Meaning |
|-----|---------------|-------------|----------|---------|
| 3739182 | 1 | true | 2025-09-08 08:52:51 | Customer 3739182 force-routed to HedgeServer 1 with limit bypass. Likely an internal or test account. |
| 3739193 | 1 | true | 2025-09-08 11:48:21 | Customer 3739193 force-routed to HedgeServer 1 with limit bypass. Same batch of overrides established Sept 2025. |

Both rows share HedgeServerID=1, IgnoreLimit=true, and were inserted on the same date (2025-09-08), suggesting a coordinated operational setup for a specific purpose (e.g., isolating internal eToro accounts).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier. FK to Customer.CustomerStatic(CID). The unique customer for whom the hedge server override applies. Clustered PK - one override per customer. |
| 2 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server this customer's positions are force-routed to, regardless of the default instrument-type routing. Both current rows point to HedgeServerID=1. |
| 3 | IgnoreLimit | bit | NO | - | CODE-BACKED | When 1 (true): hedge exposure limit enforcement is bypassed for this customer's positions. When 0 (false): normal limits apply. Both current rows have IgnoreLimit=1, indicating these are accounts where limit checks are not applicable (e.g., internal/test accounts). No DDL default - must be set explicitly at insert. |
| 4 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of when this override was established. Defaults to GETUTCDATE() at insert. Records operational timing - useful for auditing when a specific CID was redirected and whether it coincides with a known incident or operational change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK | FK_HedgeCIDToHedgeServer_CID - enforces that only real customers can be overridden |
| HedgeServerID | Trade.HedgeServer | FK | FK_HedgeCIDToHedgeServer_HedgeServerID - ensures the target server is a valid hedge server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge routing application | CID lookup | Reader | Application code reads this table to check if an incoming CID has a routing override before applying default server assignment |
| CEP UI (PROD\CEP_UI_USER) | SELECT grant | Reader | Internal operations UI surfaces this table for viewing customer hedge server assignments and overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.CIDToHedgeServer (table)
  - FK: Customer.CustomerStatic (CID)
  - FK: Trade.HedgeServer (HedgeServerID)
  - History: History.CIDToHedgeServerMapping (XML snapshots of prior states)
  - Legacy: Internal.GetCustomerToHedgeServer (old XML-based mapping in Maintenance.Feature FeatureID=9)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target - validates CID references a real customer |
| Trade.HedgeServer | Table | FK target - validates HedgeServerID is a real hedge server |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge routing application | External service | Reads for per-customer routing override decisions |
| History.CIDToHedgeServerMapping | Table | Related companion: stores XML snapshot history of prior mapping states |
| Internal.GetCustomerToHedgeServer | Procedure | Legacy alternative: reads CID->HedgeServer mapping from XML config (Maintenance.Feature FeatureID=9) - predecessor approach |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeCIDToHedgeServer | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeCIDToHedgeServer | PRIMARY KEY | CID - one override per customer |
| FK_HedgeCIDToHedgeServer_CID | FOREIGN KEY | CID -> Customer.CustomerStatic(CID) |
| FK_HedgeCIDToHedgeServer_HedgeServerID | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| DF_HedgeCIDToHedgeServer_Occurred | DEFAULT | Occurred = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 View all customer hedge server overrides with server details
```sql
SELECT CH.CID, HS.IPAddress + ':' + CAST(HS.Port AS varchar) AS HedgeServer,
       CH.IgnoreLimit, CH.Occurred
FROM Hedge.CIDToHedgeServer CH
JOIN Trade.HedgeServer HS ON CH.HedgeServerID = HS.HedgeServerID
ORDER BY CH.Occurred DESC;
```

### 8.2 Check if a specific customer has a routing override
```sql
SELECT CID, HedgeServerID, IgnoreLimit, Occurred
FROM Hedge.CIDToHedgeServer
WHERE CID = 3739182;
-- Returns a row -> customer is force-routed to the specified HedgeServerID
-- Returns no row -> customer uses default routing
```

### 8.3 Find all customers with limit bypass on a given server
```sql
SELECT CH.CID, CH.HedgeServerID, CH.Occurred
FROM Hedge.CIDToHedgeServer CH
WHERE CH.IgnoreLimit = 1
  AND CH.HedgeServerID = 1
ORDER BY CH.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Hedge.CIDToHedgeServer.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.CIDToHedgeServer | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.CIDToHedgeServer.sql*
