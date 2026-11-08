duckdb -csv -c "select * from read_csv('/dev/stdin', header=false, names=['method','path','status'])"
