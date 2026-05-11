from sqlalchemy import create_engine
import pymysql
import pandas as pd
import fire
import os
import datetime
from pathlib import Path
from urllib.parse import quote_plus


def build_db_url():
  user = os.getenv("DB_USER", "root")
  password = os.getenv("DB_PASSWORD", "")
  host = os.getenv("DB_HOST", "127.0.0.1")
  port = os.getenv("DB_PORT", "3307")
  database = os.getenv("DB_NAME", "investment_data")

  if password:
    auth = f"{quote_plus(user)}:{quote_plus(password)}"
  else:
    auth = quote_plus(user)

  return f"mysql+pymysql://{auth}@{host}:{port}/{database}"

def dump_calendar_to_qlib_dir(qlib_dir, skip_exists=False):
  sqlEngine = create_engine(build_db_url(), pool_recycle=3600)
  dbConnection = sqlEngine.raw_connection()

  old_days_file =Path(qlib_dir) / "calendars/day.txt"
  old_calendar_df = pd.read_csv(old_days_file, header=None)
  min_date = pd.to_datetime(old_calendar_df.iloc[0][0])

  filename = Path(qlib_dir) / "calendars/day_future.txt"
  print("Dumping to file: ", filename)
  sql = "select date from ts_trade_day_calendar WHERE exchange = 'SSE' AND is_open = 1;"
  calendar_df = pd.read_sql(sql, dbConnection)
  calendar_df["date"] = pd.to_datetime(calendar_df["date"])
  calendar_df.drop(calendar_df[calendar_df["date"] < min_date].index, inplace=True)

  calendar_df.to_csv(filename, index=False, header=False, sep='\t')

if __name__ == "__main__":
  fire.Fire(dump_calendar_to_qlib_dir)