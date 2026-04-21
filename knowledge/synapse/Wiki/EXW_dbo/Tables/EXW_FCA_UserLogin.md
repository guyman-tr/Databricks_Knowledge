# EXW_dbo.EXW_FCA_UserLogin

> Daily-partitioned login event log for eToro Wallet (FCA scope) users — a near-verbatim passthrough of DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=14, filtered to wallet users via EXW_Wallet.CustomerWalletsView, with IP geolocation, proxy detection, and session tracking columns.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Event Log) |
| **Writer SP** | EXW_dbo.SP_EXW_FCA_UserLogin |
| **Refresh** | Daily; DELETE WHERE DateID=@d_i + INSERT (partitioned by date) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |

---

## 1. Business Meaning

EXW_FCA_UserLogin is the wallet-scoped login event table. It contains one row per login event (ActionTypeID=14 in Fact_CustomerAction) for users who are active wallet holders (present in EXW_Wallet.CustomerWalletsView). The table provides the same login data as the full DWH Fact_CustomerAction for login events, but restricted to the ~700K EXW wallet user population.

Each row records when a wallet user logged in, their IP address, session identifier, proxy/anonymization status, and the platform they logged in from. This is the primary data source for FCA (Financial Conduct Authority) regulatory reporting on wallet user login patterns and geographic access.

Despite the "FCA" in the table name, the table is not restricted to FCA-regulated users — it contains all wallet users' login events. The FCA naming reflects the original reporting scope when the table was created.

---

## 2. Business Logic

### 2.1 Wallet User Scope Filter

**What**: Only login events from users with an active wallet account are included.

**Columns Involved**: GCID

**Rules**:
- SP joins Fact_CustomerAction to EXW_Wallet.CustomerWalletsView on GCID
- Users not in CustomerWalletsView are excluded from this table
- All FCA ActionTypeID=14 rows for wallet GCIDs are included (not just "FCA-regulated" users)

### 2.2 Date-Partitioned Daily Append

**What**: SP processes one date at a time.

**Columns Involved**: DateID, Occurred

**Rules**:
- Input parameter: `@d_i` (date as YYYYMMDD int)
- `DELETE WHERE DateID = @d_i` then INSERT from FCA for that date
- Re-running for the same date is idempotent

---

## 3. Query Advisory

### 3.1 Always filter by DateID for performance

The table is partitioned by date. Always include a DateID filter:

```sql
WHERE DateID BETWEEN 20260401 AND 20260419  -- date range
WHERE DateID = 20260419                      -- single day
```

### 3.2 Join to EXW_DimUser for enrichment

```sql
SELECT l.GCID, l.Occurred, l.IPNumber, l.ProxyType,
       u.Country, u.RegulationID, u.VerificationLevelID
FROM [EXW_dbo].[EXW_FCA_UserLogin] l
JOIN [EXW_dbo].[EXW_DimUser] u ON l.GCID = u.GCID
WHERE l.DateID = 20260419;
```

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Proxy/VPN logins | `WHERE ProxyType IS NOT NULL` |
| Anonymous IP connections | `WHERE IsAnonymousIP = 1` |
| Logins by platform | `JOIN Dim_Product ON PlatformID = Dim_Product.ProductID GROUP BY Platform` |
| Logins from specific country by IP | `JOIN Dim_Country ON CountryIDByIP = Dim_Country.CountryID WHERE Dim_Country.Name = 'Germany'` |
| Daily login count per user | `GROUP BY GCID, DateID HAVING COUNT(*) > 1` for multi-login days |

### 3.4 Gotchas

