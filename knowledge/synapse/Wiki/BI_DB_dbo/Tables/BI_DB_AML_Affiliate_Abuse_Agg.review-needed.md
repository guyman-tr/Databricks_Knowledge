# Review Needed: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg

**Generated**: 2026-04-23 | **Quality**: 8.5/10 | **Reviewer**: BI / AML team

---

## Items Requiring Human Review

### 1. UC Migration Status
- **Flag**: `UC Target: Not_Migrated` — confirm whether this frozen table will ever be migrated or can be formally decommissioned
- **Why**: SP disabled 2024-12-31; no further refreshes. A decommission decision may make migration moot.
- **Action**: Check with BI team (Lior Ben Dor or successor) whether the AML Affiliate Abuse suite has a formal decommission record

### 2. NULL Semantics in Monthly Aggregation
- **Flag**: When an affiliate had zero activity in a given month, the three-way JOIN (#CO LEFT JOIN #deposit LEFT JOIN #positions) may produce NULL vs 0 ambiguity
- **Why**: SP uses separate temp tables joined on AffiliateID+Channel+Year+Month; months with no CO leg are absent, not zero
- **Action**: Verify with SP owner whether a month entirely absent from CO leg appears in final table at all (it should not — CO drives the outer left join)

### 3. Decimal Precision of %SameIP (companion table)
- **Flag**: The `[%SameIP]` column in `BI_DB_AML_Affiliate_Abuse_SameIP` is stored as `decimal(18,0)` — this truncates to integer percent
- **Why**: SP computes ROUND(x * 100.0 / TotalClients, 2) but DDL stores as decimal(18,0), discarding the decimal places
- **Action**: Confirm this is intentional (integer-only percent was acceptable for AML reporting) or a DDL bug

### 4. AML Monitoring Replacement
- **Flag**: No replacement monitoring suite is documented
- **Why**: Suite was disabled; unclear if AML affiliate abuse monitoring continues via another mechanism
- **Action**: Confirm with compliance/AML team whether affiliate abuse monitoring was picked up by another system after 2024-12-31

---

## No Review Needed

- SP disable date (2024-12-31): confirmed in SP header comment
- Row count (20,627): confirmed via MCP live query
- SubChannelID filter values (20,31,39,40,41,42,44): confirmed in SP Step 01
- Approved/Unapproved status codes (CashoutStatusID_Funding=3, PaymentStatusID=2): consistent with DWH_dbo wiki
