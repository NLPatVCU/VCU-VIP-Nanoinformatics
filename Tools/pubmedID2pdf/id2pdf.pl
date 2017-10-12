use strict;
use URI;
use Web::Scraper;
use Encode;
use Data::Dumper;

my @links = get_pdf_links("22276919");
print join("\n",@links)."\n";
#input: pubmed id of article
#output: array containing links to full page source of article
sub get_pdf_links(){
    my ($pid) = shift;
    my $link_scraper = scraper{
      process ".icons > a", 'links[]' => scraper{
        process 'a', url => '@href';
      };
    };
    my $result = $link_scraper->scrape( URI->new("https://www.ncbi.nlm.nih.gov/pubmed/".$pid) );
    die "No full-page links were found with PMID: ".$pid if not exists $result->{links};
    my @links = ();

    for my $link (@{$result->{links}}){
      push @links, $link->{url};
    }
    return @links;
}


sub getPDFLink(){

}
