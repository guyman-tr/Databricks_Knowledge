# Review Needed — BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts

Generated: 2026-04-23 | Batch 71

## Tier 3 Items (Inferred — verify with domain expert)

| Column | Inferred Meaning | Why Uncertain |
|--------|-----------------|---------------|
| InvestedAmount | Position invested amount (Amount or Volume from Dim_Position) | Exact source column varies by rule; not consistently labelled in SP |
| Leverage | Position leverage ratio (numeric, stored as varchar) | SP uses various position columns; exact source not confirmed across all rules |
| TranID | Deposit ID or transaction ID for deposit-related alerts | Confirmed as DepositID in BC4 but not verified across all deposit rules |
| Occurred | Deposit/transaction occurred timestamp as varchar | Confirmed in BC4 context; unclear for other deposit rules |
| AmountUSD | Transaction amount in USD as varchar | Confirmed in BC4 context (pld.Amount); rule-specific elsewhere |
| State | Transaction state for cashout/deposit rules | Appears in some rules only; exact semantics unclear |
| CryptoName | Name of restricted crypto asset | Populated by crypto rules (PC33, PC36, PC44); source not confirmed from wiki |
| CryptoID | Crypto asset ID | Same as above |

## Questions for Reviewer

1. **RealCID as VARCHAR**: RealCID is declared `varchar(100)` and HASH-distributed. Is this intentional (to accommodate non-numeric GCID-style IDs), or a historical type error? Affects JOIN patterns for downstream tools.
2. **RecordID continuity**: RecordID is max(existing)+ROW_NUMBER() per day. When rows are re-deleted and reinserted for a given date (SP re-run), RecordIDs are reassigned. Is RecordID stable/idempotent? Downstream tools relying on RecordID should not cache it.
3. **AccountMgr truncation**: Some rules truncate AccountMgr to 10 chars; others to 100. Are these consistent in current SP or a known legacy issue?
4. **Deprecated DLT rule rows**: Rows with AlertType IN ('DLT1','DLT2','DLT3','DLT4') exist from before 2025-11-04 when these rules were deactivated. Should these historical rows be cleaned up?
5. **Compliance consumers**: No downstream SSDT SP/view references found. Confirm which Compliance dashboard or external tool consumes this data.
6. **BC1, BC5, BC6 deactivated**: Are these rules permanently removed or temporarily disabled? Historical rows for BC1 may exist from before 2023 (table starts 2023-01-01).

## Known Limitations

- **Sparse columns**: Many columns NULL for most alert types — this table is not "fully" relational; treat it as a per-rule export.
- **RealCID is VARCHAR** — always CAST when joining to int-keyed tables.
- **RecordID NULL pre-2025-03-09** — approximately 2 years of historical rows lack RecordID.
- **30+ rules in one SP** — SP_Compliance_Forbidden_Trades is 3,500+ lines; individual rule documentation requires reading specific rule sections.
- **6 Tier 3 columns** (InvestedAmount, Leverage, TranID, Occurred, AmountUSD, State, CryptoName, CryptoID) lack confirmed upstream wiki lineage.
- HASH(RealCID varchar) distribution may produce uneven skew if null/non-numeric values present.
