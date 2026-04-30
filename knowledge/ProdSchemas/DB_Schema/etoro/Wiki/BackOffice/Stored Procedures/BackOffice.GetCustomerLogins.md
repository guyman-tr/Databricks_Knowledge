# BackOffice.GetCustomerLogins

> Returns a date-filtered, descending-sorted list of login session records for a customer, including resolved country-by-IP, login type, and application name; optionally includes auto-login (session-refresh) events.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @StartDate/@EndDate date window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice agents use the Logins tab in the customer profile to investigate suspicious access patterns, verify account security, and support fraud reviews. This procedure queries the STS (Security Token Service) audit log for a customer's login sessions within a given date range.

Each row represents one login session: when the session started, when it ended (explicit logout or expiry), what client version was used, the source IP, the geographically resolved country, the login type (password, social, auto-renew), and the application platform (eToro, eToroX, etc.).

Key behavioral details:
- **Logout column**: prefers `ExplicitlyLoggedOutOn` (user-initiated sign-out); falls back to `ExpirationLoggedOutOn` (session timeout). If both are NULL the session is considered still active.
- **Auto-login filter**: LoginTypeId=22 is the STS code for automatic token renewal (silent session refresh). These are excluded by default (`@IncludeAutoLogin=0`) so agents only see user-initiated logins. They can be included for full-session audits.
- **OpenBook exclusion**: `ApplicationIdentifier <> 'openbook'` removes social network / CopyTrading feed logins, which are not relevant to the trading account security review.
- **Country by IP**: resolved via `Internal.GetCountryNameByIP`. An `ISNUMERIC` guard skips resolution for IPv6 addresses (which contain colons - non-numeric after dot-stripping), returning NULL instead.
- **Application Name**: looked up from `dbo.Dictionary_AuthApplications` by `GatewayAppId`. Defaults to the local constant `'eToro'` when no match exists (pre-eToroX era sessions).
- **COLLATE Latin1_General_BIN**: applied to Client and IP columns for binary (case-sensitive, accent-sensitive) collation consistency when the underlying data uses mixed collations.

Original implementation (Aug 2014, FB 23571) queried HLOP.LoggedIn. October 2014 (FB 23850) migrated to the STS_Audit_LoginHistory source. January 2015 fixed collation incompatibility. March 2017 (FB 44275) added `@IncludeAutoLogin` to expose auto-login events. February 2019 (RD-2105 - OPS0573) added application name lookup and excluded openbook. Also February 2019 (RD-3285) fixed a bug where the logins report was not sorted by last login (added ORDER BY LoggedInOn DESC).

---

## 2. Business Logic

### 2.1 Date Window Filter (Session Overlap Logic)

**What**: Finds sessions that overlap the [@StartDate, @EndDate] window, not just sessions that started within it.

**Rules**:
- Condition A: `LoggedInOn < @EndDate AND (ExplicitlyLoggedOutOn > @StartDate OR ExpirationLoggedOutOn > @StartDate)` - session started before the window ends AND ended after the window starts (standard interval overlap)
- Condition B: `LoggedInOn BETWEEN @StartDate AND @EndDate` - session started within the window (handles sessions still active / with NULL logout)
- Combined as A OR B - ensures sessions spanning the boundary are included

### 2.2 Logout Derivation

**What**: Single logout timestamp from two possible sources.

**Rules**:
- `CASE WHEN ExplicitlyLoggedOutOn IS NOT NULL THEN ExplicitlyLoggedOutOn ELSE ExpirationLoggedOutOn END`
- ExplicitlyLoggedOutOn: set when user clicks "Sign Out"
- ExpirationLoggedOutOn: set when the STS token expires automatically
- NULL result means the session is still active or logout was not recorded

### 2.3 Auto-Login Exclusion

**What**: LoginTypeId=22 represents silent token renewal, not a user-initiated login.

**Rules**:
- Default (`@IncludeAutoLogin=0`): `STS_LGHIS.LoginTypeId <> 22`
- Include mode (`@IncludeAutoLogin=1`): all login types returned
- Condition: `(@IncludeAutoLogin = 0 AND STS_LGHIS.LoginTypeId <> 22) OR @IncludeAutoLogin = 1`

### 2.4 Country by IP Guard

**What**: IPv6 addresses cannot be resolved by the IP-to-country function.

