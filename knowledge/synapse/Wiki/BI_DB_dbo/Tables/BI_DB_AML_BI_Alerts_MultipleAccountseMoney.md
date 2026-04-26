# BI_DB_dbo.BI_DB_AML_BI_Alerts_MultipleAccountseMoney

> Daily AML alert log for customers with multiple eToro accounts that share eMoney (IBAN) wallets — five threshold-based alert types (IBAN MA001–MA005) firing when combined eMoney transaction volumes exceed regulatory AML limits across the linked account group.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Primary Sources** | BI_DB_dbo.BI_DB_OPS_MultipleAccounts + eMoney_dbo.eMoney_Dim_Transaction + DWH_dbo.Fact_SnapshotCustomer |
| **Refresh** | Daily (OpsDB Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 19 |
| **Row Count** | 93 (2026-03-20; alert dates May 2025–Mar 2026) |
| **Distinct CIDs** | 67 |
| **Writer SP** | SP_AML_BI_Alerts_MultipleAccountseMoney (Author: Pavlina Masoura, 2025-05-05) |
| **Load Pattern** | DELETE WHERE AlertDate=@Date + INSERT (cumulative; historical alerts retained) |
| **SP Parameter** | `@Date DATE` |
| **Downstream Consumers** | None registered in OpsDB — terminal analytics table |
| **UC Target** | Pending |

---

## 1. Business Meaning

`BI_DB_AML_BI_Alerts_MultipleAccountseMoney` is the AML alert ledger for customers who hold multiple eToro accounts linked by the same real person (via `BI_DB_OPS_MultipleAccounts`) and have active eMoney (eToro Money IBAN wallet) accounts on more than one of those accounts. It monitors combined eMoney MIMO (Money In / Money Out — IBAN transfers) activity across the entire linked account group for five AML threshold violations.

The fundamental concern this table monitors is the **splitting of funds across multiple eMoney IBANs to evade individual account thresholds** — a classic structuring/layering pattern. By aggregating eMoney transaction volumes at the group level (`ID` from `BI_DB_OPS_MultipleAccounts`), the SP detects when the combined IBAN activity would trigger thresholds that individual accounts might not breach.

**Five alert types (all AlertCategory = 'MIMO'):**

| Code | Alert | Threshold | Frequency |
|------|-------|-----------|-----------|
| MA001 | Excessive Funds Transfers | Combined IBAN in+out ≥ $100K in 2–3 days | Daily re-fire |
| MA002 | Excessive Movement of Funds | Combined IBAN in+out ≥ $400K over 3 months | Daily re-fire |
| MA003 | Lifetime deposits + High eMoney CRA | Cumulative eMoney deposits ≥ $50K AND eMoney CRA = 'High' | First occurrence only |
| MA004 | 12-month deposits | IBAN deposits ≥ $100K in last 12 months | Annual re-fire (12-month cooldown) |
| MA005 | Lifetime deposit milestones | Cumulative eMoney deposits ≥ $250K, and every additional $250K | Daily re-fire at each milestone |

**Key structural note**: `ID` is a group identifier (from `BI_DB_OPS_MultipleAccounts`) shared across all linked accounts belonging to one person. A single alert row is generated per CID per AlertType per @Date for qualifying CIDs within the group.

**Population scope**: Only 93 rows / 67 CIDs as of March 2026 — reflecting the very narrow eligibility: must have multiple eToro accounts (BI_DB_OPS_MultipleAccounts) AND >1 active IBAN across those accounts.

---

## 2. Business Logic

### 2.1 Population Pipeline

```
BI_DB_OPS_MultipleAccounts  (pre-computed linked account clusters)
    JOIN eMoney_Dim_Account (Active IBANs)
    JOIN eMoneyClientBalance (balance at @DateID)
    JOIN eMoney_Customer_Risk_Assessment (eMoney CRA)
         → #multipleaccounts

#multipleaccounts → filter for ID groups with >1 IBAN
    JOIN Fact_SnapshotCustomer (at @DateID) + Dim_Country + Dim_Regulation + Dim_RiskClassification
    JOIN Dim_Customer + Dim_AccountType
    JOIN Dim_EvMatchStatus
         → #finalwithIBANS  (the alert-eligible population)
```

### 2.2 Alert Trigger Logic

**MA001 — Excessive Funds Transfers**  
Combined settled IBAN MI+MO transactions (TxTypeID=7 and 8) in the 2–3 day window ending @Date ≥ $100K (at group-ID level, but only for CIDs that had activity on @Date). Identified via `#ExcessiveFundsTransfers` temp table.

**MA002 — Excessive Movement of Funds**  
Combined settled MI+MO over the trailing 3 months ≥ $400K. Same event-day filtering approach as MA001. Identified via `#ExcessiveMovementofFunds`.

**MA003 — Lifetime Deposits + High eMoney CRA (first time only)**  
Fires when: cumulative lifetime eMoney deposits crossed $50K threshold on @Date (`#50K.ModificationDateID = @DateID`) AND the eMoney Customer Risk Assessment is 'High' (`#HighRiskIBANS`). The `Total_Alerts_of_TheCategory = 1` filter in the final INSERT ensures this fires only once per group-ID × AlertType combination.

**MA004 — 12-Month Deposits ≥ $100K**  
Fires when: IBAN deposits in the last 12 months crossed $100K on @Date, AND the last MA004 alert for this group-ID was more than 12 months ago (or never). The 12-month cooldown is enforced via `#LastAlerts` MAX(AlertDate) join.

**MA005 — Lifetime Milestones ($250K, $500K, $750K, $1M)**  
Fires when any of the $250K/$500K/$750K/$1M cumulative deposit milestones was first crossed on @Date. Multiple rows can fire on the same @Date if multiple milestones are crossed simultaneously.

### 2.3 Total_Alerts_of_TheCategory Counter

```sql
(COUNT(n.AlertType) + 1) AS Total_Alerts_of_TheCategory
```
`n` is a self-join on `BI_DB_AML_BI_Alerts_MultipleAccountseMoney` for the same `ID` and `AlertType`. This counts prior historical firings at the group level and adds 1 for the current alert. Grows over time as the table accumulates.

### 2.4 eMoney CRA vs Platform RiskScoreName

**CRITICAL DISTINCTION**: Two separate risk classifications are relevant to this table:
- `RiskScoreName` (stored in col 13): the **platform** AML risk classification from `Dim_RiskClassification` via `Fact_SnapshotCustomer`. This is the standard eToro platform risk score.
- `RiskeMoney` / eMoney CRA (NOT stored): `eMoney_Customer_Risk_Assessment.ClientRisk` — the eMoney-specific Client Risk Assessment. Only 'High' eMoney CRA triggers MA003. The two can differ for the same customer.

---

## 3. Query Advisory

- **Group-level analysis**: Join on `ID` (not `CID`) to aggregate across the full linked account cluster.
- **AlertCategory has trailing space**: Always use `RTRIM(AlertCategory) = 'MIMO'` when filtering.
- **AlertDate is datetime**: Use `CAST(AlertDate AS DATE)` for date comparisons — time portion is always `00:00:00`.
- **AlertID is not stable**: `NEWID()` generates a new UUID each run. Do not use as a join key across runs.
- **TotalDepositsLifetime is eMoney-only**: Represents `eMoney_Dim_Transaction` (IBAN activity only), NOT `Fact_BillingDeposit`. A customer with large platform deposits may show small eMoney amounts here.
- **IBAN MA003 fires once per group**: Filter `Total_Alerts_of_TheCategory = 1` is applied in the INSERT. Other alerts re-fire daily.
- **Very small table (93 rows)**: Full scans are cheap. No optimisation needed for direct queries.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | bigint | YES | Multi-account group identifier from BI_DB_OPS_MultipleAccounts. One ID represents all eToro accounts belonging to the same real person. Multiple rows in this table may share the same ID (one per CID per AlertType). Use ID to track cumulative alert history across the group. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via BI_DB_OPS_MultipleAccounts) |
| 2 | CID | bigint | YES | Customer identifier — the specific account within the group that triggered this alert row. Platform-internal primary key matching Dim_Customer.RealCID. One alert row per contributing CID per AlertType per @Date. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via #finalwithIBANS / Dim_Customer) |
| 3 | AlertID | nvarchar(max) | YES | Synthetic UUID (NEWID()) generated at INSERT time. Not stable — re-running for the same @Date generates new GUIDs. Do not use as a join key. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney) |
| 4 | AlertCategory | nvarchar(max) | YES | Alert classification. Always 'MIMO ' (with trailing space) for all 5 IBAN codes. MIMO = Money In / Money Out, referring to eMoney IBAN transactions. Apply RTRIM() when filtering. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney) |
| 5 | Total_Alerts_of_TheCategory | bigint | YES | Running count of times this AlertType has fired for this group ID, including the current row (prior count + 1). Tracked at group level (ID), not individual CID. For MA001/002/004/005, grows with each daily re-fire. For MA003, always 1 (first-time-only filter). (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney; self-join COUNT) |
| 6 | AlertDate | datetime | YES | The @Date parameter — the date on which the AML threshold was breached. Stored as datetime with time = 00:00:00. Use CAST(AlertDate AS DATE) for date-level comparisons. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney) |
| 7 | AlertType | nvarchar(max) | YES | IBAN MA-series description. 5 distinct values: 'IBAN MA001: Excessive Funds Transfers', 'IBAN MA002: Excessive Movement of Funds', 'IBAN MA003: Lifetime deposits >=50k over all emoney account AND eMoney CRA = High', 'IBAN MA004: Total deposits >= 100K over 12 months across all emoney accounts', 'IBAN MA005: Total deposits lifetime >= 250K across all accounts + every additional 250K'. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney) |
| 8 | Regulation | nvarchar(max) | YES | Customer's regulatory entity name at @Date, sourced from Fact_SnapshotCustomer + Dim_Regulation. Observed values: FCA (54%), CySEC (46%). (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via Fact_SnapshotCustomer) |
| 9 | Country | nvarchar(max) | YES | Customer's KYC country name at @Date from Fact_SnapshotCustomer + Dim_Country. Snapshot value — reflects country at time of alert, not necessarily current country. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via Fact_SnapshotCustomer) |
| 10 | PlayerStatus | nvarchar(max) | YES | Customer's account restriction status at @Date from BI_DB_OPS_MultipleAccounts (sourced from Dim_Customer via that table's SP). Snapshot value. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via BI_DB_OPS_MultipleAccounts) |
| 11 | Club | nvarchar(max) | YES | Customer's eToro Club loyalty tier at @Date from BI_DB_OPS_MultipleAccounts. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via BI_DB_OPS_MultipleAccounts) |
| 12 | AccountType | nvarchar(max) | YES | Customer's account type from Dim_Customer + Dim_AccountType (at @Date via Fact_SnapshotCustomer). Observed value: 'Private'. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via Dim_AccountType) |
| 13 | RiskScoreName | nvarchar(max) | YES | PLATFORM AML risk classification from Dim_RiskClassification at @Date (via Fact_SnapshotCustomer). NOTE: distinct from the eMoney CRA risk used in MA003 trigger logic (eMoney_Customer_Risk_Assessment.ClientRisk). The two can differ for the same customer. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via Fact_SnapshotCustomer) |
| 14 | HasWallet | int | YES | 1 if customer has an active eToro Money wallet product. From Dim_Customer.HasWallet (read via BI_DB_OPS_MultipleAccounts). (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via BI_DB_OPS_MultipleAccounts / Dim_Customer) |
| 15 | AllCIDs | nvarchar(max) | YES | Comma-separated string of ALL CIDs in the multi-account group (ID), e.g. '12345,67890,11111'. Built via STRING_AGG at SP run time from #finalwithIBANS. Enables AML reviewers to see the full linked-account cluster. May change over time as group membership evolves in BI_DB_OPS_MultipleAccounts. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via #ID_CID_Map) |
| 16 | MasterAccountCID | bigint | YES | Master account CID as defined in BI_DB_OPS_MultipleAccounts. The primary account in the linked cluster. May be NULL if no master is designated. May equal CID when the master account itself triggered the alert. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via BI_DB_OPS_MultipleAccounts) |
| 17 | TotalDepositsLifetime | money | YES | Cumulative lifetime settled eMoney deposits (eMoney_Dim_Transaction TxTypeID=7 = MI, IBAN inbound, Settled) for this CID in USD. Snapshot at @Date. eMoney only — does not include platform Fact_BillingDeposit amounts. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via eMoney_Dim_Transaction) |
| 18 | TotalCashoutsLifetime | money | YES | Cumulative lifetime settled eMoney cashouts (eMoney_Dim_Transaction TxTypeID=8 = MO, IBAN outbound, Settled) for this CID in USD. Snapshot at @Date. eMoney only. (Tier 2 — SP_AML_BI_Alerts_MultipleAccountseMoney via eMoney_Dim_Transaction) |
| 19 | UpdateDate | datetime | NO | ETL load timestamp set to GETDATE() at INSERT time. Not a business event timestamp. (Tier 5 — ETL metadata propagation blacklist) |

