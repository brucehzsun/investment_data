from sqlalchemy import create_engine
import pymysql
import pandas as pd
import fire
import os
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

def dump_all_to_sqlib_source(skip_exists=True):
  sqlEngine = create_engine(build_db_url(), pool_recycle=3600)
  dbConnection = sqlEngine.raw_connection()
  stock_df = pd.read_sql("select *, amount/volume*10 as vwap from final_a_stock_eod_price", dbConnection)
  dbConnection.close()
  sqlEngine.dispose()

  script_path = os.path.dirname(os.path.realpath(__file__))

  for symbol, df in stock_df.groupby("symbol"):
    filename = f'{script_path}/qlib_source/{symbol}.csv'
    print("Dumping to file: ", filename)
    if skip_exists and os.path.isfile(filename):
        continue
    df.to_csv(filename, index=False)

if __name__ == "__main__":
  fire.Fire(dump_all_to_sqlib_source)
