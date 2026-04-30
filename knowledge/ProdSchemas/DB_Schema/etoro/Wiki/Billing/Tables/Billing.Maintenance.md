# Billing.Maintenance

> Configuration table tracking the operational status (Active / Under Maintenance / Inactive) of each payment method, with optional scheduled maintenance windows and description.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY(1,2), PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on ID) |

---

## 1. Business Meaning

Billing.Maintenance stores the current operational status for each payment method (FundingType) on the eToro platform. Before presenting a payment method to a customer in the deposit or withdrawal UI, the system checks this table to determine whether the method is Active, Under Maintenance, or Inactive. If a payment method is under maintenance, it is hidden from the UI to prevent customers from initiating transactions that will fail.

This table is one of several layers of payment method control (alongside Dictionary.FundingType.IsFundingTypeActive). It provides a runtime-editable maintenance flag that can be toggled without a deployment, while Dictionary.FundingType.IsFundingTypeActive represents the more permanent platform-level activation. Billing.Maintenance is used for temporary outages and scheduled maintenance windows.

Data is written by Billing.UpsertMaintenance (MERGE by FundingTypeID) and read by Billing.GetCustomerDepositInfo (which assembles the deposit page context). Every INSERT, UPDATE, or DELETE is archived to History.Maintenance via trigger Tr_Billing_Maintenance. The table covers 26 payment methods; 7 are currently flagged as UnderMaintenance (predominantly Russian, Chinese, and discontinued payment providers).

---

## 2. Business Logic

### 2.1 Payment Method Status States

**What**: Each payment method has exactly one status that controls its visibility in the deposit/withdrawal UI.

**Columns/Parameters Involved**: `StatusID`, `FundingTypeID`

**Rules**:
- **StatusID=1 (Active)**: Payment method is operational. Shown in UI. Deposits and/or cashouts allowed.
- **StatusID=3 (UnderMaintenance)**: Payment method temporarily unavailable. Hidden from deposit/cashout UI. No new transactions allowed.
- **StatusID=5 (InActive)**: Payment method permanently disabled. No rows currently use this status - it may be reserved for decommissioning.
- The MERGE pattern in Billing.UpsertMaintenance ensures one row per FundingTypeID. Calling UpsertMaintenance with StatusID=3 immediately suppresses that payment method.
- Methods currently Under Maintenance (as of 2026-03-17): WebMoney (10), Yandex (21), CashU (24), AliPay (25), WeChat (26), AstroPay (31), Qiwi (23) - these are primarily discontinued Russian/Chinese payment providers.

### 2.2 Scheduled Maintenance Windows

**What**: ScheduledFrom and ScheduledTo record when a maintenance event was planned to occur.

**Columns/Parameters Involved**: `ScheduledFrom`, `ScheduledTo`, `Description`

**Rules**:
- Both fields are NULL for most rows - maintenance is applied immediately without scheduling.
- Historical data shows scheduled windows (2017 dates for WireTransfer, MoneyBookers, UnionPay; 2021 for OpenBanking).
- Billing.UpsertMaintenance always sets ScheduledFrom/To to NULL on update, meaning the MERGE SP no longer supports scheduling - windows must be set via direct SQL.
- Description captures a human-readable note for the maintenance event (e.g., "Start"). Most rows have empty string or NULL.

### 2.3 Duplicate CreditCard Row

**What**: FundingTypeID=1 (CreditCard) has two rows (ID=1 and ID=25).

**Columns/Parameters Involved**: `FundingTypeID`, `ID`

**Rules**:
- ID=1 (original, IDENTITY(1,2) seed) and ID=25 are both StatusID=1 Active.
- This is a data defect - the MERGE in UpsertMaintenance uses FundingTypeID as the unique key, so it would update ID=1. ID=25 is an orphan duplicate.
- No unique constraint exists on FundingTypeID, allowing this duplication.

---

## 3. Data Overview

