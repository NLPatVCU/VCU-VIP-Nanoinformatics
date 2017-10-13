#!/usr/bin/perl
# @Author Ali Senhaji


my @dir = ("NanoInformaticsTXT", "SynthesisTXT","CharacterizationTXT","IndustrialHygieneTXT","NanomedicineTXT", "ToxicologyTXT", "EnvironmentTXT");

my $arff = "paper-class.csv";

my $class = 0;
my @classes = ("NanoInformatics", "Synthesis","Characterization","IndustrialHygiene","Nanomedicine", "Toxicology", "Environment");

open(my $arffF, '>',$arff) or die "Could not open file '$arff' $!";


print $arffF "class, paper\n";

for my $dir (@dir) {
  opendir(DH, $dir);
  my @files = grep { $_ ne '.' and $_ ne '..' and $_ ne '.DS_Store' and $_ ne '.txt' } readdir(DH);
  closedir(DH);

  for my $i (0..$#files)  #loop through all files in directory
  {
      my $path = $dir . "/" . $files[$i];

          print "$path \n";

      if (open(my $fh, $path)) {
          my $doc = <$fh>;
          chomp $doc;
          $doc =~ s/[^a-zA-Z0-9-\s]/ /g;
          $doc =~ s/\t/ /g;
          $doc = lc($doc);
          print $arffF "$class,\"$doc\"\n";

          close $fh;
      }
  }

  $class++;

}