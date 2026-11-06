duckdb -csv -c "select *, x * 2 as y from read_csv('/dev/stdin')"