**Rules**:
- `ISNUMERIC(REPLACE(STS_LGHIS.ClientIp, '.', ''))` - strips dots; if non-numeric (IPv6 contains colons), returns 0
- Returns NULL for IPv6 instead of calling the function (avoids function error)
- IPv4 addresses (all digits after dot removal) are resolved via `Internal.GetCountryNameByIP`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Matched against dbo.STS_Audit_LoginHistory.RealCid. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date window (inclusive for BETWEEN, exclusive for interval overlap). |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date window. Sessions starting before this are included if their logout is after @StartDate. |
| 4 | @IncludeAutoLogin | BIT | YES | 0 | CODE-BACKED | When 0 (default): excludes LoginTypeId=22 (silent token renewal). When 1: all login types returned for full session audit. |
| **Output Columns** | | | | | | |
| 5 | [Logged In] | DATETIME | NO | - | CODE-BACKED | Session start timestamp. From STS_Audit_LoginHistory.LoggedInOn. |
| 6 | [Logged Out] | DATETIME | YES | NULL | CODE-BACKED | Session end timestamp. ExplicitlyLoggedOutOn if set; else ExpirationLoggedOutOn. NULL if session still active or not recorded. |
| 7 | Client | VARCHAR | YES | - | CODE-BACKED | Concatenation of ApplicationIdentifier + '-' + ApplicationVersion (e.g., 'eToro-6.12.0'). COLLATE Latin1_General_BIN. |
| 8 | IP | VARCHAR(50) | YES | - | CODE-BACKED | Client IP address (IPv4 or IPv6). Cast to VARCHAR(50) with COLLATE Latin1_General_BIN. |
| 9 | [Country By IP] | VARCHAR | YES | NULL | CODE-BACKED | Country name resolved from ClientIp via Internal.GetCountryNameByIP. NULL for IPv6 or unresolvable addresses. |
| 10 | [Login Type] | VARCHAR | YES | NULL | CODE-BACKED | Human-readable login type from dbo.STS_Dictionary_LoginType.LoginTypeName. NULL if LoginTypeId has no dictionary entry. |
| 11 | [Application Name] | VARCHAR | NO | 'eToro' | CODE-BACKED | Platform/application name. From dbo.Dictionary_AuthApplications.ApplicationName matched by GatewayAppId. Defaults to 'eToro' when no match (pre-eToroX or legacy sessions). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RealCid | dbo.STS_Audit_LoginHistory | Primary Source | All login session records; filtered by RealCid = @CID |
| LoginTypeId | dbo.STS_Dictionary_LoginType | LEFT JOIN | Resolves login type code to human-readable name |
| GatewayAppId | dbo.Dictionary_AuthApplications | LEFT JOIN | Resolves gateway app ID to application name (e.g., 'eToroX') |
| ClientIp | Internal.GetCountryNameByIP | Scalar Function call | Resolves IPv4 address to country name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Logins tab in customer profile for security/fraud review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerLogins (procedure)
|- dbo.STS_Audit_LoginHistory (primary - STS session audit log)
|- dbo.STS_Dictionary_LoginType (login type name lookup)
|- dbo.Dictionary_AuthApplications (application name lookup)
+-- Internal.GetCountryNameByIP (scalar function - IP geolocation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.STS_Audit_LoginHistory | Table | Primary source - all login sessions with timestamps, IP, client, login type |
| dbo.STS_Dictionary_LoginType | Table (dbo schema) | LEFT JOINed to resolve LoginTypeId to LoginTypeName |
| dbo.Dictionary_AuthApplications | Table (dbo schema) | LEFT JOINed to resolve GatewayAppId to ApplicationName |
| Internal.GetCountryNameByIP | Scalar Function | Called for IPv4 ClientIp resolution to country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Customer Logins tab - date-range login history for security/fraud investigation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `WITH(NOLOCK)` on primary table.
- `COLLATE Latin1_General_BIN` on Client and IP: binary collation for consistent case-sensitive comparison across mixed-collation columns.
- `ORDER BY LoggedInOn DESC`: ensures most recent logins appear first (fix introduced in RD-3285, Feb 2019).

---

## 8. Sample Queries

### 8.1 Get logins for a customer over the last 30 days

```sql
EXEC BackOffice.GetCustomerLogins
    @CID = 12345678,
    @StartDate = '2026-02-15',
    @EndDate = '2026-03-17',
    @IncludeAutoLogin = 0;
```

### 8.2 Include auto-login events for full session audit

```sql
EXEC BackOffice.GetCustomerLogins
    @CID = 12345678,
    @StartDate = '2026-02-15',
    @EndDate = '2026-03-17',
    @IncludeAutoLogin = 1;
```

### 8.3 Direct base-table query

```sql
SELECT TOP 50
    LoggedInOn AS [Logged In],
    CASE WHEN ExplicitlyLoggedOutOn IS NOT NULL THEN ExplicitlyLoggedOutOn ELSE ExpirationLoggedOutOn END AS [Logged Out],
    (ApplicationIdentifier + '-' + ApplicationVersion) COLLATE Latin1_General_BIN AS Client,
    CAST(ClientIp AS VARCHAR(50)) COLLATE Latin1_General_BIN AS IP,
    LoginTypeName AS [Login Type]
FROM dbo.STS_Audit_LoginHistory STS_LGHIS WITH(NOLOCK)
LEFT JOIN dbo.STS_Dictionary_LoginType ON LoginTypeId = STS_LGHIS.LoginTypeId
WHERE RealCid = 12345678
    AND ApplicationIdentifier <> 'openbook'
    AND STS_LGHIS.LoginTypeId <> 22
ORDER BY LoggedInOn DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-2105 (OPS0573) | Jira Story | Feb 2019 - "Display Application name in login tab (eToroX)". Added dbo.Dictionary_AuthApplications JOIN to show app name; excluded openbook ApplicationIdentifier. Subtask RD-2993 handled the DB script changes. |
| RD-3285 | Jira Bug | Feb 2019 - "Logins report in the BO not sorted by last login". Added ORDER BY LoggedInOn DESC to fix unsorted results. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerLogins | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerLogins.sql*
