#!/bin/bash

set -e

DIR=~/.qlib/qlib_data/cn_data/features
WORKING_DIR=~/vs_python/investment_data

if [ -d "$DIR" ]; then
    echo "$DIR exists!!"
else
    source ~/miniconda3/etc/profile.d/conda.sh 
    conda activate qlib_data
    echo "$DIR not exists, update..."

    cd /data/dolt/investment_data
    dolt pull origin

    dolt sql-server --config dolt_config.yml &

    sleep 5s

    cd $WORKING_DIR
    mkdir -p ./qlib/qlib_source
    python3 ./qlib/dump_all_to_qlib_source.py
    
    QLIB_PATH=~/vs_python/qlib
    FEATURES_DATA=~/.qlib/qlib_data/cn_data
    export PYTHONPATH=$PYTHONPATH:$QLIB_PATH/scripts
    python3 ./qlib/normalize.py normalize_data --source_dir ./qlib/qlib_source/ --normalize_dir ./qlib/qlib_normalize --max_workers=16 --date_field_name="tradedate" 
    python3 $QLIB_PATH/scripts/dump_bin.py dump_all --csv_path ./qlib/qlib_normalize/ --qlib_dir $WORKING_DIR/qlib_bin --date_field_name=tradedate --exclude_fields=tradedate,symbol

    mkdir -p ./qlib/qlib_index/
    python3 ./qlib/dump_index_weight.py 
    python3 ./tushare/dump_day_calendar.py $WORKING_DIR/qlib_bin/

    killall dolt

    cp qlib/qlib_index/csi* $WORKING_DIR/qlib_bin/instruments/

    mv qlib_bin/* ~/.qlib/qlib_data/cn_data

    rm -rf qlib/qlib_*
    rm -rf qlib_bin
fi
