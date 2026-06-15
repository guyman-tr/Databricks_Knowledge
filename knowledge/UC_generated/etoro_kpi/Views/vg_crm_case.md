---
object_fqn: main.etoro_kpi.vg_crm_case
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_crm_case
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 57
row_count: null
generated_at: '2026-05-19T15:20:43Z'
upstreams:
- main.crm.silver_crm_case
- main.crm.gold_crm_case_tiny_for_genie
- main.crm.gold_crm_web_chat_sessions
- main.crm.gold_crm_bot_eligible_chats
- main.crm.gold_crm_case_deescalation
- main.bi_output.bi_output_vg_case_event
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql
concept_count: 8
formula_count: 49
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 49
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 8
---

# vg_crm_case

> View in `main.etoro_kpi`. 8 business concept(s) in §2; 49 of 57 columns documented from anchored evidence; 8 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_crm_case` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | katyfr@etoro.com |
| **Row count** | n/a |
| **Column count** | 57 |
| **Concepts** | 8 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 17 14:13:35 UTC 2026 |

---

## 1. Business Meaning

`vg_crm_case` is a view in `main.etoro_kpi` that composes 5 CASE-based classifier flag(s) computed from upstream IDs, 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.crm.silver_crm_case` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 5 object(s), listed in §5 Lineage.

Of its 57 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 49 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `BotPlatform` computed flag
**What**: Computed flag on `BotPlatform` set to `'        '` when the predicates below hold, else `None`.
**Columns Involved**: `BotPlatform`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` etoro_kpi.sql L12-L15

### 2.2 `IsEscalated` discriminator: `Case_Owner_Title__c <> '   '` → set to 1 else 0
**What**: Computed flag on `IsEscalated` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsEscalated`
**Rules**:
- `Case_Owner_Title__c <> '   '`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` etoro_kpi.sql L110-L113

### 2.3 `CS_OPS` computed flag
**What**: Computed flag on `CS_OPS` set to `'  '` when the predicates below hold, else `'   '`.
**Columns Involved**: `CS_OPS`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` etoro_kpi.sql L116-L116

### 2.4 `IsDeflected` computed flag
**What**: Computed flag on `IsDeflected` set to `0` when the predicates below hold, else `1`.
**Columns Involved**: `IsDeflected`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` etoro_kpi.sql L117-L117
**Source(s)**: `main.crm.gold_crm_case_tiny_for_genie`, `main.crm.gold_crm_web_chat_sessions`, `main.crm.gold_crm_bot_eligible_chats`

### 2.5 `IsDeEscalated` computed flag
**What**: Computed flag on `IsDeEscalated` set to `0` when the predicates below hold, else `1`.
**Columns Involved**: `IsDeEscalated`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` etoro_kpi.sql L118-L118
**Source(s)**: `main.crm.gold_crm_case_deescalation`

### 2.6 Filter on scope `DeEscalation`: `RN = 1`; `IsDeEscalation = 0`
**What**: `WHERE` clause at the top of scope `DeEscalation` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `RN`, `IsDeEscalation`
**Rules**:
- `RN = 1`
- `IsDeEscalation = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` L50