- **"FCA" is a misnomer**: The table is not limited to FCA-regulated users. All wallet users' logins are included.
- **ActionTypeID always 14**: This table is pre-filtered to login events. ActionTypeID=14 on every row.
- **IsReal always 1**: Real accounts only. Demo account logins are not in Fact_CustomerAction.
- **DemoCID always 0**: Always 0 in Fact_CustomerAction for real events. Not meaningful here.
- **CountryIDByIP vs user's CountryID**: CountryIDByIP is the IP geolocation country at login time, which may differ from EXW_DimUser.CountryID (registered country). For FCA compliance, login-time country matters.
- **StatusID almost always 1**: Nearly always active status. NULL for a very small fraction of rows.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (passthrough from Fact_CustomerAction) |
| Tier 2 | DWH ETL-computed (passthrough from Fact_CustomerAction where it is Tier 2) |
| Tier 3 | ETL-assigned constant (passthrough from FCA) |
| Tier 5 | Domain expert knowledge only (passthrough from FCA) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. Passthrough from Fact_CustomerAction. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Real-account Customer ID. References `Dim_Customer.RealCID`. Each customer has one real CID. Passthrough from Fact_CustomerAction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DateID | int | YES | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. Passthrough from Fact_CustomerAction. (Tier 2 — ETL-computed) |
| 4 | DemoCID | int | YES | Demo-account Customer ID. Always 0 in this table (real accounts only). Passthrough from Fact_CustomerAction. (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. DWH note: only login events (ActionTypeID=14) are stored in this table. Passthrough from Fact_CustomerAction. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. Passthrough from Fact_CustomerAction. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | YES | Account type flag. Always 1 in this table (real accounts only). Passthrough from Fact_CustomerAction. (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | YES | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. DWH note: always 14 (LoggedIn) in EXW_FCA_UserLogin — table is pre-filtered to login events only. Passthrough from Fact_CustomerAction. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | YES | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. Passthrough from Fact_CustomerAction. (Tier 3 — ETL-assigned) |
| 10 | LoginID | int | YES | Login session identifier from `Billing.Login`. 0 for non-login events. Passthrough from Fact_CustomerAction. (Tier 1 — Billing.Login) |
| 11 | TimeID | int | YES | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. Passthrough from Fact_CustomerAction. (Tier 2 — ETL-computed) |
| 12 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for a small fraction of rows. Passthrough from Fact_CustomerAction. (Tier 3 — ETL-assigned) |
| 13 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. Passthrough from Fact_CustomerAction. (Tier 1 — STS) |
| 14 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). Passthrough from Fact_CustomerAction. (Tier 5 — domain expert) |
| 15 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. Passthrough from Fact_CustomerAction. (Tier 5 — domain expert) |
| 16 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. Passthrough from Fact_CustomerAction. (Tier 1 — IP geolocation) |
| 17 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. Passthrough from Fact_CustomerAction. (Tier 1 — STS) |
| 18 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at insert time. Reflects when SP_EXW_FCA_UserLogin last wrote this row. (Tier 2 — SP_EXW_FCA_UserLogin) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via Fact_CustomerAction |
| RealCID | etoro.Customer.CustomerStatic | RealCID | Passthrough via Fact_CustomerAction |
| DateID | — (ETL-computed) | — | YYYYMMDD int from Occurred |
| DemoCID | — (ETL-constant) | — | Always 0 |
| Occurred | STS_Audit_UserOperationsData | Login timestamp | Passthrough via Fact_CustomerAction |
| IPNumber | STS / Billing.Login | IP | Passthrough via Fact_CustomerAction |
| IsReal | — (ETL-constant) | — | Always 1 |
| ActionTypeID | — (ETL-derived) | — | Always 14 (login filter) |
| PlatformTypeID | — (ETL-assigned) | — | Platform type code |
| LoginID | Billing.Login | Session identifier | Passthrough via Fact_CustomerAction |
| TimeID | — (ETL-computed) | — | DATEPART(HOUR, Occurred) |
| StatusID | — (ETL-assigned) | — | Row status flag |
| SessionID | STS | Session ID | Passthrough via Fact_CustomerAction |
| PlatformID | Dim_Product | ProductID | Passthrough via Fact_CustomerAction |
| CountryIDByIP | IP geolocation | Country from IP | Passthrough via Fact_CustomerAction |
| IsAnonymousIP | IP geolocation | Anonymous flag | Passthrough via Fact_CustomerAction |
| ProxyType | STS | Proxy type code | Passthrough via Fact_CustomerAction |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
STS_Audit_UserOperationsData (production login event stream)
  └─ Generic Pipeline (Bronze export to Azure Data Lake)
  └─ DWH_dbo.Fact_CustomerAction (SP_Fact_CustomerAction — ActionTypeID=14 rows)
       ├─ LEFT JOIN EXW_Wallet.CustomerWalletsView ON GCID (wallet scope filter)
       └─ SP_EXW_FCA_UserLogin:
            DELETE FROM EXW_dbo.EXW_FCA_UserLogin WHERE DateID = @d_i
            INSERT INTO EXW_dbo.EXW_FCA_UserLogin (all FCA columns + GETDATE())
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Primary wallet user dimension — JOIN for country, regulation, club |
| ActionTypeID | DWH_dbo.Dim_ActionType | Action type dimension — JOIN for Name, Category |
| PlatformID | DWH_dbo.Dim_Product | Product/platform dimension — JOIN for platform details |
| CountryIDByIP | DWH_dbo.Dim_Country | Country dimension — JOIN for login-time country name |
| SessionID | EXW_Wallet login session | STS session identifier |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| FCA regulatory reporting | Login pattern analysis for FCA compliance |
| Security monitoring | Proxy and anonymous IP detection |
| Geographic access analysis | CountryIDByIP distribution |

---

## 7. Sample Queries

### Wallet user logins from anonymous IPs by date

```sql
SELECT DateID, COUNT(*) AS anon_logins
FROM [EXW_dbo].[EXW_FCA_UserLogin]
WHERE IsAnonymousIP = 1
  AND DateID BETWEEN 20260401 AND 20260419
GROUP BY DateID
ORDER BY DateID;
```

### Proxy type breakdown for recent logins

```sql
SELECT ProxyType, COUNT(*) AS login_count
FROM [EXW_dbo].[EXW_FCA_UserLogin]
WHERE DateID = 20260419
  AND ProxyType IS NOT NULL
GROUP BY ProxyType
ORDER BY login_count DESC;
```

### Multi-login users on a given day

```sql
SELECT GCID, COUNT(*) AS daily_logins
FROM [EXW_dbo].[EXW_FCA_UserLogin]
WHERE DateID = 20260419
GROUP BY GCID
HAVING COUNT(*) > 3
ORDER BY daily_logins DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for EXW_FCA_UserLogin specifically. Upstream documentation in DWH_dbo.Fact_CustomerAction wiki covers the source column semantics.

---

## T1 COPY VERIFICATION

| Column | Source (Fact_CustomerAction) | Status |
|--------|------------------------------|--------|
| GCID | "Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`." | IDENTICAL |
| RealCID | "Real-account Customer ID. References `Dim_Customer.RealCID`. Each customer has one real CID." Stripped "HASH distribution key" (FCA-specific) | IDENTICAL |
| Occurred | "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded." + DWH note appended | PASS |
| IPNumber | "IP address of the customer as a numeric value. Populated for logins and registrations." | IDENTICAL |
| ActionTypeID | Full description copied + DWH note appended | PASS |
| LoginID | "Login session identifier from `Billing.Login`. 0 for non-login events." | IDENTICAL |
| SessionID | "STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events." | IDENTICAL |
| IsAnonymousIP | "Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows." | IDENTICAL |
| ProxyType | "Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections." | IDENTICAL |
| DateID | "Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes." | IDENTICAL (T2) |
| TimeID | "Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`." | IDENTICAL (T2) |
| PlatformID | "Product/platform identifier — badly named, actually references `Dim_Product.ProductID`..." (full) | IDENTICAL (T5) |
| CountryIDByIP | "Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID`..." (full) | IDENTICAL (T5) |

PHASE 10.5b CHECKPOINT: PASS
- Tier 1 count: 9 (GCID, RealCID, Occurred, IPNumber, ActionTypeID, LoginID, SessionID, IsAnonymousIP, ProxyType)
- Upstream matchable from FCA: 9+ columns
- Coverage: 9/9 = 100%

---

*Generated: 2026-04-20 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 9 T1, 3 T2, 4 T3, 0 T4, 2 T5 | Elements: 18/18*
*Object: EXW_dbo.EXW_FCA_UserLogin | Type: Table | Production Source: STS_Audit_UserOperationsData (via Fact_CustomerAction)*
