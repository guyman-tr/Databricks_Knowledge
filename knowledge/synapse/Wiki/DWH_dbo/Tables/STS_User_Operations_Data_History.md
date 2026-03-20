# DWH_dbo.STS_User_Operations_Data_History

> Historical log of every STS (Security Token Service) authentication and session event — logins, logouts, token exchanges, and re-authentications — capturing client device, IP, application, and session identifiers for each customer interaction.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact-like History) |
| **Row Count** | Billions (daily partitioned, data from 2021-08 onward) |
| **Production Source** | `STS_Audit.StsAudit.UserOperations` (via `DWH_staging.STS_Audit_UserOperationsData`) |
| **Refresh** | Daily append (midnight ETL via partition SWITCH) |
| | |
| **Synapse Distribution** | HASH(Gcid) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Synapse Partitioning** | RANGE LEFT on DateID — per-day partitions from 2022-01-01 through 2026-02-28 |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history` |
| **UC Format** | Parquet |
| **Generic Pipeline** | ID 459, SynapseSourceWithoutSecret, daily Append |

---

## 1. Business Meaning

`DWH_dbo.STS_User_Operations_Data_History` is the authoritative session-level audit trail for eToro's Security Token Service (STS). Every time a user logs in, authenticates, exchanges a token, or logs out — on web, iOS, or Android — a row is recorded here. The table answers: "When did this customer access the platform, from where, and using which device/app?"

The STS service handles all authentication CRUD operations for eToro users. This DWH table captures the historical record of those events, enabling analysis of:
- **Login frequency and patterns** — how often users access the platform
- **Device/platform distribution** — mobile app vs. web, iOS vs. Android
- **Session lineage** — parent-to-child session chains via ParentSessionId
- **Geographic access patterns** — via ClientIp (CountryISOCode and ProxyType available but sparsely populated)
- **Security auditing** — hashed access tokens, device IDs, user agents

The table is loaded as a subsection of `SP_Fact_CustomerAction_DL_To_Synapse` — the same mega-SP that populates `Fact_CustomerAction`. STS data is appended daily via the partition SWITCH pattern (no deletes, no updates).

---

## 2. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Gcid | int | YES | Global Customer ID — unique cross-platform identifier linking Real and Demo accounts for the same person. Distribution key. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 2 | RealCid | int | YES | Real-money account Customer ID. NULL when the session is Demo-only. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 3 | DemoCid | int | YES | Virtual/demo account Customer ID. NULL when the session is Real-only. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 4 | ApplicationIdentifier | nvarchar(100) | YES | Client application that initiated the session. Known values: `retoro` (web/generic), `retoroios` (iOS app), `retoroandroid` (Android app). (Tier 2 — STS_Audit_UserOperationsData) |
| 5 | ApplicationVersion | nvarchar(20) | YES | Build version of the client application, e.g. `340.0.10`, `355.0.1`. (Tier 2 — STS_Audit_UserOperationsData) |
| 6 | ClientIp | varchar(20) | YES | IPv4 address of the client at the time of the session event. (Tier 2 — STS_Audit_UserOperationsData) |
| 7 | ClientName | nvarchar(100) | YES | Server-side service name that processed the authentication request. Consistently `STS.WebAPI` across all observed data. (Tier 2 — STS_Audit_UserOperationsData) |
| 8 | CreatedAt | datetime | YES | Timestamp when the authentication/session event occurred in the STS service. This is the business event time (not the ETL load time). (Tier 2 — STS_Audit_UserOperationsData) |
| 9 | UserAgent | nvarchar(512) | YES | Full HTTP User-Agent string from the client browser or mobile WebView. Contains OS, browser, and app metadata. May be NULL for some mobile token exchanges. (Tier 2 — STS_Audit_UserOperationsData) |
| 10 | AccessTokenHashed | nvarchar(256) | YES | Hashed authentication access token for security audit trail. Not reversible. Sparsely populated. (Tier 2 — STS_Audit_UserOperationsData) |
| 11 | ClientDeviceId | nvarchar(50) | YES | UUID-format device identifier (e.g. `3c24d4e9-8ef0-405f-...`). Populated primarily for mobile app sessions; typically NULL or empty for web. (Tier 2 — STS_Audit_UserOperationsData) |
| 12 | ParentSessionId | bigint | YES | Session ID of the parent session for linked/chained sessions. Value `0` indicates a root session (no parent). Enables session chain tracing. (Tier 2 — STS_Audit_UserOperationsData) |
| 13 | AccountTypeName | varchar(100) | YES | Account context for the session: `Real` (live trading) or `Demo` (virtual portfolio). (Tier 2 — STS_Audit_UserOperationsData) |
| 14 | LoginTypeName | varchar(100) | YES | Type of authentication event. Known values: `Login` (new session), `Authenticate` (credential re-validation), `TokenExchange` (token refresh), `Logout` (session end). (Tier 2 — STS_Audit_UserOperationsData) |
| 15 | SessionId | bigint | YES | Unique session identifier assigned by the STS service. Monotonically increasing. (Tier 2 — STS_Audit_UserOperationsData) |
| 16 | GatewayAppId | int | YES | Identifier of the API gateway application that routed the request. Commonly `1` or `2`. NULL for some Logout events. (Tier 2 — STS_Audit_UserOperationsData) |
| 17 | DateID | int | YES | Date partition key in YYYYMMDD integer format (e.g. `20210901`). Computed in ETL from the `@Yesterday` parameter: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))`. Clustered index and partition column. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 18 | UpdateDate | datetime | YES | Timestamp when this row was loaded into the DWH, set to `GETDATE()` during ETL execution. Not the business event time. (Tier 2 — SP_Fact_CustomerAction_DL_To_Synapse) |
| 19 | ProxyType | nvarchar(max) | YES | Type of proxy detected for the client IP connection (e.g. VPN, TOR). Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 3 — data sampling inference) |
| 20 | CountryISOCode | nvarchar(max) | YES | ISO country code resolved from the ClientIp address. Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 3 — data sampling inference) |
| 21 | AdditionalData | nvarchar(max) | YES | Extensible JSON or free-text field for additional session metadata. Sparsely populated. (Tier 3 — data sampling inference) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Customer | Gcid = Gcid (or RealCid/DemoCid) | Customer who initiated the session | Outbound FK (implicit) |
| DWH_dbo.Dim_Date | DateID = DateID | Calendar date of the session event | Outbound FK (implicit) |
| DWH_dbo.Fact_CustomerAction | Same SP populates both; Gcid+DateID linkage for login-type ActionTypeIDs | Sibling in the same ETL pipeline | Co-populated |
| DWH_dbo.Vw_STS_User_Operations_Data_History | Direct 1:1 view wrapper | Presentation layer | View |

