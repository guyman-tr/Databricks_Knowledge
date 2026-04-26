# BI_DB_dbo.BI_DB_AML_SubEntity_Categorization

> 2.11M-row daily snapshot table classifying every verified depositor customer into one or more AML sub-entities (eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta) based on their KYC country, regulation, and eToro Money account type. Rebuilt daily via TRUNCATE+INSERT from DWH_dbo dimensions and eMoney account data. Last updated 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation + eMoney_dbo.eMoney_Dim_Account via SP_AML_SubEntity_Categorization |
| **Refresh** | Daily (SB_Daily, Priority 20). TRUNCATE + INSERT — full rebuild every run. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Copy Strategy** | Override (full daily replace) |
| **Business Group** | compliance |

---

## 1. Business Meaning

`BI_DB_AML_SubEntity_Categorization` is the canonical AML sub-entity classification table for eToro's regulated entity structure. Each row represents one verified depositor customer (VerificationLevelID ≥ 2, IsDepositor = 1, IsValidCustomer = 1) and records which eToro legal sub-entities are responsible for their AML oversight.

The `AML_Sub_Entity` column contains a comma-separated string of applicable labels:
- **eToro_Germany** — CySEC-regulated customer in Germany with a crypto wallet or real crypto positions
- **eToro_Gibraltar** — Customer in any non-Germany country under CySEC/FCA/ASIC/ASIC&GAML/FSA Seychelles with a crypto wallet
- **eToro_Money_UK** — CySEC/FCA customer with a UK Card or IBAN eToro Money account
- **eToro_Money_Malta** — CySEC customer with an EU IBAN eToro Money account in an EU/EEA country, fully KYC-verified (VerLevel=3)

A single customer can qualify for multiple sub-entities (2.11M rows total; 334,000+ rows have multi-entity assignments). The table is fully rebuilt daily — no incremental updates.

As of 2026-04-13: 966K customers assigned to eToro_Money_Malta alone, 460K to eToro_Money_UK, 234K to eToro_Gibraltar, 109K to eToro_Germany. Regulation split: CySEC (66%), FCA (31%), FSA Seychelles (1.5%), ASIC&GAML (1.3%), ASIC (0.2%). Nearly all rows (99.999%) have VerificationLevelID=3 (fully verified); 17 rows at level 2.

The table is consumed by `SP_AML_Terror_Monitor_Dashboard` and `SP_M_AML_Report` for compliance monitoring and AML reporting workflows.

---

## 2. Business Logic

### 2.1 eToro Germany Population

**What**: Identifies CySEC-regulated customers resident in Germany who hold crypto assets.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- KYC country = Germany (Dim_Country.CountryID = 79)
- RegulationID = 1 (CySEC)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1
- PLUS: HasWallet = 1 OR had real crypto positions (InstrumentTypeID=10, IsSettled=1) as of yesterday

### 2.2 eToro Gibraltar Population

