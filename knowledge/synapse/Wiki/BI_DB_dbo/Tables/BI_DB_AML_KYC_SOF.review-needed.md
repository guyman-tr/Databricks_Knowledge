# Review Needed: BI_DB_dbo.BI_DB_AML_KYC_SOF

## Phase 16 Adversarial Evaluation

**Overall Score: 8.1 / 10 — PASS**

| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|---------|
| Tier Accuracy | 8.0 | 25% | 2.00 |
| Upstream Fidelity | 7.5 | 20% | 1.50 |
| Completeness | 9.0 | 20% | 1.80 |
| Business Meaning | 9.0 | 15% | 1.35 |
| Data Evidence | 9.0 | 10% | 0.90 |
| Shape Fidelity | 8.5 | 10% | 0.85 |
| **Total** | | | **8.40** |

### T1 Upstream Fidelity Table

| Column | Upstream Wiki | Verbatim Copy? |
|--------|--------------|----------------|
| CID | DWH_dbo.Dim_Customer.RealCID | ✅ |
| GCID | DWH_dbo.Dim_Customer.GCID | ✅ |
| Regulation | DWH_dbo.Dim_Regulation.Name | ✅ |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus.Name | ✅ |
| Club | DWH_dbo.Dim_PlayerLevel.Name | ✅ |
| Country | DWH_dbo.Dim_Country.Name | ✅ |
| Region | DWH_dbo.Dim_Country.Region (T2 in source wiki) | N/A → Tier 2 |
| FirstDepositDate | DWH_dbo.Dim_Customer.FirstDepositDate | ✅ |
| FirstDepositAmount | DWH_dbo.Dim_Customer.FirstDepositAmount | ✅ |
| RegisteredReal | DWH_dbo.Dim_Customer.RegisteredReal | ✅ |
| Gender | DWH_dbo.Dim_Customer.Gender | ✅ |
| Age | Computed from Dim_Customer.BirthDate | N/A → Tier 2 |
| UserName | DWH_dbo.Dim_Customer.UserName | ✅ |
| ManagerFullName | Dim_Manager (no direct wiki column match) | N/A → Tier 2 |
| Q10_Annual_Income | BI_DB_KYC_Panel (wiki exists, T2) | ✅ T2 carried |
| Q10_AnswerText | BI_DB_KYC_Panel | ✅ T2 carried |
| Q11_Liquid_Assets | BI_DB_KYC_Panel | ✅ T2 carried |
| Q11_AnswerText | BI_DB_KYC_Panel | ✅ T2 carried |
| Q14_Planned_Invested_Amount | BI_DB_KYC_Panel | ✅ T2 carried |
| Q14_AnswerText | BI_DB_KYC_Panel | ✅ T2 carried |
| Max_Q14_Answer | SP CASE computation | N/A → Tier 2 |
| Total_Deposit | Fact_CustomerAction | N/A → Tier 2 |
| RemainingAmount | SP computation | N/A → Tier 2 |
| %RemainingAmount | SP computation | N/A → Tier 2 |
| SOF_Predication | SP business logic | N/A → Tier 2 |
| ReasonType | SP business logic | N/A → Tier 2 |
| HasBusinessPotential | SP business logic | N/A → Tier 2 |
| HasOpenPosition | BI_DB_PositionPnL | N/A → Tier 2 |
| Last_Open_Position_Date | Dim_Position | N/A → Tier 2 |
| Last_Close_Position_Date | Dim_Position | N/A → Tier 2 |
| Equity | V_Liabilities | N/A → Tier 2 |
| Last_Login_Date | Fact_CustomerAction | N/A → Tier 2 |
| DocumentType | External table | N/A → Tier 2 |
| DocumentDateAdded | External table | N/A → Tier 2 |
| SuggestedDocumentType | External table | N/A → Tier 2 |
| RejectReasonName | External table | N/A → Tier 2 |
| DocumentStatus | External table | N/A → Tier 2 |
| HasProofOfIncome | SP computation | N/A → Tier 2 |
| HasSOFLast6Months | SP computation | N/A → Tier 2 |
| UpdateDate | Propagation | Propagation |

**T1 coverage: 11 / 39 non-propagation columns = 28.2%** — lower than average (many computed columns), not a hard fail (T1 > 0).

### Column Statistics Check

