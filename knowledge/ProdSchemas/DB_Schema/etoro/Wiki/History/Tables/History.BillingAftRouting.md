# History.BillingAftRouting

> SQL Server temporal history table for Billing.AftRouting: records all past states of payment depot routing rules for card transactions by country, card type, regulation, and depot, with provider whitelist/blacklist flags. Automatically maintained by SYSTEM_VERSIONING.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, CardTypeID, RegulationID, DepotID) - no PK constraint |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.BillingAftRouting is the SQL Server temporal system-versioning history table for `Billing.AftRouting`. It automatically captures every state change (INSERT, UPDATE, DELETE) to the AFT payment routing configuration, preserving the complete history of depot routing rule changes with precise UTC timestamps.

`Billing.AftRouting` defines routing rules that determine which payment depot processes card transactions for a given combination of customer country, card type, regulation, and depot. This is a configuration table for the payment routing engine - when a customer initiates a card deposit or withdrawal, the billing system uses these rules to select the appropriate payment processing depot.

**AFT context**: The table appears focused on Visa card routing (CardTypeID=1 is the only card type in both live and historical data). "AFT" likely refers to a specific card payment processing flow or routing mechanism within eToro's billing infrastructure.

**IsWhitelistedProvider / IsBlacklistedProvider**: Optional bit flags indicating whether this routing configuration designates the depot as a whitelisted or blacklisted provider for the given country/regulation/card combination. These allow the routing engine to include or exclude specific providers dynamically.

**Scale**: 99 history rows (July 2023 to January 2025). Live table has 93 rows. The small delta (99 history vs. 93 live) indicates modest configuration changes since temporal versioning was enabled. 34 distinct countries, 6 regulations, 3 depots configured.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any INSERT, UPDATE, or DELETE to Billing.AftRouting.

**Rules**:
- INSERT into source: row becomes active at SysStartTime=NOW (ValidFrom); no immediate history row
- UPDATE to source: old row moved to history with ValidTo=NOW; new row active with ValidFrom=NOW
- DELETE from source: deleted row moved to history with ValidTo=NOW
- History rows are immutable once written
- ValidFrom/ValidTo use UTC (datetime2(7))
- No stored procedures found that explicitly write to Billing.AftRouting - configuration is applied directly (DBA/admin tool)

### 2.2 Routing Rule Composition

**What**: Each routing rule is defined by a 4-part composite key.

**Rules**:
- PK in source: (CountryID, CardTypeID, RegulationID, DepotID)
- Each combination defines routing for a specific country + card type + regulatory jurisdiction + payment depot
- Current data: all rules are CardTypeID=1 (Visa) - the table may be specifically for Visa AFT routing
- DepotID 92, 87, and 114 are the three active depots
- RegulationID 1 (CySEC?) has the highest history volume (90/99 rows across 3 depots)
- IsWhitelistedProvider=NULL (not specified) is the default; IsWhitelistedProvider=1 explicitly marks a provider as trusted for the route

### 2.3 Depot Distribution

| DepotID | History Rows | Notes |
|---------|-------------|-------|
| 92 | ~32 | Most common depot |
| 87 | ~34 | Operations depot |
| 114 | ~33 | Third depot |

---

## 3. Data Overview

99 history rows, July 2023 to January 2025. 93 live rows. Only Visa card type (CardTypeID=1) in all rows. 34 distinct countries, 6 regulations, 3 depots.

