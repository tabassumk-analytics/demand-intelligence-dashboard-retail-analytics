
-- created enriched analytical view with time dimensions
-- purpose: support reusable sales trend and seasonality queries

create or replace view vw_demand_sales_enriched as
select
    date,
    store,
    item,
    sales,
    extract(year from date) as year,
    extract(month from date) as month,
    extract(quarter from date) as quarter,
    trim(to_char(date, 'day')) as day_of_week
from demand_daily_sales;

select *
from vw_demand_sales_enriched
limit 5;

-- yearly sales summary
-- purpose: measure overall demand growth across the five-year period
select
    year,
    sum(sales) as total_sales
from vw_demand_sales_enriched
group by year
order by year;

--monthly summary
select
    month,
    sum(sales) as total_sales
from vw_demand_sales_enriched
group by month
order by month;
--weekday summary
select
    day_of_week,
    sum(sales) as total_sales
from vw_demand_sales_enriched
group by day_of_week
order by
    case day_of_week
        when 'monday' then 1
        when 'tuesday' then 2
        when 'wednesday' then 3
        when 'thursday' then 4
        when 'friday' then 5
        when 'saturday' then 6
        when 'sunday' then 7
    end;
	
--store contribution
select
    store,
    sum(sales) as total_sales
from vw_demand_sales_enriched
group by store
order by total_sales desc;

--item contribution
select
    item,
    sum(sales) as total_sales
from vw_demand_sales_enriched
group by item
order by total_sales desc
limit 10;
	
 -- store contribution analysis with cumulative percentage
-- purpose: measure store-level revenue concentration and cumulative sales share
with store_sales as (
    select
        store,
        sum(sales) as total_sales
    from vw_demand_sales_enriched
    group by store
),
store_pct as (
    select
        store,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct
    from store_sales
)
select
    store,
    total_sales,
    sales_pct,
    round(
        sum(sales_pct) over (
            order by total_sales desc
            rows between unbounded preceding and current row
        ),
        2
    ) as cumulative_pct
from store_pct
order by total_sales desc;

-- top item contribution analysis with cumulative percentage
-- purpose: measure item-level revenue concentration across the highest-selling products
with item_sales as (
    select
        item,
        sum(sales) as total_sales
    from vw_demand_sales_enriched
    group by item
),
item_pct as (
    select
        item,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct
    from item_sales
)
select
    item,
    total_sales,
    sales_pct,
    round(
        sum(sales_pct) over (
            order by total_sales desc
            rows between unbounded preceding and current row
        ),
        2
    ) as cumulative_pct
from item_pct
order by total_sales desc
limit 10;   

-- store diagnostic segmentation
-- purpose: classify stores by contribution and variability to identify dependable and riskier contributors
---- store diagnostic segmentation
-- purpose: classify stores by contribution and variability to identify dependable and riskier contributors
with store_sales as (
    select
        store,
        sum(sales) as total_sales,
        avg(sales) as avg_sales,
        stddev(sales) as std_sales
    from vw_demand_sales_enriched
    group by store
),
store_metrics as (
    select
        store,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct,
        avg_sales,
        std_sales,
        round(std_sales / nullif(avg_sales, 0), 4) as cv
    from store_sales
),
store_ranked as (
    select
        *,
        round(
            sum(sales_pct) over (
                order by total_sales desc
                rows between unbounded preceding and current row
            ),
            2
        ) as cumulative_pct
    from store_metrics
),
store_thresholds as (
    select
        percentile_cont(0.5) within group (order by sales_pct) as median_sales_pct,
        percentile_cont(0.5) within group (order by cv) as median_cv
    from store_ranked
)
select
    r.store,
    r.total_sales,
    r.sales_pct,
    r.cumulative_pct,
    round(r.avg_sales, 2) as avg_sales,
    round(r.std_sales, 2) as std_sales,
    r.cv,
    case
        when r.sales_pct >= t.median_sales_pct and r.cv < t.median_cv
            then 'high contribution | low variability'
        when r.sales_pct >= t.median_sales_pct and r.cv >= t.median_cv
            then 'high contribution | high variability'
        when r.sales_pct < t.median_sales_pct and r.cv < t.median_cv
            then 'low contribution | low variability'
        else 'low contribution | high variability'
    end as store_segment
from store_ranked r
cross join store_thresholds t
order by r.total_sales desc;

