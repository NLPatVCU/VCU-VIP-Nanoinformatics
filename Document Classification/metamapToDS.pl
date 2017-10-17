#!/usr/bin/perl
# @Author Ali Senhaji

use Getopt::Long;
use MetaMap::DataStructures; 


my $datastructures = MetaMap::DataStructures->new(\%params); 

my @dir = ("NanoinformaticsTMMcCon", "SynthesisTMMcCon","CharacterizationTMMcCon","IndustrialHygieneTMMcCon","NanomedicineTMMcCon", "ToxicologyTMMcCon", "EnvironmentTMMcCon");

for my $dir (@dir) {
  opendir(DH, $dir);
  my @files = grep { $_ ne '.' and $_ ne '..' and $_ ne '.DS_Store' and $_ ne '.txt' } readdir(DH);
  closedir(DH);

  for my $i (0..$#files)  #loop through all files in directory
  {
    my $outFileName = $dir . "DS/" . $files[$i];
    my $inFileName = $dir . "/" . $files[$i];

    #open test input
    open (IN, $inFileName) || die "Coudn't open the input file: $inFileName\n";

    #create Output
    open (OUT, ">$outFileName") ||  die "Could not open output file: $outFileName\n";

    #read each utterance
    my $input = '';
    print STDERR "Reading Input\n";
    $id = 0;
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
  }
}
    
print STDERR "DONE!, results written to $outFileName\n";
