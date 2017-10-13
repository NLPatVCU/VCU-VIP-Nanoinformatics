# !/usr/bin/perl
# @Author Ali Senhaji

use File::Slurp;
use Term::ANSIColor;
use Getopt::Long;
use MetaMap::DataStructures; 

print color('bold blue');

## Converting to Text, preprocessing and cleaning

my $file = $ARGV[0];
my $text = `nohup java -jar tika-app-1.14.jar --text '$file' &`;  

$text =~ s/[^[:ascii:]]/ /g;
$text =~ s/[^a-zA-Z\-\s\.\,\n]/ /g;

	# Reformatting the paper
$text =~ s/\.\n/\<Paragraph\>\n/g;         
$text =~ s/\-\n/\<flag\>/g;
$text =~ s/\n\-/\<flag\>/g;
$text =~ s/\<flag\>\n/\<flag\>/g;	
$text =~ s/\n\<flag\>/\<flag\>/g;
$text =~ s/\<flag\>//g;
$text =~ s/\R/ /g;

$text =~ s/(.*)[R|r][E|e][F|f][E|e][R|r][E|e][N|n][C|c][E|e][S|s].*/$1/g; #Remove references

$text =~ s/\<Paragraph\>/\n/g;
$text =~ s/\s+/ /g;
$text =~ s/\s[a-z|A-Z]\s/ /g;

## Shortening the paper 

my @split = split /\s+/, $text;
$text = join(" ", @split[100 .. 750] ); # Defines the set of words we are going to be using.
$text =~ s/\./.\n/g;
$file =~ s/\..*//;        

	# Saving out the converted/cleaned paper
my $filename = $file . ".txt";     
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";    
print $fh $text;
printf("Reading file ..\n");
close $fh;
printf("$file.pdf converted to TXT..\n");

## Metamap processing
printf("Processing through Metamap .. \n");
my $fileCUIs = $file . "CUIs.txt"; 
system("nohup /home/share/programs/metamap/2016/public_mm/bin/metamap -q -y /home/senhajia/$filename /home/senhajia/$fileCUIs &");

## Extracting CUIs

my $datastructures = MetaMap::DataStructures->new(\%params); 

my $outFileName = $file . "concepts.txt";
my $inFileName = $fileCUIs; 

	#open Metamap file
open (IN, $inFileName) || die "Coudn't open the input file: $inFileName\n";
open (OUT, ">$outFileName") ||  die "Could not open output file: $outFileName\n";

print STDERR "Extracting CUIs ..\n";

#read each utterance
my $input = '';
my $id = 0;
while(<IN>) {
    #build a string until the utterance has been read in
    chomp $_;
    $input .= $_;
    if ($_ eq "\'EOU\'.") {
    $id = 00000000.'.ab.'.($id++);
	$datastructures->createFromTextWithId($input, $id); 
	$input = '';
    }
}

my $citations = $datastructures->getCitations(); 

foreach my $key1 (keys %{$citations}) {

    my $citation = ${$citations}{$key1};
    
    my @orderedConcepts = @{ $citation->getOrderedConcepts() };
    foreach my $arrayRef(@orderedConcepts) {
    	foreach my $concept (@{$arrayRef}) {
			print OUT  $concept->{cui}." ";
		}
    }

}

close IN;
close OUT;

## Building Feature Vector (ARFF)

my $arff = "testFile.arff";
open(my $arffF, '>',$arff) or die "Could not open file '$arff' $!";

printf("Creating Features Vector .. \n");

print $arffF "\@relation Reuters-21578\n
\@attribute Text string\n
\@attribute Class {'NanoInformatics', 'Synthesis','Characterization','IndustrialHygiene','Nanomedicine', 'Toxicology', 'Environment'}\n
\@data\n\n";


if (open(my $fh, $outFileName)) {
  my $doc = <$fh>;
  chomp $doc;
  print $arffF "\'$doc\',?\n";
  close $fh;
}

## Create the bag of words froms concepts
system("java -cp /home/share/programs/weka/weka-3-8-0/weka.jar weka.filters.unsupervised.attribute.StringToWordVector -b -R 1 -W 1000 -prune-rate -1.0 -C -N 0 -L -stemmer weka.core.stemmers.NullStemmer -stopwords-handler weka.core.stopwords.Null -M 1 -i input.arff -o output_training_set.arff -r testFile.arff -s output-test-vector.arff");
system("java -cp /home/share/programs/weka/weka-3-8-0/weka.jar  weka.filters.unsupervised.attribute.Reorder -R last-first -i output-test-vector.arff -o output-test-vectorN.arff");

## Reorder the features
system("java -cp /home/share/programs/weka/weka-3-8-0/weka.jar  weka.filters.unsupervised.attribute.Reorder -R last-first -i output_training_set.arff -o output_training_setN.arff");

## Predict the class
system("java -cp /home/share/programs/weka/weka-3-8-0/weka.jar weka.classifiers.functions.SMO -l modelF.model -T output-test-vectorN.arff -p 0");

