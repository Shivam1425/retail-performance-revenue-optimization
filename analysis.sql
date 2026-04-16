/* =========================================================
PROJECT: Retail Performance Diagnosis & Revenue Optimization
AUTHOR: Shivam Kumar

GOAL:
Diagnose store-level performance differences, category demand,
revenue concentration, and operational efficiency to support
better retail decisions.
========================================================= */


/* =========================================================
SECTION 0: DATA VALIDATION
========================================================= */

-- Q0.1: Are there missing sales values?
SELECT COUNT(*) AS null_sales
FROM train
WHERE sales IS NULL;

-- Insight: Missing sales values weaken revenue analysis and can distort store/category comparisons.
-- Recommendation: Validate completeness before using the data for performance ranking or forecasting.


-- Q0.2: Are there missing transaction values?
SELECT COUNT(*) AS null_transactions
FROM transactions
WHERE transactions IS NULL;

-- Insight: Transaction gaps make revenue-per-transaction metrics unreliable.
-- Recommendation: Resolve transaction completeness before measuring store efficiency.


-- Q0.3: Are there negative revenue rows?
SELECT *
FROM train
WHERE sales < 0;

-- Insight: Negative revenue may indicate returns, corrections, or data issues rather than normal selling activity.
-- Recommendation: Separate operational adjustments from clean sales in any final dashboard or KPI view.


-- Q0.4: Are there duplicate store-date-family records?
SELECT store_nbr, date, family, COUNT(*) AS duplicate_count
FROM train
GROUP BY store_nbr, date, family
HAVING COUNT(*) > 1;

-- Insight: Duplicate records would overstate revenue and distort category/store performance.
-- Recommendation: Enforce grain-level uniqueness before trend and ranking analysis.


/* =========================================================
SECTION 1: STORE & PRODUCT PERFORMANCE
========================================================= */

-- Q1: What is the top-performing product family in each store?
WITH sales_summary AS (
    SELECT 
        store_nbr,
        family,
        SUM(sales) AS revenue
    FROM train
    GROUP BY store_nbr, family
),
ranked AS (
    SELECT 
        store_nbr,
        family,
        revenue,
        DENSE_RANK() OVER (PARTITION BY store_nbr ORDER BY revenue DESC) AS rank_position
    FROM sales_summary
)
SELECT store_nbr, family, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rank_position = 1
ORDER BY revenue DESC;

-- Insight: Top families differ by store, which suggests local assortment demand matters more than a generic company-wide category mix.
-- Recommendation: Localize inventory and promotions using store-specific winning families instead of a one-size-fits-all product strategy.


/* =========================================================
SECTION 2: ANOMALY DETECTION
========================================================= */

-- Q2: Which dates show abnormal revenue spikes?
WITH daily_sales AS (
    SELECT 
        date,
        SUM(sales) AS revenue
    FROM train
    GROUP BY date
),
stats AS (
    SELECT
        AVG(revenue) AS avg_rev,
        STDDEV(revenue) AS std_rev
    FROM daily_sales
)
SELECT 
    d.date,
    ROUND(d.revenue, 2) AS revenue,
    h.type AS holiday_type,
    h.locale_name
FROM daily_sales d
CROSS JOIN stats s
LEFT JOIN holidays_events h ON d.date = h.date
WHERE d.revenue > s.avg_rev + 3 * s.std_rev
ORDER BY d.revenue DESC;

-- Insight: Outlier spikes often correspond to events, promotions, or extraordinary demand bursts.
-- Recommendation: Study these dates before forecasting so temporary spikes don’t mislead baseline demand assumptions.


/* =========================================================
SECTION 3: TEMPORAL ANALYSIS
========================================================= */

-- Q3: How does revenue trend month by month?
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    ROUND(SUM(sales), 2) AS revenue
FROM train
GROUP BY month
ORDER BY month;

-- Insight: Monthly trend reveals seasonality, recovery periods, and slowdown phases that daily data can hide.
-- Recommendation: Use monthly revenue patterns to plan promotions, inventory, and staffing around predictable demand cycles.


/* =========================================================
SECTION 4: DEMAND STABILITY
========================================================= */

-- Q4: Which categories show the highest demand volatility?
WITH monthly_sales AS (
    SELECT 
        family,
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(sales) AS revenue
    FROM train
    GROUP BY family, month
)
SELECT 
    family,
    ROUND(VARIANCE(revenue), 2) AS demand_volatility
FROM monthly_sales
GROUP BY family
ORDER BY demand_volatility DESC;

-- Insight: High-volatility categories are harder to forecast and more exposed to stockout or overstock risk.
-- Recommendation: Apply tighter forecasting controls and safer inventory buffers for highly volatile families.


/* =========================================================
SECTION 5: REVENUE CONCENTRATION
========================================================= */

-- Q5: How concentrated is revenue across stores? (Pareto view)
WITH store_revenue AS (
    SELECT 
        store_nbr,
        SUM(sales) AS revenue
    FROM train
    GROUP BY store_nbr
),
ranked AS (
    SELECT 
        store_nbr,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM store_revenue
)
SELECT 
    store_nbr,
    ROUND(revenue, 2) AS revenue,
    ROUND(100 * cumulative_revenue / total_revenue, 2) AS cumulative_pct
