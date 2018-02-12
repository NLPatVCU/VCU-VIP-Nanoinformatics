package ID2PDF;


#@author Andriy Mulyar

use strict;
use warnings;
use URI;
use Web::Scraper;
use WWW::Mechanize;
use Data::Dumper;
use LWP::Simple;

sub new {

    my $self = {
      _mech => WWW::Mechanize->new()
    };
    my $class = shift;

    die "Could not connect to PubMed" if not $self->{_mech}->get("https://www.ncbi.nlm.nih.gov/pubmed/");


    bless($self, $class);

    return $self;
}



#input: $id, location (default: pdf/$id.pdf)
sub getPDF(){
  my $self = shift;
  my $id = shift;
  my $location = shift;

  if(not $location){
    $location = "$id.pdf";
  }else{
    $location .= "$id.pdf";
  }

  my @links;
  eval{
    @links = $self->getLinksToPDF($id);
  }or return 0;



  my $downloaded = 0;

  foreach my $link (@links){
    if($link && not $downloaded){
      my $pdfURL = "";
      eval{
        $pdfURL = $self->getPDFLink($link,$id);
      };

      if($pdfURL){
        eval{
        #  print $pdfURL."\n";
          $self->downloadPDF($pdfURL, $location);
          $downloaded = 1;
        };

      }
    }
  }

  return $downloaded;



}


#input: pubmed id of article
#output: array containing links to full page source of article

#attempts to download PDF from given PID and runs through several special cases
#associated with common journals
sub getLinksToPDF(){
    my $self = shift;
    my $pid = shift;
    my $link_scraper = scraper{
      process ".icons > a", 'links[]' => scraper{
        process 'a', url => '@href';
      };
    };
    my $result = $link_scraper->scrape( URI->new("https://www.ncbi.nlm.nih.gov/pubmed/".$pid) );
    die "No full-paper links were found with PMID: $pid" if not exists $result->{links};
    my @links = ();

    for my $link (@{$result->{links}}){
      push @links, $link->{url};
    }
    return @links;

}

#input: url of webpage containing the full text of an article pdf
#output: link to pdf
sub getPDFLink(){
  my $self = shift;
  my $fullTextURL = shift;
  my $regex = shift;
  my $mech = $self->{_mech};

  $mech->get($fullTextURL);

  my $link;


  ##Begin dx.doi redirect  special case.
  if(not $link){
    if($fullTextURL =~ /\Qdx.doi.org\E/){
      $mech->follow_link(text_regex => qr/PDF/);

      ##Begin ACS Publications special case
      if($mech->uri() =~ /\Qpubs.acs.org\E/){
        my $id = $fullTextURL =~ s/(.+)\/(.+\/.+)/$2/r;
        my $pdfUrl = "http://pubs.acs.org/doi/pdf/$id";
        return $pdfUrl;
      }else{
        $mech->get($fullTextURL);
      }
      ##End ACS Publications Special case



    }
  }

  ##End dx.doi redirect  special case.



  ##Begin Science Direct special case.
  if(not $link){
    if($fullTextURL =~ /\Qlinkinghub.elsevier.com\E/){ #https://linkinghub.elsevier.com/retrieve/pii/S0927-7765(10)00087-1
      my $id = $fullTextURL =~ s/(.+)\/(.+)/$2/r;
      $id =~ s/[^SX\d]//g; #parses end of URL to get specific id for ScienceDirect
      $mech->get("http://www.sciencedirect.com/science/article/pii/$id");
      #$link = $mech->follow_link(text_regex => qr/PDF/);
      return "DOES NOT WORK";
    }
  }
  ##End Science Direct special case.

  if($mech->find_link(text_regex => qr/PDF/)){

    $link = $mech->find_link(text_regex => qr/PDF/);

    if($link->url_abs() =~ /\Qepdf\E/){ # if it contains an epdf, extract it.
      $mech->get($link);
      $mech->get($link->url_abs() =~ s/epdf/pdf/r );
      $link = $mech->find_link(tag => "iframe");
    }
  }

  if(not $link){
    if($mech->find_link(text_regex => qr/.pdf/)){
      $link = $mech->find_link(text_regex => qr/.pdf/);
    }
  }








  die "Unable to find PDF on page: ".$fullTextURL if not $link;
  my $linkURL = $link->url_abs();
  return $linkURL;


}

#input: url of pdf, location to save
#output: pdf
sub downloadPDF(){
  my $self = shift;
  my $pdfURL = shift;
  my $location = shift;

  my $mech = $self->{_mech};
  $mech->get($pdfURL);
  $mech->save_content($location, binary => 1);
#  print "Created File: $location"."\n";
}


1;
