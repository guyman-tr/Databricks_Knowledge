# Review Needed — BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD

## Items Requiring Human Review

---

### 1. RegulationID Values for ASIC and GAML

**Issue**: The SP filters `Fact_SnapshotCustomer` by `RegulationID IN (4, 10)`. The wiki comments these as "ASIC" and "GAML" respectively, but the actual mapping (which RegulationID=4 vs. 10 maps to which entity) should be verified against `Dim_Regulation`.

**Risk**: If regulation IDs shift due to new entity registration, the SP population filter may silently include/exclude wrong customers.

**Action**: Confirm with compliance team that RegulationID=4 = ASIC and RegulationID=10 = GAML. Add a note to the SP if confirmed.

---

### 2. Alert A3 — Missing

**Issue**: The SP comments section header reads "Alerts #2 #4 #6" for `Dim_Position` sources, implying Alert #3 was planned but is not implemented. The table has no A3_* columns.

**Risk**: If ASIC regulations require an Alert #3 to be reported, this is a compliance gap.

**Action**: Verify with the compliance/analytics team whether Alert #3 was deliberately skipped, deprecated, or not yet implemented. If required, escalate to the owning team.

---

### 3. Alert A6 Logic — Threshold vs. Ratio

**Issue**: The SP code computes `A6_HighLeverageTrading_Ind` as:
```sql
CASE WHEN TotalPosManualCFD > 0 AND TotalPosMaxLeverage/TotalPosManualCFD > 0 THEN 1 ELSE 0 END
```
The SP comment says "Total closed Manual CFD Positions at Max Leverage / Total closed Manual CFD Positions > **0.5**" (i.e., 50%), but the actual condition checks `> 0` (any max-leverage position). This means the flag triggers for any customer with even a single max-leverage position, not only those where the majority (>50%) of positions used max leverage.

**Risk**: Potential over-flagging of customers. If regulators expect a strict >50% threshold, the current implementation is more conservative.

**Action**: Confirm with compliance team whether the intended threshold is `> 0` (any occurrence) or `> 0.5` (majority), and align the SP code, documentation, and regulatory reporting accordingly.

---

### 4. Table Coverage — Only 6 Dates

**Issue**: As of 2026-04-28, the table contains only 6 dates (2023-10-30 to 2023-11-04). This suggests the SP has not been run regularly, or older dates are being purged by another process.

**Risk**: If the ASIC monitoring reports require a longer history, the current table may be insufficient.

**Action**: Verify whether the SP runs daily in production, and whether older dates are retained or purged. Check OpsDB for the SP's scheduling status.

---

### 5. No UC / Databricks Export Identified

**Issue**: No UC target or generic pipeline mapping was found for this table during documentation. ASIC monitoring data may need to be accessible to Databricks-based compliance workflows.

**Action**: Confirm with data platform team whether a UC export is planned or required for this table.

---

### 6. AccountManager as Free-Text String

**Issue**: `AccountManager` stores the display name (FirstName + LastName concatenated) rather than a FK to `Dim_Manager.ManagerID`. This makes it difficult to join back to manager attributes or handle name changes.

**Risk**: If a manager's name changes in Dim_Manager, historical rows in this table retain the old name. Manager-level aggregations must be done by string matching rather than a stable ID.

**Action**: Consider adding `AccountManagerID` (int) as an additional column to enable reliable manager-level joins and trend analysis. The SP already has access to `fsc.AccountManagerID`.

---

*Review file generated: 2026-04-28*
*Object: BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD*
