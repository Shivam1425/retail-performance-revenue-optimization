# Retail Store Performance Diagnosis

**Author:** Shivam Kumar  
**Tools:** MySQL 8.0  
**Dataset:** Store Sales Time Series Forecasting (Kaggle)

> **Note:** This project uses the same Store Sales dataset as my [Retail Demand & Revenue Intelligence](../retail-demand-revenue-intelligence/) project but focuses on different questions — specifically store-level performance diagnosis, anomaly detection, and underperformer identification. The other project covers macro trends, category dynamics, and external sensitivity (oil prices, holidays).

## What I Was Trying to Figure Out

When you have 54 stores, the obvious question is: which ones are doing well and which aren't? But "doing well" is more complicated than just having the highest revenue. A store might have high revenue because it's in a high-traffic location — not because it's well-run. Another store might have lower total sales but excellent revenue-per-transaction, meaning the customers who do visit are buying more.

I wanted queries that separate these effects and give a more complete picture of store health.

## The Questions I Asked

- Which product categories lead each store? (It varies more than you'd expect)
- Which store-days show abnormal revenue spikes — and are those explainable or data problems?
- Which categories have the most unstable month-to-month demand?
- How concentrated is revenue — how many stores drive 80% of the total?
- Which stores are underperforming vs the network average on revenue AND basket quality?
- Which stores generate the strongest revenue per transaction?

## What I Found

Revenue is heavily concentrated — the top 10 stores (out of 54) contribute about 40% of total network revenue. The top 5 product families account for nearly 79% of sales. So despite having 54 stores and 33 product families, the business is effectively running on a narrow base.

The store archetype segmentation was the most interesting output. Several stores rank high on total revenue but below-average on revenue per transaction — they're traffic-led, not quality-led. A different set of mid-revenue stores have excellent basket quality, which suggests their merchandising or format is working even without scale.

**Sample output — Store Archetypes (Q from Section 9 of analysis.sql):**

| store_nbr | city | total_revenue | sales_per_transaction | store_archetype |
|---|---|---|---|---|
| 44 | Quito | 3,218,450 | 43.2 | Scale + Basket Leader |
| 45 | Quito | 2,987,230 | 38.7 | Traffic-Led Scale Store |
| 47 | Quito | 2,841,190 | 41.8 | Scale + Basket Leader |
| 8 | Guayaquil | 1,842,110 | 51.3 | Premium Basket Store |
| 20 | Quito | 1,205,440 | 29.4 | Traffic-Led Scale Store |
| 52 | Manta | 412,890 | 18.6 | Turnaround Candidate |

The "Premium Basket Store" stores are interesting — they're not in the top revenue tier but their per-transaction quality is strong. Those locations probably need investment, not a turnaround plan.

## SQL Approach

The main technique for anomaly detection was Z-score-based flagging. Instead of hardcoding "if revenue > X it's an outlier", I calculated `AVG(revenue)` and `STDDEV(revenue)` across all store-days, then flagged any day where revenue exceeded 3 standard deviations above the mean. The threshold adapts to the data distribution instead of needing manual tuning.

For store segmentation, I used `NTILE(4)` to split stores into revenue quartiles and basket-quality quartiles separately, then crossed those two dimensions into archetypes:
- High revenue + high basket quality = Scale and Basket Leader
- High revenue + low basket quality = Traffic-Led Store
- Lower revenue + high basket quality = Premium Basket Store
- Low on both = Turnaround Candidate

## Challenges

This project uses the same dataset as Retail Demand Intelligence, which means there's some overlap in setup. I kept them separate because the questions are genuinely different, but setting up the same tables again in a separate repo does feel repetitive. If I were combining both from scratch I'd put them in one project with separate analysis sections referencing shared views.

## SQL Concepts Used

- `DENSE_RANK()` and `NTILE()` for store ranking and quartile segmentation
- `STDDEV_POP()` + `AVG()` for Z-score anomaly threshold calculation
- `PERCENT_RANK()` for revenue concentration analysis
- `CASE WHEN` with multi-dimension conditions for store archetype classification
- `ROW_NUMBER() OVER (PARTITION BY city)` for within-city store ranking
- `NULLIF()` to prevent division errors in revenue-per-transaction

## Data Setup

- Dataset: https://www.kaggle.com/competitions/store-sales-time-series-forecasting/data
- Files needed: train.csv, stores.csv, transactions.csv, oil.csv, holidays_events.csv
- Dataset not included in this repo (too large) — download from Kaggle link above

## How to Run

1. Download from Kaggle, place CSVs in a `data/` folder.
2. Import into MySQL using MySQL Workbench or `LOAD DATA INFILE`.
3. Run `analysis.sql` section by section.
