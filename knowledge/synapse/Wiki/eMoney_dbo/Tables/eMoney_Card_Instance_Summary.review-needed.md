# Review Needed: eMoney_dbo.eMoney_Card_Instance_Summary

**Generated**: 2026-04-21  
**Reviewer**: Data Engineering / eToro Money Analytics Team  
**Priority**: Medium

---

## Tier 4 Items (Unverified — Require Business Confirmation)

None. All 18 columns traced to SP code or upstream FiatDwhDB/etoro production sources.

---

## Open Questions

1. **SP_eMoney_Card_Instance_Summary not in Execute_Group_One**: This SP (created 2025-05-27) runs after the orchestrator was already disabled. Confirm: does it run via ADF pipeline or another scheduler? And what is the exact refresh time relative to eMoney_Dim_Account and eMoney_Panel_FirstDates (both must run first)?

2. **MaskedPAN format**: Sample data shows format `459688******9786` (BIN + masked middle + last 4). Confirm: is this the Tribe Mastercard BIN 459688? And is 459689 (seen in newer rows) a second BIN after card program migration?

3. **InstanceCreatedDate vs InstanceIssuedDate terminology**: The SP uses `InstanceIssuedDate` (= first NotActivated status event) but the target DDL column is `InstanceCreatedDate`. These represent the same concept — the date the card was recorded in the system (before the cardholder activates it). Confirm this is consistent with business terminology.

4. **IsValidETM=0 rows (1,195 rows, 0.9%)**: The SP doesn't filter on IsValidETM — it just joins eMoney_Dim_Account on GCID_Unique_Count=1. So 1,195 rows belong to test/cancelled accounts that still have card records. Should these be filtered out in the SP, or is it intentional to include them for reconciliation purposes?

5. **GCID_Unique_Count always=1**: Confirmed by SP JOIN clause. Rows where GCID has multiple eMoney accounts are excluded entirely. This means customers with account migrations are documented only for their most recent account. Flagging for awareness.

---

## Validation Flags

- **MaskedPAN is PII**: Excluded from `v_eMoney_Card_Instance_Summary`. Ensure UC Gold export respects data masking policy.
- **TxAfterActivationCount may be stale for recent instances**: Since the SP is TRUNCATE+INSERT daily, the count reflects yesterday's transaction data from eMoney_Dim_Transaction. For the most recent instances, TxAfterActivationCount may undercount.
- **NULL InstanceCreatedDate (1,120 rows)**: Cards with no status history in FiatCardStatuses have NULL. These are likely data gaps (historical cards from before status tracking began or cards with missing events).

---

## Cross-Object Consistency Check

| Shared Column | Source Description (eMoney_Panel_FirstDates) | This Wiki Description | Match? |
|--------------|----------------------------------------------|----------------------|--------|
| CID | "Customer ID - platform-internal primary key…" | Verbatim copy | YES |
| FMI_Date | "Date of the account's first settled money-in transaction…" | Verbatim copy | YES |
| IsValidETM | From eMoney_Dim_Account #15 | Verbatim copy | YES |
| GCID_Unique_Count | From eMoney_Dim_Account #19 | Verbatim copy + DWH note about always=1 | YES |
| CardCreateDate | From eMoney_Dim_Account #81 | Verbatim copy | YES |
| ProviderCardID | From eMoney_Dim_Account #87 | Verbatim copy | YES |

---

*Review generated: 2026-04-21 | Object: eMoney_dbo.eMoney_Card_Instance_Summary*
