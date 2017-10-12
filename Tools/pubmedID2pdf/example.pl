use strict;
use URI;
use Web::Scraper;
use Encode;

  # First, create your scraper block
  my $authors = scraper {
      # Parse all TDs inside 'table[width="100%]"', store them into
      # an array 'authors'.  We embed other scrapers for each TD.
      process 'table[width="100%"] td', "authors[]" => scraper {
        # And, in each TD,
        # get the URI of "a" element
        process "a", uri => '@href';
        # get text inside "small" element
        process "small", fullname => 'TEXT';
      };
  };

  my $res = $authors->scrape( URI->new("http://search.cpan.org/author/?A") );

  # iterate the array 'authors'
  for my $author (@{$res->{authors}}) {
      # output is like:
      # Andy Adler      http://search.cpan.org/~aadler/
      # Aaron K Dancygier       http://search.cpan.org/~aakd/
      # Aamer Akhter    http://search.cpan.org/~aakhter/
      print Encode::encode("utf8", "$author->{fullname}\t$author->{uri}\n");
  }


#################################


# <span class="date">2008/12/21</span>
# date => "2008/12/21"
process ".date", date => 'TEXT';

# <div class="body"><a href="http://example.com/">foo</a></div>
# link => URI->new("http://example.com/")
process ".body > a", link => '@href';

# <div class="body"><!-- HTML Comment here --><a href="http://example.com/">foo</a></div>
# comment => " HTML Comment here "
#
# NOTES: A comment nodes are accessed when installed
# the HTML::TreeBuilder::XPath (version >= 0.14) and/or
# the HTML::TreeBuilder::LibXML (version >= 0.13)
process "//div[contains(@class, 'body')]/comment()", comment => 'TEXT';

# <div class="body"><a href="http://example.com/">foo</a></div>
# link => URI->new("http://example.com/"), text => "foo"
process ".body > a", link => '@href', text => 'TEXT';

# <ul><li>foo</li><li>bar</li></ul>
# list => [ "foo", "bar" ]
process "li", "list[]" => "TEXT";

# <ul><li id="1">foo</li><li id="2">bar</li></ul>
# list => [ { id => "1", text => "foo" }, { id => "2", text => "bar" } ];
process "li", "list[]" => { id => '@id', text => "TEXT" };
