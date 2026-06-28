---
object_fqn: main.bi_output.bi_output_vg_case
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_case
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 50
row_count: null
generated_at: '2026-06-19T14:35:52Z'
upstreams:
- main.crm.silver_crm_case
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case.sql
concept_count: 2
formula_count: 49
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 49
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 1
---

# bi_output_vg_case

> View in `main.bi_output`. 2 business concept(s) in §2; 49 of 50 columns documented from anchored evidence; 1 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_case` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 50 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Jan 21 15:49:28 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_case` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.crm.silver_crm_case` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`).

Of its 50 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 49 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsDuplicate` discriminator: `Origin = '    '`, `Status = '      '` → set to 1 else 0
**What**: Computed flag on `IsDuplicate` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsDuplicate`
**Rules**:
- `Origin = '    '`
- `Status = '      '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case.sql` bi_output.sql L42-L42
**Source(s)**: `main.crm.silver_crm_case`

### 2.2 `ChatSkill` discriminator: `Original_Skillset__c LIKE '    '`, `Original_Skillset__c LIKE '                 '`, `Original_Skillset__c LIKE '                    '` → set to '                 ' else '     '
**What**: Computed flag on `ChatSkill` set to `'                 '` when the predicates below hold, else `'     '`.
**Columns Involved**: `ChatSkill`
**Rules**:
- `Original_Skillset__c LIKE '    '`
- `Original_Skillset__c LIKE '                 '`
- `Original_Skillset__c LIKE '                    '`
- `Original_Skillset__c LIKE '             '`
- `Original_Skillset__c LIKE '        '`
- `Original_Skillset__c LIKE '      '`
- `Original_Skillset__c LIKE '         '`
- `Original_Skillset__c LIKE '             '`
- `Original_Skillset__c LIKE '                    '`
- `Original_Skillset__c LIKE '           '`
- `Original_Skillset__c LIKE '              '`
- `Original_Skillset__c LIKE '    '`
- `Original_Skillset__c LIKE '        '`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_case.sql` bi_output.sql L54-L69
**Source(s)**: `main.crm.silver_crm_case`

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
| Filter on discriminator flags | Use `ChatSkill = 1`-style filters on the precomputed flag columns (`ChatSkill`, `IsDuplicate`) instead of recomputing the underlying CASE predicates downstream. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CaseNumber | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_case -- Captured: 2026-05-19T14…`. (Tier 2 — computed in source) |
| 1 | CaseID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 2 | CreatedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 3 | CreatedById | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 4 | LastModifiedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 5 | LastModifiedByID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 6 | OwnerID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 7 | OwnerCSDesk | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 8 | OwnerSubRole | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 9 | OwnerTeam | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 10 | AccountID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 11 | RealCID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 12 | Origin | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 13 | CurrentStatus | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 14 | Priority | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 15 | Subject | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 16 | Description | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 17 | IsClosedOnCreate | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 18 | Product | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 19 | CASS_Impact | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 20 | AML_status | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 21 | Type | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 22 | SubType | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 23 | SubType2 | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 24 | NumberOfTouches | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 25 | NumberOfOutboundEmailMessages | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 26 | NumberOfIncomingEmailMessages | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 27 | NumberOfInternalCaseComments | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 28 | IsReopened | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 29 | IsPP_Report | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 30 | IsPlatform | STRING | YES | Computed in source (transform kind not classified). Formula: `,Id AS CaseID ,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 31 | Phase | STRING | YES | Computed in source (transform kind not classified). Formula: `,CreatedDate AS CreatedDate ,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID ,Owner_CS_Desk__c …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 32 | DepositID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CreatedById AS CreatedById ,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID ,Owner_CS_Desk__c AS OwnerCSDesk ,Owner_Sub_Ro…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 33 | WithdrawalID | STRING | YES | Computed in source (transform kind not classified). Formula: `,LastModifiedDate AS LastModifiedDate ,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID ,Owner_CS_Desk__c AS OwnerCSDesk ,Owner_Sub_Role__c AS OwnerSubRole ,Owner…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 34 | ServiceLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,LastModifiedById AS LastModifiedByID ,OwnerId AS OwnerID ,Owner_CS_Desk__c AS OwnerCSDesk ,Owner_Sub_Role__c AS OwnerSubRole ,Owner_Team__c AS OwnerTeam ,AccountId AS Ac…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 35 | IsDuplicate | INT | NO | `IsDuplicate` discriminator: `Origin = '    '`, `Status = '      '` → set to 1 else 0. Formula: `,OwnerId AS OwnerID ,Owner_CS_Desk__c AS OwnerCSDesk ,Owner_Sub_Role__c AS OwnerSubRole ,Owner_Team__c AS OwnerTeam ,AccountId AS AccountID ,CID__c AS RealCID ,Orig…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 36 | IsOneTouch | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Owner_CS_Desk__c AS OwnerCSDesk ,Owner_Sub_Role__c AS OwnerSubRole ,Owner_Team__c AS OwnerTeam ,AccountId AS AccountID ,CID__c AS RealCID ,Origin AS Origin ,Status…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 37 | ClosedByAutomation | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Owner_Sub_Role__c AS OwnerSubRole ,Owner_Team__c AS OwnerTeam ,AccountId AS AccountID ,CID__c AS RealCID ,Origin AS Origin ,Status AS CurrentStatus ,Priority AS Pr…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 38 | UpdatedByAutomaticProcess | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Owner_Team__c AS OwnerTeam ,AccountId AS AccountID ,CID__c AS RealCID ,Origin AS Origin ,Status AS CurrentStatus ,Priority AS Priority ,Subject AS Subject ,D…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 39 | InternalCase | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,AccountId AS AccountID ,CID__c AS RealCID ,Origin AS Origin ,Status AS CurrentStatus ,Priority AS Priority ,Subject AS Subject ,Description AS Description ,I…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 40 | EscalatedBy | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS RealCID ,Origin AS Origin ,Status AS CurrentStatus ,Priority AS Priority ,Subject AS Subject ,Description AS Description ,IsClosedOnCreate AS IsClosedOnC…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 41 | EscalationStatus | STRING | YES | Computed in source (transform kind not classified). Formula: `,Origin AS Origin ,Status AS CurrentStatus ,Priority AS Priority ,Subject AS Subject ,Description AS Description ,IsClosedOnCreate AS IsClosedOnCreate ,Product__c A…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 42 | EscalationDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Status AS CurrentStatus ,Priority AS Priority ,Subject AS Subject ,Description AS Description ,IsClosedOnCreate AS IsClosedOnCreate ,Product__c AS Product ,CASS_Im…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 43 | EscalatedByBot | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Priority AS Priority ,Subject AS Subject ,Description AS Description ,IsClosedOnCreate AS IsClosedOnCreate ,Product__c AS Product ,CASS_Impact__c AS CASS_Impact ,A…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 44 | FinalEscalationResponseDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Subject AS Subject ,Description AS Description ,IsClosedOnCreate AS IsClosedOnCreate ,Product__c AS Product ,CASS_Impact__c AS CASS_Impact ,AML_Status__c as AML_status …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 45 | IsEscalated | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Description AS Description ,IsClosedOnCreate AS IsClosedOnCreate ,Product__c AS Product ,CASS_Impact__c AS CASS_Impact ,AML_Status__c as AML_status ,Type__c AS Type …`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 46 | ElapsedTimeFromEscalation | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,IsClosedOnCreate AS IsClosedOnCreate ,Product__c AS Product ,CASS_Impact__c AS CASS_Impact ,AML_Status__c as AML_status ,Type__c AS Type ,Sub_Type__c AS SubType ,S…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 47 | FirstResponseDateTime | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Product__c AS Product ,CASS_Impact__c AS CASS_Impact ,AML_Status__c as AML_status ,Type__c AS Type ,Sub_Type__c AS SubType ,Sub_Type_2__c AS SubType2 ,Number_of_to…`. (Tier 2 — from `main.crm.silver_crm_case`) |
| 48 | ClosedDate | TIMESTAMP | YES | Transform `passthrough` for column `ClosedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 49 | ChatSkill | STRING | NO | `ChatSkill` discriminator: `Original_Skillset__c LIKE '    '`, `Original_Skillset__c LIKE '                 '`, `Original_Skillset__c LIKE '                    '` → set to '                 ' else '     '. Formula: `,Withdrawal_ID__c AS WithdrawalID ,Service_Language__c AS ServiceLanguage ,CASE WHEN Duplicate__c = true and Origin = 'Chat' and Status = 'Closed' THEN 1 else 0 END AS IsDuplicate ,O…`. (Tier 2 — from `main.crm.silver_crm_case`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.crm.silver_crm_case` | Primary | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.crm.silver_crm_case
        │
        ▼
main.bi_output.bi_output_vg_case   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=50 runtime=50 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.crm.silver_crm_case` (wiki: `(no wiki)`)

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

*Generated: 2026-06-19 | Concepts: 2 | Formulas: 49 | Tiers: 0 T1, 49 T2, 0 T3, 0 T4, 0 T5, 0 TN, 1 U | Elements: 50/50 | Source: view_definition*
