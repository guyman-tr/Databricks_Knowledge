# EXW_dbo.EXW_WalletEntity

> Daily snapshot tracking every wallet user's assigned legal entity (eToroX, eToroEU, eToroDA, eToroSEY, eToroGermany, eToroUS) and their complete Terms and Conditions acceptance history, with entity assignment resolved via an 8-branch priority CASE over T&C history, per-customer settings tags, join-date windows, and country-level EXW_Settings configuration.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Daily Snapshot Fact) |
| **Writer SP** | EXW_dbo.SP_EXW_WalletEntity |
| **Refresh** | Daily; DELETE WHERE DateID=@d_i + INSERT (full snapshot replacement per date) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX(DateID ASC) |
| **UC Target** | _Not_Migrated |
| **Author / First Created** | Inessa, 2024-12-15 |
| **Last SP Change** | 2026-02-16 — Added group tag for UK, new logic for non-signed population |

---

## 1. Business Meaning

EXW_WalletEntity provides a daily snapshot of the legal entity assignment for every eToro Wallet user. As eToro operates under multiple regulatory entities (eToroX, eToroEU, eToroDA, eToroSEY, eToroGermany, eToroUS), each wallet customer must be attributed to exactly one entity per day for regulatory, financial, and T&C compliance reporting.

Each row answers: "Which legal entity governed this wallet user on this date, and what Terms and Conditions have they accepted?"

The table is created by `SP_EXW_WalletEntity` which runs a 13-step pipeline across 13 temp tables. It reads the DWH customer snapshot (for regulatory/country attributes), the WalletDB T&C acceptance records (for T&C history), and the EXW_Settings system (for country-level entity configuration). The WalletEntity assignment follows a strict priority order — T&C acceptance always wins if a user has signed to a specific entity, with country/date-window rules as fallback.

---

## 2. Business Logic

### 2.1 WalletEntity Assignment — 8-Branch Priority CASE

**What**: Every user is assigned to exactly one wallet legal entity per snapshot date. The assignment follows a strict priority cascade.

**Columns Involved**: WalletEntity, GCID, RegulationID, CountryID, JoinDate, TermsAndConditionTypeID

**Rules (in priority order)**:

| Priority | Condition | Entity Assigned |
|----------|-----------|----------------|
| 1 | User has accepted T&C for a specific entity (`#lastregulation.GCID IS NOT NULL`) | EntityName from `BI_DB_dbo.External_WalletDB_Dictionary_EtoroLegalEntities` mapped via TypeId |
| 2 | User has a per-customer `Customer` tag in EXW_Settings (`#userlevelfinal.GCID IS NOT NULL`) | EntityName from same dictionary |
| 3 | JoinDate ≥ 2024-12-18 AND JoinDate < 2025-06-11 AND CountryID IN(191=Spain, 54=Cyprus) AND RegulationID=1(CySEC) | eToroDA |
| 4 | JoinDate ≥ 2025-06-11 AND JoinDate < 2025-06-13 AND CountryID IN(191, 54) AND RegulationID=1 | eToroEU |
| 5 | JoinDate ≥ 2024-12-18 AND CountryID=123(Malaysia) AND RegulationID=9(FSA-SEY) | eToroSEY |
| 6 | JoinDate ≥ 2025-06-13 AND CountryID in EXW_Settings ResourceId=5904 AND Excluded=0 | EntityName from settings-based lookup |
| 7 | CountryID in settings AND SelectedValue IN(2=eToroGermany, 3=eToroUS) | eToroGermany or eToroUS |
| 8 | Default | eToroX |

### 2.2 Excluded Users

**What**: Some users are blocked from entity assignment (Excluded=1) and fall through to lower priorities or eToroX.

**Columns Involved**: WalletEntity, GCID (via `#blocked`)

**Rules**:
- `PlayerStatusID IN(2,4)` → Excluded (blocked/suspended accounts)
- `EXW_UserSettingsWalletAllowance.SelectedValue = 0` → Excluded
- `CountryID = 169` OR `CitizenshipCountryID = 169` OR `POBCountryID = 169` → Excluded (OFAC-restricted country)

### 2.3 T&C History Aggregation

**What**: For each user, all accepted T&C versions within their most recent entity group are aggregated into comma-separated strings.

