#!/usr/bin/perl
use strict;
my @data;
my @split;
my %gitable;
while(my $line=<>){
    chomp($line);
    $line=~s/^>//;
    @data=split(/\x01/, $line);
    foreach my $oneLine (@data){
        undef %gitable;
        $oneLine=~s/ .*//;
        @split=split(/\|/, $oneLine);
        for(my $i=0; $i<@split; $i+=2){
            if($i+1<@split){
                $gitable{$split[$i]}=$split[$i+1];
            }
        }
        foreach my $key (keys %gitable){
            if($key ne "gi"){
                printf("%s\t%s\t%s\n"
                       , $gitable{$key}, $gitable{"gi"}, $key);
            }
        }
    }
}
