duckdb -csv -c "create temp table t as select * from read_csv('/dev/stdin'); pivot t on key using sum(val) group by id order by id"
