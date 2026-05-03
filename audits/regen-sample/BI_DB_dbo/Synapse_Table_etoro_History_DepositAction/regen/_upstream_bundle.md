# Pre-Resolved Upstream Bundle for `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction.sql`

```sql
CREATE TABLE [BI_DB_dbo].[Synapse_Table_etoro_History_DepositAction]
(
	[DepositActionID] [int] NULL,
	[DepositID] [int] NULL,
	[PaymentActionStatusID] [int] NULL,
	[PaymentActionTypeID] [int] NULL,
	[PaymentStatusID] [int] NULL,
	[ResponseID] [int] NULL,
	[ManagerID] [int] NULL,
	[ExchangeRate] [numeric](16, 8) NULL,
	[ApprovalNumber] [varchar](max) NULL,
	[AuthCode] [varchar](max) NULL,
	[ModificationDate] [datetime2](7) NULL,
	[ClearingHouseEffectiveDate] [datetime2](7) NULL,
	[Amount] [numeric](19, 4) NULL,
	[CurrencyID] [int] NULL,
	[MatchStatusID] [int] NULL,
	[Remark] [varchar](max) NULL,
	[SessionID] [bigint] NULL,
	[DepotID] [int] NULL,
	[ExchangeFee] [int] NULL,
	[BaseExchangeRate] [numeric](16, 8) NULL,
	[PaymentGeneration] [int] NULL,
	[ProcessRegulationID] [int] NULL,
	[MerchantAccountID] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
