# EXW_dbo.EXW_AMLProviderID

> Daily delta extract of AML (Anti-Money Laundering) provider user mappings for the eToro Wallet. Records which Wallet users were submitted to each AML compliance provider on a given date, with their base64-encoded external user identifiers. 206,407 rows covering 2020-05-27 to 2026-04-11. Used by KYT (Know Your Transaction) email reports and wallet allowance controls.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_Wallet.AmlProviderUsers (WalletDB) |
| **Writer SP** | EXW_dbo.SP_EXW_AMLProviderID |
| **Refresh** | Daily (date-partitioned replace: DELETE + INSERT by DateID) |
| **Row Count** | 206,407 rows |
| **Date Range** | DateID: 20200527 to 20260411 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to data lake |

---

## 1. Business Meaning

This table is a daily delta log of AML (Anti-Money Laundering) compliance provider submissions for eToro Wallet users. Each row records one GCID (Wallet user) that was submitted to an AML provider (identified by AMLProviderID) on a specific date (DateID), along with the provider's own identifier for that user (ProviderUserID — a base64-encoded string).

The table is populated by SP_EXW_AMLProviderID, which runs daily and processes events from the previous day: it deletes any existing rows for that DateID and re-inserts from EXW_Wallet.AmlProviderUsers filtered to that date's Occurred range. RealCID is enriched by joining to EXW_DimUser.

Three distinct AML providers are active: ID 1 (166,322 rows), ID 3 (27,381 rows), and ID 4 (12,704 rows). The ProviderUserIDNormalized column strips base64 padding ('=') for systems that expect unpadded identifiers — observed in live data to consistently match the GCID value encoded as a base64 ASCII string.

The primary consumer is the weekly KYT email report (BI_DB_dbo.SP_W_Tue_Email_for_KYT), which joins on ProviderUserIDNormalized or ProviderUserID to identify Wallet users submitted to AML providers. The GetProviderUserIDNormalized view surfaces the table enriched with Country and Regulation context.

---

## 2. Business Logic

### 2.1 Daily Date-Partition Replace

**What**: Each run replaces one day's AML provider submission events — not a full table reload.

**Columns Involved**: DateID (partition key), GCID, AMLProviderID, ProviderUserID

**Rules**:
- DELETE FROM EXW_AMLProviderID WHERE DateID = CONVERT(varchar(8), @dt, 112)
- INSERT from EXW_Wallet.AmlProviderUsers WHERE Occurred >= @dt AND Occurred < @dt+1
- One row per (GCID, AMLProviderID, DateID) event — a user can appear for multiple providers or multiple days

### 2.2 ProviderUserID Normalization

**What**: The provider's external user identifier is base64-encoded and may include padding; the normalized form strips it for cross-system matching.

**Columns Involved**: ProviderUserID, ProviderUserIDNormalized

**Rules**:
- ProviderUserIDNormalized = CASE WHEN ProviderUserID LIKE '%=' THEN SUBSTRING(ProviderUserID, 0, CHARINDEX('=', ProviderUserID)) ELSE ProviderUserID END
- Observed in live data: ProviderUserID is the GCID encoded as a base64 ASCII string (e.g., GCID=46955266 → ProviderUserID='NDY5NTUyNjY=' → Normalized='NDY5NTUyNjY')
- Used by KYT JOIN: `eai.ProviderUserIDNormalized = kk.user_id OR eai.ProviderUserID = kk.user_id WHERE ProviderUserIDNormalized IS NULL`

### 2.3 RealCID Enrichment

**What**: RealCID is not available directly in AmlProviderUsers — it is joined from EXW_DimUser.

**Columns Involved**: GCID (join key), RealCID (result)

**Rules**:
- JOIN EXW_dbo.EXW_DimUser ON a.Gcid = b.GCID — INNER JOIN (rows without an EXW_DimUser record are excluded)
- RealCID reflects the DWH internal customer ID linked to the Wallet GCID

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CCI. Co-located with EXW_DimUser (also HASH(GCID)) for efficient JOINs. CCI is optimal for analytic aggregations over this fact-style table (time-series of AML submissions).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Has a specific user been submitted to AML? | `SELECT * FROM EXW_dbo.EXW_AMLProviderID WHERE GCID = @gcid ORDER BY DateID DESC` |
| All users submitted today | `SELECT * FROM EXW_dbo.EXW_AMLProviderID WHERE DateID = CONVERT(varchar(8), GETDATE(), 112)` |
| Provider submission breakdown | `SELECT AMLProviderID, COUNT(*) FROM EXW_dbo.EXW_AMLProviderID GROUP BY AMLProviderID` |
| Lookup by provider's external ID | `SELECT * FROM EXW_dbo.EXW_AMLProviderID WHERE ProviderUserIDNormalized = @normalized_id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_AMLProviderID.GCID` | User profile enrichment |
| DWH_dbo.Dim_Customer | `Dim_Customer.RealCID = EXW_AMLProviderID.RealCID` | Full DWH customer attributes |

### 3.4 Gotchas