**What**: Customers with crypto wallets outside Germany, under major regulations.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- KYC country ≠ Germany (CountryID ≠ 79)
- RegulationID IN (1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1, HasWallet = 1

### 2.3 eToro Money UK Population

**What**: Customers with an active UK eToro Money account (Card UK or IBAN UK).
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- RegulationID IN (1=CySEC, 2=FCA)
- IsValidCustomer = 1, VerificationLevelID ≥ 2, IsDepositor = 1
- Card UK path: eMoney_Dim_Account.AccountSubProgramID IN (1=Card Premium UK, 2=Card Standard UK) AND CardID IS NOT NULL AND UK country (CountryID=218)
- IBAN UK path: eMoney_Dim_Account.AccountSubProgramID IN (3, 4, 8) — any country eligible

### 2.4 eToro Money Malta Population

**What**: Customers with an EU IBAN eToro Money account who are fully KYC-verified EU/EEA residents.
**Columns Involved**: CID, CountryID, RegulationID, AML_Sub_Entity
**Rules**:
- RegulationID = 1 (CySEC only)
- VerificationLevelID = 3 (fully verified — stricter than other populations)
- IsDepositor = 1
- eMoney_Dim_Account.AccountSubProgramID IN (5, 6, 7, 9) — EU IBAN programs
- KYC country must be in the EEA/EU hardcoded list (37 country IDs)

### 2.5 Multi-Entity Dedup and STRING_AGG

**What**: A customer can qualify for multiple sub-entities simultaneously.
**Columns Involved**: AML_Sub_Entity
**Rules**:
- All 4 populations are UNIONed into #finaltbl
- ROW_NUMBER() dedup by CID picks the row with the longest combined entity label string (most qualifying entities)
- STRING_AGG(AMLValue, ', ') concatenates all applicable sub-entity labels into a comma-separated string
- A CID can appear as e.g. "eToro_Germany, eToro_Money_Malta" if they qualify for both

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED INDEX(CID ASC). Efficient for CID-level lookups and JOINs to other HASH(CID) tables (Dim_Customer, BI_DB_CID_Daily_NWA, etc.). No partitioning — the full 2.11M rows are always current (single daily snapshot).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "Which sub-entity does customer X belong to?" | `SELECT AML_Sub_Entity FROM BI_DB_AML_SubEntity_Categorization WHERE CID = @cid` |
| "All customers in eToro_Germany?" | `WHERE AML_Sub_Entity LIKE '%eToro_Germany%'` (LIKE because multi-valued CSV) |
| "Count per sub-entity?" | `SELECT AML_Sub_Entity, COUNT(*) FROM … GROUP BY AML_Sub_Entity` (counts combinations, not individual entities) |
| "All eToro Money Malta customers under FCA?" | `WHERE AML_Sub_Entity LIKE '%eToro_Money_Malta%' AND RegulationID = 2` — NOTE: FCA is not eligible for Malta per SP logic; result will be 0. Use CySEC (1). |
| "Get country + regulation for AML report?" | JOIN to Dim_Country on CountryID, Dim_Regulation on RegulationID for enriched decode |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `AML.CID = dc.RealCID` | Enrich with customer demographics |
| DWH_dbo.Dim_Country | `AML.CountryID = dc.CountryID` | Country name decode |
| DWH_dbo.Dim_Regulation | `AML.RegulationID = dr.DWHRegulationID` | Regulation name decode |
| BI_DB_dbo.BI_DB_PositionPnL | `AML.CID = pnl.CID` | Cross-reference with position P&L |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | `AML.CID = ch.CID` | AML status change history |

### 3.4 Gotchas

- **AML_Sub_Entity is a multi-value CSV string** — do NOT use `= 'eToro_Germany'` for filtering; use `LIKE '%eToro_Germany%'`. This pattern is non-trivial to aggregate accurately.
- **Not a universe of all customers** — only verified (VerLevel≥2) depositors with active eToro Money or crypto wallet holdings qualify. Silent exclusion of unverified, non-depositors, and TP-only customers.
- **eToro_Money_Malta requires VerLevel=3 only** — the other three populations accept VerLevel≥2 (includes level 2). This is a data quality distinction: most customers qualify at level 3.
- **Germany population dual-criteria**: HasWallet OR RealCrypto. Both paths produce label "eToro_Germany" — the sub-entity label does not distinguish which criterion triggered.
- **Full rebuild daily** — UpdateDate is the same for all rows in a given day's run (confirmed: all 2.11M rows have UpdateDate 2026-04-13 04:05:57). Do not use UpdateDate for change tracking.
- **AML_Sub_Entity can be NULL** — if a CID qualifies under a population where all entity labels (AMLSubEntity, AMLEntity, AMLSubEntity_2) are NULL (edge case). Filter `WHERE AML_Sub_Entity IS NOT NULL` when needed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description copied verbatim from upstream wiki (DWH_dbo.Dim_Customer or production source) |
| **Tier 2** | Derived from SP code analysis or DWH-layer ETL logic |
| **Tier 3** | Inferred from data patterns and context; no SP confirmation |
| **Tier 4** | Best available knowledge; limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer (RealCID). (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer via Dim_Country.DWHCountryID=CountryID identity. (Tier 1 — Customer.CustomerStatic) |
| 4 | Country | varchar(50) | NO | Country name, denormalized from DWH_dbo.Dim_Country.Name. Matches CountryID. Included to avoid join in downstream AML reports. (Tier 2 — SP_AML_SubEntity_Categorization) |
| 5 | RegulationID | tinyint | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. In this table: 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML only (other regulations are excluded by SP eligibility criteria). (Tier 1 — BackOffice.Customer) |
| 6 | Regulation | varchar(50) | YES | Regulation name, denormalized from DWH_dbo.Dim_Regulation.Name. Matches RegulationID. (Tier 2 — SP_AML_SubEntity_Categorization) |
| 7 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. All rows share the same timestamp per daily run (single TRUNCATE+INSERT batch). (Tier 2 — SP_AML_SubEntity_Categorization) |
| 8 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Only VerLevel≥2 customers are in this table; 99.999% are VerLevel=3. (Tier 1 — BackOffice.Customer) |
| 9 | AML_Sub_Entity | nvarchar(max) | YES | ETL-computed comma-separated list of eToro AML sub-entities this customer qualifies for. Possible values (may be combined): eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta. NULL if no entity label applies. Use LIKE '%value%' for filtering. (Tier 2 — SP_AML_SubEntity_Categorization) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough (DWHCountryID=CountryID) |
| Country | DWH_dbo.Dim_Country | Name | Denormalized join |
| RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Denormalized join |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| AML_Sub_Entity | DWH_dbo.Dim_Customer + eMoney_dbo.eMoney_Dim_Account | Multiple fields | STRING_AGG of 4 population labels |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (RealCID, GCID, CountryID, RegulationID, VerificationLevelID, HasWallet, IsValidCustomer, IsDepositor)
DWH_dbo.Dim_Country  (CountryID, Name — for Germany=79, EEA list, UK=218)
DWH_dbo.Dim_Regulation (Name)
DWH_dbo.Dim_Instrument (InstrumentTypeID=10 for crypto check)
BI_DB_dbo.BI_DB_PositionPnL (RealCrypto position check for Germany population)
eMoney_dbo.eMoney_Dim_Account (AccountSubProgramID for UK Card/IBAN, EU IBAN Malta)
  |
  |-- SP_AML_SubEntity_Categorization ---|
  |   Step 01-03: #germany03 (eToro_Germany — CySEC+Germany+crypto)
  |   Step 04:    #gibraltar01 (eToro_Gibraltar — non-Germany+wallet+major regs)
  |   Step 05-06: #etoromoney02 (eToro_Money_UK — CySEC/FCA+UK card/IBAN)
  |   Step 07-08: #etoromalta02 (eToro_Money_Malta — CySEC+EU IBAN+EEA country)
  |   Step 10:    #finaltbl (UNION all 4 populations)
  |   Step 11:    #finaltbl2 ROW_NUMBER dedup by CID (keep max-label-length row)
  |   Step 12:    #finaltbl4 STRING_AGG → AML_Sub_Entity
  |   Step 13:    TRUNCATE BI_DB_AML_SubEntity_Categorization
  |   Step 14:    INSERT INTO target (2.11M rows)
  v
BI_DB_dbo.BI_DB_AML_SubEntity_Categorization (2.11M rows, daily TRUNCATE+INSERT)
  |
  |-- Generic Pipeline (Override, delta, daily, 1440 min) ---|
  v
compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension — source of CID, GCID, CountryID, RegulationID, VerificationLevelID |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country dimension — source of Country name |
| RegulationID | DWH_dbo.Dim_Regulation.DWHRegulationID | Regulation dimension — source of Regulation name |
| (AML filter) | BI_DB_dbo.BI_DB_PositionPnL.CID | Crypto position check for Germany population |
| (eMoney) | eMoney_dbo.eMoney_Dim_Account.CID | eMoney account sub-program lookup for UK/Malta populations |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard | Reads AML_Sub_Entity for AML terrorism monitoring dashboard |
| BI_DB_dbo.SP_M_AML_Report | Reads AML_Sub_Entity for monthly AML reporting |

---

## 7. Sample Queries

### All eToro Money UK customers under FCA regulation

```sql
SELECT CID, GCID, Country, Regulation, AML_Sub_Entity
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization]
WHERE AML_Sub_Entity LIKE '%eToro_Money_UK%'
  AND RegulationID = 2  -- FCA
ORDER BY CID;
```

### Sub-entity count distribution

```sql
SELECT AML_Sub_Entity, COUNT(*) AS customer_count
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization]
GROUP BY AML_Sub_Entity
ORDER BY customer_count DESC;
```

### Germany + Malta dual-entity customers

```sql
SELECT sc.CID, sc.Country, sc.AML_Sub_Entity
FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization] sc
WHERE sc.AML_Sub_Entity LIKE '%eToro_Germany%'
  AND sc.AML_Sub_Entity LIKE '%eToro_Money_Malta%'
ORDER BY sc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped — AML sub-entity classification logic is fully captured in SP_AML_SubEntity_Categorization code and DWH dimension wikis). The four entity classifications (Germany, Gibraltar, Money UK, Money Malta) align with eToro's regulated entity structure for crypto AML oversight.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14 (P10 Jira skipped)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 | Elements: 9/9 | Logic: 5 subsections*
*Object: BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | Type: Table | Production Source: DWH_dbo.Dim_Customer + eMoney_dbo.eMoney_Dim_Account via SP_AML_SubEntity_Categorization*
