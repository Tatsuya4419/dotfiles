duckdb -csv -c "select distinct a from read_csv('/dev/stdin') order by a"