---

## 5. Lineage

### 5.1 Sources

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_OPS_MultipleAccounts | BI_DB_dbo | Multi-account group spine: ID, MasterAccountCID, HasWallet, PlayerStatus, Club, Regulation |
| eMoney_Dim_Account | eMoney_dbo | Active IBAN count per CID; eMoneyStatus |
| eMoneyClientBalance | eMoney_dbo | eMoney balance at @Date (BalanceDateID=@DateID) |
| eMoney_Customer_Risk_Assessment | eMoney_dbo | eMoney CRA risk label (ClientRisk='High' triggers MA003) |
| eMoney_Dim_Transaction | eMoney_dbo | MIMO transactions: TxTypeID=7 (MI inbound), 8 (MO outbound); Settled status only |
| Fact_SnapshotCustomer | DWH_dbo | Customer snapshot at @DateID for Regulation, Country, RiskClassificationID |
| Dim_Customer | DWH_dbo | AccountTypeID, EvMatchStatusID |
| Dim_Regulation | DWH_dbo | Regulation name decode |
| Dim_Country | DWH_dbo | Country name decode |
| Dim_RiskClassification | DWH_dbo | RiskScoreName decode |
| Dim_AccountType | DWH_dbo | AccountType name decode |
| Dim_Range | DWH_dbo | DateRangeID → FromDateID/ToDateID for Fact_SnapshotCustomer |
| BI_DB_AML_BI_Alerts_MultipleAccountseMoney (self) | BI_DB_dbo | Prior alert history for Total_Alerts_of_TheCategory counter and MA004 cooldown check |

