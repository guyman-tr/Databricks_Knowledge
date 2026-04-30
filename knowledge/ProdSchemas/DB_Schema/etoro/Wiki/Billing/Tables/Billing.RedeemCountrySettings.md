# Billing.RedeemCountrySettings

> Per-country, per-player-level configuration controlling whether cryptocurrency redemption is permitted for users in a given country, with full temporal history tracking via system-versioning.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 (PK + 1 UNIQUE NCI) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON -> History.RedeemCountrySettings |

---

## 1. Business Meaning

Billing.RedeemCountrySettings is the country-level availability gate for the crypto redemption feature. Each row defines whether a specific player level in a specific country is allowed to redeem their crypto positions. Before a redemption can proceed, the validation layer checks this table to confirm that redemptions are enabled for the user's country and player level combination.

The table is populated at the country granularity (one row per country per player level combination) and controls which countries are active for redemption. In practice, all current rows use PlayerLevelID=1 (Bronze/standard), meaning the configuration is country-wide rather than tier-specific. Countries that are inactive (IsActive=0) have redemption blocked regardless of the user's portfolio size or eligibility.

Data is system-versioned (temporal), meaning every change to a country's active/inactive setting is preserved in History.RedeemCountrySettings. This supports regulatory audit trails: if a country was enabled then disabled, the full history of when that occurred is captured. The Trace computed column embeds the database session context (hostname, app name, user, SPID) into each write for operational diagnostics.

Current state (2026-03-17): 251 rows across 251 countries. 245 active, 6 inactive (Afghanistan, Austria, Belgium, Denmark, Norway, United States).

---

## 2. Business Logic

### 2.1 Redemption Country Gate

**What**: Controls which countries have crypto redemption enabled. Used as a prerequisite check before a user can initiate a redemption.

**Columns/Parameters Involved**: `CountryID`, `PlayerLevelID`, `IsActive`

**Rules**:
- A row with IsActive=1 means users from that country at that player level CAN submit redemptions
- A row with IsActive=0 means redemption is BLOCKED for that country/level - validation returns an error
- The unique constraint on (CountryID, PlayerLevelID) enforces exactly one configuration per country-level pair
- If no row exists for a country+level, the validation logic treats it as not permitted (no row = blocked)
- All current rows use PlayerLevelID=1 (Bronze). Higher tiers would need separate rows to have different settings.

**Diagram**:
```
User submits redemption
        |
        v
GetRedeemValidationData(@CustomerID, @InstrumentID)
        |
        v
JOIN Billing.RedeemCountrySettings
  ON CountryID = user's country AND PlayerLevelID = user's level
        |
        +-- IsActive=1 -> Validation passes (country permitted)
        +-- IsActive=0 -> Validation fails (country blocked)
        +-- No row    -> Validation fails (not configured)
```

### 2.2 Temporal History - Configuration Change Audit

**What**: Every INSERT or UPDATE to a country setting is automatically preserved in History.RedeemCountrySettings via SQL Server system-versioning.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, temporal system

**Rules**:
- ValidFrom: UTC datetime2 when the row became current (set automatically by SQL Server on INSERT/UPDATE)
- ValidTo: UTC datetime2 when the row stopped being current (9999-12-31 for current rows)
- When a row is updated (e.g., IsActive flipped from 1 to 0), the old version moves to History with ValidTo set to the moment of change
- Historical queries: `SELECT * FROM Billing.RedeemCountrySettings FOR SYSTEM_TIME AS OF '2025-01-01'`
- This captures full regulatory history: when countries were enabled/disabled

---

## 3. Data Overview

| CountryID | Country | PlayerLevelID | IsActive | Meaning |
|-----------|---------|---------------|----------|---------|
| (most countries) | Active markets | 1 (Bronze) | 1 | Redemption enabled for all standard users in this country |
| Afghanistan | AF | 1 | 0 | Redemption blocked - likely sanctions/regulatory restriction |
| Austria | AT | 1 | 0 | Redemption blocked - regulatory restriction |
| Belgium | BE | 1 | 0 | Redemption blocked - regulatory restriction |
| Denmark | DK | 1 | 0 | Redemption blocked - regulatory restriction |
| Norway | NO | 1 | 0 | Redemption blocked - regulatory restriction |
| United States | US | 1 | 0 | Redemption blocked - regulatory restriction (US crypto rules) |