---

## 4. ETL & Data Pipeline

### Load Pattern: Daily Append via Partition SWITCH

```
SP_Fact_CustomerAction_DL_To_Synapse(@dt)
  │
  ├─ [Step 1] EXEC SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE @dt
  │    → Drops and recreates _SWITCH_SINGLE and _SWITCH tables
  │    → Creates matching HASH(Gcid), CI(DateID) with 3-day partition range
  │
  ├─ [Step 2] INSERT INTO STS_User_Operations_Data_History_SWITCH_SINGLE
  │    SELECT * FROM DWH_staging.STS_Audit_UserOperationsData
  │    WHERE CreatedAt >= @Yesterday AND CreatedAt < @CurrentDate
  │    + DateID computed from @Yesterday
  │    + UpdateDate = GETDATE()
  │
  └─ [Step 3] EXEC SP_STS_User_Operations_Data_History_SWITCH
       → Determines partition number for @CurrentDay
       → SWITCH existing partition data OUT to _SWITCH (shadow table)
       → SWITCH new data IN from _SWITCH_SINGLE (WITH TRUNCATE_TARGET = ON)
       → TRUNCATE _SWITCH shadow table
```

### Source Chain

```
STS_Audit.StsAudit.UserOperations (production)
  → Generic Pipeline (Bronze, daily Append)
  → DWH_staging.STS_Audit_UserOperationsData (Synapse staging)
  → SP_Fact_CustomerAction_DL_To_Synapse (daily ETL)
  → STS_User_Operations_Data_History_SWITCH_SINGLE (temp)
  → SP_STS_User_Operations_Data_History_SWITCH (partition swap)
  → DWH_dbo.STS_User_Operations_Data_History (final)
  → Generic Pipeline ID 459 (Gold, daily Append, parquet)
  → dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history (UC)
```

### Column Transformations

