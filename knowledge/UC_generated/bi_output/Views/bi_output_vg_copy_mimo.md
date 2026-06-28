---
object_fqn: main.bi_output.bi_output_vg_copy_mimo
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_copy_mimo
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 55
row_count: null
generated_at: '2026-06-19T14:35:54Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.bi_output.bi_output_vg_date
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql
concept_count: 17
formula_count: 55
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 52
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_copy_mimo

> View in `main.bi_output`. 17 business concept(s) in §2; 55 of 55 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_copy_mimo` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 55 |
| **Concepts** | 17 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Mar 11 19:56:51 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_copy_mimo` is a view in `main.bi_output` that composes 3 CASE-based classifier flag(s) computed from upstream IDs, 14 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 16 object(s), listed in §5 Lineage.

Of its 55 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 52 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` bi_output.sql L41-L41
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 `IsDetachMirror` discriminator: `ActionTypeID = 19` → set to 1 else 0
**What**: Computed flag on `IsDetachMirror` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsDetachMirror`
**Rules**:
- `ActionTypeID = 19`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` bi_output.sql L56-L56
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.3 `MirrorType` discriminator: `ActionTypeID = 15`, `ActionTypeID = 16`, `ActionTypeID = 18` → set to '  ' else '    '
**What**: Computed flag on `MirrorType` set to `'  '` when the predicates below hold, else `'    '`.
**Columns Involved**: `MirrorType`
**Rules**:
- `ActionTypeID = 15`
- `ActionTypeID = 16`
- `ActionTypeID = 18`
- `ActionTypeID = 17`
- `AccountTypeID = 9`
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` bi_output.sql L57-L63
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.4 Dim lookup via alias `mr` → `gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_mirror` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.MirrorID = mr.MirrorID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L65
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

### 2.5 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RealCID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L73
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.6 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L75
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.7 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L77
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.8 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L79
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.9 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L81
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.10 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L83,L99
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.11 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L85
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.12 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L87
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.13 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L89
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.14 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L91
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.15 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L93
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.16 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L95
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.17 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_copy_mimo.sql` L97
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsDetachMirror = 1`-style filters on the precomputed flag columns (`IsDetachMirror`, `IsPI`, `MirrorType`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_mirror`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `fca.MirrorID = mr.MirrorID` | Lookup via alias `mr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `fsc.RealCID = dcu.RealCID` | Lookup via alias `dcu` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `fsc.AccountManagerID = dm.ManagerID` | Lookup via alias `dm` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `fsc.RegulationID = dr.ID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `fsc.LanguageID = dl.LanguageID` | Lookup via alias `dl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `fsc.VerificationLevelID = dv.ID` | Lookup via alias `dv` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `fsc.GuruStatusID = gs.GuruStatusID` | Lookup via alias `gs` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `fsc.AccountStatusID = ast.AccountStatusID` | Lookup via alias `ast` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `fsc.AccountTypeID = act.AccountTypeID` | Lookup via alias `act` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `fsc.PlayerStatusID = pst.PlayerStatusID` | Lookup via alias `pst` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID` | Lookup via alias `psr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID` | Lookup via alias `pssr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 1 | WeekNumberYear | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | ParentCID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 6 | ParentUserName | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 7 | MirrorTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 8 | OpenOccurred | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 9 | CloseOccurred | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 10 | RegisteredReal | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 11 | FirstDepositDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 12 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 13 | MirrorID | INT | YES | FK to Trade.Mirror (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). (Tier 1 — Trade.PositionTbl) |
| 14 | PositionID | LONG | YES | Position identifier from the source trading system. NOT a primary key of this table — defaults to 0 for non-position events, and the same PositionID appears in both open and close rows (Tier 1 — inherited from main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction). |
| 15 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 16 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 17 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 18 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 19 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 20 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 21 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 22 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 23 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 24 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 25 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 26 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 27 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 28 | CommunicationLanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 29 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 30 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 31 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredRea…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 32 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarQuarter ,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepos…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 33 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYear ,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepositDate ,Rea…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_output.bi_output_vg_date` (+1 more)) |
| 34 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,ParentCID ,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorI…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 35 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,ParentUserName ,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorID ,Positio…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 36 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,MirrorTypeID ,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorID ,PositionID ,PlayerLev…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` (+1 more)) |
| 37 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,OpenOccurred ,CloseOccurred ,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorID ,PositionID ,PlayerLevelID ,Name AS…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 38 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CloseOccurred ,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorID ,PositionID ,PlayerLevelID ,Name AS ClubTier ,Re…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 39 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,RegisteredReal ,FirstDepositDate ,RealCID ,MirrorID ,PositionID ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Nam…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+2 more)) |
| 40 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,FirstDepositDate ,RealCID ,MirrorID ,PositionID ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,fsc…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+2 more)) |
| 41 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,RealCID ,MirrorID ,PositionID ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 42 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,MirrorID ,PositionID ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS Verifica…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+2 more)) |
| 43 | CanDeposit | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PositionID ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,fsc…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+2 more)) |
| 44 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Na…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 45 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,M…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 46 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 47 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 48 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(d…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 49 | IsDetachMirror | INT | NO | `IsDetachMirror` discriminator: `ActionTypeID = 19` → set to 1 else 0. Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 50 | MoneyInMirror | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 51 | MoneyOutMirror | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS La…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 52 | CloseMirror | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,Communic…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 53 | NewMirror | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS Communicati…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 54 | MirrorType | STRING | NO | `MirrorType` discriminator: `ActionTypeID = 15`, `ActionTypeID = 16`, `ActionTypeID = 18` → set to '  ' else '    '. Formula: `,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusNam…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
... (14 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_copy_mimo   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=55 runtime=55 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 16 additional object(s)
- **Wiki coverage**: 16/16 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-06-19 | Concepts: 17 | Formulas: 55 | Tiers: 3 T1, 52 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 55/55 | Source: view_definition*
