#!/usr/bin/perl
# @Author Ali Senhaji

use File::Slurp;

my @dir = ("NanoInformaticsTMMc", "SynthesisTMMc","CharacterizationTMMc","IndustrialHygieneTMMc","NanomedicineTMMc", "ToxicologyTMMc", "EnvironmentTMMc");

for my $dir (@dir) {
  opendir(DH, $dir);
  my @files = grep { $_ ne '.' and $_ ne '..' and $_ ne '.DS_Store' and $_ ne '.txt' } readdir(DH);
  closedir(DH);

  for my $i (0..$#files)  #loop through all files in directory
  {
      my $path = $dir . "/" . $files[$i];
      if (open(my $fh, $path)) {
		
		my $doc = read_file($fh);
        $doc =~ s/\s+/ /g;
        close $fh;

        open(my $fh, '>', $path);
        $doc =~ s/\s[a-z|A-Z]\s/ /g;
		@Split = split /\s+/, $doc;
		$towrite = join(" ", @Split[100 .. 750] );
		$towrite =~ s/\./.\n/g;
		print $fh $towrite;
		print $path . "\n";
		close $fh;
          
      }
  }


}