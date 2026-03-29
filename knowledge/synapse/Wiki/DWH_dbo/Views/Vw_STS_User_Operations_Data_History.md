# DWH_dbo.Vw_STS_User_Operations_Data_History

> Thin pass-through view over STS_User_Operations_Data_History that widens the ClientDeviceId column to nvarchar(max) for downstream consumption compatibility.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Production Source** | DWH_dbo.STS_User_Operations_Data_History (base table) |
| **Refresh** | Real-time (view over daily-refreshed table) |
| | |
| **Synapse Distribution** | N/A (view inherits base table HASH(Gcid)) |
| **Synapse Index** | N/A (view inherits base table CLUSTERED INDEX on DateID) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Vw_STS_User_Operations_Data_History` is a trivial pass-through view over the `STS_User_Operations_Data_History` table. It exposes all 21 columns identically, with a single type-widening transformation: `ClientDeviceId` is CAST from `nvarchar(50)` to `nvarchar(max)`. No rows are filtered and no columns are added or removed.

The purpose of this view is to provide a consistent nvarchar(max) interface for the ClientDeviceId field, enabling downstream consumers (e.g., BigQuery exports, replication pipelines) to handle device IDs without truncation concerns. The base table `STS_User_Operations_Data_History` contains the authoritative session/authentication audit trail from eToro's Security Token Service — see its wiki for full documentation.

There is no ETL for this view — it reads the base table directly. The base table is refreshed daily via partition SWITCH (see `STS_User_Operations_Data_History.md`).

---

## 2. Business Logic

### 2.1 ClientDeviceId Type Widening

**What**: The only transformation in this view: `CAST([ClientDeviceId] AS nvarchar(max))`

**Columns Involved**: `ClientDeviceId`

**Rules**:
- Base table column is `nvarchar(50)` — view widens to `nvarchar(max)`
- No data truncation risk (device IDs are UUID-format, well within 50 chars)
- Likely added for compatibility with downstream systems that expect nvarchar(max) on all string columns

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this view inherits the base table's HASH(Gcid) distribution and CLUSTERED INDEX on DateID. Always include DateID in WHERE clauses for partition pruning and Gcid for co-located JOINs. Querying the view is identical to querying the base table.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Login events for a customer | `WHERE Gcid = @gcid AND DateID BETWEEN @from AND @to` |
| Daily login count by platform | `GROUP BY DateID, ApplicationIdentifier` |
| Session chain tracing | Self-join on `SessionId = ParentSessionId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Gcid = Gcid | Resolve customer demographics for session analysis |
| DWH_dbo.V_Dim_Date | ON DateID = DateID | Calendar attributes for time-series analysis |

### 3.4 Gotchas

- **Identical to base table**: This view adds no filtering or business logic beyond the CAST. Use the base table `STS_User_Operations_Data_History` directly unless you specifically need nvarchar(max) on ClientDeviceId
- **Performance**: No difference vs. querying the base table — no materialization overhead
- **ProxyType and CountryISOCode**: Sparsely populated — mostly NULL. Do not rely on these for geographic analysis without checking fill rate first

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| ★★★★☆ | Tier 1 — upstream wiki (inherited from base table doc) | `(Tier 1 — STS_User_Operations_Data_History wiki)` |
| ★★★☆☆ | Tier 2 — SP code | `(Tier 2 — SP code)` |

All descriptions inherited from `STS_User_Operations_Data_History.md` (Batch 11).

