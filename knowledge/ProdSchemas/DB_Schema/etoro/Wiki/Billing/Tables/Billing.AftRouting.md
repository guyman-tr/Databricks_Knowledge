# Billing.AftRouting

> Temporal routing configuration table mapping (Country + CardType + Regulation + Depot) combinations for AFT (Automatic Fund Transfer) transactions, with optional provider whitelist/blacklist flags.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, CardTypeID, RegulationID, DepotID) - composite clustered PK |
| **Partition** | No (DICTIONARY filegroup, PAGE compression) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.AftRouting` defines the set of payment gateway depots that are eligible to process AFT (Automatic Fund Transfer) transactions for a given combination of customer country, card type, and regulatory jurisdiction. Each row represents one approved routing path: "for customers in CountryID X, using CardTypeID Y, under RegulationID Z, depot DepotID D is an eligible AFT processor."

This table exists because AFT eligibility is not universal - different payment networks, gateways, and regulators impose constraints on which country/card/regulation combinations a given processor can handle. The routing engine queries `Billing.AftRoutingGet` to find the eligible depots for a specific card type + regulation (and optionally country), then selects the best depot from those results.

As a temporal table (SYSTEM_VERSIONING = ON), all historical changes to routing rules are automatically preserved in `History.BillingAftRouting`. This enables full audit trails of routing configuration changes without requiring manual logging. The `ValidFrom` date range (July 2023 - December 2025) shows this is an active, frequently-updated configuration. The `Trace` computed column captures connection context (hostname, app, user, SPID) for each row as it exists at read time - providing lightweight operation-level context.

---

## 2. Business Logic

### 2.1 Routing Matrix

**What**: The composite PK forms a 4-dimensional routing key selecting eligible AFT gateways.

**Columns/Parameters Involved**: `CountryID`, `CardTypeID`, `RegulationID`, `DepotID`

**Rules**:
- The routing engine queries `Billing.AftRoutingGet(@CountryID, @CardTypeID, @RegulationID)` to retrieve all eligible depots for a transaction.
- `@CountryID=NULL` is supported as a wildcard - returns ALL countries' entries for the given card/regulation.
- All 93 current rows cover only CardTypeID 1 (Visa, 82%) and 2 (Mastercard, 18%) - AFT routing is limited to card-based transactions.
- RegulationID distribution: CySEC (69%), FCA/ASIC/others (31%) - majority of AFT routes are for CySEC-regulated customers.

**Diagram**:
```
AFT Transaction Request
        |
        v
AftRoutingGet(@CountryID, @CardTypeID, @RegulationID)
        |
        v
AftRouting rows: all eligible DepotIDs for this combination
        |
        +-- IsWhitelistedProvider = true  -> preferred/forced provider
        +-- IsBlacklistedProvider = false -> explicitly excluded provider
        +-- NULL for both                 -> standard eligible provider (93% of rows)
```

### 2.2 Provider Whitelist / Blacklist Overrides

**What**: Individual routing entries can be flagged to force or exclude a specific provider.

**Columns/Parameters Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- `IsWhitelistedProvider = true` (3 rows): this depot is specifically preferred for this combination - indicates a forced routing override.
- `IsBlacklistedProvider = false` (2 rows): this depot is explicitly excluded from this combination despite appearing in the routing matrix.
- `NULL` for both (90 rows): standard eligible provider - no override applied.
- Currently no row has `IsBlacklistedProvider = true` - the blacklist flag is implemented but unused.

### 2.3 Temporal History

**What**: All routing rule changes are tracked automatically via SQL Server temporal tables.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidFrom` / `ValidTo` are generated automatically by SQL Server (GENERATED ALWAYS AS ROW START/END).
- Current rows have `ValidTo = 9999-12-31` (open-ended, currently active).
- Historical versions stored in `History.BillingAftRouting` with non-infinite ValidTo.
- Date range: July 2023 (earliest entry) to December 2025 (most recent change).

---

## 3. Data Overview