- **DateID is YYYYMMDD as int**: Cast carefully when filtering by date range — use CONVERT(varchar(8), @date, 112) format.
- **Three provider IDs only**: Values observed are 1, 3, and 4. Provider names are not mapped anywhere in SSDT code.
- **INNER JOIN to EXW_DimUser**: RealCID is populated only for GCIDs that exist in EXW_DimUser at the time of the SP run. Users not yet in EXW_DimUser are excluded.
- **CCI on a small-ish table**: 206K rows is small for CCI; aggregation queries benefit but point lookups may be slower than a clustered B-tree on this volume.
- **ProviderUserID = base64(GCID)**: Useful for reverse-decoding — if you have an external provider ID, base64-decode it to get the GCID directly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Enriched by JOIN to EXW_DimUser on GCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key. Source: AmlProviderUsers.Gcid. (Tier 2 — SP_EXW_AMLProviderID) |
| 3 | ProviderUserID | varchar(256) | YES | Base64-encoded external user identifier for the AML compliance provider (observed to encode the GCID as an ASCII string, e.g., GCID=46955266 → 'NDY5NTUyNjY='). May include base64 padding character '='. Raw form as received from AmlProviderUsers. (Tier 2 — SP_EXW_AMLProviderID) |
| 4 | AMLProviderID | int | YES | Integer identifier for the AML compliance provider. Observed values: 1, 3, 4. Provider names are not mapped in SSDT code. (Tier 2 — SP_EXW_AMLProviderID) |
| 5 | DateID | int | YES | AML submission date as YYYYMMDD integer, computed from AmlProviderUsers.Occurred. Partition key for the daily DELETE + INSERT replace pattern. Range: 20200527–20260411. (Tier 2 — SP_EXW_AMLProviderID) |
| 6 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT time. Reflects when SP_EXW_AMLProviderID wrote this row. (Tier 2 — SP_EXW_AMLProviderID) |
| 7 | ProviderUserIDNormalized | varchar(256) | YES | Normalized ProviderUserID with base64 trailing '=' padding stripped. Used for JOIN matching in external KYT systems that expect unpadded identifiers. Logic: CASE WHEN LIKE '%=' THEN SUBSTRING(…, 0, CHARINDEX('=', …)) ELSE passthrough END. (Tier 2 — SP_EXW_AMLProviderID) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | etoro.Customer.CustomerStatic (via EXW_DimUser) | RealCID | JOIN EXW_DimUser on GCID |
| GCID | EXW_Wallet.AmlProviderUsers | Gcid | Passthrough |
| ProviderUserID | EXW_Wallet.AmlProviderUsers | ProviderUserId | Passthrough |
| AMLProviderID | EXW_Wallet.AmlProviderUsers | AmlProviderId | Passthrough |
| DateID | EXW_Wallet.AmlProviderUsers | Occurred | CONVERT(varchar(8), Occurred, 112) |
| UpdateDate | — | — | GETDATE() |
| ProviderUserIDNormalized | EXW_Wallet.AmlProviderUsers | ProviderUserId | CASE WHEN strip trailing '=' |

### 5.2 ETL Pipeline

```
EXW_Wallet.AmlProviderUsers (WalletDB — AML provider event log)
  |-- SP_EXW_AMLProviderID (date filter: Occurred in [@dt, @dt+1))
  |   |-- JOIN EXW_dbo.EXW_DimUser ON Gcid = GCID → RealCID enrichment
  |   |-- COMPUTE DateID = CONVERT(varchar(8), Occurred, 112)
  |   |-- COMPUTE ProviderUserIDNormalized = strip trailing '=' from ProviderUserId
  |   |-- DELETE WHERE DateID = @dt_str
  v
EXW_dbo.EXW_AMLProviderID
  |-- EXW_dbo.GetProviderUserIDNormalized (view — enriched AML lookup)
  |-- BI_DB_dbo.SP_W_Tue_Email_for_KYT (weekly KYT email report)
  |-- EXW_dbo.SP_EXW_UserSettingsWalletAllowance (wallet allowance control)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Source of RealCID via JOIN; also confirms GCID is a valid Wallet user |
| GCID | EXW_Wallet.AmlProviderUsers | Primary source of all AML submission events |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| EXW_dbo.GetProviderUserIDNormalized | View sourced from EXW_AMLProviderID — enriches with Country, Regulation, WalletAllowance |
| BI_DB_dbo.SP_W_Tue_Email_for_KYT | KYT email report JOINs on ProviderUserID / ProviderUserIDNormalized |
| EXW_dbo.SP_EXW_UserSettingsWalletAllowance | Reads AML provider IDs for wallet allowance determination |

---

## 7. Sample Queries

### AML submissions for a specific user

```sql
SELECT RealCID, GCID, AMLProviderID, ProviderUserID, ProviderUserIDNormalized, DateID
FROM [EXW_dbo].[EXW_AMLProviderID]
WHERE GCID = @gcid
ORDER BY DateID DESC;
```

### Reverse-lookup by normalized provider ID

```sql
SELECT *
FROM [EXW_dbo].[EXW_AMLProviderID]
WHERE ProviderUserIDNormalized = @external_user_id
   OR ProviderUserID = @external_user_id;
```

### AML submissions in the last 30 days

```sql
SELECT DateID, AMLProviderID, COUNT(*) AS submissions
FROM [EXW_dbo].[EXW_AMLProviderID]
WHERE DateID >= CAST(CONVERT(varchar(8), DATEADD(dd,-30,GETDATE()), 112) AS INT)
GROUP BY DateID, AMLProviderID
ORDER BY DateID DESC, AMLProviderID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. AML compliance tooling details (provider names for IDs 1, 3, 4) may be in Jira/Confluence under AML or Compliance workspaces.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 1 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 8/10, Source: EXW_Wallet.AmlProviderUsers*
*Object: EXW_dbo.EXW_AMLProviderID | Type: Table | Production Source: EXW_Wallet.AmlProviderUsers (WalletDB)*
