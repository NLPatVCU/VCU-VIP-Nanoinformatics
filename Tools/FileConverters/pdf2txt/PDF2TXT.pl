#!/usr/bin/perl
# @Author Ali Senhaji


###################################################
# How to use this program>
# 	1. Make sure this perl program and the tika application are on the same directory as the directory you want to convert.
# 		---|PDF2TXT.pl
# 		   |tika-app-1.14.jar
# 		   |Directory_of_PDFs_to_Convert
# 	2. Run the perl program with the nume of the directory as a parameter
# 			perl PDF2TXT.pl Directory_of_PDFs_to_Convert
# 	3. It will create a new directory Directory_of_PDFs_to_ConvertTXT containning all the converted papers
# 		---|PDF2TXT.pl
# 		    --|1.pdf
# 		    --|2.pdf
# 		   |tika-app-1.14.jar
# 		   |Directory_of_PDFs_to_Convert
# 		   |Directory_of_PDFs_to_ConvertTXT
# 		    --|1.txt
# 		    --|2.tx

use strict;

my $dir = $ARGV[0];

# Creates the name of the output directory
my $outdir = $dir."TXT";
mkdir $outdir, 0755;

opendir(DH, $dir);
my @files = readdir(DH);
closedir(DH);

# my $id = 0;

foreach my $file (@files)  
{
    next if(($file eq '.') or ($file eq '..'));  

	## Calling TIKA for conversion, you can change the version from this line
    my $text = `java -jar tika-app-1.14.jar --text '$dir/$file'`;  
	
### Text Cleanning	
	$text =~ s/[^[:ascii:]]/ /g;
	$text =~ s/[^a-zA-Z\-\s\.\,\n]/ /g;
	
	
### This part restores the formating and structure of the paragraphs

	$text =~ s/\.\n/\<Paragraph\>\n/g;        
	$text =~ s/\-\n/\<flag\>/g;
	$text =~ s/\n\-/\<flag\>/g;

	$text =~ s/\<flag\>\n/\<flag\>/g;	
	$text =~ s/\n\<flag\>/\<flag\>/g;
	$text =~ s/\<flag\>//g;

	$text =~ s/\R/ /g;
    $text =~ s/(.*)[R|r][E|e][F|f][E|e][R|r][E|e][N|n][C|c][E|e][S|s].*/$1/g;
    $text =~ s/\<Paragraph\>/\n/g;

#######    #######    #######    #######    #######    #######    

    $file =~ s/\..*//;        #remove the .pdf extension from the file name
    my $filename = "$outdir/" . $file . ".txt";     #set output file name to outputdirectory/filename.txt
    
### Writing the TXT output 

    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";    #write $text to output file
    print $fh $text;
    close $fh;
    
#     $id += 1;
    
    printf("$file converted successfully.\n");
}