| CountryID | CardTypeID | RegulationID | DepotID | IsWhitelistedProvider | IsBlacklistedProvider | Meaning |
|-----------|-----------|-------------|---------|----------------------|----------------------|---------|
| 12 | 1 (Visa) | 4 (ASIC) | 87 | NULL | NULL | Standard AFT routing: Depot 87 is an eligible Visa AFT processor for Australia (ASIC-regulated). |
| 12 | 1 (Visa) | 4 (ASIC) | 92 | NULL | NULL | Second eligible Visa AFT depot for the same country/regulation - routing engine can choose between 87 and 92. |
| 12 | 1 (Visa) | 4 (ASIC) | 114 | NULL | NULL | Third eligible Visa AFT depot for Australia/ASIC - added March 2024, showing active expansion of routing options. |
| 12 | 1 (Visa) | 10 (ASIC & GAML) | 87 | NULL | NULL | Same Depot 87 also eligible for the combined ASIC+GAML regulatory overlay. |
| 12 | 1 (Visa) | 1 (CySEC) | 92 | NULL | NULL | CySEC-regulated customers in CountryID 12 can also use Depot 92 for Visa AFT transactions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate sequential identifier. NOT the primary key - included for convenience reference (e.g., admin UI row identification). The real routing key is the composite PK (CountryID, CardTypeID, RegulationID, DepotID). |
| 2 | CountryID | int | NO | - | CODE-BACKED | Country of the customer initiating the AFT transaction. Part of the composite PK. Implicit FK to Dictionary.Country. Combined with CardTypeID and RegulationID to identify the applicable routing set. Used as an optional filter in AftRoutingGet (@CountryID=NULL means all countries). |
| 3 | CardTypeID | int | NO | - | CODE-BACKED | Credit/debit card network type. Part of the composite PK. All current rows: 1=Visa (82%), 2=MasterCard (18%). FK to Dictionary.CardType. Determines which card network's AFT routing rules apply. |
| 4 | RegulationID | int | NO | - | CODE-BACKED | Regulatory jurisdiction governing the customer's account. Part of the composite PK. Current values: 1=CySEC (69%), 2=FCA (5%), 4=ASIC (5%), 9=FSA Seychelles (3%), 10=ASIC & GAML (5%). FK to Dictionary.Regulation. Determines jurisdiction-specific AFT gateway eligibility. |
| 5 | DepotID | int | NO | - | CODE-BACKED | The payment gateway depot eligible for AFT processing for this country/card/regulation combination. Part of the composite PK. FK to Billing.Depot. Multiple DepotIDs per (CountryID, CardTypeID, RegulationID) tuple represent alternative eligible gateways. |
| 6 | Trace | computed | NO | - | CODE-BACKED | Audit context column, computed at read time. JSON string capturing: HostName (server running the query), AppName (application name), SUserName (SQL login), SPID (session ID), DBName, ObjectName (stored procedure if any). Format: `{"HostName": "...", "AppName": "...", ...}`. Not stored persistently - recalculated every SELECT. Used to identify which application/process is reading routing data. |
| 7 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | Timestamp when this routing rule became effective. Auto-managed by SQL Server temporal system. Populated on INSERT and each UPDATE. Earliest value: 2023-07-25 (table creation). Read-only - cannot be set by application code. |
| 8 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | Timestamp when this routing rule was superseded. Auto-managed by SQL Server temporal system. Active rows: 9999-12-31 (open-ended). On UPDATE/DELETE, SQL Server sets this to the change timestamp and moves the row to History.BillingAftRouting. Read-only. |
| 9 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | Whether this depot is explicitly preferred (forced) for this routing combination: true=whitelisted/forced, NULL=standard eligible. Only 3 rows have true - used for priority routing overrides. No false values currently exist. |
| 10 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | Whether this depot is explicitly excluded from this routing combination despite being listed: false=explicitly excluded, NULL=standard eligible. Only 2 rows have false - used for suppression overrides. No true values currently exist (bit semantics: true would mean "is blacklisted"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Customer's country. No explicit FK constraint. |
| CardTypeID | Dictionary.CardType | Implicit FK | Card network (1=Visa, 2=MasterCard). All values verified against Dictionary.CardType. |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction (1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC & GAML). |
| DepotID | Billing.Depot | Implicit FK | The eligible payment gateway for this routing combination. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AftRoutingGet | @CountryID, @CardTypeID, @RegulationID | READER | Returns all eligible DepotIDs for a given AFT routing lookup. Primary read path. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. (Temporal history in History.BillingAftRouting is auto-managed by SQL Server.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AftRoutingGet | Stored Procedure | READER - queries eligible AFT depots by CardTypeID + RegulationID (+ optional CountryID) |
| History.BillingAftRouting | Table | SYSTEM_VERSIONING history table - receives superseded rows automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AftRouting | CLUSTERED PK | CountryID, CardTypeID, RegulationID, DepotID (all ASC) | - | - | Active |

PAGE compression applied. Stored on DICTIONARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AftRouting | PRIMARY KEY | Composite (CountryID, CardTypeID, RegulationID, DepotID) - each routing combination appears at most once |
| PERIOD FOR SYSTEM_TIME | Temporal | (ValidFrom, ValidTo) - enables automatic history tracking to History.BillingAftRouting |

---

## 8. Sample Queries

### 8.1 Get eligible AFT depots for a Visa transaction under CySEC

```sql
SELECT ID, CountryID, CardTypeID, RegulationID, DepotID, IsWhitelistedProvider, IsBlacklistedProvider
FROM [Billing].[AftRouting] WITH (NOLOCK)
WHERE CardTypeID = 1     -- Visa
  AND RegulationID = 1   -- CySEC
ORDER BY CountryID, DepotID;
```

### 8.2 Find all whitelisted (forced) provider entries

```sql
SELECT ar.CountryID, ar.CardTypeID, ar.RegulationID, ar.DepotID,
       d.Name AS DepotName, ar.IsWhitelistedProvider, ar.ValidFrom
FROM [Billing].[AftRouting] ar WITH (NOLOCK)
INNER JOIN [Billing].[Depot] d WITH (NOLOCK) ON ar.DepotID = d.DepotID
WHERE ar.IsWhitelistedProvider = 1
ORDER BY ar.ValidFrom;
```

### 8.3 View routing history for a specific combination

```sql
SELECT CountryID, CardTypeID, RegulationID, DepotID, ValidFrom, ValidTo
FROM [Billing].[AftRouting] WITH (NOLOCK)
WHERE CountryID = 12 AND CardTypeID = 1 AND RegulationID = 4
UNION ALL
SELECT CountryID, CardTypeID, RegulationID, DepotID, ValidFrom, ValidTo
FROM [History].[BillingAftRouting] WITH (NOLOCK)
WHERE CountryID = 12 AND CardTypeID = 1 AND RegulationID = 4
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian sources found for Billing.AftRouting. Related MIMO Group pages found (Routing Tool Mapping, Handover Document) but content is general payment routing context not specific to this table.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.AftRouting | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.AftRouting.sql*
