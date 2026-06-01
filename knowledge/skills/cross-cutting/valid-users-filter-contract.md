---
name: cross-cutting
description: "Omni-filter. Every business aggregate, always, silently applies IsValidCustomer = 1 via an SCD-2 walk on V_Fact_SnapshotCustomer_FromDateID joined with DateID BETWEEN snap.FromDateID AND snap.ToDateID — period-correct (a customer who was valid in 2024 but isn't now is counted in 2024 revenue and dropped from 2026 revenue, automatically). The default filter excludes accounts where PlayerLevel='Internal' (PlayerLevelID=4 per Dim_PlayerLevel), Label IN ('Dealing','ILQ') (LabelID IN (30,26) per Dim_Label), or Country='eToro' (CountryID=250 per Dim_Country, the internal pseudo-jurisdiction). Popular Investors are valid customers (tracked by GuruStatusID, not PlayerLevelID — do NOT assert otherwise). Two opt-ins, EXPLICIT user request only, no trigger-word heuristics: (a) regulatory variant — switch to IsCreditReportValidCB only when the user literally says 'CB valid' or 'Client Balance valid' or 'credit-report valid'; (b) opt-out — skip the filter only when the user literally says 'include non-valids' / 'include internals' / 'include etorians' / 'include test accounts' / 'unfiltered'. Present-state Dim_Customer is the fallback only for 'today / right now / currently' questions. Every numeric output ends with a one-line scope footer. Never pre-flight a question. Physical column is IsValidCustomer; IsValidUser is the colloquial alias."
triggers:
  - IsValidCustomer
  - IsValidUser
  - IsCreditReportValidCB
  - valid users
  - valid customers
  - test accounts
  - internal accounts
  - etorians
  - CB valid
  - Client Balance valid
  - credit-report valid
  - period-correct
  - scope footer
  - filter contract
required_tables:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
sample_questions:
  - "Total trading revenue YTD"
  - "Net deposits last month by country"
  - "Customer balances last month, CB valid"
  - "How many valid customers right now"
  - "Include test accounts in row count for a data-quality check"
domain_tags:
  - shared
  - contract
  - filter
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-13"
---

# Valid-Users Filter Contract (cross-cutting)

Omni-filter. Every per-customer numeric aggregate. Silent. No pre-flight question. No trigger-word heuristics — the only way Rule 1 changes is an EXPLICIT user request.

## When to Use

Apply on every per-customer aggregate. The two opt-ins below fire only on the user's literal words; do not infer them from question topic.

## Scope

In scope: the default SCD-2 walk + `IsValidCustomer` omni-filter, two explicit opt-ins (regulatory variant `IsCreditReportValidCB`; opt-out for unfiltered), the present-state `Dim_Customer` fallback for "right now" questions, the mandatory output-footer wording, two SQL patterns.
Out of scope: `customer_exclude_list` (funnel-scoped — a valid user with revenue is counted even if they sit on the exclude list; the list is for onboarding-funnel population only, owned by `registration-to-ftd-funnel`), `Dim_Customer` column dictionaries (`customer-master-record.md`), SCD-2 mechanic deep-dive (`identity-jurisdiction-and-regulation.md`), per-table pre-filter inventory (deferred — separate spec).
Last verified: 2026-05-13

## Critical Warnings

1. **Tier 1 — Default is SCD-2, NOT current-state.** Almost every question is a period, not "today". Joining to current-state `Dim_Customer` silently applies today's validity to a historical period — a user who was valid in 2024 but isn't now gets dropped from 2024 revenue. Wrong number, silently. Always walk `V_Fact_SnapshotCustomer_FromDateID` with `fact.DateID BETWEEN snap.FromDateID AND snap.ToDateID`. Present-state `Dim_Customer` is the fallback only when the user explicitly says "today / current / right now".
2. **Tier 1 — Silent enforcement + mandatory footer.** Never ask "valid or all?" — apply the rule, disclose the scope in a one-line footer. The footer is what makes the silent default safe.
3. **Tier 1 — No trigger-word heuristics.** Do NOT switch to Rule 2 because the question mentions ASIC / CySEC / FINRA / broker-recon / regulatory / audit / etc. — those questions still get the default `IsValidCustomer` filter unless the user literally writes "CB valid" / "Client Balance valid" / "credit-report valid". Heuristic-based switching produces silent wrong populations on every adjacent question. Same goes for the opt-out: only fires on the literal phrases listed in the contract.
4. **Tier 2 — `IsCreditReportValidCB` is a sibling, not a superset.** Same quad as `IsValidCustomer` PLUS `AccountTypeID != 2` MINUS specific CID exceptions where `CountryID = 250` is re-included (the ~10-12 subsidiary trade accounts at the parent broker that regulatory reporting must count). Do not derive it from `IsValidCustomer` by adding clauses — always filter on the column directly.
5. **Tier 5 — `CB` means `Client_Balance`, NOT *CreditBureau* (user expert clarification 2026-05-29).** The corpus had a fabricated "CreditBureau credit report validation" narrative across ~90 wiki §4 cells and 8 deployed UC column comments — purged 2026-05-29. The actual semantic is: "is this customer a **FINANCIAL CUSTOMER** for Client_Balance / regulatory capital reports". The carve-out (the 6 hardcoded CIDs under `CountryID = 250` in Rule 2 above) are **eToro-EU subsidiary trade accounts** — counterparty entities owned by the eToro parent, whose assets the parent entity custodies. For these accounts: `IsValidCustomer = 0` (business KPIs ignore their revenue / deposits / volume — they are not "customers" in the commercial sense) but `IsCreditReportValidCB = 1` (the parent custodies their assets, so they DO appear in Client_Balance, FCA Liabilities, ASIC capital, and audit reports). That asymmetry is the entire reason the two flags coexist; neither is a superset of the other.

