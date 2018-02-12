#!/usr/bin/perl
# @Author Ali Senhaji

my @dir = ("NanoinformaticsTXT", "SynthesisTXT","CharacterizationTXT","IndustrialHygieneTXT","NanomedicineTXT", "ToxicologyTXT", "EnvironmentTXT");
my $arff = "Weka_file.arff";

my $class = 0;
my @classes = ("NanoInformatics", "Synthesis","Characterization","IndustrialHygiene","Nanomedicine", "Toxicology", "Environment");

open(my $arffF, '>',$arff) or die "Could not open file '$arff' $!";

print $arffF "\@relation Reuters-21578\n
\@attribute Text string\n
\@attribute class {'NanoInformatics', 'Synthesis','Characterization','IndustrialHygiene','Nanomedicine', 'Toxicology', 'Environment'}\n
\@data\n\n";

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
          $doc =~ s/[^a-zA-Z\-\s]/ /g;
          $doc = lc($doc);

          print $arffF "\'$doc\','$classes[$class]'\n";

          close $fh;
      }
  }

  $class++;

}