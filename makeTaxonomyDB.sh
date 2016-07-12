#!/bin/bash
NT="/data1/ncbimirror/blast/nt"
grep ">" $NT | ./makeGItable.pl > gitable.txt

sqlite3 taxonomy.db.pre <<EOF
drop table if exists nodes;
drop table if exists names;
drop table if exists gi_taxid_nucl;
drop table if exists gi_gb_table;

create table if not exists nodes(tax_id, parent, rank, embl_code, division_id, inherited_div_flag, genetic_code_id, inherited_GC_flag, mitochondrial_genetic_code_id, inherited_MGC_flag, GenBank_hidden_flag, hidden_subtree_root_flag, comments);
create table if not exists names(tax_id, name_txt, unique_name, name_class);
create table if not exists gi_taxid_nucl(gi, taxid);
create table if not exists gi_gb_table(gb, gi, type);

.separator "\t|\t"
.import /data1/ncbimirror/taxonomy/names.dmp names

.separator "\t|\t"
.import /data1/ncbimirror/taxonomy/nodes.dmp nodes

.separator "\t"
.import /data1/ncbimirror/taxonomy/gi_taxid_nucl.dmp gi_taxid_nucl
.import gitable.txt gi_gb_table
create index gi_taxid_nucl_index on gi_taxid_nucl(gi);
create index names_index on names(tax_id);
create index nodes_index on nodes(tax_id);
