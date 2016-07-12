#!/usr/bin/perl
use DBI;
use strict;

&main;

sub main{
    my %options=&interface();
    &connect2db(\%options);
}

sub interface{ #();
    my %options;
    my $key;
    my $value;
    for(my $i=0; $i<@ARGV; $i+=2){
        $key=$ARGV[$i];
        $value=$ARGV[$i+1];
        if($key eq "-d" || $key eq "-l" || $key eq "-s"){
            $options{$key}=$value;
        }else{
            print stderr "Unknown option: $key\n";
            &help();
        }
    }
    return %options;
}

sub help{ #();
    my $file=__FILE__;
    print stderr << "EOF";
$file

Decode gi list to taxonomy

Usage:
$file -d [taxonomy database] -l [gi list file]
$file -d [taxonomy database] -s [gi]

-d: [taxonomy database] should be the sqlite3 database made from gi_taxid_nucl.
-l: [gi list file] should be line delimited gi list
-s: [gi] string or integer. Single gi number.

EOF
    ;
}

sub connect2db{ #(\%options);
    my $options=$_[0];
    my $filename=$options->{"-d"};
    my $dbh = DBI->connect("dbi:SQLite:dbname=$filename");
    my @result;
    if(exists($options->{"-l"})){
        &checkList($dbh, $options->{"-l"})
    }elsif(exists($options->{"-s"})){
        @result=&checkSingleID($dbh, $options->{"-s"});
        &showResult(\@result);
    }
    $dbh->disconnect;
}

sub showResult{ #(\@result);
    my $result=$_[0];
    foreach my $data (@{$result}){
        printf("%s (%s)\t", $data->[0], $data->[1]);
    }
    print "\n";
}

sub checkSingleID{ #($dbh, $options->{"-s"});
    my $dbh=$_[0];
    my $gi=$_[1];
    my $taxid=&get_taxid($dbh, $gi);
    my $name;
    my $parentTaxid;
    my @result;
    while($taxid!=1){
        $name=&get_name($dbh, $taxid);
#       printf("TaxID: $taxid, name: $name\n");
        $parentTaxid=&get_parent_taxid($dbh, $taxid);
        $taxid=$parentTaxid->[0];
        unshift(@result, [$name, $parentTaxid->[1]]);
    }
    return @result;
}

sub get_taxid{
    my $dbh=$_[0];
    my $gi=$_[1];
    my $taxid=&get_taxid_naive($dbh, $gi);
    if($taxid eq ""){
        $gi=&getGI($dbh, $gi);
        $taxid=&get_taxid_naive($dbh, $gi);
    }
    return $taxid;
}

sub getGI{ #($dbh, $gi);
    my $dbh=$_[0];
    my $id=$_[1];
    my $command="select gi from gi_gb_table where gb='$id' limit 1;";
    my $statement=$dbh->prepare("$command");
    $statement->execute();
    my $row=$statement->fetch();
    $statement->finish();
    return $row->[0];
}

sub get_taxid_naive{
    my $dbh=$_[0];
    my $gi=$_[1];
    my $command="select taxid from gi_taxid_nucl where gi='$gi' limit 1;";
    my $statement=$dbh->prepare("$command");
    $statement->execute();
    my $row=$statement->fetch();
    $statement->finish();
    return $row->[0];
}

sub get_name{ #($dbh, $taxid);
    my $dbh=$_[0];
    my $taxid=$_[1];
    my $command="select * from names where tax_id='$taxid';";
#    print "$command\n";
    my $statement=$dbh->prepare("$command");
    my $row;
    $statement->execute();
    while($row=$statement->fetch()){
        if($row->[3]=~/scientific name/){
            last;
        }
    }
    $statement->finish();
    return $row->[1];
}

sub get_parent_taxid{ #($dbh, $taxid);
    my $dbh=$_[0];
    my $taxid=$_[1];
    my $command="select parent,rank from nodes where tax_id='$taxid'";
    my $statement=$dbh->prepare("$command");
    $statement->execute();
    my $row=$statement->fetch();
    $statement->finish();
    return $row;
}

sub checkList{ #($dbh, $options->{"-l"})
    my $dbh=$_[0];
    my $file=$_[1];
    my @result;
    my $taxonomy={};
    my $pointer;
    my $newPointer;
    my $key;
    my $Gkey;
    my $num;
    my $result;
    if( -r $file ){
#       print "Opening $file\n";
        if(open FIN, "$file"){
            while(my $line=<FIN>){
#               print "$line\n";
                chomp($line);
                @result=&checkSingleID($dbh, $line);
                $newPointer=$taxonomy;
                $result="";
                foreach $Gkey (@result){
                    $key=$Gkey->[0];
                    $pointer=$newPointer;
                    $result.="$key->";
                    if(!defined($pointer->{$key})){
                        $pointer->{$key}[1]={};
                        $pointer->{$key}[0]=1;
                        $pointer->{$key}[2]=$Gkey->[1];
                    }else{
                        $pointer->{$key}[0]++;
                        $num=$pointer->{$key}[0];
                    }
                    $newPointer=$pointer->{$key}[1];
                }
#               print "$result$num\n";
            }
            close FIN;
        }
    }

    &digTaxonomy($taxonomy, "");
    return $taxonomy;
}

sub digTaxonomy{ #(\%taxonomy)
    my $taxonomy=$_[0];
    my $depth=$_[1];
    my $key;
    my $num=scalar(keys %{$taxonomy});
    my $bar;
    my $species=1;
    foreach $key (keys %{$taxonomy}){
        $num--;
        if($num>0){
            $bar="|";
        }else{
            $bar=" ";
        }
        if(scalar(keys %{$taxonomy->{$key}[1]})==0){
            printf("%s+--> %s (%s): %d\n"
                   , $depth, $key, $taxonomy->{$key}[2], $taxonomy->{$key}[0]);
        }elsif($taxonomy->{$key}[2] eq "species" && $species==1){
            printf("%s+--> %s (%s): %d\n"
                   , $depth, $key, $taxonomy->{$key}[2], $taxonomy->{$key}[0]);
        }else{
            printf("%s+-+ %s (%s): %d\n"
                   , $depth, $key, $taxonomy->{$key}[2], $taxonomy->{$key}[0]);
            &digTaxonomy($taxonomy->{$key}[1], "$depth$bar ");
        }
    }
}
