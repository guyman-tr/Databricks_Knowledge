# BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany

> 226K-row daily TRUNCATE snapshot tracking the Tangany crypto wallet transition status for German customers, including Terms & Conditions, selfie verification, and confirmation popup completion states. Sourced from DWH_dbo.Dim_Customer, External_UserApiDB_Dictionary_TanganyStatus, and External_ComplianceStateDB_Compliance_CustomerInteractions via SP_BI_DB_German_Crypto_Transition_To_Tangany.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + UserApiDB.Dictionary.TanganyStatus + ComplianceStateDB.Compliance.CustomerInteractions via `BI_DB_dbo.SP_BI_DB_German_Crypto_Transition_To_Tangany` |
| **Refresh** | Daily (SB_Daily), TRUNCATE+INSERT |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_German_Crypto_Transition_To_Tangany tracks the **crypto custody transition** for German customers moving to the **Tangany wallet provider**. Under MiCA (Markets in Crypto-Assets Regulation) and BaFin requirements, eToro's German crypto customers must transition to Tangany-based custody accounts. This table provides a daily snapshot of each customer's progress through the multi-step onboarding workflow.

Each row represents one German customer with a Tangany ID (from Dim_Customer WHERE TanganyID IS NOT NULL). The workflow involves three customer interaction steps tracked via ComplianceStateDB:
1. **Terms & Conditions (UserInteractionId=45)** — crypto custody agreement acceptance
2. **Selfie Popup (UserInteractionId=46)** — identity re-verification via selfie
3. **Confirmation Popup (UserInteractionId=47)** — final acknowledgment of custody transfer

**Key metrics**: 226,618 customers with Tangany IDs. Status distribution: Inactive (33.5%), Internal (24.9%), MicaCustomer (23.3%), Customer (18.2%), ConsentCustomer (0.06%), Pending (0.03%). T&C engagement: 186,971 users encountered T&C (82.5%), 139,087 completed (61.4%). Selfie popup: 37,304 encountered (16.5%), 21,611 completed (9.5%). Confirmation popup: 69,503 encountered (30.7%), 68,590 completed (30.3%).

---

## 2. Business Logic

### 2.1 Population — German Users with Tangany IDs

**What**: Identifies customers who have been assigned a Tangany crypto custody account.
**Columns Involved**: RealCID, GCID, TanganyID, TanganyStatusID, TanganyStatus
**Rules**:
- From Dim_Customer WHERE TanganyID IS NOT NULL
- JOIN to External_UserApiDB_Dictionary_TanganyStatus for status name
- TanganyStatus values: 1=Pending (created ID, no account), 2=Internal (opened account), 3=Customer (linked), 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer

### 2.2 Three-Step Interaction Tracking (PIVOT Pattern)

**What**: Converts row-level CustomerInteractions into per-user flag columns via CASE+MAX aggregation.
**Columns Involved**: Is_TC/Is_Active_TC/Is_Completed_TC/TC_LastCompletionDate (and Selfie/Confirmation equivalents)
**Rules**:
- Each interaction type (45, 46, 47) produces four columns: exists flag, active flag, completed flag, last completion date
- **Completed definition**: IsCompleted=1 AND IsActive=0 — the interaction is done and no longer active
- **Active definition**: IsActive=1 — the interaction is currently presented to the user
- **Sentinel date**: 1900-01-01 = interaction not completed or not encountered
- LEFT JOIN from population to interactions — customers without interactions get NULL flags (not 0)

### 2.3 Tangany Status Progression