**Columns Involved**: TermsAndConditionVersions, TermsAndConditionIDs, TermsAndConditionDate, TermsAndConditionTime, TermsAndConditionTypeID

**Rules**:
- T&C acceptances are grouped by `GCID + EntityName + TypeId`
- Within each group: `STRING_AGG(Version, ',')` → TermsAndConditionVersions
- Within each group: `STRING_AGG(TermsAndConditionId, ',')` → TermsAndConditionIDs
- Most recent entity group selected by `MAX(DateOccurred) DESC` per GCID
- `MAX(Occured)` of the selected group → TermsAndConditionTime; `CAST(MAX(Occured) AS DATE)` → TermsAndConditionDate
- Users who have never accepted T&C: all T&C columns are NULL (LEFT JOIN from snapshot)

---

## 3. Query Advisory

### 3.1 Synapse Distribution

HASH(GCID) distribution with CLUSTERED INDEX(DateID ASC). The DateID index enables efficient date-range filtering. Join to EXW_DimUser on GCID is co-located (both HASH(GCID)).

### 3.2 Snapshot Semantics

This table contains one row per user **per date**. Always filter by Date or DateID for point-in-time analysis:

```sql
-- Current entity assignment
SELECT WalletEntity, COUNT(*) AS users
FROM [EXW_dbo].[EXW_WalletEntity]
WHERE DateID = 20260419
GROUP BY WalletEntity
ORDER BY users DESC;
```

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's entity distribution | `WHERE DateID = CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)` |
| Entity changes over time | Join on GCID, track WalletEntity across dates |
| T&C acceptance coverage | `WHERE TermsAndConditionDate IS NOT NULL` |
| Users with no T&C signed | `WHERE TermsAndConditionDate IS NULL` |
| eToroDA/EU population history | `WHERE WalletEntity IN('eToroDA','eToroEU')` |

### 3.4 Gotchas

