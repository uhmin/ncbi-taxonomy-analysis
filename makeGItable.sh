#!/bin/bash
NT="/data1/ncbimirror/blast/nt"
GITABLE="gitable.txt"
TAXONOMY_DB="taxonomy.db.pre"

grep ">" $NT | ./makeGItable.pl > $GITABLE

sqlite3 $TAXONOMY_DB <<EOF
drop table if exists gi_gb_table;
create table if not exists gi_gb_table(gb, gi, type);
.separator "\t"
.import $GITABLE gi_gb_table
create index gi_gb_table_index on gi_gb_table(gb);
EOF
