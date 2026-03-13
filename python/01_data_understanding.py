import pandas as pd
from pathlib import Path

project_root = Path(__file__).resolve().parents[1]
data_path = project_root / "data" / "raw" / "train.csv"

df = pd.read_csv(data_path)
print(df.head())

print(df.shape)
print(df.columns)
print(df.dtypes)
print(df.isnull().sum())

print(df.duplicated().sum())
print(df.describe())
print(df["date"].min(), df["date"].max())

df["date"] = pd.to_datetime(df["date"])

print(df.dtypes)

df["year"] = df["date"].dt.year
df["month"] = df["date"].dt.month
df["quarter"] = df["date"].dt.quarter
df["day_of_week"] = df["date"].dt.day_name()

print(df[["date", "year", "month", "quarter", "day_of_week"]].head())

print(df["store"].nunique())
print(df["item"].nunique())
print(df["sales"].min(), df["sales"].max())
print((df["sales"] == 0).sum())

yearly_sales = df.groupby("year")["sales"].sum().reset_index()
monthly_sales = df.groupby("month")["sales"].sum().reset_index()
dayofweek_sales = df.groupby("day_of_week")["sales"].sum().reset_index()

print(yearly_sales)
print(monthly_sales)
print(dayofweek_sales)


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

print(dayofweek_sales)

store_sales = df.groupby("store")["sales"].sum().reset_index().sort_values("sales", ascending=False)
item_sales = df.groupby("item")["sales"].sum().reset_index().sort_values("sales", ascending=False)

print(store_sales)
print(item_sales.head(10))

total_sales = df["sales"].sum()

store_sales["sales_pct"] = (store_sales["sales"] / total_sales) * 100
item_sales["sales_pct"] = (item_sales["sales"] / total_sales) * 100

print(store_sales)
print(item_sales.head(10))

store_sales["cumulative_pct"] = store_sales["sales_pct"].cumsum()
item_sales["cumulative_pct"] = item_sales["sales_pct"].cumsum()

print(store_sales)
print(item_sales.head(10))

store_variability = df.groupby("store")["sales"].agg(["mean", "std", "min", "max"]).reset_index()
item_variability = df.groupby("item")["sales"].agg(["mean", "std", "min", "max"]).reset_index()

store_variability["cv"] = store_variability["std"] / store_variability["mean"]
item_variability["cv"] = item_variability["std"] / item_variability["mean"]

store_variability = store_variability.sort_values("cv", ascending=False)
item_variability = item_variability.sort_values("cv", ascending=False)

print(store_variability)
print(item_variability.head(10))

store_diagnostics = store_sales.merge(
    store_variability[["store", "mean", "std", "cv"]],
    on="store",
    how="left"
)

item_diagnostics = item_sales.merge(
    item_variability[["item", "mean", "std", "cv"]],
    on="item",
    how="left"
)

print(store_diagnostics)
print(item_diagnostics.head(10))

store_diagnostics["contribution_flag"] = store_diagnostics["sales_pct"].apply(
    lambda x: "high contribution" if x >= store_diagnostics["sales_pct"].median() else "low contribution"
)

store_diagnostics["variability_flag"] = store_diagnostics["cv"].apply(
    lambda x: "high variability" if x >= store_diagnostics["cv"].median() else "low variability"
)

store_diagnostics["store_segment"] = (
    store_diagnostics["contribution_flag"] + " | " + store_diagnostics["variability_flag"]
)

print(store_diagnostics[["store", "sales", "sales_pct", "cv", "store_segment"]])

store_segment_summary = (
    store_diagnostics.groupby("store_segment")
    .agg(
        store_count=("store", "count"),
        total_sales=("sales", "sum"),
        avg_sales_pct=("sales_pct", "mean")
    )
    .reset_index()
    .sort_values("total_sales", ascending=False)
)

print(store_segment_summary)

##
item_diagnostics["contribution_flag"] = item_diagnostics["sales_pct"].apply(
    lambda x: "high contribution" if x >= item_diagnostics["sales_pct"].median() else "low contribution"
)

item_diagnostics["variability_flag"] = item_diagnostics["cv"].apply(
    lambda x: "high variability" if x >= item_diagnostics["cv"].median() else "low variability"
)

item_diagnostics["item_segment"] = (
    item_diagnostics["contribution_flag"] + " | " + item_diagnostics["variability_flag"]
)

item_segment_summary = (
    item_diagnostics.groupby("item_segment")
    .agg(
        item_count=("item", "count"),
        total_sales=("sales", "sum"),
        avg_sales_pct=("sales_pct", "mean")
    )
    .reset_index()
    .sort_values("total_sales", ascending=False)
)

print(item_diagnostics[["item", "sales", "sales_pct", "cv", "item_segment"]].head(10))
print(item_segment_summary)

print("top 4 stores cumulative contribution:", round(store_diagnostics["cumulative_pct"].iloc[3], 2))
print("top 5 stores cumulative contribution:", round(store_diagnostics["cumulative_pct"].iloc[4], 2))
print("top 10 items cumulative contribution:", round(item_diagnostics["cumulative_pct"].iloc[9], 2))

processed_path = project_root / "data" / "processed"

yearly_sales.to_csv(processed_path / "yearly_sales.csv", index=False)
monthly_sales.to_csv(processed_path / "monthly_sales.csv", index=False)
dayofweek_sales.to_csv(processed_path / "dayofweek_sales.csv", index=False)
store_diagnostics.to_csv(processed_path / "store_diagnostics.csv", index=False)
item_diagnostics.to_csv(processed_path / "item_diagnostics.csv", index=False)

print("processed files saved successfully")