# Billing.DepositAlertReportByRiskManagementStatus

> Returns a count of DeclineByRRE deposits grouped by Risk Management decline reason for deposits from the specified DepositID window, for use by the DepositAlert monitoring service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositIDFrom defines the current alert window; filters PaymentStatusID=35 (DeclineByRRE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositAlertReportByRiskManagementStatus` is the third report in the DepositAlert service family (ticket 46780, deployed in a follow-up as ticket 49800, Geri Reshef, 14/12/2017). It provides a breakdown of deposits declined by the Risk Rules Engine (`PaymentStatusID=35 = DeclineByRRE`) by the specific risk reason that caused the decline.

When the Risk Rules Engine (RRE) declines a deposit, it sets `Billing.Deposit.PaymentStatusID=35` and records the specific decline reason in `Billing.Deposit.RiskManagementStatusID`. This procedure aggregates those declines by reason name, giving the DepositAlert service a fast view of which risk rules are firing most frequently in the current monitoring window.

Unlike the other DepositAlert procedures, this report has only a single DepositID parameter (`@DepositIDFrom`) with no previous-period comparison. It is a "current window" snapshot only - the DepositAlert service is expected to compare across calls rather than within a single call.

Key `Dictionary.RiskManagementStatus` values include: CardIsBlocked, BinInBlackList, MemberLimit, FundingTypeLimit, OverTheLimit, DeclinedHighRiskDeposit, MultipleDepositsAggregatedAmount, LoginToRegCountryConflict, and many others. Sudden spikes in any of these counts indicate specific fraud patterns or configuration issues.

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space).

---

## 2. Business Logic

### 2.1 DeclineByRRE Count by Risk Reason

**What**: Counts all RRE-declined deposits from the current window, grouped by the specific risk reason that triggered the decline.

**Columns/Parameters Involved**: `@DepositIDFrom`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.RiskManagementStatusID`, `Dictionary.RiskManagementStatus.Name`

**Rules**:
- Filter: `PaymentStatusID=35` (DeclineByRRE - declined by Risk Rules Engine) only
- Filter: `DepositID >= @DepositIDFrom` (current alert window)
- JOIN to Dictionary.RiskManagementStatus on RiskManagementStatusID -> gets the decline reason Name
- GROUP BY: r.Name (the risk reason name)
- COUNT(*) per group
- ORDER BY: Count ASC (lowest count first - useful for spotting new/emerging patterns as they grow)

**Output columns**:
| Column | Description |
|--------|-------------|
| Name | Risk management decline reason (e.g., CardIsBlocked, BinInBlackList, MemberLimit) |
| Count | Number of DeclineByRRE deposits with this reason in the current window |

**Risk reason reference** (from Dictionary.RiskManagementStatus):
| ID | Name | Meaning |
|----|------|---------|
| 1 | Success | Passed risk checks |
| 2 | CardIsBlocked | Specific card is on the block list |
| 3 | BinInBlackList | Card BIN (bank identifier number) is blacklisted |
| 4 | MemberLimit | Customer has reached their deposit limit |
| 5 | FundingTypeLimit | Payment method deposit limit exceeded |
| 10 | DeclinedBlackListCountry | Country is on the restricted list |
| 11 | DeclinedHighRiskDeposit | Deposit flagged as high-risk |
| 12 | OverTheLimit | Total deposit volume limit exceeded |
| 13 | DeclinedTooManyCreditCards | Too many different cards used |
| 17 | MultipleDepositsAggregatedAmount | Multiple small deposits aggregate over limit |
| 18 | LoginToRegCountryConflict | Login country conflicts with registration country |
| 20 | OverTheLimitSingleDeposit | Single deposit amount limit exceeded |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositIDFrom | INT | NO | - | CODE-BACKED | Lower bound of the monitoring window. All deposits with DepositID >= this value and PaymentStatusID=35 (DeclineByRRE) are included in the count. Used as a time proxy - the DepositAlert service computes the appropriate DepositID boundary for each alert cycle. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DeclineByRRE deposits | Billing.Deposit | Read | Filters PaymentStatusID=35 deposits from the alert window. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| Risk decline reason | Dictionary.RiskManagementStatus | Read | Resolves RiskManagementStatusID to a human-readable decline reason name. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the DepositAlert monitoring service to surface RRE decline pattern spikes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositAlertReportByRiskManagementStatus (procedure)
├── Billing.Deposit (table)
└── Dictionary.RiskManagementStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of DeclineByRRE deposits with RiskManagementStatusID |
| Dictionary.RiskManagementStatus | Table | Lookup: RiskManagementStatusID -> decline reason Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositAlert monitoring service | External (App) | Risk Rules Engine decline pattern monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get current RRE decline breakdown for the last 1000 deposits

```sql
DECLARE @From INT;
SELECT @From = MAX(DepositID) - 1000
FROM Billing.Deposit WITH (NOLOCK);

EXEC Billing.DepositAlertReportByRiskManagementStatus
    @DepositIDFrom = @From;
```

### 8.2 Manual query: RRE decline reasons for a recent window

```sql
SELECT r.Name AS DeclineReason,
       COUNT(*) AS DeclineCount,
       SUM(d.Amount) AS TotalAmountDeclined
FROM Billing.Deposit d WITH (NOLOCK)
    JOIN Dictionary.RiskManagementStatus r WITH (NOLOCK)
        ON d.RiskManagementStatusID = r.RiskManagementStatusID
WHERE d.PaymentStatusID = 35  -- DeclineByRRE
  AND d.DepositID >= 5000000
GROUP BY r.Name
ORDER BY DeclineCount DESC;
```

### 8.3 Check proportion of RRE declines vs. total declines

```sql
SELECT
    SUM(CASE WHEN d.PaymentStatusID = 35 THEN 1 ELSE 0 END) AS DeclineByRRE,
    SUM(CASE WHEN d.PaymentStatusID = 3  THEN 1 ELSE 0 END) AS GatewayDecline,
    SUM(CASE WHEN d.PaymentStatusID = 4  THEN 1 ELSE 0 END) AS TechnicalDecline,
    COUNT(*) AS TotalDeposits
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.DepositID >= 5000000;
```

---

## 9. Atlassian Knowledge Sources

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space) - not accessible. Ticket 46780 (Geri Reshef, 11/07/2017): initial DepositAlert service deployment. Ticket 49800 (Geri Reshef, 14/12/2017): "DB: deploy SP DepositAlertReportByRiskManagementStatus for Deposit alert service" - specific deployment of this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 1 Confluence (not accessible) + 2 Jira tickets (46780, 49800) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositAlertReportByRiskManagementStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositAlertReportByRiskManagementStatus.sql*