Note: All 251 rows use PlayerLevelID=1 (Bronze). The design supports per-tier configuration but current data is single-tier.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Used as the clustered PK for the temporal table. Not a business key - (CountryID, PlayerLevelID) is the functional uniqueness key. |
| 2 | CountryID | INT | NO | - | CODE-BACKED | FK to Dictionary.Country(CountryID). Identifies the country for which this redemption availability setting applies. The UNIQUE constraint on (CountryID, PlayerLevelID) enforces one row per country-level pair. |
| 3 | PlayerLevelID | INT | NO | - | CODE-BACKED | FK to Dictionary.PlayerLevel(PlayerLevelID). Player tier for this setting: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. All current rows = 1 (Bronze), meaning the config is effectively country-wide for all tiers. |
| 4 | IsActive | BIT | NO | 1 | CODE-BACKED | Whether crypto redemption is currently enabled for this country/level combination. 1=Active (redemption allowed), 0=Inactive (redemption blocked). Default=1 (active when inserted). 245 of 251 rows are active. |
| 5 | Occurred | DATETIME | NO | getdate() | CODE-BACKED | Local server datetime when the row was inserted or last modified (application-set, not UTC). Defaults to getdate() on INSERT. Not auto-updated on UPDATE - reflects insertion time unless explicitly set by the calling application. |
| 6 | Trace | (computed) | YES | - | CODE-BACKED | Computed column emitting JSON with connection context: `{"HostName": "...","AppName": "...","SUserName": "...","SPID": "...","DBName": "...","ObjectName": "..."}`. Populated automatically from SQL Server built-in functions (host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid)). Used for operational diagnostics - identifies which application and session wrote the row. Not persisted (computed on read). |
| 7 | ValidFrom | DATETIME2(7) | NO | (system) | CODE-BACKED | Temporal row start - UTC timestamp when this version of the row became current. Set automatically by SQL Server on INSERT/UPDATE. Used for AS OF queries to see historical state. |
| 8 | ValidTo | DATETIME2(7) | NO | (system) | CODE-BACKED | Temporal row end - UTC timestamp when this version expired. 9999-12-31 for all current rows. Set automatically by SQL Server when a row is updated or deleted (moved to History.RedeemCountrySettings). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | FK (FK_BillingRedeemCountrySettings_DictionaryCountry_TPL) | Country identity. Links each setting row to the country whose residents are subject to the configuration. |
| PlayerLevelID | Dictionary.PlayerLevel | FK (FK_BillingRedeemCountrySettings_TPL_DictionaryPlayerLevel) | Player tier. Allows configuring redemption availability differently per VIP tier. All current rows use level 1 (Bronze). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRedeemValidationData | CountryID, PlayerLevelID | READER | Core redemption validation procedure - checks IsActive for the user's country and player level before allowing a redemption |
| Billing.GetRedeemNFTValidationData | CountryID, PlayerLevelID | READER | NFT redemption variant of the validation check - same country gate logic |
| History.RedeemCountrySettings | - | TEMPORAL HISTORY | System-versioned history table - receives old row versions on every UPDATE to allow point-in-time queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemCountrySettings (table)
├── Dictionary.Country (table) [FK: CountryID]
└── Dictionary.PlayerLevel (table) [FK: PlayerLevelID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK constraint - CountryID must exist in Dictionary.Country |
| Dictionary.PlayerLevel | Table | FK constraint - PlayerLevelID must exist in Dictionary.PlayerLevel |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRedeemValidationData | Stored Procedure | READER - country/level availability gate check |
| Billing.GetRedeemNFTValidationData | Stored Procedure | READER - NFT redemption country gate check |
| History.RedeemCountrySettings | History Table | TEMPORAL - receives superseded row versions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing.RedeemCountrySettings_TPL | CLUSTERED PK | ID ASC | - | - | Active |
| UQ_CountryID_PlayerLevelID_TPL | NONCLUSTERED UNIQUE | CountryID ASC, PlayerLevelID ASC | - | - | Active |

Index options: FILLFACTOR=95, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing.RedeemCountrySettings_TPL | PRIMARY KEY CLUSTERED | ID must be unique |
| UQ_CountryID_PlayerLevelID_TPL | UNIQUE NONCLUSTERED | (CountryID, PlayerLevelID) must be unique - one config per country-level pair |
| FK_BillingRedeemCountrySettings_DictionaryCountry_TPL | FOREIGN KEY | CountryID must exist in Dictionary.Country |
| FK_BillingRedeemCountrySettings_TPL_DictionaryPlayerLevel | FOREIGN KEY | PlayerLevelID must exist in Dictionary.PlayerLevel |
| DF_BillingRedeemCountrySettings_TPL_IsActive | DEFAULT | IsActive defaults to 1 (active) on INSERT |
| DF_BillingRedeemCountrySettings_TPL_Occurred | DEFAULT | Occurred defaults to getdate() on INSERT |

### 7.3 Temporal Configuration

| Property | Value |
|----------|-------|
| System Versioning | ON |
| History Table | History.RedeemCountrySettings |
| Period Start | ValidFrom (DATETIME2(7)) |
| Period End | ValidTo (DATETIME2(7)) |
| Point-in-time queries | `FOR SYSTEM_TIME AS OF '{datetime}'` |

---

## 8. Sample Queries

### 8.1 Get all countries with redemption status

```sql
SELECT
    rcs.ID,
    rcs.CountryID,
    c.Name AS CountryName,
    pl.Name AS PlayerLevelName,
    rcs.IsActive,
    rcs.Occurred,
    rcs.ValidFrom,
    rcs.ValidTo
FROM [Billing].[RedeemCountrySettings] rcs WITH (NOLOCK)
INNER JOIN [Dictionary].[Country] c WITH (NOLOCK) ON c.CountryID = rcs.CountryID
INNER JOIN [Dictionary].[PlayerLevel] pl WITH (NOLOCK) ON pl.PlayerLevelID = rcs.PlayerLevelID
ORDER BY rcs.IsActive DESC, c.Name
```

### 8.2 Find blocked countries

```sql
SELECT
    rcs.CountryID,
    c.Name AS CountryName,
    rcs.PlayerLevelID,
    rcs.IsActive,
    rcs.Occurred
FROM [Billing].[RedeemCountrySettings] rcs WITH (NOLOCK)
INNER JOIN [Dictionary].[Country] c WITH (NOLOCK) ON c.CountryID = rcs.CountryID
WHERE rcs.IsActive = 0
ORDER BY c.Name
```

### 8.3 View historical state of a country's redemption setting

```sql
-- See what the setting was for United States on a specific date
SELECT
    rcs.CountryID,
    rcs.IsActive,
    rcs.ValidFrom,
    rcs.ValidTo
FROM [Billing].[RedeemCountrySettings]
FOR SYSTEM_TIME ALL
WHERE rcs.CountryID = (SELECT CountryID FROM Dictionary.Country WHERE Name = 'United States')
ORDER BY rcs.ValidFrom
```

### 8.4 Check if a specific country/level is eligible for redemption

```sql
DECLARE @CountryID INT = 100  -- e.g., Israel
DECLARE @PlayerLevelID INT = 1  -- Bronze

SELECT
    CASE WHEN COUNT(*) > 0 AND MAX(CAST(IsActive AS INT)) = 1
         THEN 'Redemption Allowed'
         ELSE 'Redemption Blocked'
    END AS RedemptionStatus
FROM [Billing].[RedeemCountrySettings] WITH (NOLOCK)
WHERE CountryID = @CountryID
  AND PlayerLevelID = @PlayerLevelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table. The table is referenced indirectly through the redemption validation flow described in the parent Billing.Redeem documentation.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.4/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RedeemCountrySettings | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RedeemCountrySettings.sql*