### 5.2 ETL Pipeline

```
BI_DB_OPS_MultipleAccounts
    JOIN eMoney_Dim_Account (Active IBANs per CID)
    JOIN eMoneyClientBalance (balance @DateID)
    JOIN eMoney_Customer_Risk_Assessment
         → #multipleaccounts

#multipleaccounts
    HAVING COUNT(IBAN) > 1 per ID group
         → (ID groups with >1 active IBAN)
    JOIN Fact_SnapshotCustomer + Dim_Range (@DateID range)
    JOIN Dim_Country, Dim_Regulation, Dim_RiskClassification
    JOIN Dim_Customer, Dim_AccountType, Dim_EvMatchStatus
         → #finalwithIBANS  (alert-eligible: multi-IBAN account groups)

eMoney_Dim_Transaction (TxTypeID IN (7,8), Settled)
    GROUP BY ID with time windows
         → #TotalDepositsLifetime / #TotalCashoutsLifetime
         → #AggAmount (running cumulative: SUM OVER(ORDER BY TxCreatedDateID))
         → #50K / #100K / #100Klast12months / #250K / #500K / #750K / #1M
               (milestone thresholds: first row where Agg_AmountUSD > threshold)
         → #event / #eventdep (event-day activity: @DateID transactions)
         → #ExcessiveFundsTransfers   (MA001: 2-3 day in+out >= 100K)
         → #ExcessiveMovementofFunds  (MA002: 3-month in+out >= 400K)
         → #lifetimedepositsHIGH      (MA003: lifetime >= 50K AND eMoney CRA = High)
         → #totaldeposits12M          (MA004: 12-month deposits > 100K)
         → #lifetimedeposits          (MA005: 250K/500K/750K/1M milestones on @DateID)

5 alert branches (IBAN001–005) → UNION → #UNION

STRING_AGG(CID) per ID → #ID_CID_Map (AllCIDs)

Self-join: COUNT prior alerts per ID × AlertType → Total_Alerts_of_TheCategory

DELETE FROM BI_DB_AML_BI_Alerts_MultipleAccountseMoney WHERE AlertDate = @Date
INSERT: #results filtered by:
    IBAN MA003 → only if Total_Alerts_of_TheCategory = 1 (first-time only)
    MA001/002/004/005 → all qualifying rows
```