FROM ranked
ORDER BY revenue DESC;

-- Insight: Revenue is usually concentrated among a subset of stores, which creates both scaling opportunities and concentration risk.
-- Recommendation: Protect top stores operationally while building targeted growth plans for mid-tier locations.


/* =========================================================
SECTION 6: STORE PERFORMANCE DIAGNOSIS
========================================================= */

-- Q6: Which stores underperform versus the average?
WITH store_revenue AS (
    SELECT 
        store_nbr,
        SUM(sales) AS revenue
    FROM train
    GROUP BY store_nbr
),
avg_rev AS (
    SELECT AVG(revenue) AS avg_revenue
    FROM store_revenue
)
SELECT 
    s.store_nbr,
    ROUND(s.revenue, 2) AS revenue,
    ROUND(a.avg_revenue, 2) AS avg_revenue,
    CASE
        WHEN s.revenue < a.avg_revenue THEN 'UNDERPERFORMING'
        ELSE 'ABOVE_AVERAGE'
    END AS performance_flag
FROM store_revenue s
CROSS JOIN avg_rev a
ORDER BY s.revenue DESC;

-- Insight: Underperforming stores are not always operational failures; they may reflect local demand, weak assortment, or traffic issues.
-- Recommendation: Diagnose low-performing stores through a mix of demand, product mix, and transaction analysis rather than using revenue alone.


/* =========================================================
SECTION 7: OPERATIONAL EFFICIENCY
========================================================= */

-- Q7: Which stores generate the highest revenue per transaction?
SELECT 
    t.store_nbr,
    ROUND(SUM(t.sales), 2) AS total_revenue,
    SUM(tr.transactions) AS total_transactions,
    ROUND(SUM(t.sales) / NULLIF(SUM(tr.transactions), 0), 2) AS revenue_per_transaction
FROM train t
JOIN transactions tr
    ON t.store_nbr = tr.store_nbr
   AND t.date = tr.date
GROUP BY t.store_nbr
ORDER BY revenue_per_transaction DESC;

-- Insight: Revenue per transaction is a stronger productivity measure than revenue alone because it captures basket quality.
-- Recommendation: Replicate merchandising and cross-sell practices from high revenue-per-transaction stores.


/* =========================================================
SECTION 8: EXTERNAL FACTORS & EVENTS
========================================================= */

-- Q8: How do holidays compare with non-holiday days?
SELECT 
    CASE
        WHEN he.type = 'Holiday' THEN 'Holiday'
        ELSE 'Non_Holiday'
    END AS day_type,
    ROUND(SUM(t.sales), 2) AS total_revenue,
    ROUND(AVG(t.sales), 2) AS avg_revenue
FROM train t
LEFT JOIN holidays_events he ON t.date = he.date
GROUP BY day_type;

-- Insight: Holiday performance helps determine whether the business is truly capturing calendar-driven demand.
-- Recommendation: If holiday lift is weak, redesign holiday campaigns rather than assuming seasonality will drive growth automatically.


-- Q9: Which stores perform best within each city?
SELECT *
FROM (
    SELECT
        st.city,
        t.store_nbr,
        ROUND(SUM(t.sales), 2) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY st.city
            ORDER BY SUM(t.sales) DESC
        ) AS rank_position
    FROM train t
    JOIN stores st ON t.store_nbr = st.store_nbr
    GROUP BY st.city, t.store_nbr
) ranked_city
WHERE rank_position <= 3
ORDER BY city, total_revenue DESC;

-- Insight: City-level rankings help separate location effects from store execution effects.
-- Recommendation: Benchmark weaker city stores against top city peers before generalizing across the entire network.


/* =========================================================
SECTION 9: OIL PRICE IMPACT
========================================================= */

-- Q10: Analyze relationship between oil prices and revenue

WITH daily_sales AS (
    SELECT 
        date,
        SUM(sales) AS revenue
    FROM train
    GROUP BY date
)
SELECT 
    d.date,
    d.revenue,
    o.dcoilwtico AS oil_price
FROM daily_sales d
JOIN oil o
    ON d.date = o.date
ORDER BY d.date;


/* =========================================================
PERFORMANCE OPTIMIZATION
========================================================= */

-- Suggested Indexes:
-- CREATE INDEX idx_train_store_date ON train(store_nbr, date);
-- CREATE INDEX idx_transactions_store_date ON transactions(store_nbr, date);

/* =========================================================
BUSINESS INSIGHTS:

- Revenue is concentrated in a subset of stores (Pareto effect)
- Certain product categories dominate store-level performance
- Some stores consistently underperform → require intervention
- Revenue spikes are often linked to holidays/events
- Demand volatility varies significantly across categories
- Revenue per transaction highlights operational efficiency gaps

BUSINESS ACTIONS:

- Focus marketing and inventory on high-performing categories
- Improve low-performing stores via targeted strategies
- Prepare inventory for high-demand seasonal periods
- Monitor anomalies to detect risks or opportunities
- Optimize pricing and promotions using transaction efficiency

========================================================= */

/* =========================================================
FINAL TAKEAWAY
========================================================= */
-- This project connects store performance, category demand, anomaly detection,
-- transaction efficiency, and event-based revenue behavior into a decision-ready
-- retail performance diagnosis framework.