**What**: Tracks the customer's wallet provisioning status.
**Columns Involved**: TanganyStatusID, TanganyStatus
**Rules**:
- 1=Pending: Tangany ID created but account not opened
- 2=Internal: Tangany account opened
- 3=Customer: Tangany customer created and linked to account
- 4=Inactive: Account deactivated
- 5=MicaCustomer: Fully transitioned under MiCA regulation
- 6=ConsentCustomer: Consent-based transition (rare, 140 users)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) — co-located JOINs on RealCID. HEAP storage (no clustered index). For queries filtering by TanganyStatusID, consider adding WHERE clause early. TRUNCATE pattern = always current snapshot.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many users completed all 3 steps? | `SELECT COUNT(*) FROM BI_DB_German_Crypto_Transition_To_Tangany WHERE Is_Completed_TC = 1 AND Is_Completed_Selfie_Popup = 1 AND Is_Completed_Confirmation_Popup = 1` |
| Tangany status funnel | `SELECT TanganyStatus, COUNT(*) cnt, SUM(CASE WHEN Is_Completed_TC=1 THEN 1 ELSE 0 END) tc_done FROM ... GROUP BY TanganyStatus` |
| Users stuck at active T&C | `SELECT * FROM ... WHERE Is_Active_TC = 1 AND Is_Completed_TC = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Additional customer attributes (country, regulation, VL) |
| BI_DB_dbo.BI_DB_PositionPnL | CID = RealCID | Check current crypto positions for transitioning users |

### 3.4 Gotchas

- **NULL interaction flags** — customers who were never presented an interaction (not in ComplianceStateDB for that UserInteractionId) get NULL, not 0. Filter with `ISNULL(Is_TC, 0) = 1` or `Is_TC = 1`.
- **Sentinel date 1900-01-01** — TC_LastCompletionDate, Selfie_Popup_LastCompletionDate, and Confirmation_Popup_LastCompletionDate use 1900-01-01 as "not completed" sentinel. Do NOT treat as real dates.
- **TanganyStatus comes from External table** — the Dictionary_TanganyStatus values are loaded via data lake from UserApiDB. If new statuses are added in production, they appear automatically on next pipeline refresh.
- **TRUNCATE table** — no historical tracking. Only the current state is available. For trend analysis, snapshots must be taken externally.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Domain expert input or ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | TanganyID | nvarchar(max) | YES | Tangany crypto custody integration ID. UUID format (e.g., '56eec52d-4d56-448a-b502-10b2aa1d8f6f'). Always NOT NULL in this table (population filter). Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 4 | TanganyStatusID | int | YES | Tangany integration status ID. 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. FK to External_UserApiDB_Dictionary_TanganyStatus. (Tier 2 — SP_Dim_Customer) |
| 5 | TanganyStatus | varchar(50) | YES | Tangany status name from UserApiDB.Dictionary.TanganyStatus. 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 6 | Is_TC | int | YES | Flag: 1 if Terms & Conditions interaction (UserInteractionId=45) exists for this user, 0 if not. NULL if user not found in CustomerInteractions at all. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 7 | Is_Active_TC | int | YES | Flag: 1 if T&C interaction is currently active (presented to user, not yet completed), 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 8 | Is_Completed_TC | int | YES | Flag: 1 if T&C interaction is completed (IsCompleted=1 AND IsActive=0), 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 9 | TC_LastCompletionDate | datetime2(7) | YES | Last completion datetime for T&C interaction. Sentinel: 1900-01-01 = not completed or not encountered. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 10 | Is_Selfie_Popup | int | YES | Flag: 1 if Selfie verification popup (UserInteractionId=46) exists for this user, 0 if not. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 11 | Is_Active_Selfie_Popup | int | YES | Flag: 1 if Selfie popup is currently active, 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 12 | Is_Completed_Selfie_Popup | int | YES | Flag: 1 if Selfie popup is completed (IsCompleted=1 AND IsActive=0), 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 13 | Selfie_Popup_LastCompletionDate | datetime2(7) | YES | Last completion datetime for Selfie popup. Sentinel: 1900-01-01 = not completed or not encountered. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 14 | Is_Confirmation_Popup | int | YES | Flag: 1 if Confirmation popup (UserInteractionId=47) exists for this user, 0 if not. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 15 | Is_Active_Confirmation_Popup | int | YES | Flag: 1 if Confirmation popup is currently active, 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 16 | Is_Completed_Confirmation_Popup | int | YES | Flag: 1 if Confirmation popup is completed (IsCompleted=1 AND IsActive=0), 0 otherwise. NULL if not in CustomerInteractions. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 17 | Confirmation_Popup_LastCompletionDate | datetime2(7) | YES | Last completion datetime for Confirmation popup. Sentinel: 1900-01-01 = not completed or not encountered. (Tier 2 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |
| 18 | UpdateDate | datetime2(7) | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_BI_DB_German_Crypto_Transition_To_Tangany) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| TanganyID | DWH_dbo.Dim_Customer | TanganyID | Passthrough (NOT NULL filter) |
| TanganyStatusID | DWH_dbo.Dim_Customer | TanganyStatusID | Passthrough |
| TanganyStatus | External_UserApiDB_Dictionary_TanganyStatus | Name | Passthrough via TanganyStatusID JOIN |
| Is_TC through Is_Completed_TC | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive, IsCompleted | CASE+MAX PIVOT for UserInteractionId=45 |
| TC_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | MAX with ISNULL sentinel for ID=45 |
| Is_Selfie_Popup through Is_Completed_Selfie_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive, IsCompleted | CASE+MAX PIVOT for UserInteractionId=46 |
| Selfie_Popup_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | MAX with ISNULL sentinel for ID=46 |
| Is_Confirmation_Popup through Is_Completed_Confirmation_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive, IsCompleted | CASE+MAX PIVOT for UserInteractionId=47 |
| Confirmation_Popup_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | MAX with ISNULL sentinel for ID=47 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
UserApiDB.Dictionary.TanganyStatus (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
BI_DB_dbo.External_UserApiDB_Dictionary_TanganyStatus (external table)

ComplianceStateDB.Compliance.CustomerInteractions (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions (external table)

etoro.Customer.CustomerStatic (production, TanganyID)
  |-- Generic Pipeline → SP_Dim_Customer ---|
  v
DWH_dbo.Dim_Customer (TanganyID, GCID, RealCID)
  |
  |-- SP_BI_DB_German_Crypto_Transition_To_Tangany ---|
  |   (TRUNCATE + 3-step interaction PIVOT via CASE+MAX)
  v
BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany (226K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer.RealCID | German customer with Tangany ID |
| GCID | DWH_dbo.Dim_Customer.GCID | Group customer identity |
| TanganyStatusID | External_UserApiDB_Dictionary_TanganyStatus.TanganyStatusID | Tangany status lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo codebase.

---

## 7. Sample Queries

### 7.1 Tangany Transition Funnel

```sql
SELECT TanganyStatus,
       COUNT(*) AS TotalUsers,
       SUM(CASE WHEN Is_Completed_TC = 1 THEN 1 ELSE 0 END) AS CompletedTC,
       SUM(CASE WHEN Is_Completed_Selfie_Popup = 1 THEN 1 ELSE 0 END) AS CompletedSelfie,
       SUM(CASE WHEN Is_Completed_Confirmation_Popup = 1 THEN 1 ELSE 0 END) AS CompletedConfirmation
FROM BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany
GROUP BY TanganyStatus
ORDER BY TotalUsers DESC
```

### 7.2 Users Stuck in Active T&C Step

```sql
SELECT RealCID, GCID, TanganyStatus, TC_LastCompletionDate
FROM BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany
WHERE Is_Active_TC = 1 AND ISNULL(Is_Completed_TC, 0) = 0
ORDER BY RealCID
```

### 7.3 Fully Transitioned MiCA Customers

```sql
SELECT RealCID, GCID, TanganyID,
       TC_LastCompletionDate, Selfie_Popup_LastCompletionDate, Confirmation_Popup_LastCompletionDate
FROM BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany
WHERE TanganyStatusID = 5
  AND Is_Completed_TC = 1
  AND Is_Completed_Selfie_Popup = 1
  AND Is_Completed_Confirmation_Popup = 1
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 15 T2, 0 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany | Type: Table | Production Source: Dim_Customer + UserApiDB + ComplianceStateDB via SP_BI_DB_German_Crypto_Transition_To_Tangany*