-- item diagnostic segmentation
-- purpose: classify items by contribution and variability to identify strong core products and more volatile lower-value items
with item_sales as (
    select
        item,
        sum(sales) as total_sales,
        avg(sales) as avg_sales,
        stddev(sales) as std_sales
    from vw_demand_sales_enriched
    group by item
),
item_metrics as (
    select
        item,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct,
        avg_sales,
        std_sales,
        round(std_sales / nullif(avg_sales, 0), 4) as cv
    from item_sales
),
item_ranked as (
    select
        *,
        round(
            sum(sales_pct) over (
                order by total_sales desc
                rows between unbounded preceding and current row
            ),
            2
        ) as cumulative_pct
    from item_metrics
),
item_thresholds as (
    select
        percentile_cont(0.5) within group (order by sales_pct) as median_sales_pct,
        percentile_cont(0.5) within group (order by cv) as median_cv
    from item_ranked
)
select
    r.item,
    r.total_sales,
    r.sales_pct,
    r.cumulative_pct,
    round(r.avg_sales, 2) as avg_sales,
    round(r.std_sales, 2) as std_sales,
    r.cv,
    case
        when r.sales_pct >= t.median_sales_pct and r.cv < t.median_cv
            then 'high contribution | low variability'
        when r.sales_pct >= t.median_sales_pct and r.cv >= t.median_cv
            then 'high contribution | high variability'
        when r.sales_pct < t.median_sales_pct and r.cv < t.median_cv
            then 'low contribution | low variability'
        else 'low contribution | high variability'
    end as item_segment
from item_ranked r
cross join item_thresholds t
order by r.total_sales desc;

----item segment summary
with item_sales as (
    select
        item,
        sum(sales) as total_sales,
        avg(sales) as avg_sales,
        stddev(sales) as std_sales
    from vw_demand_sales_enriched
    group by item
),
item_metrics as (
    select
        item,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct,
        avg_sales,
        std_sales,
        round(std_sales / nullif(avg_sales, 0), 4) as cv
    from item_sales
),
item_ranked as (
    select
        *,
        round(
            sum(sales_pct) over (
                order by total_sales desc
                rows between unbounded preceding and current row
            ),
            2
        ) as cumulative_pct
    from item_metrics
),
item_thresholds as (
    select
        percentile_cont(0.5) within group (order by sales_pct) as median_sales_pct,
        percentile_cont(0.5) within group (order by cv) as median_cv
    from item_ranked
),
item_segmented as (
    select
        r.*,
        case
            when r.sales_pct >= t.median_sales_pct and r.cv < t.median_cv
                then 'high contribution | low variability'
            when r.sales_pct >= t.median_sales_pct and r.cv >= t.median_cv
                then 'high contribution | high variability'
            when r.sales_pct < t.median_sales_pct and r.cv < t.median_cv
                then 'low contribution | low variability'
            else 'low contribution | high variability'
        end as item_segment
    from item_ranked r
    cross join item_thresholds t
)
select
    item_segment,
    count(*) as item_count,
    sum(total_sales) as segment_total_sales,
    round(avg(sales_pct), 2) as avg_sales_pct
from item_segmented
group by item_segment
order by segment_total_sales desc;

--store segment summary
with store_sales as (
    select
        store,
        sum(sales) as total_sales,
        avg(sales) as avg_sales,
        stddev(sales) as std_sales
    from vw_demand_sales_enriched
    group by store
),
store_metrics as (
    select
        store,
        total_sales,
        round(
            100.0 * total_sales / sum(total_sales) over (),
            2
        ) as sales_pct,
        avg_sales,
        std_sales,
        round(std_sales / nullif(avg_sales, 0), 4) as cv
    from store_sales
),
store_ranked as (
    select
        *,
        round(
            sum(sales_pct) over (
                order by total_sales desc
                rows between unbounded preceding and current row
            ),
            2
        ) as cumulative_pct
    from store_metrics
),
store_thresholds as (
    select
        percentile_cont(0.5) within group (order by sales_pct) as median_sales_pct,
        percentile_cont(0.5) within group (order by cv) as median_cv
    from store_ranked
),
store_segmented as (
    select
        r.*,
        case
            when r.sales_pct >= t.median_sales_pct and r.cv < t.median_cv
                then 'high contribution | low variability'
            when r.sales_pct >= t.median_sales_pct and r.cv >= t.median_cv
                then 'high contribution | high variability'
            when r.sales_pct < t.median_sales_pct and r.cv < t.median_cv
                then 'low contribution | low variability'
            else 'low contribution | high variability'
        end as store_segment
    from store_ranked r
    cross join store_thresholds t
)
select
    store_segment,
    count(*) as store_count,
    sum(total_sales) as segment_total_sales,
    round(avg(sales_pct), 2) as avg_sales_pct
from store_segmented
group by store_segment
order by segment_total_sales desc;