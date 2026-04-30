# History.RedeemCountrySettings

> System-versioned temporal history table automatically maintained by SQL Server to record all historical states of Billing.RedeemCountrySettings, capturing which country+player level combinations were allowed to use the Redeem feature and when those permissions changed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite (ValidTo, ValidFrom) - temporal range key |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo ASC, ValidFrom ASC) |

---

## 1. Business Meaning

This table is the **system-versioned temporal history table** for `Billing.RedeemCountrySettings`. SQL Server automatically moves rows here (with their ValidFrom/ValidTo interval stamped) whenever a row in `Billing.RedeemCountrySettings` is updated or deleted. It is not written to by application code directly.

The source table `Billing.RedeemCountrySettings` controls which (country, player level) combinations are permitted to use the eToro **Redeem** feature - the ability to withdraw realized trading equity to a wallet (including NFT redemption via `Billing.GetRedeemNFTValidationData`). Each row in this history table represents a past configuration state: a specific country+player level pair with its IsActive flag set to a particular value, valid from ValidFrom until ValidTo.

With only 2 rows in production, the Redeem country+player level configuration is extremely stable - most settings have been set once and never changed. The history table grows only when an operator updates or removes a row from the source table.

---

## 2. Business Logic

### 2.1 Temporal Period Semantics

**What**: The ValidFrom/ValidTo pair defines the closed interval during which a configuration row was current in `Billing.RedeemCountrySettings`.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidFrom`: the instant this configuration row became active in the source table (either when it was inserted or last updated)
- `ValidTo`: the instant this row was superseded - either updated to a new value or deleted from the source table
- The current (live) version of any row is in `Billing.RedeemCountrySettings`, not here
- To query historical configuration as of a specific point in time, use `FOR SYSTEM_TIME AS OF {datetime}` on the source table; SQL Server reads from this history table automatically

**Diagram**:
```
Billing.RedeemCountrySettings (current state)
      |
      | [row updated/deleted by admin/service]
      v
History.RedeemCountrySettings (past state recorded here)
      ValidFrom = when row was last created/updated
      ValidTo   = when row was updated/deleted (end of validity)
```

### 2.2 Redeem Eligibility Context

**What**: Each row represents a past eligibility decision - whether customers from a specific country at a specific player level could use the Redeem feature at a given time.

**Columns/Parameters Involved**: `CountryID`, `PlayerLevelID`, `IsActive`

**Rules**:
- `Billing.GetRedeemValidationData` checks `IsActive=1` to determine redeem eligibility at query time - it reads from `Billing.RedeemCountrySettings` (current), not this history table
- The history table enables compliance/audit: "was this country eligible for redemption on date X?"
- UNIQUE constraint on source table (CountryID, PlayerLevelID) means only one setting per country+level combination exists at any point in time

---

## 3. Data Overview

| ID | CountryID | PlayerLevelID | IsActive | Occurred | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|
| 2 | 1 | 1 | true | 2019-11-21 | 2021-09-19 | 2025-04-21 | Country 1 (first country in Dictionary.Country), Bronze-level players were permitted to redeem from Sep 2021 until Apr 2025, when this setting was updated |
| 220 | 219 | 1 | true | 2019-11-21 | 2021-09-19 | 2026-03-09 | Country 219, Bronze-level players were permitted to redeem from Sep 2021 until Mar 2026, when this setting was changed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate identifier of the original `Billing.RedeemCountrySettings` row. NOT an identity in the history table - SQL Server copies the source table's ID value here. Uniquely identifies which source row this history entry belongs to, but the same ID can appear multiple times (one per historical state). |
| 2 | CountryID | int | NO | - | VERIFIED | The country for which this redemption eligibility setting applies. FK to `Dictionary.Country`. Combined with PlayerLevelID, defines a unique eligibility rule. Example: CountryID=1 is the first registered country in the Dictionary. |
| 3 | PlayerLevelID | int | NO | - | VERIFIED | The customer loyalty tier for which this redemption eligibility setting applies. FK to `Dictionary.PlayerLevel`. Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. All levels have `IsWalletRedeemAllowed=true` in the current Dictionary.PlayerLevel data, making the IsActive flag in this table the primary gate for per-country eligibility. |
| 4 | IsActive | bit | NO | - | CODE-BACKED | Whether the Redeem feature is enabled for this country+player level combination. 1 = allowed to redeem; 0 = redemption blocked for this combination. `Billing.GetRedeemValidationData` checks `IsActive=1` to grant redemption access. `Billing.GetRedeemNFTValidationData` applies the same check for NFT-specific redemption flows. |
| 5 | Occurred | datetime | NO | - | CODE-BACKED | The timestamp when the original setting was created or last explicitly modified by a user/service (from the source table's `Occurred` column with default `getdate()`). Distinct from ValidFrom - `Occurred` is application-managed while ValidFrom is SQL Server-managed. The sample data shows Occurred = 2019-11-21 for both history rows, indicating the original settings were created in Nov 2019. |
| 6 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Computed JSON audit trail from the source table, capturing the execution context at the moment the row was modified. Contains: HostName (server name), AppName (application name, e.g., "Asi" = eToro main app), SUserName (SQL login, e.g., "BillingService_stg"), SPID (SQL Server process ID), DBName, ObjectName (stored procedure that made the change, if any). Stored as a plain string in history (not recomputed - SQL Server copies the evaluated value). |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | The point in time when this row's configuration state became active in `Billing.RedeemCountrySettings`. Automatically set by SQL Server's temporal system versioning to the time of INSERT or UPDATE on the source row. Nanosecond precision (datetime2(7)). Clustered index includes this column for efficient point-in-time range queries. |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | The point in time when this row was superseded in `Billing.RedeemCountrySettings` (by an UPDATE or DELETE). Automatically set by SQL Server to the exact moment the source row changed. The leading key of the clustered index (ValidTo ASC, ValidFrom ASC) optimizes for FOR SYSTEM_TIME range queries, which SQL Server expresses as `ValidFrom <= @AsOf AND ValidTo > @AsOf`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.RedeemCountrySettings | Temporal History | Each row is a past state of the corresponding source row; ID matches Billing.RedeemCountrySettings.ID |
| CountryID | Dictionary.Country | Implicit (FK in source) | Explicit FK on source table. Country for which redemption settings apply. |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit (FK in source) | Explicit FK on source table. Player loyalty tier: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemCountrySettings | HISTORY_TABLE | Temporal History | Source table declares this as its SYSTEM_VERSIONING history table. SQL Server routes all expired rows here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RedeemCountrySettings (table)
  (temporal history - no code-level dependencies; populated by SQL Server automatically from Billing.RedeemCountrySettings)
```