| # | Column | Type | Nullable | Source | Description |
|---|--------|------|----------|--------|-------------|
| 1 | Gcid | int | YES | STS_User_Operations_Data_History.Gcid | Global Customer ID — unique cross-platform identifier linking Real and Demo accounts for the same person. Distribution key. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 2 | RealCid | int | YES | STS_User_Operations_Data_History.RealCid | Real-money account Customer ID. NULL when the session is Demo-only. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 3 | DemoCid | int | YES | STS_User_Operations_Data_History.DemoCid | Virtual/demo account Customer ID. NULL when the session is Real-only. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 4 | ApplicationIdentifier | nvarchar(100) | YES | STS_User_Operations_Data_History.ApplicationIdentifier | Client application that initiated the session. Known values: `retoro` (web/generic), `retoroios` (iOS app), `retoroandroid` (Android app). (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 5 | ApplicationVersion | nvarchar(20) | YES | STS_User_Operations_Data_History.ApplicationVersion | Build version of the client application, e.g. `340.0.10`, `355.0.1`. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 6 | ClientIp | varchar(20) | YES | STS_User_Operations_Data_History.ClientIp | IPv4 address of the client at the time of the session event. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 7 | ClientName | nvarchar(100) | YES | STS_User_Operations_Data_History.ClientName | Server-side service name that processed the authentication request. Consistently `STS.WebAPI` across all observed data. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 8 | CreatedAt | datetime | YES | STS_User_Operations_Data_History.CreatedAt | Timestamp when the authentication/session event occurred in the STS service. This is the business event time (not the ETL load time). (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 9 | UserAgent | nvarchar(512) | YES | STS_User_Operations_Data_History.UserAgent | Full HTTP User-Agent string from the client browser or mobile WebView. Contains OS, browser, and app metadata. May be NULL for some mobile token exchanges. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 10 | AccessTokenHashed | nvarchar(256) | YES | STS_User_Operations_Data_History.AccessTokenHashed | Hashed authentication access token for security audit trail. Not reversible. Sparsely populated. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 11 | ClientDeviceId | nvarchar(max) | YES | CAST(STS_User_Operations_Data_History.ClientDeviceId AS nvarchar(max)) | UUID-format device identifier (e.g. `3c24d4e9-8ef0-405f-...`). **Widened from base table's nvarchar(50) to nvarchar(max) via CAST in this view.** Populated primarily for mobile app sessions; typically NULL or empty for web. (Tier 1 — inherited from STS_User_Operations_Data_History wiki, with type widening) |
| 12 | ParentSessionId | bigint | YES | STS_User_Operations_Data_History.ParentSessionId | Session ID of the parent session for linked/chained sessions. Value `0` indicates a root session (no parent). Enables session chain tracing. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 13 | AccountTypeName | varchar(100) | YES | STS_User_Operations_Data_History.AccountTypeName | Account context for the session: `Real` (live trading) or `Demo` (virtual portfolio). (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 14 | LoginTypeName | varchar(100) | YES | STS_User_Operations_Data_History.LoginTypeName | Type of authentication event. Known values: `Login` (new session), `Authenticate` (credential re-validation), `TokenExchange` (token refresh), `Logout` (session end). (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 15 | SessionId | bigint | YES | STS_User_Operations_Data_History.SessionId | Unique session identifier assigned by the STS service. Monotonically increasing. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 16 | GatewayAppId | int | YES | STS_User_Operations_Data_History.GatewayAppId | Identifier of the API gateway application that routed the request. Commonly `1` or `2`. NULL for some Logout events. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 17 | DateID | int | YES | STS_User_Operations_Data_History.DateID | Date partition key in YYYYMMDD integer format (e.g. `20210901`). Computed in ETL from the `@Yesterday` parameter. Clustered index and partition column. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 18 | UpdateDate | datetime | YES | STS_User_Operations_Data_History.UpdateDate | Timestamp when this row was loaded into the DWH, set to `GETDATE()` during ETL execution. Not the business event time. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 19 | ProxyType | nvarchar(max) | YES | STS_User_Operations_Data_History.ProxyType | Type of proxy detected for the client IP connection (e.g. VPN, TOR). Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 20 | CountryISOCode | nvarchar(max) | YES | STS_User_Operations_Data_History.CountryISOCode | ISO country code resolved from the ClientIp address. Sparsely populated — NULL in most observed rows. Added after initial table creation. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |
| 21 | AdditionalData | nvarchar(max) | YES | STS_User_Operations_Data_History.AdditionalData | Extensible JSON or free-text field for additional session metadata. Sparsely populated. (Tier 1 — inherited from STS_User_Operations_Data_History wiki) |

---

## 5. Lineage

### 5.1 Production Sources

All columns pass through directly from `DWH_dbo.STS_User_Operations_Data_History`. See that table's lineage for full production source mapping.

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ClientDeviceId | STS_Audit.StsAudit.UserOperations | ClientDeviceId | View widens: CAST(nvarchar(50) → nvarchar(max)) |
| (all others) | STS_Audit.StsAudit.UserOperations | (same name) | Passthrough via base table |

### 5.2 ETL Pipeline

```
STS_Audit.StsAudit.UserOperations → DWH_staging.STS_Audit_UserOperationsData → SP_Fact_CustomerAction_DL_To_Synapse → STS_User_Operations_Data_History → [this view]
```

| Step | Object | Description |
|------|--------|-------------|
| Source | STS_Audit.StsAudit.UserOperations | STS authentication event log |
| Staging | DWH_staging.STS_Audit_UserOperationsData | Raw import from data lake |
| ETL | SP_Fact_CustomerAction_DL_To_Synapse | Daily partition SWITCH append |
| Base Table | DWH_dbo.STS_User_Operations_Data_History | Partitioned fact-like history table |
| View | DWH_dbo.Vw_STS_User_Operations_Data_History | Pass-through with ClientDeviceId CAST |

---

## 6. Relationships

### 6.1 References To (this view points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (base table) | DWH_dbo.STS_User_Operations_Data_History | Direct SELECT from base table |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| No known consumers | — | This view may be consumed by replication pipelines or external systems requiring nvarchar(max) on all string columns |

---

## 7. Sample Queries

### 7.1 Daily login count by application platform

```sql
SELECT
    DateID,
    ApplicationIdentifier,
    COUNT(*) AS LoginCount
FROM DWH_dbo.Vw_STS_User_Operations_Data_History
WHERE LoginTypeName = 'Login'
  AND DateID >= 20260301
GROUP BY DateID, ApplicationIdentifier
ORDER BY DateID DESC;
```

### 7.2 Customer session history with device info

```sql
SELECT
    Gcid,
    CreatedAt,
    ApplicationIdentifier,
    ApplicationVersion,
    ClientDeviceId,
    LoginTypeName,
    SessionId,
    ParentSessionId
FROM DWH_dbo.Vw_STS_User_Operations_Data_History
WHERE Gcid = @gcid
  AND DateID BETWEEN 20260101 AND 20260319
ORDER BY CreatedAt DESC;
```

### 7.3 Session chain: trace parent-child relationships

```sql
SELECT
    child.SessionId,
    child.ParentSessionId,
    child.LoginTypeName,
    child.CreatedAt,
    parent.LoginTypeName AS ParentLoginType,
    parent.CreatedAt AS ParentCreatedAt
FROM DWH_dbo.Vw_STS_User_Operations_Data_History child
LEFT JOIN DWH_dbo.Vw_STS_User_Operations_Data_History parent
    ON child.ParentSessionId = parent.SessionId
   AND child.DateID = parent.DateID
WHERE child.Gcid = @gcid
  AND child.DateID = 20260319
  AND child.ParentSessionId != 0;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [STS - Audit_Loggin](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12026741071) | ADF pipeline: `STS_Audit_User_Operations_Data` → lake/Synapse path for STS audit operations |
| [Separate STS create user from UserAPI](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11493540399) | STS user provisioning context (registration / UserAPI split) |
| [sts-device-management-front-api](https://etoro-jira.atlassian.net/wiki/spaces/IG/pages/13346439264) | End-user device lifecycle; relates to device identifiers in STS |

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 6/14 (view — inherited from base table) | Batch: 16*
*Tiers: 0 T1, 18 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 10/10*
*Object: DWH_dbo.Vw_STS_User_Operations_Data_History | Type: View | Production Source: STS_User_Operations_Data_History (base table)*
