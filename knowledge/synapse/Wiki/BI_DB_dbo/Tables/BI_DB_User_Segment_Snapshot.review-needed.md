---
table: BI_DB_dbo.BI_DB_User_Segment_Snapshot
type: review-needed
batch: 37
---

# Review Notes: BI_DB_User_Segment_Snapshot

## Phase 16 Adversarial Evaluation

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.0 | All 8 columns correctly T2 — no Tier 1 passthrough columns (all are computed/derived) |
| Upstream Fidelity | 20% | 9.5 | No direct Tier 1 inheritance needed; SP code read fully; computation logic accurately transcribed |
| Completeness | 20% | 9.5 | All 8 columns documented; ABC model thresholds enumerated; end-of-month logic documented; population filter documented |
| Business Meaning | 15% | 9.0 | Three segmentation dimensions clearly explained; risk model explained with thresholds; ActivitySegment carry-forward behavior documented |
| Data Evidence | 10% | 9.0 | 9.7M rows/day, 4,845 dates (20130101-20260412), full RiskIndex distribution sampled |
| Shape Fidelity | 10% | 10.0 | HASH(RealCID) + CLUSTERED INDEX (Date, RealCID) correctly documented |

**Weighted Score: 9.1 / 10.0 ✅ PASS (threshold: 7.5)**

---

## Items Requiring Human Review

### MEDIUM: ActivitySegment empty string vs NULL semantics
The SP carries forward `ActivitySegment` from the previous day's row via LEFT JOIN: `LEFT JOIN BI_DB_User_Segment_Snapshot uss ON uss.RealCID = ri.CID AND uss.Date = @BeforeYesterdayINT`. The value is not explicitly defaulted — if no previous row exists (new customer), `ActivitySegment` is NULL in the insert. However, the end-of-month UPDATE may set it to a segment value. In the sampled data (2026-04-12), `ActivitySegment = ''` (empty string) appears for ~385K rows. It's unclear whether these are NULLs converted to empty strings by the MCP client or genuine empty strings in the database.
**Action**: Verify `SELECT COUNT(*) FROM BI_DB_User_Segment_Snapshot WHERE Date = 20260412 AND ActivitySegment IS NULL` vs `= ''`.

### MEDIUM: RiskIndex = 0 edge case behavior
When a customer has deposits but `RiskIndex = 0` (ISNULL fallback — no AvgSTD), their `RiskGroup = 'A'` due to the ELSE clause `WHEN ISNULL(ri.RiskIndex,0) <= 3 THEN 'A' ... ELSE 'A'`. This means RiskIndex=0 customers are silently grouped with genuinely low-risk customers. For regulatory or risk analytics, `RiskIndex = 0` rows should be filtered out separately.
**Action**: Document the frequency of `RiskIndex = 0` customers and confirm whether business users are aware of this grouping behavior.

### LOW: AvgSTD scope is ALL historical dates, not a rolling window
The ABC risk model uses ALL historical qualifying dates (from 2013 onward), not a rolling window. This means a customer who was highly active in 2015 but dormant since will still have their 2015 risk profile reflected in today's RiskIndex. This may produce stale risk classifications for dormant customers.
**Action**: Confirm with risk/compliance owners whether all-time AvgSTD is the intended design or if a rolling window was intended but not implemented.

### LOW: SP uses WITH (NOLOCK) on several reads
The SP uses `WITH (NOLOCK)` on reads from `BI_DB_EquitySnapshots`, `BI_DB_STDSnapshots`, `BI_DB_DepositSnapshots`, and `BI_DB_User_Segment_Snapshot`. Per the MCP query rules, Synapse uses snapshot isolation — `WITH (NOLOCK)` is redundant but not harmful in Synapse (it differs from SQL Server behavior). No action needed, but be aware this is legacy code.