| ID | CountryID | CardTypeID | RegulationID | DepotID | IsWhitelisted | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 218 | 1 (Visa) | 2 | 92 | 1 | 2023-09-26 | 9999-12-31 (live) | CountryID=218 Visa Regulation=2 routed to Depot=92, whitelisted provider |
| (history) | (any) | 1 | 1 | 87 | NULL | 2023-07-09 | 2025-01-16 | Previous routing config for RegulationID=1 to Depot=87 before the January 2025 change |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Row identifier carried from Billing.AftRouting IDENTITY column. Not a PK in the history table (temporal history tables have no PK constraint). In the source, ID is IDENTITY(1,1) but the business key is the composite (CountryID, CardTypeID, RegulationID, DepotID). |
| 2 | CountryID | int | NO | - | CODE-BACKED | Customer's country. Part of the routing rule composite key. 34 distinct values in history. References Dictionary.Country (soft reference, no FK on history table). |
| 3 | CardTypeID | int | NO | - | CODE-BACKED | Payment card type. Part of composite key. Only CardTypeID=1 (Visa) appears in all current data. Other card types may be supported in source schema but are not yet configured. |
| 4 | RegulationID | int | NO | - | CODE-BACKED | Regulatory jurisdiction governing the routing. Part of composite key. 6 distinct values in history (1, 2, 4, 7, 8, 10, 11). RegulationID=1 (likely CySEC/EU regulation) has 90 of 99 history rows. |
| 5 | DepotID | int | NO | - | CODE-BACKED | Payment processing depot (payment provider/acquirer). Part of composite key. 3 distinct values: 87, 92, 114. This is the target payment processor for the given country/card/regulation combination. |
| 6 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON connection context captured at DML time via computed column. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Identifies who changed the routing configuration. Computed in source (concat of host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid)); stored as data in history snapshot. |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this routing rule became active. Set by SQL Server temporal system (GENERATED ALWAYS AS ROW START in source). |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this routing rule was superseded. Set by SQL Server temporal system (GENERATED ALWAYS AS ROW END in source). Clustered index leading key. ValidTo=9999-12-31T23:59:59.999 in live rows (replicated from source defaults). |
| 9 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | When 1, this routing configuration designates the depot as an explicitly whitelisted (trusted) provider for the given route. NULL indicates no explicit whitelist designation. |
| 10 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | When 1, this routing configuration designates the depot as explicitly blacklisted (excluded) for the given route. NULL indicates no blacklist designation. No rows with IsBlacklistedProvider=1 in current history data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table. Source table Billing.AftRouting has composite PK (CountryID, CardTypeID, RegulationID, DepotID) and implicit references to Dictionary.Country, Dictionary.CardType, Dictionary.Regulation, and billing depot configuration.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically when Billing.AftRouting is modified. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingAftRouting (temporal history table)
  - automatically maintained by: Billing.AftRouting (source table)
```

### 6.1 Objects This Depends On

None. Temporal history tables have no code-level dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Writes historical rows from Billing.AftRouting changes automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingAftRouting | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Standard temporal history clustering on (ValidTo, ValidFrom). Stored on DICTIONARY filegroup. PAGE compression applied.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. |

---

## 8. Sample Queries

### 8.1 History of routing changes for a specific country/regulation
```sql
SELECT
    h.ID,
    h.CountryID,
    h.DepotID,
    h.IsWhitelistedProvider,
    h.IsBlacklistedProvider,
    h.Trace,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(DAY, h.ValidFrom, h.ValidTo) AS ActiveDays
FROM History.BillingAftRouting h WITH (NOLOCK)
WHERE h.CountryID = @CountryID
  AND h.RegulationID = @RegulationID
ORDER BY h.ValidFrom ASC;
```

### 8.2 Point-in-time routing configuration (temporal syntax)
```sql
-- What routing rules were active on a specific date?
SELECT *
FROM Billing.AftRouting
FOR SYSTEM_TIME AS OF '2024-06-01T00:00:00';
```

### 8.3 All routing changes made by a specific user
```sql
SELECT
    ID, CountryID, CardTypeID, RegulationID, DepotID,
    JSON_VALUE(Trace, '$.SUserName') AS ChangedBy,
    JSON_VALUE(Trace, '$.AppName') AS Application,
    ValidFrom,
    ValidTo
FROM History.BillingAftRouting WITH (NOLOCK)
WHERE JSON_VALUE(Trace, '$.SUserName') = @UserName
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

Related Confluence page found: "Depot routing migration" (Confluence 12146999387) - likely documents the migration of depot routing configuration that generated these changes.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingAftRouting | Type: Table | Source: etoro/etoro/History/Tables/History.BillingAftRouting.sql*