### 2.7 Filter on scope `Solved`: `EventType = '             '`; `NewStatus = '      '`
**What**: `WHERE` clause at the top of scope `Solved` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `EventType`, `NewStatus`
**Rules**:
- `EventType = '             '`
- `NewStatus = '      '`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` L59

### 2.8 State + timestamp pair
**What**: Column-name pattern group (Is* + *Date): these columns work together as a unit. Treat them together when filtering or aggregating.
**Columns Involved**: `IsSolved`, `SolvedDate`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_crm_case.sql` uc_inventory.json

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
| Filter on discriminator flags | Use `BotPlatform = 1`-style filters on the precomputed flag columns (`BotPlatform`, `CS_OPS`, `IsDeEscalated`, `IsDeflected`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `DeEscalation` applies `RN = 1`; `IsDeEscalation = 0` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `Solved` applies `EventType = '             '`; `NewStatus = '      '` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CaseID | STRING | YES | Direct passthrough from upstream. Formula: `Case_Id_18__c`. (Tier 2 — from `main.crm.gold_crm_case_tiny_for_genie`) |
| 1 | CID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c`. (Tier 2 — literal) |
| 2 | CreatedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `WHERE CID__c = CID__c AND Category__c = Category__c AND CreatedDate > CreatedDate`. (Tier 2 — from `main.crm.gold_crm_case_tiny_for_genie`) |
| 3 | CaseNumber | STRING | YES | Transform `passthrough` for column `CaseNumber` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | Status | STRING | YES | Transform `passthrough` for column `Status` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | Origin | STRING | YES | Transform `passthrough` for column `Origin` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | Subject | STRING | YES | Transform `passthrough` for column `Subject` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | Priority | STRING | YES | Transform `passthrough` for column `Priority` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | OwnerId | STRING | YES | Transform `passthrough` for column `OwnerId` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | CaseOwnerTitle | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 10 | IsSolved | BOOLEAN | YES | State + timestamp pair. Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 11 | ClosedDate | TIMESTAMP | YES | Transform `passthrough` for column `ClosedDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | IsClosedOnCreate | BOOLEAN | YES | Transform `passthrough` for column `IsClosedOnCreate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | ServiceLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 14 | Product | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 15 | Category | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 16 | CaseType | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 17 | SubType | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 18 | SubType2 | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 19 | WithdrawalID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 20 | DepositID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 21 | PositionID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 22 | MirrorID | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 23 | Phase | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 24 | IsOfficialComplaint | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 25 | IsReOpened | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 26 | CaseCreatedByRole | STRING | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 27 | IncomingEmailCount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 28 | OutboundEmailCount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 29 | InternalCommentCount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 30 | FirstResponseDateTime | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,CID__c AS CID ,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c …`. (Tier 2 — literal) |
| 31 | TimeToFirstResponse | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CreatedDate ,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c …`. (Tier 2 — literal) |
| 32 | ResolutionTimeFromFirstResponse | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CaseNumber ,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsS…`. (Tier 2 — literal) |
| 33 | TotalTimeToResolve | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Status ,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,Close…`. (Tier 2 — literal) |
| 34 | TouchCount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Origin ,Subject ,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,ClosedDate ,I…`. (Tier 2 — literal) |
| 35 | TechnicalRefund | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Subject ,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,ClosedDate ,IsClosedOnCreat…`. (Tier 2 — literal) |
| 36 | OwnerSubRole | STRING | YES | Computed in source (transform kind not classified). Formula: `,Priority ,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,ClosedDate ,IsClosedOnCreate ,Servic…`. (Tier 2 — literal) |
| 37 | JiraID | STRING | YES | Computed in source (transform kind not classified). Formula: `,OwnerId ,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,ClosedDate ,IsClosedOnCreate ,Service_Language__c …`. (Tier 2 — literal) |
| 38 | GoodwillGesture | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Case_Owner_Title__c AS CaseOwnerTitle ,Solved__c AS IsSolved ,ClosedDate ,IsClosedOnCreate ,Service_Language__c …`. (Tier 2 — literal) |
| 39 | AMLState | STRING | YES | Computed in source (transform kind not classified). Formula: `,Solved__c AS IsSolved ,ClosedDate ,IsClosedOnCreate ,Service_Language__c AS ServiceLanguage ,Product__c …`. (Tier 2 — literal) |
| 40 | QCSurvey | STRING | YES | Computed in source (transform kind not classified). Formula: `,ClosedDate ,IsClosedOnCreate ,Service_Language__c AS ServiceLanguage ,Product__c AS Product ,Category__c …`. (Tier 2 — literal) |
| 41 | CaseSkillSet | STRING | YES | Computed in source (transform kind not classified). Formula: `,IsClosedOnCreate ,Service_Language__c AS ServiceLanguage ,Product__c AS Product ,Category__c AS Category …`. (Tier 2 — literal) |
| 42 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,Service_Language__c AS ServiceLanguage ,Product__c AS Product ,Category__c AS Category ,Type__c …`. (Tier 2 — literal) |
| 43 | ClubLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,Product__c AS Product ,Category__c AS Category ,Type__c AS CaseType ,Sub_Type__c …`. (Tier 2 — literal) |
| 44 | EscalatedBy | STRING | YES | Computed in source (transform kind not classified). Formula: `,Category__c AS Category ,Type__c AS CaseType ,Sub_Type__c AS SubType ,Sub_Type_2__c …`. (Tier 2 — literal) |
| 45 | EscalationDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Type__c AS CaseType ,Sub_Type__c AS SubType ,Sub_Type_2__c AS SubType2 ,Withdrawal_ID__c …`. (Tier 2 — literal) |
| 46 | IsEscalated | INT | NO | `IsEscalated` discriminator: `Case_Owner_Title__c <> '   '` → set to 1 else 0. Formula: `,Deposit_ID__c AS DepositID ,Position_ID__c AS PositionID ,Mirror_ID__c AS MirrorID ,Phase__c …`. (Tier 2 — literal) |
| 47 | EscalationStatus | STRING | YES | Computed in source (transform kind not classified). Formula: `,Position_ID__c AS PositionID ,Mirror_ID__c AS MirrorID ,Phase__c AS Phase ,Official_Complaint__c …`. (Tier 2 — literal) |
| 48 | FinalEscalationResponseDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Mirror_ID__c AS MirrorID ,Phase__c AS Phase ,Official_Complaint__c AS IsOfficialComplaint ,Re_Opened__c …`. (Tier 2 — literal) |
| 49 | CS_OPS | STRING | NO | `CS_OPS` computed flag. Formula: `,Phase__c AS Phase ,Official_Complaint__c AS IsOfficialComplaint ,Re_Opened__c AS IsReOpened ,Case_Created_By_Ro…`. (Tier 2 — literal) |
| 50 | IsDeflected | INT | NO | `IsDeflected` computed flag. Formula: `,Official_Complaint__c AS IsOfficialComplaint ,Re_Opened__c AS IsReOpened ,Case_Created_By_Role__c AS CaseCreatedByRole ,Number…`. (Tier 2 — literal) |
| 51 | IsDeEscalated | INT | NO | `IsDeEscalated` computed flag. Formula: `,Re_Opened__c AS IsReOpened ,Case_Created_By_Role__c AS CaseCreatedByRole ,Number_of_Incoming_Email_Messages__c AS IncomingEmailCount ,Number_…`. (Tier 2 — literal) |
| 52 | ClosedBy | STRING | YES | Computed in source (transform kind not classified). Formula: `,Case_Created_By_Role__c AS CaseCreatedByRole ,Number_of_Incoming_Email_Messages__c AS IncomingEmailCount ,Number_of_Outbound_Email_Messages__c AS OutboundEmailCount …`. (Tier 2 — literal) |
| 53 | EventID | STRING | YES | Computed in source (transform kind not classified). Formula: `,Number_of_Incoming_Email_Messages__c AS IncomingEmailCount ,Number_of_Outbound_Email_Messages__c AS OutboundEmailCount ,Number_of_Internal_Case_Comments__c AS InternalCommentCount …`. (Tier 2 — literal) |
| 54 | DoneBy | STRING | YES | Computed in source (transform kind not classified). Formula: `,Number_of_Outbound_Email_Messages__c AS OutboundEmailCount ,Number_of_Internal_Case_Comments__c AS InternalCommentCount ,X1st_Response_Date_Time__c AS FirstResponseDateTime …`. (Tier 2 — literal) |
| 55 | Touches | LONG | YES | Computed in source (transform kind not classified). Formula: `,Number_of_Internal_Case_Comments__c AS InternalCommentCount ,X1st_Response_Date_Time__c AS FirstResponseDateTime ,Time_to_1st_Response__c AS TimeToFirstResponse…`. (Tier 2 — literal) |
| 56 | SolvedDate | STRING | YES | State + timestamp pair. Formula: `,X1st_Response_Date_Time__c AS FirstResponseDateTime ,Time_to_1st_Response__c AS TimeToFirstResponse ,Resolution_Time_From_1st_Response__c AS ResolutionTimeFromFi…`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.crm.silver_crm_case` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.crm.gold_crm_case_tiny_for_genie` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.crm.gold_crm_web_chat_sessions` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.crm.gold_crm_bot_eligible_chats` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.crm.gold_crm_case_deescalation` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_output.bi_output_vg_case_event` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_case_event.md` |

### 5.2 Pipeline ASCII Diagram

```
main.crm.silver_crm_case
main.crm.gold_crm_case_tiny_for_genie
main.crm.gold_crm_web_chat_sessions
... (3 more upstream(s))
        │
        ▼
main.etoro_kpi.vg_crm_case   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=57 runtime=57 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.crm.silver_crm_case` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 5 additional object(s)
- **Wiki coverage**: 1/5 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 8 | Formulas: 49 | Tiers: 0 T1, 49 T2, 0 T3, 0 T4, 0 T5, 0 TN, 8 U | Elements: 57/57 | Source: view_definition*