- All 40 columns documented: ✅
- Row count confirmed via MCP: 5,371,229 ✅
- SOF_Predication distribution (3 values), ReasonType × HasBusinessPotential (6 combinations), Q14_AnswerText (12 values), Regulation (15 values) — all confirmed ✅
- Sample data (TOP 10) reviewed ✅

---

## Items for Human Review

### HIGH — Data Quality Issues

1. **Q14 CASE statement gap (unmapped answers)**: Q14_AnswerText values `'$20k-$100k'` (979 rows) and `'More than $100k'` (526 rows) are not present in the SP's CASE statement, causing Max_Q14_Answer = 0 for ~1,505 rows. This leads to:
   - `%RemainingAmount` = NULL (NULLIF prevents division by zero)
   - `RemainingAmount` = 0 - Total_Deposit (negative, even if deposits are small)
   - These customers likely appear as 'More then decleared deposit' / 'SOF' incorrectly
   - **Recommendation**: Add these values to the CASE in SP_AML_KYC_SOF. `$20k-$100k` → 100,000, `More than $100k` → suitable cap.

2. **Q10_Annual_Income stores question text, not answer code**: Live data shows the column contains "What is your net annual income?" (the full question text) rather than an answer code or ID. The BI_DB_KYC_Panel wiki describes this column as "Q10 raw answer ID (annual income bracket)" which contradicts observation. Investigate whether BI_DB_KYC_Panel.Q10_Annual_Income changed semantics, or if the KYC_Panel wiki is incorrect.

3. **Blocked customers included**: Unlike BI_DB_AML_KYC_Process, this table includes customers with PlayerStatus = 'Blocked'. Rows 5 and 7 in sample data show 'Blocked' status. AML analysts using this table should be aware that some cases are already blocked accounts.

### HIGH — SP Code Issues

4. **Orphaned `#AMLticket` temp table**: SP computes a full `#AMLticket` temp table with HasOpenTicket (from BI_DB_SF_Cases_Panel — open AML Salesforce cases). This temp table is **never referenced** after creation — the flow goes `#BusinessPotential` → `#Equity`, `#Positions`, `#Last_Login`, `#LastPositionDate`, `#consolidate`, bypassing `#AMLticket` entirely. `HasOpenTicket` is NOT in the final DDL. This is dead code. The SP owner should confirm whether this was intentionally removed from the output or is a regression.

5. **SP uses `WITH(NOLOCK)` on Synapse tables**: Lines reference `WITH(NOLOCK)` on Dim_Customer and other tables. Synapse SQL Pool uses snapshot isolation by default — NOLOCK is not needed, not meaningful, and may cause warnings on some configurations. This does not affect data correctness but is a code quality issue.

### MEDIUM — Column Naming and Values

6. **`SOF_Predication` column name**: May be a misspelling of "Prediction" ("Predic**a**tion" vs "Predic**t**ion"). If the intent was "Prediction," the column is misnamed in both the SP and DDL. Not a data quality issue, but worth confirming with the SP owner whether this is intentional terminology or a typo.

7. **`ReasonType` string typos**: Values stored are:
   - `'More then decleared deposit'` — should be "than declared"
   - `'Less then 15% left'` — should be "than"
   These are hardcoded strings in the SP that propagate to the table. Fixing them would require an SP change and any downstream filters on these strings to be updated simultaneously.

8. **Age computed without birthday logic**: `DATEDIFF(YEAR, BirthDate, GETDATE())` can be off by 1 year for customers whose birthday hasn't occurred yet in the current year. This affects ~50% of customers at any given point in the year. For precise age filtering, use BirthDate directly from Dim_Customer.

### LOW — Documentation Gaps

9. **BI_DB_PositionPnL not documented**: The HasOpenPosition column sources from BI_DB_PositionPnL, which is not yet wikied. The join is on CID and DateID=yesterday. Document in a future batch.

10. **Dim_Manager wiki missing**: ManagerFullName sources from DWH_dbo.Dim_Manager but this dimension table has no wiki. The column 'System  ' (with trailing whitespace) appears for system-assigned accounts. Analysts doing manager-based filtering should apply RTRIM().

11. **SP run time context**: `GETDATE()` is called multiple times in the SP (for Age, equity DateID, HasSOFLast6Months, UpdateDate). All calls happen within the same SP execution and should be consistent, but technically Is_POI_Expired-style logic could differ across long-running SPs. Not a current concern.

---

*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_KYC_SOF | Batch 46*