- **NULL T&C columns**: Users who have never accepted T&C will have NULL for all TermsAndCondition* columns. The snapshot still includes them; entity is assigned via priority rules 2–8.
- **Multiple versions in one column**: TermsAndConditionVersions and TermsAndConditionIDs are comma-separated strings. Parse with STRING_SPLIT if needed.
- **TermsAndConditionTime is stored as DATETIME not TIME**: Despite the name, this column stores the full datetime of acceptance, not just the time portion.
- **JoinDate is wallet activation date**: JoinDate = MIN(EXW_Wallet.CustomerWalletsView.Occurred) per Gcid — first wallet creation, not eToro registration. For registration date, use EXW_DimUser.JoinDate (which also sources CustomerWalletsView).
- **eToroX is the catch-all**: Any user not matched by rules 1–7 is assigned eToroX.
- **Snapshot replaces per date**: SP does DELETE WHERE DateID=@d_i then INSERT. Re-running for the same date is idempotent.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (computed, join-derived, or renamed) |
| Tier 3 | Inferred from column name, type, and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot date for this row — the `@run` parameter passed to SP_EXW_WalletEntity. One snapshot per user per date. (Tier 2 — SP_EXW_WalletEntity) |
| 2 | DateID | int | YES | Snapshot date as YYYYMMDD integer. `CAST(CONVERT(VARCHAR(8), @run, 112) AS INT)`. CLUSTERED INDEX key enabling efficient date-range scans. (Tier 2 — SP_EXW_WalletEntity) |
| 3 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. HASH distribution key for this table. (Tier 1 — Customer.CustomerStatic) |
| 4 | RealCID | int | YES | Real-account Customer ID. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 5 | WalletEntity | nvarchar(124) | YES | Legal entity governing this wallet user on this date. Resolved via 8-branch CASE: T&C acceptance → per-customer tag → eToroDA/eToroEU date windows → eToroSEY → settings-based → eToroGermany/eToroUS → default eToroX. See Section 2.1. (Tier 2 — SP_EXW_WalletEntity) |
| 6 | TermsAndConditionDate | date | YES | Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. DWH note: date portion (CAST AS DATE) of the MAX acceptance datetime for the user's most recent T&C entity group. NULL if user has never accepted T&C. (Tier 1 — Wallet.CustomerTermsAndConditions) |
| 7 | TermsAndConditionTime | datetime | YES | Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. DWH note: full datetime of MAX acceptance for the user's most recent T&C entity group. Stored as datetime despite column name suggesting time-only. NULL if user has never accepted T&C. (Tier 1 — Wallet.CustomerTermsAndConditions) |
| 8 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Passthrough from Fact_SnapshotCustomer. (Tier 1 — BackOffice.Customer) |
| 9 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Fact_SnapshotCustomer. (Tier 1 — Customer.CustomerStatic) |
| 10 | JoinDate | date | YES | First wallet activation date for this user. `MIN(EXW_Wallet.CustomerWalletsView.Occurred)` per Gcid, filtered to records before @end_date. Used in WalletEntity assignment rules (date-window branches). (Tier 2 — SP_EXW_WalletEntity) |
| 11 | TermsAndConditionTypeID | int | YES | Legal entity type identifier that scopes this T&C version. Different eToro entities (eToroX, eToroUS, eToroEU, etc.) may have jurisdiction-specific terms. Part of unique constraint with Version. Implicit reference to the eToro legal entity system. DWH note: renamed TypeId → TermsAndConditionTypeID; reflects the user's most recently accepted entity group. NULL if user has never accepted T&C. (Tier 1 — Wallet.TermsAndConditions) |
| 12 | TermsAndConditionVersions | nvarchar(124) | YES | Version identifier string (e.g., "V1", "V2", "V3"). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency. DWH note: `STRING_AGG(Version, ',')` — comma-separated list of all T&C versions accepted by this user within their most recent entity group. NULL if user has never accepted T&C. (Tier 1 — Wallet.TermsAndConditions) |
| 13 | TermsAndConditionIDs | nvarchar(124) | YES | The T&C version accepted. FK to Wallet.TermsAndConditions.Id. Multiple rows per Gcid reflect acceptance of different versions over time. DWH note: `STRING_AGG(TermsAndConditionId, ',')` — comma-separated list of all T&C IDs accepted by this user within their most recent entity group. NULL if user has never accepted T&C. (Tier 1 — Wallet.CustomerTermsAndConditions) |
| 14 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at INSERT time. Reflects when SP_EXW_WalletEntity last wrote this row. (Tier 2 — SP_EXW_WalletEntity) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | — | SP param @run | Direct |
| DateID | — | SP param @d_i | CAST(CONVERT(VARCHAR(8), @run, 112) AS INT) |
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via Fact_SnapshotCustomer |
| RealCID | etoro.Customer.CustomerStatic | RealCID | Passthrough via Fact_SnapshotCustomer |
| WalletEntity | Multiple | — | 8-branch CASE (see Section 2.1) |
| TermsAndConditionDate | Wallet.CustomerTermsAndConditions | Occured | MAX(CAST(Occured AS DATE)) per entity group |
| TermsAndConditionTime | Wallet.CustomerTermsAndConditions | Occured | MAX(Occured) per entity group |
| RegulationID | etoro.BackOffice.Customer | RegulationID | Passthrough via Fact_SnapshotCustomer |
| CountryID | etoro.Customer.CustomerStatic | CountryID | Passthrough via Fact_SnapshotCustomer |
| JoinDate | EXW_Wallet.CustomerWalletsView | Occurred | MIN(Occurred) per Gcid |
| TermsAndConditionTypeID | Wallet.TermsAndConditions | TypeId | Renamed; last entity group's TypeId |
| TermsAndConditionVersions | Wallet.TermsAndConditions | Version | STRING_AGG(Version, ',') per entity group |
| TermsAndConditionIDs | Wallet.CustomerTermsAndConditions | TermsAndConditionId | STRING_AGG(TermsAndConditionId, ',') per entity group |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  └─ DWH_dbo.Fact_SnapshotCustomer → #snapprep (GCID, RealCID, RegulationID, CountryID)

WalletDB.Wallet.TermsAndConditions + CustomerTermsAndConditions
  └─ CopyFromLake.WalletDB_Wallet_TermsAndConditions → #map (TypeId→EntityName)
  └─ CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions → #userstnc → #changes → #lastregulation

EXW_Wallet.CustomerWalletsView → #usersw (JoinDate = MIN(Occurred))

EXW_Settings (ResourceId=5904) → #settings → #union → #value (country-level entity)

EXW_dbo.EXW_UserSettingsWalletAllowance + DWH_dbo.Dim_Customer → #blocked (Excluded flag)

EXW_Settings (TagType='Customer') → #userlevel → #userlevelfinal (per-customer entity tag)