---

### 6.1 Objects This Depends On

No dependencies. This is a temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemCountrySettings | Table | Source table - SQL Server moves expired rows here when rows are updated or deleted (SYSTEM_VERSIONING = ON) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RedeemCountrySettings | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Note: No primary key on the history table. SQL Server requires the history table to have a clustered index on the temporal period columns for efficient FOR SYSTEM_TIME query execution. DATA_COMPRESSION = PAGE applied to reduce storage for historical audit data.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression applied to both the table and its clustered index, reducing storage for this archival table. |

---

## 8. Sample Queries

### 8.1 View all historical configuration changes
```sql
SELECT
    ID,
    CountryID,
    PlayerLevelID,
    IsActive,
    Occurred,
    ValidFrom,
    ValidTo,
    ValidTo - ValidFrom AS Duration,
    JSON_VALUE(Trace, '$.SUserName') AS ChangedBy,
    JSON_VALUE(Trace, '$.AppName') AS ChangedByApp
FROM [History].[RedeemCountrySettings] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

### 8.2 Check redemption eligibility for a country+level as of a past date
```sql
-- Use temporal query on source table (SQL Server reads History table automatically)
SELECT ID, CountryID, PlayerLevelID, IsActive
FROM [Billing].[RedeemCountrySettings]
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00'
WHERE CountryID = @CountryID
  AND PlayerLevelID = @PlayerLevelID
```

### 8.3 Full history for a specific country setting with human-readable lookups
```sql
SELECT
    h.ID,
    dc.Name AS CountryName,
    dp.Name AS PlayerLevel,
    h.IsActive,
    h.Occurred,
    h.ValidFrom,
    h.ValidTo,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM [History].[RedeemCountrySettings] h WITH (NOLOCK)
JOIN [Dictionary].[Country] dc WITH (NOLOCK) ON dc.CountryID = h.CountryID
JOIN [Dictionary].[PlayerLevel] dp WITH (NOLOCK) ON dp.PlayerLevelID = h.PlayerLevelID
WHERE h.CountryID = @CountryID
ORDER BY h.ValidFrom ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [RD-20096 - Upsert Script - SQL Script to Configure Ideal](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1054244895/RD-20096+-+Upsert+Script+-+SQL+Script+to+Configure+Ideal+-+Stored+Procedures) | Confluence | Old (May 2020) configuration script page mentioning RedeemCountrySettings; predates current temporal implementation; low confidence - not incorporated. |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RedeemCountrySettings | Type: Table | Source: etoro/etoro/History/Tables/History.RedeemCountrySettings.sql*
