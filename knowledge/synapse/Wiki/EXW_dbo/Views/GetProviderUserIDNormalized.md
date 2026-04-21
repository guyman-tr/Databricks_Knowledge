# EXW_dbo.GetProviderUserIDNormalized

> Query-time lookup view over EXW_AMLProviderID (206,407 rows, 2020-05-27 to 2026-04-11) that enriches AML compliance provider user records with country, regulation, player status, and wallet allowance context. Used directly by AML analysts to identify the DWH-resolved profile for users submitted to external AML providers.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | View |
| **Primary Base Table** | EXW_dbo.EXW_AMLProviderID |
| **Refresh** | Query-time — no ETL SP; results reflect current state of all base tables |
| **Row Count** | 206,407 (at query time — matches EXW_AMLProviderID exactly; no orphan exclusions) |
| **Data Coverage** | AML submission events 2020-05-27 to 2026-04-11 |
| **Synapse Distribution** | N/A (view) |
| **Synapse Index** | N/A (view) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to data lake |

---

## 1. Business Meaning

GetProviderUserIDNormalized is an AML analyst-facing view that surfaces each AML compliance provider submission event alongside the corresponding user's DWH-resolved country, regulation entity, player status, and wallet allowance decision. Each row represents one AML provider submission event for a Wallet user (one row per GCID × AMLProviderID × date in EXW_AMLProviderID).

The view is named after its key column: ProviderUserIDNormalized — the base64-encoded GCID string with trailing `=` padding stripped, which is the form expected by external AML systems for cross-platform user identity matching.

INNER JOINs on Dim_Country and Dim_Regulation ensure only users with valid DWH dimension coverage appear. The row count parity with EXW_AMLProviderID (206,407) confirms that 100% of AML submissions have valid DWH customer records. UserWalletAllowance distribution in this AML-scoped population: Allowed=167,720 (81.2%), NotAllowed=30,961 (15.0%), ReadOnly=7,726 (3.7%) — a higher NotAllowed rate than the overall wallet population (11.4%) reflecting AML-flagged user skew.

---

## 2. Business Logic

### 2.1 INNER JOIN Exclusion Filter

**What**: Users in EXW_AMLProviderID with no Dim_Customer → Dim_Country or Dim_Regulation chain are excluded from this view.

**Columns Involved**: CID, Country, Regulation

**Rules**:
- LEFT JOIN DWH_dbo.Dim_Customer ON eai.RealCID = dc.RealCID
- INNER JOIN DWH_dbo.Dim_Country ON dc.CountryID = dcn.CountryID
- INNER JOIN DWH_dbo.Dim_Regulation ON dr.DWHRegulationID = dc.RegulationID
- If dc.RealCID IS NULL (no Dim_Customer match), the INNER JOINs filter the row out
- 100% row retention observed — all AML users currently have DWH dimension coverage

### 2.2 ProviderUserIDNormalized Passthrough

**What**: The normalized (no `=` padding) form of the provider's external user identifier is the join key for external AML systems.

**Columns Involved**: ProviderUserIDNormalized, CID, GCID

**Rules**:
- ProviderUserIDNormalized = base64(GCID) with trailing `=` stripped (computed in EXW_AMLProviderID ETL)
- Used by KYT email report to cross-reference external provider response files
- Decode to recover GCID: base64-decode(ProviderUserIDNormalized) → ASCII GCID string → cast to int

### 2.3 UserWalletAllowance via LEFT JOIN

**What**: Wallet access decision is joined from EXW_UserSettingsWalletAllowance on GCID.

**Columns Involved**: UserWalletAllowance, GCID

