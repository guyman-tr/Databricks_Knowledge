-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_deltaapp_subscription_view
-- Captured: 2026-05-19T14:23:40Z
-- ==========================================================================

SELECT
  data.user_id,
  data.event_date,
  data.account_id,
  data.event_origin,
  data.event_id,
  data.event_type,
  data.event_status,
  data.customer_id,
  data.product_id,
  data.price_id,
  data.subscription_interval,
  data.subscription_type,
  data.subscription_plan_id,
  data.period_start_date,
  data.period_end_date,
  data.trial_active,
  data.payment_amount,
  data.payment_amount_received,
  data.payment_amount_refunded,
  data.payment_currency,
  data.payment_method
FROM
  main.bi_db.bronze_deltaapp_bronze_subscriptions
  LATERAL VIEW
    EXPLODE(
      from_json(
        json_text,
        'array<struct<
            user_id: string,
            event_date: string,
            account_id: string,
            event_origin: string,
            event_id: string,
            event_type: string,
            event_status : string,
            customer_id: string,
            product_id: string,
            price_id: string,
            subscription_interval: string,
            subscription_type: string,
            subscription_plan_id: string,
            period_start_date: string,
            period_end_date: string,
            trial_active: string,
            payment_amount: float,
            payment_amount_received: float,
            payment_amount_refunded: float,
            payment_currency: string,
            payment_method: string
        >>'
      )
    ) AS data