| ID | FundingTypeID | FundingTypeName | StatusID | StatusName | ScheduledFrom | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | CreditCard | 1 | Active | NULL | Credit card deposits and withdrawals are operational. Most critical payment method - always kept Active. |
| 11 | 10 | WebMoney | 3 | UnderMaintenance | NULL | WebMoney suspended indefinitely. Russian e-wallet discontinued due to sanctions/regulatory issues. No return to active expected. |
| 15 | 21 | Yandex | 3 | UnderMaintenance | NULL | Yandex.Money suspended. Russian payment method removed due to 2022 sanctions. Permanently under maintenance. |
| 40 | 38 | OpenBanking | 1 | Active | 2021-07-26 13:26 | OpenBanking active. Historical scheduled window from July 2021 (2-hour maintenance window, Description="Start"). Now fully operational. |
| 1027 | 43 | GCCInstantBankTransfer | 1 | Active | NULL | Gulf Cooperation Council instant bank transfer active. ID=1027 is unusually high - the identity was reseeded between ID=44 and this row. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,2) | CODE-BACKED | Surrogate primary key. Identity seed=1, increment=2, producing odd IDs for original rows (1,3,5...25). Increment changed at some point - later rows include even IDs (34,36,38,40,42,44) and then ID=1027, suggesting manual reseeding. No business meaning beyond row identification. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier. Natural key for business lookups - Billing.UpsertMaintenance merges on this column. Implicit FK to Dictionary.FundingType. No unique constraint - allows duplicates (CreditCard has two rows: ID=1 and ID=25). |
| 3 | StatusID | int | NO | - | VERIFIED | Operational status of the payment method. 1=Active (visible in UI, transactions allowed), 3=UnderMaintenance (hidden from UI, transactions blocked), 5=InActive (permanently disabled, no rows currently). Explicit FK to Dictionary.BillingMaintenanceStatus. See Section 2.1 for current status by method. |
| 4 | ScheduledFrom | datetime | YES | - | CODE-BACKED | UTC start of a planned maintenance window. NULL for immediate/unscheduled maintenance. Billing.UpsertMaintenance always sets this to NULL, so scheduling requires direct SQL update. Historical values show old maintenance windows that were never cleared. |
| 5 | ScheduledTo | datetime | YES | - | CODE-BACKED | UTC end of a planned maintenance window. NULL for open-ended maintenance. Same caveat as ScheduledFrom - UpsertMaintenance resets to NULL. Most historical rows have stale past dates (2017-2021). |
| 6 | Description | nvarchar(500) | YES | - | CODE-BACKED | Free-text note about the maintenance event. Most rows have empty string or NULL. Only meaningful example in current data: OpenBanking (ID=40) has Description="Start" from its 2021 maintenance window. Passed as @Description parameter to Billing.UpsertMaintenance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.BillingMaintenanceStatus | FK (explicit) | 1=Active, 3=UnderMaintenance, 5=InActive. |
| FundingTypeID | Dictionary.FundingType | Implicit | References the payment method definition. No declared FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpsertMaintenance | FundingTypeID | MERGE writer | Primary write path - inserts or updates the status for a payment method. |
| Billing.GetCustomerDepositInfo | StatusID | Reader | Reads maintenance status as part of assembling the customer deposit page. |
| History.Maintenance | (trigger target) | Trigger | Receives archived copies of all INSERT/UPDATE/DELETE via Tr_Billing_Maintenance. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Maintenance (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BillingMaintenanceStatus | Table | Explicit FK target for StatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpsertMaintenance | Stored Procedure | MERGE writer (INSERT + UPDATE) |
| Billing.GetCustomerDepositInfo | Stored Procedure | Reader - deposit page assembly |
| History.Maintenance | Table | Trigger-written audit archive |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_Maintenance | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_Maintenance | PRIMARY KEY | ID column |
| FK_Billing_Maintenance_StatusID | FK | StatusID -> Dictionary.BillingMaintenanceStatus(ID) |
| Tr_Billing_Maintenance | TRIGGER | AFTER INSERT, UPDATE, DELETE - archives both INSERTED and DELETED rows to History.Maintenance (IsInserted=1 for new state, IsInserted=0 for old state) |

---

## 8. Sample Queries

### 8.1 Get current status of all payment methods

```sql
SELECT
    ft.Name AS PaymentMethod,
    ms.Name AS Status,
    m.ScheduledFrom,
    m.ScheduledTo,
    m.Description
FROM Billing.Maintenance m WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON m.FundingTypeID = ft.FundingTypeID
JOIN Dictionary.BillingMaintenanceStatus ms WITH (NOLOCK) ON m.StatusID = ms.ID
ORDER BY ms.ID, ft.Name
```

### 8.2 Put a payment method under maintenance

```sql
-- Immediately suspend a payment method (hides from UI)
EXEC Billing.UpsertMaintenance
    @FundingTypeID = 3,         -- PayPal
    @StatusID = 3,              -- UnderMaintenance
    @Description = 'PayPal API outage - JIRA-1234'
```

### 8.3 Find payment methods currently under maintenance

```sql
SELECT
    ft.Name AS PaymentMethod,
    m.Description,
    m.ScheduledFrom,
    m.ScheduledTo
FROM Billing.Maintenance m WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON m.FundingTypeID = ft.FundingTypeID
WHERE m.StatusID = 3  -- UnderMaintenance
ORDER BY ft.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED (StatusID), 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Maintenance | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Maintenance.sql*