**Rules**:
- LEFT JOIN EXW_UserSettingsWalletAllowance ON eai.GCID = euswa.GCID
- NULL if GCID not present in EXW_UserSettingsWalletAllowance (rare — both tables share the same GCID population)
- Values in AML-scoped population: Allowed (81.2%), NotAllowed (15.0%), ReadOnly (3.7%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

This is a view over HASH(GCID)-distributed tables. The primary join (EXW_AMLProviderID GCID ↔ EXW_UserSettingsWalletAllowance GCID) is colocation-eligible. The DWH_dbo dimension JOINs (REPLICATE typically) add broadcast overhead but are small tables — acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up AML user by external ID | `WHERE ProviderUserIDNormalized = @external_id` |
| All users submitted to AML with wallet blocked | `WHERE UserWalletAllowance = 'NotAllowed'` |
| AML users by country | `GROUP BY Country ORDER BY COUNT(*) DESC` |
| Find CID from external provider ID | `SELECT CID, GCID FROM GetProviderUserIDNormalized WHERE ProviderUserIDNormalized = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_AMLProviderID | GCID | Full AML event detail (AMLProviderID, DateID, ProviderUserID) |
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer attributes not in this view |

### 3.4 Gotchas

- **Multiple rows per GCID**: EXW_AMLProviderID has one row per GCID × AMLProviderID × date — this view inherits that cardinality. Always aggregate on GCID if counting users, not rows.
- **UserWalletAllowance is NCHAR(50)**: Trailing spaces may be present. Use RTRIM() or N'' literals in comparisons.
- **INNER JOINs may exclude future orphans**: If a user is in EXW_AMLProviderID but not in Dim_Customer (e.g., due to ETL timing), they disappear from this view.
- **No date filter**: This view spans all dates in EXW_AMLProviderID (2020–2026). Filter on DateID from EXW_AMLProviderID if joining back for a specific date range.

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
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Enriched by JOIN to EXW_DimUser on GCID. Aliased from EXW_AMLProviderID.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Source: AmlProviderUsers.Gcid. Passthrough from EXW_AMLProviderID. (Tier 2 — SP_EXW_AMLProviderID) |
| 3 | Country | nvarchar | NO | Country name resolved from Dim_Country via Dim_Customer.CountryID. INNER JOIN guarantees non-NULL. 14 regulation groups observed (CySEC=93,792, FCA=60,898, FinCEN+FINRA=15,169, FSA Seychelles=9,228, BVI=8,375, others). (Tier 3 — Dim_Country) |
| 4 | Regulation | nvarchar | NO | Regulation entity name resolved from Dim_Regulation via Dim_Customer.RegulationID. INNER JOIN guarantees non-NULL. 14 values observed (CySEC=45%, FCA=29%, US-regulated combined=12%). (Tier 3 — Dim_Regulation) |
| 5 | ProviderUserIDNormalized | varchar(256) | YES | Normalized ProviderUserID with base64 trailing '=' padding stripped. Used for JOIN matching in external KYT systems that expect unpadded identifiers. Logic: CASE WHEN LIKE '%=' THEN SUBSTRING(…, 0, CHARINDEX('=', …)) ELSE passthrough END. Passthrough from EXW_AMLProviderID. (Tier 2 — SP_EXW_AMLProviderID) |
| 6 | PlayerStatus | nvarchar | YES | Player status name resolved from Dim_PlayerStatus via Dim_Customer.PlayerStatusID. LEFT JOIN — NULL if Dim_Customer not matched. 9 values: Normal (162,057), Blocked (25,893), Blocked Upon Request (10,369), Trade & MIMO Blocked (5,038), Block Deposit & Trading (2,308), Deposit Blocked (422), Warning (220), Copy Block (94), Pending Verification (6). (Tier 3 — Dim_PlayerStatus) |
| 7 | UserWalletAllowance | nchar(50) | YES | Resolved Wallet access decision. Values: 'Allowed', 'NotAllowed', 'ReadOnly'. Derived from SelectedValue CASE: 0→NotAllowed, 1→ReadOnly, 2 or 3→Allowed, else→NotAllowed. Passthrough from EXW_UserSettingsWalletAllowance. In this AML-scoped population: Allowed=167,720, NotAllowed=30,961, ReadOnly=7,726. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |

---

## 5. Lineage

### 5.1 Production Sources

| View Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| CID | EXW_dbo.EXW_AMLProviderID | RealCID | Alias rename |
| GCID | EXW_dbo.EXW_AMLProviderID | GCID | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID |
| ProviderUserIDNormalized | EXW_dbo.EXW_AMLProviderID | ProviderUserIDNormalized | Passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN via Dim_Customer.PlayerStatusID |
| UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance | Passthrough (LEFT JOIN) |

### 5.2 Query-Time Resolution Diagram

```
EXW_dbo.EXW_AMLProviderID (206,407 rows)
  |-- CID (alias of RealCID)
  |-- GCID
  |-- ProviderUserIDNormalized
  |
  |-- LEFT JOIN DWH_dbo.Dim_Customer (on RealCID)
  |     |-- INNER JOIN DWH_dbo.Dim_Country (on CountryID) → Country
  |     |-- INNER JOIN DWH_dbo.Dim_Regulation (on RegulationID) → Regulation
  |     |-- LEFT JOIN DWH_dbo.Dim_PlayerStatus (on PlayerStatusID) → PlayerStatus
  |
  |-- LEFT JOIN EXW_dbo.EXW_UserSettingsWalletAllowance (on GCID)
        → UserWalletAllowance
  v
EXW_dbo.GetProviderUserIDNormalized (7 columns, 206,407 rows at query time)
  |-- Direct AML analyst queries
  |-- BI_DB_dbo.SP_W_Tue_Email_for_KYT (KYT email report)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID / GCID | EXW_dbo.EXW_AMLProviderID | Primary base table; all AML event data |
| Country | DWH_dbo.Dim_Country | Country name resolution |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name resolution |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status name resolution |
| UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | Wallet access decision |
| (bridge) | DWH_dbo.Dim_Customer | Connects RealCID to DWH dimension chain |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| BI_DB_dbo.SP_W_Tue_Email_for_KYT | KYT weekly email report reads this view for AML-provider enriched user profiles |
| Direct AML analyst queries | No SSDT-tracked SP consumers — primarily used for ad-hoc AML compliance analysis |

---

## 7. Sample Queries

### Lookup a user by external AML provider ID

```sql
SELECT CID, GCID, Country, Regulation, UserWalletAllowance, PlayerStatus
FROM [EXW_dbo].[GetProviderUserIDNormalized]
WHERE ProviderUserIDNormalized = N'NDY5NTUyNjY';
```

### Blocked AML users by country

```sql
SELECT Country, COUNT(*) AS BlockedUsers
FROM [EXW_dbo].[GetProviderUserIDNormalized]
WHERE UserWalletAllowance = N'NotAllowed'
GROUP BY Country
ORDER BY BlockedUsers DESC;
```

### AML provider coverage by regulation

```sql
SELECT v.Regulation,
       COUNT(DISTINCT v.GCID) AS Users,
       COUNT(DISTINCT v.CID)  AS CIDs
FROM [EXW_dbo].[GetProviderUserIDNormalized] v
GROUP BY v.Regulation
ORDER BY Users DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this view. This is an AML compliance support view built to service external provider cross-referencing workflows. Domain context found in EXW_AMLProviderID documentation.

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: 7/14 (P9/P9B/P10 N/A for views)*
*Tiers: 1 T1, 3 T2, 3 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 8/10, Coverage: 7 columns*
*Object: EXW_dbo.GetProviderUserIDNormalized | Type: View | Base Table: EXW_dbo.EXW_AMLProviderID*
