# BI_DB_dbo.BI_DB_RAF_Invitees_KPIs — Column Lineage

## Writer SP
`BI_DB_dbo.SP_RAF_InviteeAbuser` — rolling DELETE+INSERT WHERE registered >= @Last2months

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | Population base (SerialID=11, registered>=@Last2months), invitee CID, inviter, registration, FTD, country, state |
| BI_DB_dbo.History_Credit_Range | BI_DB_dbo | RAF compensation payments (CompensationReasonID 53=inviter, 54=invitee, CreditTypeID=6) |
| DWH_dbo.Dim_Position | DWH_dbo | Trading activity (SUM Amount) within 30 days of FTD |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | Deposits (ActionTypeID=7), Cashouts (ActionTypeID=8), Logins+IP (ActionTypeID=14) |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | BI_DB_dbo | IsFunded_New check 14 days after FTD |
| DWH_dbo.Dim_Customer | DWH_dbo | Inviter's RegulationID for payment amount determination |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Invitee | BI_DB_CIDFirstDates | RealCID | passthrough (PK) |
| Country | BI_DB_CIDFirstDates | Country | passthrough |
| State | BI_DB_CIDFirstDates | State | passthrough |
| Inviter | BI_DB_CIDFirstDates | ReferralID | passthrough |
| registered | BI_DB_CIDFirstDates | registered | passthrough |
| FirstDepositDate | BI_DB_CIDFirstDates | FirstDepositDate | passthrough |
| FirstDepositAmount | BI_DB_CIDFirstDates | FirstDepositAmount | passthrough |
| FunnelName | (legacy) | — | Not populated by current SP |
| DesignatedRegulationID | (legacy) | — | Not populated by current SP |
| PaymentToInvitee | History_Credit_Range | Payment | WHERE CompensationReasonID=54, CreditTypeID=6, invitee CID match |
| PaymentToInviter | History_Credit_Range | Payment | WHERE CompensationReasonID=53, CreditTypeID=6, invitee CID in Description |
| RevenueFromUser | (legacy) | — | Not populated by current SP |
| NoOfTotalDeposits | Fact_CustomerAction | COUNT(*) | WHERE ActionTypeID=7, Occurred >= registered |
| TotalDepositAmount | Fact_CustomerAction | SUM(Amount) | WHERE ActionTypeID=7, Occurred >= registered |
| UpdateDate | (computed) | — | GETDATE() |
| NoOfTotalCashout | (legacy) | — | Not populated by current SP |
| TotalCashoutAmount | Fact_CustomerAction | SUM(Amount) | WHERE ActionTypeID=8, Occurred >= registered |
| FirstPosOpenDate | (legacy) | — | Not populated by current SP |
| Compensation_date | History_Credit_Range | MAX(Occurred) | WHERE CompensationReasonID=54 for invitee |
| Cashout_request | (legacy) | — | Not populated by current SP |
| Cashout_date | (legacy) | — | Not populated by current SP |
| Revenue14days | (legacy) | — | Not populated by current SP |
| NewTrades | Dim_Position | SUM(Amount) | WHERE OpenDateID within 30 days of FTD (renamed from PositionsAmount) |
| FTDMeanOfPayment | (legacy) | — | Not populated by current SP |
| LastCashoutDate | (legacy) | — | Not populated by current SP |
| MatualIPAdress30Days | Fact_CustomerAction | CASE | 1 if invitee+inviter share IP (ActionTypeID=14) within 30 days of FTD |
| TradesAmount | (legacy) | — | Not populated by current SP |
| TradesAmount_tillRAFbonus | (legacy) | — | Not populated by current SP |
| Date_AccTrade100_Invitee | (legacy) | — | Not populated by current SP |
| Date_AccTrade100_Inviter | (legacy) | — | Not populated by current SP |
| NoOfTotalCashout14DaysFromFTD | Fact_CustomerAction | COUNT(*) | WHERE ActionTypeID=8, within 14 days of FTD |
| TotalCashoutAmount14DaysFromFTD | Fact_CustomerAction | SUM(Amount) | WHERE ActionTypeID=8, within 14 days of FTD |
| IsFundedAfter14Days | BI_DB_CID_DailyPanel_FullData | IsFunded_New | 14 days after FTD |
| TotalCashoutAmountAfterCompensation | Fact_CustomerAction | SUM(Amount) | WHERE ActionTypeID=8, within 7 days after Compensation_date |
| EligibleForCompensation | (computed) | — | 1 if (Global AND NewTrades>=100) OR (US AND FTD>=100) |
| isCashoutAfterCompensation | (computed) | — | 1 if TotalCashoutAmountAfterCompensation >= PaymentToInvitee |
| isFTD30days | (computed) | — | 1 if FirstDepositDate within 30 days of registered |
| isAbuser | (computed) | — | 1 if MatualIPAdress30Days=1 OR isCashoutAfterCompensation=1 |

**PHASE 10B CHECKPOINT: PASS**