## The contract

| Rule | Fires when | Filter | Join |
|---|---|---|---|
| 1 (default, ALWAYS) | every per-customer aggregate | `snap.IsValidCustomer = 1` | SCD-2 walk on `V_Fact_SnapshotCustomer_FromDateID` with `fact.DateID BETWEEN snap.FromDateID AND snap.ToDateID` |
| 2 (regulatory variant) | user explicitly says "CB valid" / "Client Balance valid" / "credit-report valid" — and only then | `snap.IsCreditReportValidCB = 1` | same SCD walk |
| 3 (opt-out) | user explicitly says "include non-valids" / "include internals" / "include etorians" / "include test accounts" / "unfiltered" — and only then | none | no join |
| Present-state fallback | user explicitly says "today" / "right now" / "currently" | `c.IsValidCustomer = 1` | direct join to `Dim_Customer` |

Formal definitions (verbatim from `DWH_dbo.SP_Dim_Customer`; column on both `Dim_Customer` and `V_Fact_SnapshotCustomer_FromDateID`):

- `IsValidCustomer = 1` ⇔ `PlayerLevelID <> 4` (`Dim_PlayerLevel.Name = 'Internal'`) AND `LabelID NOT IN (30, 26)` (`Dim_Label.Name IN ('Dealing', 'ILQ')`) AND `CountryID <> 250` (`Dim_Country.Name = 'eToro'` — internal pseudo-jurisdiction, `Abbreviation = 'ZZ'`).
- `IsCreditReportValidCB = 1` ⇔ `NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)` AND `LabelID NOT IN (26, 30)` AND `NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243, 10842855, 11464063, 21547142, 34537826))` — i.e., same Internal / Dealing / ILQ exclusions, plus the demo-account exclusion (`AccountTypeID <> 2`), with the six hard-coded subsidiary CIDs under `CountryID = 250` re-included.

**Popular Investors are valid customers.** They are tracked by `Dim_Customer.GuruStatusID`, not by `PlayerLevelID`. Neither flag excludes them. Do not assert otherwise in any output.

## Mandatory output footer

Default scope:
> *Scope: valid users only — `IsValidCustomer = 1` (excludes `PlayerLevel='Internal'`, `Label IN ('Dealing','ILQ')`, `Country='eToro'`), period-correct (SCD-2). Popular Investors ARE valid. For credit-balance-valid scope, ask explicitly ("CB valid").*

Regulatory scope:
> *Scope: `IsCreditReportValidCB = 1` (period-correct) — same Internal / Dealing / ILQ / eToro exclusions as default PLUS demo-account exclusion (`AccountTypeID <> 2`), with six hard-coded subsidiary CIDs re-included. For standard valid-users scope, ask explicitly.*

Opt-out scope:
> *Scope: unfiltered — includes test / internal / non-valid accounts on user request. NOT suitable for executive reporting.*

## SQL patterns

### Pattern 1 — Default (SCD-2 walk, period-correct)

```sql
SELECT SUM(d.Revenue_USD) AS revenue_usd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
       ON snap.RealCID = d.CID
      AND snap.IsValidCustomer = 1
      AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID BETWEEN :from_yyyymmdd AND :to_yyyymmdd;
```

### Pattern 2 — Regulatory variant (explicit "CB valid" request)

```sql
SELECT SUM(d.Revenue_USD) AS revenue_usd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
       ON snap.RealCID = d.CID
      AND snap.IsCreditReportValidCB = 1
      AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID BETWEEN :from_yyyymmdd AND :to_yyyymmdd;
```
