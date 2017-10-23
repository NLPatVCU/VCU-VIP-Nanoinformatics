use lib qw(../);
use ID2PDF;

my $conv = new ID2PDF();


my $filename = 'icon_id.data';
open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

my $count = 0;
my $dummy=<$fh>; #eat file header
my @tempIds;
chomp(@tempIds = <$fh>);

my @ids;

foreach my $id (@tempIds){
  unless( grep( /^$id$/, @ids) ){
    unless($id eq "NOT_FOUND"){
      push @ids, $id;
    }

  }
}



# $conv->getPDF("17928048", "../icon/icon_pdf/")
#
# $conv->downloadPDF("https://link.springer.com/content/pdf/10.1007%2Fs10856-009-3978-8.pdf", "../icon/icon_pdf/test.pdf")

open(my $log, '>', "download.log");

foreach my $id (@ids){
  chomp($row);
  if(count >= 20){last;}
  if($result = $conv->getPDF($id, "../icon/icon_pdf/")){
    print $log "Downloaded PDF: $id\n";
  }else{
    print $log "Could not download PDF: $id\n";
  }
  #print $conv->getPDF("21294262");
  $count++;
}
