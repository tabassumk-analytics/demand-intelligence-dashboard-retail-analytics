from pathlib import Path
import pandas as pd

project_root = Path(__file__).resolve().parent.parent

raw_path = project_root / "data" / "raw" / "train.csv"
processed_path = project_root / "data" / "processed"

df = pd.read_csv(raw_path)
df["date"] = pd.to_datetime(df["date"])

total_sales = df["sales"].sum()
store_count = df["store"].nunique()
item_count = df["item"].nunique()

monthly_sales = (
    df.groupby(df["date"].dt.month)["sales"]
    .sum()
    .reset_index()
)
monthly_sales.columns = ["month", "sales"]

peak_month_row = monthly_sales.sort_values("sales", ascending=False).iloc[0]
peak_month = int(peak_month_row["month"])
peak_month_sales = int(peak_month_row["sales"])

dayofweek_sales = (
    df.groupby(df["date"].dt.day_name())["sales"]
    .sum()
    .reset_index()
)
dayofweek_sales.columns = ["day_of_week", "sales"]

day_order = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
]

dayofweek_sales["day_of_week"] = pd.Categorical(
    dayofweek_sales["day_of_week"],
    categories=day_order,
    ordered=True
)

dayofweek_sales = dayofweek_sales.sort_values("day_of_week").reset_index(drop=True)

peak_day_row = dayofweek_sales.sort_values("sales", ascending=False).iloc[0]
peak_weekday = str(peak_day_row["day_of_week"])
peak_weekday_sales = int(peak_day_row["sales"])

store_contribution = (
    df.groupby("store")["sales"]
    .sum()
    .reset_index()
    .sort_values("sales", ascending=False)
    .reset_index(drop=True)
)

store_contribution["sales_pct"] = (
    100 * store_contribution["sales"] / store_contribution["sales"].sum()
)

top_4_store_contribution_pct = round(store_contribution["sales_pct"].iloc[:4].sum(), 2)

item_contribution = (
    df.groupby("item")["sales"]
    .sum()
    .reset_index()
    .sort_values("sales", ascending=False)
    .reset_index(drop=True)
)

item_contribution["sales_pct"] = (
    100 * item_contribution["sales"] / item_contribution["sales"].sum()
)

top_10_item_contribution_pct = round(item_contribution["sales_pct"].iloc[:10].sum(), 2)
kpi_summary = pd.DataFrame({
    "metric": [
        "total_sales",
        "store_count",
        "item_count",
        "top_4_store_contribution_pct",
        "top_10_item_contribution_pct",
        "peak_month",
        "peak_weekday"
    ],
    "metric_label": [
        "Total sales",
        "Store count",
        "Item count",
        "Top 4 stores",
        "Top 10 items",
        "Peak month",
        "Peak weekday"
    ],
    "metric_order": [
        1,
        2,
        3,
        4,
        5,
        6,
        7
    ],
    "value": [
        total_sales,
        store_count,
        item_count,
        top_4_store_contribution_pct,
        top_10_item_contribution_pct,
        peak_month,
        peak_weekday
    ],
    "display_value": [
        f"{total_sales / 1_000_000:.1f}M",
        f"{store_count}",
        f"{item_count}",
        f"{top_4_store_contribution_pct:.2f}%",
        f"{top_10_item_contribution_pct:.2f}%",
        "July" if peak_month == 7 else str(peak_month),
        peak_weekday
    ]
})

kpi_summary.to_csv(processed_path / "kpi_summary.csv", index=False)

print(kpi_summary)
print("kpi_summary.csv saved successfully")