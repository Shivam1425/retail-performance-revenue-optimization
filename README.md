# Retail Performance Diagnosis and Revenue Optimization

Author: Shivam Kumar
Role: Aspiring Data Analyst
Tools: MySQL 8.0, SQL
Project Type: SQL Portfolio Project

## Project Overview

An advanced SQL case study focused on diagnosing store performance, detecting anomalies, and identifying revenue concentration and demand stability risks.

## Project Objective

Evaluate store-level performance differences, revenue concentration, operational productivity, and demand stability in order to support better retail optimization decisions.

## Dataset

This project uses the **Store Sales Time Series Forecasting dataset**.

- Source: https://www.kaggle.com/competitions/store-sales-time-series-forecasting/data
- Files used:
  - train.csv
  - test.csv
  - stores.csv
  - transactions.csv
  - oil.csv
  - holidays_events.csv

Note: Dataset is not included in this repository due to size constraints.

## Business Questions Answered

- Which product categories lead each store?
- Which days show abnormal sales spikes?
- Which categories have unstable demand?
- How concentrated is revenue across stores?
- Which stores underperform versus the average?
- Which stores generate the strongest revenue per transaction?

## Key Business Insights

- Store performance is uneven, and winning categories vary by location.
- Revenue concentration means a subset of stores drives a disproportionate share of results.
- Outlier days and category volatility introduce forecasting and planning risk.
- Revenue per transaction highlights quality differences that revenue totals alone miss.

## Business Recommendations

- Use top-category-by-store diagnostics to localize assortment strategy.
- Investigate outlier revenue days before using them in baseline planning.
- Monitor underperforming stores with both revenue and transaction-quality metrics.
- Treat revenue concentration as both a scaling opportunity and an operating risk.

## Files Included

- `analysis.sql` - main retail performance case study queries
- Dataset is externally hosted (see Dataset section)

## SQL Skills Demonstrated

- Complex JOIN operations across multiple tables
- Window functions for ranking and distribution analysis
- Aggregation and group-based performance comparison
- Outlier detection using statistical thresholds
- Pareto analysis (80/20 revenue distribution)

## Why This Project Matters

This project demonstrates business-focused SQL analysis by connecting raw relational data to decisions, commercial insights, and actionable recommendations.

## Data Setup

- Import CSV files into MySQL using `LOAD DATA INFILE` or GUI tools like MySQL Workbench.
- Ensure correct data types (dates, numeric fields) before running analysis.

## How To Use

1. Download the dataset from the link provided in the Dataset section.
2. Create a local folder named `data/` and place all CSV files inside it.
3. Import the CSV files into MySQL (or your preferred SQL environment).
4. Run `analysis.sql` step by step to reproduce the analysis and insights.
