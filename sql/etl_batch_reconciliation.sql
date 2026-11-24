-- Oracle SQL: reconcile staged and target ETL batches.
-- Assumed source: STG_ORDERS(LOAD_BATCH_ID, ORDER_ID, ORDER_AMOUNT).
-- Assumed target: FACT_ORDERS(LOAD_BATCH_ID, ORDER_ID, ORDER_AMOUNT).
-- Bind :p_batch_id to the batch under investigation.
--
-- Read-only diagnostic. This query compares row counts and amounts by batch,
-- then returns only reconciliation mismatches. Confirm whether target rows
-- represent accepted rows only and whether ORDER_AMOUNT may legitimately be NULL.

WITH source_metrics AS (
    SELECT
        load_batch_id,
        COUNT(*) AS source_row_count,
        COUNT(order_id) AS source_nonnull_order_ids,
        COUNT(DISTINCT order_id) AS source_distinct_order_ids,
        SUM(order_amount) AS source_amount
    FROM stg_orders
    WHERE load_batch_id = :p_batch_id
    GROUP BY load_batch_id
),
target_metrics AS (
    SELECT
        load_batch_id,
        COUNT(*) AS target_row_count,
        COUNT(order_id) AS target_nonnull_order_ids,
        COUNT(DISTINCT order_id) AS target_distinct_order_ids,
        SUM(order_amount) AS target_amount
    FROM fact_orders
    WHERE load_batch_id = :p_batch_id
    GROUP BY load_batch_id
),
reconciliation AS (
    SELECT
        COALESCE(s.load_batch_id, t.load_batch_id) AS load_batch_id,
        NVL(s.source_row_count, 0) AS source_row_count,
        NVL(t.target_row_count, 0) AS target_row_count,
        NVL(s.source_distinct_order_ids, 0) AS source_distinct_order_ids,
        NVL(t.target_distinct_order_ids, 0) AS target_distinct_order_ids,
        s.source_amount,
        t.target_amount
    FROM source_metrics s
    FULL OUTER JOIN target_metrics t
      ON t.load_batch_id = s.load_batch_id
)
SELECT
    load_batch_id,
    source_row_count,
    target_row_count,
    target_row_count - source_row_count AS row_count_difference,
    source_distinct_order_ids,
    target_distinct_order_ids,
    source_amount,
    target_amount,
    CASE
        WHEN source_row_count = 0 THEN 'SOURCE_BATCH_MISSING'
        WHEN target_row_count = 0 THEN 'TARGET_BATCH_MISSING'
        WHEN source_row_count <> target_row_count THEN 'ROW_COUNT_MISMATCH'
        WHEN source_distinct_order_ids <> target_distinct_order_ids
            THEN 'DISTINCT_KEY_MISMATCH'
        WHEN NVL(source_amount, 0) <> NVL(target_amount, 0)
            THEN 'AMOUNT_MISMATCH'
        ELSE 'RECONCILED'
    END AS reconciliation_status
FROM reconciliation
WHERE source_row_count IS NULL
   OR target_row_count IS NULL
   OR source_row_count <> target_row_count
   OR source_distinct_order_ids <> target_distinct_order_ids
   OR NVL(source_amount, 0) <> NVL(target_amount, 0)
ORDER BY load_batch_id;

-- Operational checklist:
-- 1. Run after the target load completes and before downstream publication.
-- 2. If counts differ, inspect rejected rows, filters, and batch boundaries.
-- 3. If distinct keys differ, investigate duplicates and missing business keys.
-- 4. If amounts differ, compare currency, rounding, NULL handling, and adjustments.
-- 5. A zero-row result means these aggregate checks found no mismatch; it does
--    not prove row-by-row equality. Add key-level anti-joins when needed.
-- 6. Record the batch ID, run timestamp, query result, and incident/ticket ID
--    in the operational audit trail.
