---
object: BI_DB_dbo.BI_DB_CryptoMarketingList
review_generated: 2026-04-23
status: needs_review
---

# Review Notes — BI_DB_CryptoMarketingList

## Tier 4 Inferences (Reviewer Verification Required)

| Column | Inferred Claim | Confidence | Evidence |
|--------|---------------|------------|----------|
| HoldedEligibleCoins | InstrumentIDs 100000-100005+100020 = specific promotional coins | Medium | IDs hardcoded in SP line 57. XRP qualifies (shows 'Yes' in sample), Flare/Songbird don't. Exact instrument names not confirmed — reviewer should validate which coins these IDs represent in Dim_Instrument. |
| IsOptIn='No' | ResourceId=5564 SelectedValue='2' = marketing opt-out setting | High | SP explicit. ResourceId=5564 is the setting key in External_SettingsDB_Settings_CustomerData. The specific opt-out semantics of this ResourceId should be confirmed with the product/settings team. |
| HasWallet | Binary 0/1 for eToro Money wallet | High | All sample rows show HasWallet=0. Confirmed as int column. eToro Money wallet link assumption based on column name and context — verify against Dim_Customer.HasWallet documentation. |
| CryptoHolded='No' for IsMajor=No | Non-major coins shown as 'No' rather than their display name | High | SP explicit: CASE WHEN di.IsMajor='Yes' THEN InstrumentDisplayName ELSE 'No'. Flare and Songbird are not IsMajor in sample. This means the marketing team may not know WHICH non-major coin the customer holds. |

## Data Quality Issues (Confirmed)

1. **SP typo in Category value** — `Category = 'Holded Postions'` (missing 'i') is hardcoded in the SP and stored verbatim in the table. All queries for this segment MUST use the misspelled string. Fixing requires SP modification and a data reload. **Action**: Decide whether to fix the SP typo or document it as a permanent quirk.

2. **HoldedAbove NULL handling** — SP uses ISNULL(h.HoldedAbove, 'Not Holded') but the #holdings table can produce NULL from the CASE expression if DATEDIFF result falls outside all WHEN clauses (theoretically not possible but edge case for positions opened exactly 1/2/3/4/5 months ago at exact month boundaries). 'Not Holded' appears in data — confirm whether these are legitimate non-holders or edge cases.

## Open Questions for Business Reviewer

1. **GCID uniqueness per segment** — Can a GCID appear in both 'Holded Postions' AND 'Opened/Closed Positions' simultaneously (e.g., holding some crypto and having closed other crypto recently)? The UNION (not UNION ALL) in the SP should deduplicate at GCID+Category level, but a customer could have rows in both categories.

2. **Eligible coins list hardcoding** — InstrumentIDs 100000, 100001, 100002, 100003, 100005, 100020 are hardcoded in the SP for HoldedEligibleCoins. Is there a business definition for what makes a coin "eligible"? This list should ideally be in a lookup table, not hardcoded, to allow updates without SP changes.

3. **BI_DB_First5Actions.FirstAction semantics** — Crypto Leads are identified as customers with `FirstAction IS NULL` from BI_DB_First5Actions. What does FirstAction = NULL mean — does it indicate no first action exists at all, or no CRYPTO first action specifically? If it's any first action, a customer who traded stocks (non-crypto) would appear as a Crypto Lead.

4. **External_SettingsDB_Settings_CustomerData source** — This table name suggests it comes from SettingsDB (a production system). Is it an External Table or a replicated copy? The SP reads it directly without specifying a schema external table prefix. Lineage through this source should be verified.

5. **FunnelFromID=57 = Crypto funnel** — Confirmed by SP comment "NEW USERS CRYPTO FUNNEL". Is 57 the only Crypto funnel ID, or could there be others (e.g., 57a, multiple sub-funnels)? If new crypto funnel campaigns are launched with different FunnelFromIDs, they won't appear in Crypto Leads.

## UC Migration Status

- **UC Target**: `_Not_Migrated` — not found in generic pipeline mapping
- Table has no date column — TRUNCATE+INSERT semantics mean no historical versioning
- If migrated to UC, consider whether to add an `as_of_date` column for historical tracking
