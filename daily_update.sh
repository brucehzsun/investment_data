set -e
set -x

[ ! -d "/mnt/data/dolt/investment_data" ] && echo "initializing dolt repo" && cd /mnt/data/dolt && dolt clone chenditc/investment_data
cd /mnt/data/dolt/investment_data
dolt pull

echo "Updating index weight"
startdate=$(dolt sql -q "select * from max_index_date" -r csv | tail -1)
python3 ~/vs_python/investment_data/tushare/dump_index_weight.py --start_date=$startdate
for file in $(ls ~/vs_python/investment_data/tushare/index_weight/); 
do  
  dolt table import -u ts_index_weight ~/vs_python/investment_data/tushare/index_weight/$file; 
done

# echo "Updating index price"
python3 ~/vs_python/investment_data/tushare/dump_index_eod_price.py 
for file in $(ls ~/vs_python/investment_data/tushare/index/); 
do   
  dolt table import -u ts_a_stock_eod_price ~/vs_python/investment_data/tushare/index/$file; 
done

# echo "Updating stock price"
dolt sql-server --port 3307 &
sleep 5 && python3 ~/vs_python/investment_data/tushare/update_a_stock_eod_price_to_latest.py
killall dolt

dolt sql --file ~/vs_python/investment_data/tushare/regular_update.sql

dolt add -A

status_output=$(dolt status)

# Check if the status output contains the "nothing to commit, working tree clean" message
if [[ $status_output == *"nothing to commit, working tree clean"* ]]; then
    echo "No changes to commit. Working tree is clean."
else
    echo "Changes found. Committing and pushing..."
    # Run the necessary commands
    dolt commit -m "Daily update"
    dolt push 
    echo "Changes committed and pushed."
fi

