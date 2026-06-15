---
object_fqn: main.billing.bronze_etoro_backoffice_manager
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_manager
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 18
row_count: null
generated_at: '2026-05-18T10:58:26Z'
upstreams:
- etoro.BackOffice.Manager
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md
  source_database: etoro
  source_schema: BackOffice
  source_table: Manager
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/Manager
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 18
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_manager

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.Manager`). 18 of 18 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_manager` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 18 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Dec 05 13:52:54 UTC 2022 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.Manager` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md`.

- Lake path: `Bronze/etoro/BackOffice/Manager`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.Manager`
- 18 of 18 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ManagerID | INT | YES | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the "acting staff" reference (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 1 | UserGroupID | INT | YES | Department/team assignment. FK to Dictionary.UserGroup. Determines access scope and team membership. Values: 1=Administrators, 2=Operations, 3=Risk, 4=Marketing, 5=Accounting, 6=Trading, 7=Sales/Support, 8=Account Management, 9=Sales 1, 10=Sales 2, 11-13=Account Management 1-3, 16=Local Offices (IBs), 17-30=Regional IB offices (Singapore, Brazil, Australia, etc.), 20=Support, 31=BackOffice, 32=Training, 33=Turkey, 34=MimoOps, 35=MimoApps, 36=AML. See [UserGroup](_glossary.md) for hierarchy. Largest groups: Administrators (431), Account Management (112), MimoOps (98) (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 2 | FirstName | STRING | YES | Staff member's first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + ' ' + LastName) (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 3 | LastName | STRING | YES | Staff member's last name. Combined with FirstName for display. LastName='*' indicates a functional/shared account (e.g., the generic 'support' account) (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 4 | Login | STRING | YES | Unique username for BackOffice authentication. Used as the primary lookup key in BackOffice.LogIn (case-insensitive match via LOWER()). Has unique index BMNG_LOGIN enforcing uniqueness. Maximum 20 characters. Exposed as UserName in LoadManagers and LoadManagerByUsername procedures (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 5 | Password | STRING | YES | Authentication credential. Masked in application layer with partial(0, "XXXXXXXX", 0) - all characters replaced with X when queried by non-privileged users. BackOffice.GetManager view exposes this column (legacy view used by older BackOffice app versions). NULL values indicate SSO-authenticated managers or deactivated accounts (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 6 | Email | STRING | YES | Staff member's eToro corporate email address. Used by the email notification subsystem when IsEmailNotified=1. Exposed in LoadManagers, GetManagers, and related procedures for manager roster APIs (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 7 | IsEmailNotified | BOOLEAN | YES | Controls whether this manager receives automated email notifications from BackOffice system events (e.g., deposit alerts, escalation triggers). 1=email notifications enabled, 0=email silent. Exposed in LoadManagers procedure for application-side notification routing (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 8 | IsActive | BOOLEAN | YES | Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked by BackOffice.LogIn which checks IsActive=1). BackOffice.GetManager view filters WHERE IsActive=1, hiding deactivated managers from most application queries. Do NOT physically delete manager rows - use IsActive=0 to preserve audit history. 505 active, 455 inactive in production (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 9 | IsTeamLeader | BOOLEAN | YES | Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. 30 active team leaders in production (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 10 | ForceChangePassword | BOOLEAN | YES | When set to 1, forces this manager to change their password at the next login session. Default 0 (no forced change). Used by administrators after password resets or security policy enforcement (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 11 | OverrideReplicaSettings | BOOLEAN | YES | When 1, bypasses read-replica routing for this manager's BackOffice queries, directing all reads to the primary database. Used for managers requiring real-time data accuracy (e.g., risk managers monitoring live positions). Exposed in LoadManagers and LoadManagerByUsername for application-layer routing decisions (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 12 | IsCustomerManager | BOOLEAN | YES | Indicates this manager directly manages and is responsible for a portfolio of customers. 1=customer-facing manager who appears in GetMyCustomers results. 0=back-office operations role without direct customer assignment. BackOffice.GetMyCustomers filters BackOffice.Customer WHERE ManagerID IN (@ManagerIds) - the ManagerIds parameter is the set of IsCustomerManager=1 managers. 31 active customer managers in production (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 13 | RegionalManagerID | INT | YES | Self-referential FK (no constraint defined) pointing to another Manager's ManagerID. Represents the regional manager responsible for this staff member, primarily used for IB (Introducing Broker) local offices. 951 of 960 managers have NULL (flat org structure internally). Only populated for regional office managers (UserGroupID 16-30 range) where a parent regional coordinator exists (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 14 | ManagerGroupID | INT | YES | FK to BackOffice.T_GroupsDictionary (no explicit constraint). Assigns this manager to a database connection group for multi-environment routing. When set, LoadManagerByUsername and LoadManagers also return ManagerGroupType from T_ManagerAccessGroupToConnectionStrings, which the application uses to select the appropriate connection string. 346 managers have this set (primarily MimoOps/MimoApps groups). NULL = default connection routing (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 15 | CalendlyID | STRING | YES | Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. 958 of 960 managers have this populated (default value "etoro-club" used as placeholder for system/generic accounts) (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 16 | ManagerTitleID | INT | YES | Job title classification FK to Dictionary.ManagerTitle. Values: 1=Sales Team, 2=Sales Representative, 3=Account Management Team, 4=Account Manager (note: DDL typo "Account Manger"), 5=Customer Success Agent. Exposed via GetManagers procedure. 293 managers have NULL (non-customer-facing roles: Administrators, Risk, Operations, Trading teams). Most populated: 4=Account Manager (176), 1=Sales Team (164), 3=Account Management Team (163), 2=Sales Representative (163) (Tier 1 — inherited from etoro.BackOffice.Manager). |
| 17 | eToroCID | INT | YES | The manager's own eToro customer account CID (Customer ID). Links to Customer.CustomerStatic. Many staff members are also eToro customers themselves. Exposed as CID in GetManagers procedure. 659 of 960 managers have this populated. NULL for system accounts and staff who do not have personal eToro accounts (Tier 1 — inherited from etoro.BackOffice.Manager). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.Manager` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.Manager
        │
        ▼
main.billing.bronze_etoro_backoffice_manager   ←── this object
        │
        ▼
main.bi_dealing.bi_output_dealing_tables_bi_db_h_nonpi_highaum
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| UserGroupID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| FirstName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| LastName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| Login | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| Password | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| Email | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| IsEmailNotified | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| IsTeamLeader | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| ForceChangePassword | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| OverrideReplicaSettings | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| IsCustomerManager | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| RegionalManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| ManagerGroupID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| CalendlyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| ManagerTitleID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |
| eToroCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Manager.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.Manager) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 18 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 18/18 | Source: bronze_tier1_inheritance*
