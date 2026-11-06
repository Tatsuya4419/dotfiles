duckdb -csv -c "select g, count(*) n, avg(x) mean from read_csv('/dev/stdin') group by g order by g"