| Target Column | Source Expression | Notes |
|---------------|-------------------|-------|
| DateID | `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))` | Computed from SP parameter, not from source data |
| UpdateDate | `GETDATE()` | ETL load timestamp |
| All other columns | Direct pass-through | No transformation from STS_Audit_UserOperationsData |

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| DWH_dbo.Vw_STS_User_Operations_Data_History | Trivial wrapper view — `SELECT *` with `CAST(ClientDeviceId AS NVARCHAR(MAX))` to widen the column type |
| SP_Fact_CustomerAction_DL_To_Synapse | Writer SP (daily ETL) |
| SP_STS_User_Operations_Data_History_SWITCH | Partition swap SP |
| SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE | SWITCH table creator SP |

---

## 6. Business Logic & Patterns

### Key Patterns

- **Append-only history**: No deletes or updates after initial load. The commented-out DELETE confirms this was a design decision (old delete-then-insert replaced by SWITCH pattern).
- **Partition SWITCH for performance**: Daily data is loaded via a temp table with matching schema, then swapped in atomically — avoids row-by-row INSERT overhead on a massive partitioned table.
- **Session lifecycle tracking**: A single user action (e.g. opening the app) generates multiple events — `Login` → `TokenExchange` → ... → `Logout`. Sessions can be chained via `ParentSessionId`.
- **Sparse late columns**: `ProxyType`, `CountryISOCode`, and `AdditionalData` are `NVARCHAR(MAX)` and mostly NULL in older data — likely added after the table was created (Jira DSM-598: "STS - add 3 new fields").

### Data Quality Notes

- **ParentSessionId = 0**: Indicates a root session (most Authenticate events have ParentSessionId = 0)
- **GatewayAppId NULL**: Some Logout events have NULL GatewayAppId
- **UserAgent NULL**: Some older mobile TokenExchange events have no UserAgent
- **ClientDeviceId truncation**: Stored as nvarchar(50) in the table but CAST to nvarchar(max) in the view — some UUIDs may be truncated at the 50-char boundary

---

## 7. Query Advisory

### Distribution & Partitioning

- **Distribution**: HASH(Gcid) — optimized for per-customer queries
- **Clustered Index**: DateID ASC — fast date-range scans
- **Partitioning**: Daily partitions — always filter on DateID for partition elimination

### Recommended Patterns

```sql
-- Daily login count by platform
SELECT DateID,
       ApplicationIdentifier,
       LoginTypeName,
       COUNT_BIG(*) AS event_count
FROM [DWH_dbo].[STS_User_Operations_Data_History]
WHERE DateID BETWEEN 20260301 AND 20260319
  AND LoginTypeName = 'Login'
GROUP BY DateID, ApplicationIdentifier, LoginTypeName
ORDER BY DateID, event_count DESC;
```

### Anti-Patterns

- **Never scan without DateID filter** — table has billions of rows across daily partitions
- **Avoid COUNT(*)** — overflows INT; always use `COUNT_BIG(*)`
- **Prefer the base table** over `Vw_STS_User_Operations_Data_History` — the view's `CAST(ClientDeviceId)` prevents index usage on that column

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Information |
|--------|------|-----------------|
| [STS - Audit_Loggin](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12026741071/STS+-+Audit_Loggin) | Confluence | ADF pipeline documentation: **STSAuditToDataLake** uses dataset **STS_Audit_User_Operations_Data** — maps the lake/staging lineage into Synapse `STS_User_Operations_Data_History` load path. |
| [DEI-2424](https://etoro-jira.atlassian.net/browse/DEI-2424) | Jira | "Optimize insert into [DWH_dbo].[STS_User_Operations_Data_History]" — performance optimization ticket for the INSERT step |
| [DSM-598](https://etoro-jira.atlassian.net/browse/DSM-598) | Jira | "STS - add 3 new fields" — added ProxyType, CountryISOCode, AdditionalData columns. Source: SP_Fact_CustomerAction_DL_To_Synapse |
| [Azure Data Platform Projects](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11782555745) | Confluence | Notes that the Gold data lake path for STS_User_Operations_Data_History was "cancelled" per Inbal Escholi — however the Synapse table and its ETL remain active |
| [sts-user-api](https://etoro-jira.atlassian.net/wiki/spaces/IG/pages/11791106108) | Confluence | STS service documentation — handles CRUD operations on STS user data including creating, retrieving, and updating user sessions |

---

*Generated: 2026-03-19 | Quality: 7.6/10 (★★★★☆) | Phases: 9/14 (P10 Atlassian refresh)*
*Tiers: 0 T1, 16 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 7.5/10*
*Object: DWH_dbo.STS_User_Operations_Data_History | Type: Table | Production Source: STS_Audit.StsAudit.UserOperations*
