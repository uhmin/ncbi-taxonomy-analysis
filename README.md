# ncbi-taxonomy-analysis
This set of programs summarises number of organisms from gi or gb (or even mixed) table.

1) Create sqlite database using makeTaxonomyDB.sh. GB->GI table can be added independently using makeGItable.sh.
2) Taxonomy summary can be made using the following command.

processGiList.pl -d taxonomy.db -l [gi or gb list file]

or

processGiList.pl -d taxonomy.db -s [gi or gb]


I appreciate this site
https://www.biostars.org/p/13452/

