#!/usr/bin/perl
# @Author Ali Senhaji

use strict;

my $dir = $ARGV[0];
my $outdir = $dir."Concepts";
mkdir $outdir, 0755;

opendir(DH, $dir);
my @files = readdir(DH);
closedir(DH);

foreach my $file (@files)  #loop through all files in directory
{
    next if(($file eq '.') or ($file eq '..'));  #skip . and .. files

    my $text = './bin/metamap -q -y /home/senhajia/$dir/$file /home/senhajia/$outdir/$file';

#     my $filename = "$outdir/" . $file;     #set output file name to outputdirectory/filename.txt
#     open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";    #write $text to output file
#     print $fh $text;
#     close $fh;
    
    printf("$file converted with success. ////\n");
}