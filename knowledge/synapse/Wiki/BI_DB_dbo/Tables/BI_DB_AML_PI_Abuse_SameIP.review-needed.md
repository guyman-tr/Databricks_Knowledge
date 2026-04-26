# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP

**Generated**: 2026-04-22 | **Batch**: 47 | **Reviewer**: SP owner (Lior Ben Dor) + AML team

---

## IP Source Confirmation

- [ ] **Registration IP only**: The `IP` column is sourced from `Dim_Customer.IP` (registration IP — a static value set at account creation). Confirm this is the intended signal, not session/login IP data. Registration IPs can be stale for long-standing accounts.

- [ ] **Future enhancement**: Is there a plan to supplement or replace registration IP with session IP from STS audit logs (as used for device fingerprinting)? Session-level IPs would provide a more current and reliable geographic signal.

---

## Threshold and Filter Confirmation

- [ ] **`HAVING COUNT(DISTINCT CopierCID) >= 2`**: Confirm the minimum cluster size of 2 is correct. Some use cases may require ≥3 for stronger confidence. Is the threshold configurable?

- [ ] **VPN false positive handling**: At scale, common VPN/proxy exit nodes can create large fake clusters. Does the AML team have a list of known VPN IP ranges to exclude? Should these be filtered in the SP?

---

## Documentation Flags

- [ ] No open documentation issues — table is straightforward with clean grain.