---

## 6. Data Quality Notes

| Issue | Severity | Detail |
|-------|----------|--------|
| `AlertCategory` has trailing space | LOW | All 5 alert types write `'MIMO '`. Apply `RTRIM()` when filtering. |
| `AlertID` is unstable | INFO | `NEWID()` generates new UUID at INSERT — cannot be used as a stable alert identifier across runs. |
| `RiskScoreName` ≠ eMoney CRA | HIGH | Platform risk (stored) and eMoney CRA (used for MA003 trigger) are independent. A customer can be 'Medium' on platform but 'High' in eMoney CRA. Do not confuse the two. |
| `Total_Alerts_of_TheCategory` counts at group level | INFO | Counter is for the group ID × AlertType combination. Distinct customers (CIDs) within the group each get the same counter in their rows. |
| `TotalDepositsLifetime` is eMoney-only | INFO | Does not include Fact_BillingDeposit platform deposits. Represents only IBAN MI transactions. |
| `AllCIDs` changes over time | INFO | STRING_AGG at SP run time reflects current group membership — past rows may have different AllCIDs values if the group composition changed. |

---

## 7. Relationships

| Related Table | Join Key | Relationship |
|--------------|----------|-------------|
| `BI_DB_dbo.BI_DB_OPS_MultipleAccounts` | ID | Group spine — source for linked account clusters and MasterAccountCID |
| `eMoney_dbo.eMoney_Dim_Transaction` | CID | eMoney MIMO transaction source for all deposit/cashout calculations |
| `eMoney_dbo.eMoney_Customer_Risk_Assessment` | CID | eMoney CRA — used for MA003 trigger (not stored in table) |
| `DWH_dbo.Dim_Customer` | CID = RealCID | Customer master for AccountType, HasWallet, EvMatchStatus |

---

## 8. Atlassian

No direct Confluence documentation found for this specific table. Context:
- Part of the MIMO (Money In / Money Out) AML monitoring suite for eToro Money IBAN wallets.
- Author: Pavlina Masoura. Key change 2025-07-07: IBAN MA003 condition was simplified — removed requirement for a recent risk classification change to High, now fires solely on lifetime deposit threshold + eMoney CRA = High.
- IBAN MA-series codes follow the eToro eMoney AML rule taxonomy. For full IBAN rule documentation, contact the AML compliance / eToro Money team.
