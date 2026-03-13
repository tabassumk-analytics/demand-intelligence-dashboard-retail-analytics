# Demand intelligence: store and item concentration analysis

## Executive summary
This project analyzes five years of daily retail demand data across 10 stores and 50 items to identify growth patterns, seasonal behavior, sales concentration, and contributor stability. Using Python for data preparation, PostgreSQL for analytical querying, and Tableau for final dashboard planning, the analysis evaluates how demand is distributed across time, stores, and products. The results show that sales are more concentrated at the store level than at the item level, with a small group of high-contribution, low-variability stores driving a disproportionate share of overall demand.

## Business problem
Retail demand planning becomes more difficult when sales are unevenly distributed across stores and products, and when contributor stability varies over time. In this dataset, leadership would need to understand whether growth is broad-based or concentrated, whether seasonality creates predictable demand peaks, and whether the business depends too heavily on a smaller set of stores or items. Without this visibility, inventory planning, replenishment timing, and operational prioritization become less efficient and more reactive.

## Project objective
The objective of this project is to build a demand intelligence framework that evaluates retail sales performance across time, stores, and items using both Python and SQL. The analysis is designed to identify long-term growth, monthly seasonality, weekday demand behavior, store and item concentration, and contributor stability. The final goal is to support a dashboard and decision-support view that helps business leaders distinguish dependable core contributors from more volatile or lower-priority segments.

## Dataset overview
The dataset contains daily retail sales records from 2013 through 2017 across 10 stores and 50 items. Each row represents item-level sales for a given store on a specific date, with four core fields: `date`, `store`, `item`, and `sales`. The dataset includes 913,000 rows, no missing values in the core fields, and only one zero-sales observation, making it a strong candidate for concentration, seasonality, and contributor stability analysis.

## Tools and technologies
- Python: data loading, validation, feature engineering, and summary table generation  
- pandas: data transformation and exploratory analysis  
- PostgreSQL: analytical querying, contribution analysis, cumulative share logic, and segmentation  
- pgAdmin: database management and SQL execution  
- Tableau: final dashboard design and business-facing visualization  
- VS Code: project scripting, SQL documentation, and README development

## Methodology
1. Loaded the raw daily sales file in Python and validated row count, columns, data types, nulls, duplicates, and date coverage.  
2. Created time-based features such as year, month, quarter, and day of week to support trend and seasonality analysis.  
3. Generated summary tables for yearly sales, monthly sales, weekday sales, store contribution, and item contribution, then saved processed outputs for reuse.  
4. Imported the raw dataset into PostgreSQL and created an enriched analytical view for reusable SQL-based reporting.  
5. Built SQL queries for yearly trends, monthly seasonality, weekday demand patterns, store and item concentration, cumulative contribution, and contribution-versus-variability segmentation.  
6. Structured the outputs to support a Tableau dashboard focused on demand trend, seasonality, concentration risk, and contributor stability.

## Key findings
- Total sales increased each year from 2013 through 2017, indicating a clear upward demand trend across the five-year period.  
- Monthly sales showed a visible seasonal pattern, with stronger performance in the middle of the year and softer demand in the early months.  
- Weekday demand was not evenly distributed, with sales building through the week and peaking on Sunday.  
- Store-level concentration was stronger than item-level concentration: the top 4 stores contributed about 47.7% of total sales, while the top 10 items contributed about 31.4%.  
- Store segmentation showed that a small group of high-contribution, low-variability stores drove the majority of business demand, while several lower-contribution stores were also more volatile.  
- Item segmentation showed that the product base was split between a stronger set of higher-contribution, lower-variability items and a weaker set of lower-contribution, higher-variability items.

## Dashboard structure
The final dashboard is designed to present the analysis through four business-facing views:

1. **Demand Trend Overview**  
   A high-level view of yearly sales growth and the overall demand trajectory across the five-year period.

2. **Seasonality and Weekly Demand Patterns**  
   Monthly and weekday sales views to highlight recurring seasonal peaks and operational demand rhythm.

3. **Store Contribution and Stability**  
   Store-level concentration, contribution share, cumulative sales impact, and segmentation into high- and low-stability contributors.

4. **Item Contribution and Stability**  
   Item-level concentration, top-selling products, cumulative contribution, and segmentation into stronger versus more variable item groups.

## Project files
- `data/raw/train.csv` — original source dataset  
- `data/processed/` — exported summary tables generated during Python analysis  
- `python/01_data_understanding.py` — data loading, quality checks, feature creation, and summary generation  
- `sql/01_demand_intelligence_analysis.sql` — SQL logic for trend analysis, concentration analysis, and segmentation  
- `README.md` — executive project documentation  
- `tableau/` — reserved for the final Tableau workbook and dashboard assets  
- `outputs/` — charts, screenshots, and report-ready visuals

## Business recommendations
- Prioritize planning attention on the highest-contributing stores, since a relatively small subset of locations drives a disproportionate share of total sales.  
- Monitor high-contribution but more variable contributors closely, as these may create demand planning and replenishment risk despite their commercial importance.  
- Use seasonal and weekday demand patterns to improve inventory readiness, especially ahead of stronger mid-year and weekend demand periods.  
- Review lower-contribution, higher-variability stores and items to determine whether they require localized planning adjustments, assortment refinement, or lower operational priority.  
- Use contribution and variability segmentation as a recurring framework for distinguishing dependable core demand drivers from more volatile, lower-value contributors.

## Data source
This project uses the Store Item Demand Forecasting Challenge dataset from Kaggle. The dataset contains daily item-level sales records across multiple retail stores and supports analysis of demand trend, seasonality, sales concentration, and contributor stability.

## Author
Tabassum Arshad

Retail Analytics Consultant | Business & Data Analyst

Tableau Public: https://tinyurl.com/2s4m9sk6