All streams → #compile (WalletEntity CASE + T&C aggregates)
  └─ DELETE WHERE DateID=@d_i + INSERT INTO EXW_dbo.EXW_WalletEntity
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | Customer identity — JOIN for full customer attributes |
| GCID | EXW_dbo.EXW_DimUser | Wallet customer dimension — JOIN for enriched user attributes |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory entity dimension |
| CountryID | DWH_dbo.Dim_Country | Country dimension |
| TermsAndConditionTypeID | Wallet.TermsAndConditions | TypeId of last accepted T&C version |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| Regulatory reporting | Authoritative daily entity assignment for compliance |
| T&C compliance audits | T&C acceptance history per user per date |

---

## 7. Sample Queries

### Entity distribution for a given date

```sql
SELECT WalletEntity, COUNT(*) AS user_count,
       SUM(CASE WHEN TermsAndConditionDate IS NOT NULL THEN 1 ELSE 0 END) AS has_signed_tc
FROM [EXW_dbo].[EXW_WalletEntity]
WHERE DateID = 20260419
GROUP BY WalletEntity
ORDER BY user_count DESC;
```

### Users who changed entity between two dates

```sql
SELECT a.GCID, a.WalletEntity AS entity_before, b.WalletEntity AS entity_after
FROM [EXW_dbo].[EXW_WalletEntity] a
JOIN [EXW_dbo].[EXW_WalletEntity] b ON a.GCID = b.GCID
WHERE a.DateID = 20260301
  AND b.DateID = 20260419
  AND a.WalletEntity <> b.WalletEntity;
```

### T&C acceptance coverage by entity

```sql
SELECT WalletEntity,
       COUNT(*) AS total_users,
       SUM(CASE WHEN TermsAndConditionDate IS NOT NULL THEN 1 ELSE 0 END) AS signed,
       CAST(SUM(CASE WHEN TermsAndConditionDate IS NOT NULL THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,1)) AS pct_signed
FROM [EXW_dbo].[EXW_WalletEntity]
WHERE DateID = 20260419
GROUP BY WalletEntity
ORDER BY total_users DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for EXW_WalletEntity. The entity assignment logic is embedded in SP_EXW_WalletEntity with author history in the SP header (Inessa, 2024-12-15 through 2026-02-16).

---

## T1 COPY VERIFICATION

| Column | Upstream Words | Wiki Words | Status |
|--------|---------------|-----------|--------|
| GCID | "Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`." | Same, stripped "HASH distribution key" (FCA-specific note) | IDENTICAL |
| RealCID | "Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID." | IDENTICAL | IDENTICAL |
| RegulationID | "Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC..." (full) | IDENTICAL | IDENTICAL |
| CountryID | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | IDENTICAL | IDENTICAL |
| TermsAndConditionDate | "Timestamp when the user accepted. Note: column name typo 'Occured' preserved from original schema." + DWH note appended | IDENTICAL (DWH note added) | PASS |
| TermsAndConditionTime | Same source + DWH note appended | IDENTICAL (DWH note added) | PASS |
| TermsAndConditionTypeID | "Legal entity type identifier that scopes this T&C version. Different eToro entities...Part of unique constraint with Version. Implicit reference to the eToro legal entity system." + DWH note | IDENTICAL (DWH note added) | PASS |
| TermsAndConditionVersions | "Version identifier string (e.g., 'V1', 'V2', 'V3'). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency." + DWH note | IDENTICAL (DWH note added) | PASS |
| TermsAndConditionIDs | "The T&C version accepted. FK to Wallet.TermsAndConditions.Id. Multiple rows per Gcid reflect acceptance of different versions over time." + DWH note | IDENTICAL (DWH note added) | PASS |

PHASE 10.5b CHECKPOINT: PASS
- Tier 1 count: 9 (GCID, RealCID, RegulationID, CountryID, TermsAndConditionDate, TermsAndConditionTime, TermsAndConditionTypeID, TermsAndConditionVersions, TermsAndConditionIDs)
- Total columns: 14
- Upstream T1-matchable: 9
- Coverage: 9/9 = 100%

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 9 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 14/14*
*Object: EXW_dbo.EXW_WalletEntity | Type: Table | Production Sources: etoro.Customer.CustomerStatic + BackOffice.Customer + Wallet.CustomerTermsAndConditions + Wallet.TermsAndConditions*
