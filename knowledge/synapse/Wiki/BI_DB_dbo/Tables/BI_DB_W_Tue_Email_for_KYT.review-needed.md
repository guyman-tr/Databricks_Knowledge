# BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT — Review Needed

## Tier 4 Items (needs human verification)

- **20 columns from External_Fivetran_google_sheets_kyt_alerts**: All alert-specific columns (severity, category, alert_created_at, transfer_at, status, service_name, exposure, direction, alert_amount, user_id, asset, tx_hash, tx_index, output_address, alert_type, state, _of_transfer, symbol, network, alert_id) are Tier 4 because they originate from an external Google Sheets source with no upstream wiki. Descriptions are inferred from live data sampling and column naming conventions.

## Questions for Reviewer

1. **KYT provider identity**: Which KYT provider generates these alerts? (e.g., Chainalysis, Elliptic, Crystal) — the table references service_name for counterparty but not the screening vendor.
2. **_of_transfer column**: Is this "% of transfer" as suspected? What does 100.0 mean vs 1.888632?
3. **Date format inconsistency**: alert_created_at uses DD/MM/YYYY HH:MM while transfer_at uses both DD/MM/YYYY and YYYY-MM-DD formats. Is this a Google Sheets formatting issue?
4. **Tuesday email**: SP name contains "Tue" — is this still run on Tuesdays only, or has the schedule changed to daily?
5. **user_id encoding**: Confirmed Base64-encoded GCID? (e.g., "Nzg4NjU5NQ" decodes to "7886595" matching GCID column)

## Reviewer Corrections

(none yet)

---

*Generated: 2026-04-27 | Object: BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT*
