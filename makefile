output_files := rivco.csv

.PHONY: all
all: $(output_files)

rivco.csv: rivco.db join.sql
	sqlite3 $(word 1, $^) < $(word 2, $^) > $@

.PHONY: clean
clean:
	rm $(output_files)
