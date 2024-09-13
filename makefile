output_files := rivco.csv assigned-addresses.csv

.PHONY: all
all: $(output_files)

rivco.csv: rivco.db join.sql
	sqlite3 $(word 1, $^) < $(word 2, $^) > $@

assigned-addresses.csv: rivco.csv assign_to_territories.awk territories.csv
	awk --csv -f $(word 2, $^) -v territories_csv=$(word 3, $^) $< > $@

.PHONY: clean
clean:
	rm $(output_files)
