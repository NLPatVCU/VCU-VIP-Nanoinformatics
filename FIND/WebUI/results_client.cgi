#!"c:\xampp\perl\bin\perl.exe" -w


use CGI;
use IO::Socket::INET;
use Scalar::Util qw(looks_like_number);


my $cgi = new CGI;

# Build CGI Header
print $cgi->header;

# HTML To CGI Parameters
my $keyword = $cgi->param( 'keywords' );
my $searchField = $cgi->param( 'field' );                      # Types: all, title, abstract, author
my $type = $cgi->param( 'type' );                              # Types: Contains, Exact
my $startYear = $cgi->param( 'start year' );
my $endYear = $cgi->param( 'end year' );
my $retStart = 0;                                              # Set Using CGI Parameter ( Possible For Prev/Next Page Button)
my $results = $cgi->param( 'results' );                        # Number Of Results To Display Per Page
my $prevPage = $cgi->param( 'prevPage' );
my $nextPage = $cgi->param( 'nextPage' );

# Global Variables
my $socket;
my $data = "";
my $prevResults = $results;
my $startYearStr = "Present" if $startYear eq 3000;
$startYearStr = $startYear if $startYear ne 3000;

# Global PubMed Data Storage Arrays
my @pmid = ();
my @authorList = ();		# <= Array References
my @dateCreated = ();
my @dateCompleted = ();
my @publishYear = ();
my @articleTitle = ();
my @journalTitle = ();
my @abstractList = ();		# <= Array References
my @urlList = ();

# Set RetStart According To Prev/Next Page Variables
$retStart = $prevPage - $results if defined( $prevPage );
$retStart = $nextPage if defined( $nextPage );
$retStart = 0 if $retStart < 0;

# Build HTML Page Head (Display Loading Image)
BuildPageHead();

# Retrieve Data From Server
ConnectToServer();
RetrieveDatabaseDataFromServer();
EndConnectionToServer();

# Set Prev/Next Page Index Variables
$prevPage = $retStart;
$nextPage = $retStart + $results if( $prevResults eq $results );
$nextPage = $retStart if ( $prevResults ne $results );

# Build Remaining HTML Page
BuildPageHeader();
BuildPageNav();
BuildPageBody();

# Clears Data Prior To Termination
ClearData();


#############################################################
#	Server Sub-Routines                                 #
#############################################################

sub ConnectToServer
{
    $socket = new IO::Socket::INET (
            PeerHost => 'localhost',
            PeerPort => '7777',
            Proto => 'tcp',
    );
    die print "Error: Cannot Connect To FiND Server : $!\n" unless $socket;
    
    # auto-flush on socket
    $| = 1;
}

sub RetrieveDatabaseDataFromServer
{
    if( defined( $socket ) && $socket->connected() )
    {
        my $searchBy = "";
        $searchBy = "title" if ( $searchField eq "Title" );
        $searchBy = "abstract" if ( $searchField eq "Abstract" );
        $searchBy = "author" if ( $searchField eq "Author" );
        $searchBy = "all" if ( $searchField eq "All of Above" );
        
        # Setting Up Client-To-Server Variables
        $data = SendCommandReceiveMessage( $socket, "pubmeddefault $results" );

        my $searchWords = $keyword;
        $searchWords =~ s/ /+/g;                # Replace ' ' (Space) with '+'
        
        my $searchType = lc( $type );
        
        # Fetch The Specified Query And Simultaneously Parse That Data (Quick Command)
        $data = SendCommandReceiveMessage( $socket, "dbretrieveentries $searchWords $searchBy $searchType $startYear $endYear $retStart $results" );
        
        
        ################################################################################################
        #       Fetch And Client Side Parsing (Store Data In Global Arrays)
        ################################################################################################
        
        ParseDatabaseData( $data );
        
        # Clear Received Data
        $data = "";
    }
}

sub EndConnectionToServer
{
    if( defined( $socket ) && $socket->connected() )
    {
        SendCommandReceiveMessage( $socket, "exit" );
        shutdown( $socket, 2 );		# Tells the server that you're done reading and writing.
        $socket->close();
    }
}

sub ClearData
{
    @pmid = ();
    @authorList = ();
    @dateCreated = ();
    @dateCompleted = ();
    @publishYear = ();
    @articleTitle = ();
    @journalTitle = ();
    @abstractList = ();
    @urlList = ();
}


#############################################################
#	Parsing Sub-Routines
#############################################################

sub SendCommandReceiveMessage
{
    my $socket = shift;
    my $command = shift;
    
    SendCommand( $socket, $command );
    return ReceiveMessage( $socket );
}

sub SendCommand
{
    my $socket = shift;
    my $command = shift;
    
    my $size = 0;
    
    if( defined( $command ) && $socket && defined( $socket->connected() ) )
    {
        $command .= "<EOTEOT><EOTEOT>";
        $size = $socket->send( $command );
    }
    
    return $size;
}

sub ReceiveMessage
{
    my $socket = shift;
    my $message = "";
    
    if( $socket && defined( $socket->connected() ) )
    {
        my $data = "";
        my $bufferSize = 0;
        
        while( $data !~ /<\\Length>/ )
        {
            # receive a response of up to 1024 characters from server
            $socket->recv( $data, 1024 );
        }
        
        # Find and Replace "<Length>" and "<\Length>" In Response With "" (Nothing) Globally For The Entire Response String
        $data =~ s/<Length>//g;
        $data =~ s/<\\Length>//g;
        
        $bufferSize = $data;
        
        while( $data !~ /<EOTEOT>/ )
        {
            # receive a response of up to $bufferSize characters from server
            $socket->recv( $data, $bufferSize );
            $message .= $data;
        }
        
        # Remove Client Termination Signal String "<EOTEOT>" From Server Fetched Data
        # Find and Replace "<EOTEOT>" In Response With "" (Nothing) Globally For The Entire $message String
        $message =~ s/<EOTEOT>//g;
    }
    
    return $message;
}

# Parses Database Stored Entry Data Retrieved From Server (Parses Multiple Concatenated Elements)
sub ParseDatabaseData
{
    my $str = shift;
    
    my @dataElements = split( '<nd>', $str );
    
    for my $dataElement ( @dataElements )
    {   
        my @elementAry = split( '<=>', $dataElement );
        
        if( $elementAry[0] eq "RetMax" )
        {
            $results = $elementAry[1];
        }
        elsif( $elementAry[0] eq "PMID" )
        {
            my @pmidAry = split( '<en>', $elementAry[1] );
            push( @pmid, @pmidAry );
        }
        if( $elementAry[0] eq "DateCreated" )
        {
            my @dateCreatedAry = split( '<en>', $elementAry[1] );
            push( @dateCreated, @dateCreatedAry );
        }
        if( $elementAry[0] eq "DateCompleted" )
        {
            my @dateCompletedAry = split( '<en>', $elementAry[1] );
            push( @dateCompleted, @dateCompletedAry );
        }
        if( $elementAry[0] eq "PublishYear" )
        {
            my @publishYearAry = split( '<en>', $elementAry[1] );
            push( @publishYear, @publishYearAry );
        }
        if( $elementAry[0] eq "ArticleTitle" )
        {
            my @articleTitleAry = split( '<en>', $elementAry[1] );
            push( @articleTitle, @articleTitleAry );
        }
        if( $elementAry[0] eq "JournalTitle" )
        {
            my @journalTitleAry = split( '<en>', $elementAry[1] );
            push( @journalTitle, @journalTitleAry );
        }
        if( $elementAry[0] eq "AuthorList" )
        {
            my @authorListAry = split( '<ls>', $elementAry[1] );
            
            for my $authorList ( @authorListAry )
            {
                push( @authorList, ParseEntryAuthorList( $authorList ) );
            }
        }
        if( $elementAry[0] eq "Abstract" )
        {
            my @abstractListAry = split( '<ls>', $elementAry[1] );
            
            for my $abstract ( @abstractListAry )
            {
                push( @abstractList, ParseEntryAbstract( $abstract ) );
            }
        }
        if( $elementAry[0] eq "ArticleURL" )
        {
            my @urlListAry = split( '<en>', $elementAry[1] );
            push( @urlList, @urlListAry );
        }
    }
}

# Parses Server Stored Entry Data (Parses Single Element - Multiple Elements Require Calling This Method In Loop)
sub ParseEntryData
{
    my $str = shift;
    
    my @dataElements = split( '<nd>', $str );
    
    for my $dataElement ( @dataElements )
    {   
        my @elementAry = split( '<=>', $dataElement );
        push( @pmid, $elementAry[-1] ) if( $elementAry[0] eq "PMID" );
        push( @dateCreated, $elementAry[1] ) if( $elementAry[0] eq "DateCreated" );
        push( @dateCompleted, $elementAry[-1] ) if( $elementAry[0] eq "DateCompleted" );
        push( @publishYear, $elementAry[-1] ) if( $elementAry[0] eq "PublishYear" );
        push( @articleTitle, $elementAry[-1] ) if( $elementAry[0] eq "ArticleTitle" );
        push( @journalTitle, $elementAry[-1] ) if( $elementAry[0] eq "JournalTitle" );
        push( @authorList, ParseEntryAuthorList( $elementAry[-1] ) ) if( $elementAry[0] eq "AuthorList" ); 
        push( @abstractList, ParseEntryAbstract( $elementAry[-1] ) ) if( $elementAry[0] eq "Abstract" ); 
        push( @urlList, $elementAry[-1] ) if( $elementAry[0] eq "ArticleURL" );
    }
}

# Helper Function: Aid "ParseEntryData" To Parse Abstract Data
sub ParseEntryAbstract
{
    my $str = shift;
    my @abstract = ();
    
    my @categories = split( '<en>', $str );
    
    for my $category ( @categories )
    {
        my @categoryAry = split( '<:>', $category );
        push( @abstract, @categoryAry );
    }
    
    return \@abstract;
}

# Helper Function: Aid "ParseEntryData" To Parse AuthorList Data
sub ParseEntryAuthorList
{
    my $str = shift;
    my @authorAry = ();
    
    my @authors = split( '<en>', $str );
    
    for my $author ( @authors )
    {
        my $nameStr = "";
        my @name = split( '<sp>', $author );
        
        for my $i( 0..@name )
        {
            my $tempStr = "";
            $tempStr = $name[$i];
            
            if( defined( $tempStr ) && index( $tempStr, "LastName<:>" ) != -1 )
            {
                $tempStr =~ s/LastName<:>//g if $tempStr ne "";
                $nameStr .= $tempStr if $tempStr ne "";
            }
            elsif( defined( $tempStr ) && index( $tempStr, "FirstName<:>" ) != -1 )
            {
                $tempStr =~ s/FirstName<:>//g if $tempStr ne "";
                $nameStr .= ", $tempStr" if $tempStr ne "";
            }
            elsif( defined( $tempStr ) && index( $tempStr, "Initials<:>" ) != -1 )
            {
                $tempStr =~ s/Initials<:>//g if $tempStr ne "";
                #$nameStr .= $tempStr if $tempStr ne "";              # Ignore Initials, Since It Is Not Needed
            }
            elsif( defined( $tempStr ) && index( $tempStr, "Affiliation<:>" ) != -1 )
            {
                $tempStr =~ s/Affiliation<:>//g if $tempStr ne "";
                $nameStr .= " Affiliation: $tempStr" if $tempStr ne "";
            }
            
        }
        
        push( @authorAry, $nameStr ) if defined ( $nameStr );
        $nameStr = "";
    }
    
    return \@authorAry;
}

#############################################################
#	End Of Parsing Sub-Routines
#############################################################


sub BuildPageHead
{
    print <<"PAGEHEAD";
    <html>
    <head>
    <title>
    Framework for IntelligeNt research Discovery
    </title>
    <link rel="stylesheet" href="../style1.css" type="text/css" />
    
        <script type="text/javascript" src="../jquery.min.js"></script>
	<script type="text/javascript">
	\$(window).load(function() {
		\$(".loader").fadeOut("slow");
	})
	</script>
    
    </head>
    <body>
    <div class="loader"></div>
PAGEHEAD
}
	
sub BuildPageHeader{
	
	print <<"PAGEHEADER";
	<div id="header">

	<img src="http://www.vcu.edu/assets-vcuhp/images/favicons/apple-touch-icon-144x144-precomposed.png" alt="VCU" style="width:200px;height:120px;">
	<div class= "absolute">
	<form action = "results_client.cgi" method="get" onreset="formreset()">
	<b style="font-size:180%;"> FiND:                                              </b>
	<input type = "search" name ="keywords" placeholder=" Search Keywords" style ="width:350px; height: 25px" value = "$keyword" >

	<select name = "field" style="width: 150px;height:25px">
	<option selected ="selected" value = "$searchField">$searchField</option>
	<option value = "Title">Title</option>
	<option value = "Author">Author</option>
	<option value = "Abstract">Abstract</option>
	<option value = "All of Above">All of Above</option>
	</select>
	
	<select name = "type" style="width: 150px;height:25px">
	<option selected ="selected" value = "$type">$type</option>
	<option value = "Contains">Contains</option>
	<option value = "Exact">Exact</option>
	</select>

	<p>
	Year Start:<select name = "start year" style = "width:100px">
	<option selected = "selected" value = $startYear>$startYearStr</option>
	<option value="3000">Present</option>
	<option value="2016">2016</option>
	<option value="2015">2015</option>
	<option value="2014">2014</option>
	<option value="2013">2013</option>
	<option value="2012">2012</option>
	<option value="2011">2011</option>
	<option value="2010">2010</option>
	<option value="2009">2009</option>
	<option value="2008">2008</option>
	<option value="2007">2007</option>
	<option value="2006">2006</option>
	<option value="2005">2005</option>
	<option value="2004">2004</option>
	<option value="2003">2003</option>
	<option value="2002">2002</option>
	<option value="2001">2001</option>
	<option value="2000">2000</option>
	<option value="1999">1999</option>
	<option value="1998">1998</option>
	<option value="1997">1997</option>
	<option value="1996">1996</option>
	<option value="1995">1995</option>
	<option value="1994">1994</option>
	<option value="1993">1993</option>
	<option value="1992">1992</option>
	<option value="1991">1991</option>
	<option value="1990">1990</option>
	<option value="1989">1989</option>
	<option value="1988">1988</option>
	<option value="1987">1987</option>
	<option value="1986">1986</option>
	<option value="1985">1985</option>
	<option value="1984">1984</option>
	<option value="1983">1983</option>
	<option value="1982">1982</option>
	<option value="1981">1981</option>
	<option value="1980">1980</option>
	<option value="1979">1979</option>
	<option value="1978">1978</option>
	<option value="1977">1977</option>
	<option value="1976">1976</option>
	<option value="1975">1975</option>
	<option value="1974">1974</option>
	<option value="1973">1973</option>
	<option value="1972">1972</option>
	<option value="1971">1971</option>
	<option value="1970">1970</option>
	<option value="1969">1969</option>
	<option value="1968">1968</option>
	<option value="1967">1967</option>
	<option value="1966">1966</option>
	<option value="1965">1965</option>
	<option value="1964">1964</option>
	<option value="1963">1963</option>
	<option value="1962">1962</option>
	<option value="1961">1961</option>
	<option value="1960">1960</option>
	<option value="1959">1959</option>
	<option value="1958">1958</option>
	<option value="1957">1957</option>
	<option value="1956">1956</option>
	<option value="1955">1955</option>
	<option value="1954">1954</option>
	<option value="1953">1953</option>
	<option value="1952">1952</option>
	<option value="1951">1951</option>
	<option value="1950">1950</option>
	<option value="1949">1949</option>
	<option value="1948">1948</option>
	<option value="1947">1947</option>
	<option value="1946">1946</option>
	<option value="1945">1945</option>
	<option value="1944">1944</option>
	<option value="1943">1943</option>
	<option value="1942">1942</option>
	<option value="1941">1941</option>
	<option value="1940">1940</option>
	<option value="1939">1939</option>
	<option value="1938">1938</option>
	<option value="1937">1937</option>
	<option value="1936">1936</option>
	<option value="1935">1935</option>
	<option value="1934">1934</option>
	<option value="1933">1933</option>
	<option value="1932">1932</option>
	<option value="1931">1931</option>
	<option value="1930">1930</option>
	<option value="1929">1929</option>
	<option value="1928">1928</option>
	<option value="1927">1927</option>
	<option value="1926">1926</option>
	<option value="1925">1925</option>
	<option value="1924">1924</option>
	<option value="1923">1923</option>
	<option value="1922">1922</option>
	<option value="1921">1921</option>
	<option value="1920">1920</option>
	<option value="1919">1919</option>
	<option value="1918">1918</option>
	<option value="1917">1917</option>
	<option value="1916">1916</option>
	<option value="1915">1915</option>
	<option value="1914">1914</option>
	<option value="1913">1913</option>
	<option value="1912">1912</option>
	<option value="1911">1911</option>
	<option value="1910">1910</option>
	<option value="1909">1909</option>
	<option value="1908">1908</option>
	<option value="1907">1907</option>
	<option value="1906">1906</option>
	<option value="1905">1905</option>
	<option value="1904">1904</option>
	<option value="1903">1903</option>
	<option value="1902">1902</option>
	<option value="1901">1901</option>
	<option value="1900">1900</option>
	</select>

	Year End:
	<select name = "end year" style="width:100">
	<option selected = "selected" value = $endYear>$endYear</option>
	<option value="2016">2016</option>
	<option value="2015">2015</option>
	<option value="2014">2014</option>
	<option value="2013">2013</option>
	<option value="2012">2012</option>
	<option value="2011">2011</option>
	<option value="2010">2010</option>
	<option value="2009">2009</option>
	<option value="2008">2008</option>
	<option value="2007">2007</option>
	<option value="2006">2006</option>
	<option value="2005">2005</option>
	<option value="2004">2004</option>
	<option value="2003">2003</option>
	<option value="2002">2002</option>
	<option value="2001">2001</option>
	<option value="2000">2000</option>
	<option value="1999">1999</option>
	<option value="1998">1998</option>
	<option value="1997">1997</option>
	<option value="1996">1996</option>
	<option value="1995">1995</option>
	<option value="1994">1994</option>
	<option value="1993">1993</option>
	<option value="1992">1992</option>
	<option value="1991">1991</option>
	<option value="1990">1990</option>
	<option value="1989">1989</option>
	<option value="1988">1988</option>
	<option value="1987">1987</option>
	<option value="1986">1986</option>
	<option value="1985">1985</option>
	<option value="1984">1984</option>
	<option value="1983">1983</option>
	<option value="1982">1982</option>
	<option value="1981">1981</option>
	<option value="1980">1980</option>
	<option value="1979">1979</option>
	<option value="1978">1978</option>
	<option value="1977">1977</option>
	<option value="1976">1976</option>
	<option value="1975">1975</option>
	<option value="1974">1974</option>
	<option value="1973">1973</option>
	<option value="1972">1972</option>
	<option value="1971">1971</option>
	<option value="1970">1970</option>
	<option value="1969">1969</option>
	<option value="1968">1968</option>
	<option value="1967">1967</option>
	<option value="1966">1966</option>
	<option value="1965">1965</option>
	<option value="1964">1964</option>
	<option value="1963">1963</option>
	<option value="1962">1962</option>
	<option value="1961">1961</option>
	<option value="1960">1960</option>
	<option value="1959">1959</option>
	<option value="1958">1958</option>
	<option value="1957">1957</option>
	<option value="1956">1956</option>
	<option value="1955">1955</option>
	<option value="1954">1954</option>
	<option value="1953">1953</option>
	<option value="1952">1952</option>
	<option value="1951">1951</option>
	<option value="1950">1950</option>
	<option value="1949">1949</option>
	<option value="1948">1948</option>
	<option value="1947">1947</option>
	<option value="1946">1946</option>
	<option value="1945">1945</option>
	<option value="1944">1944</option>
	<option value="1943">1943</option>
	<option value="1942">1942</option>
	<option value="1941">1941</option>
	<option value="1940">1940</option>
	<option value="1939">1939</option>
	<option value="1938">1938</option>
	<option value="1937">1937</option>
	<option value="1936">1936</option>
	<option value="1935">1935</option>
	<option value="1934">1934</option>
	<option value="1933">1933</option>
	<option value="1932">1932</option>
	<option value="1931">1931</option>
	<option value="1930">1930</option>
	<option value="1929">1929</option>
	<option value="1928">1928</option>
	<option value="1927">1927</option>
	<option value="1926">1926</option>
	<option value="1925">1925</option>
	<option value="1924">1924</option>
	<option value="1923">1923</option>
	<option value="1922">1922</option>
	<option value="1921">1921</option>
	<option value="1920">1920</option>
	<option value="1919">1919</option>
	<option value="1918">1918</option>
	<option value="1917">1917</option>
	<option value="1916">1916</option>
	<option value="1915">1915</option>
	<option value="1914">1914</option>
	<option value="1913">1913</option>
	<option value="1912">1912</option>
	<option value="1911">1911</option>
	<option value="1910">1910</option>
	<option value="1909">1909</option>
	<option value="1908">1908</option>
	<option value="1907">1907</option>
	<option value="1906">1906</option>
	<option value="1905">1905</option>
	<option value="1904">1904</option>
	<option value="1903">1903</option>
	<option value="1902">1902</option>
	<option value="1901">1901</option>
	<option value="1900">1900</option>
	</select>
	
	No. of Results:<select name = "results" style = "width:100px">
	<option selected = "selected" value = "$prevResults">$prevResults</option>
	<option value="10">10</option>
	<option value="20">20</option>
	<option value="30">30</option>
	<option value="40">40</option>
	<option value="50">50</option>
	<option value="60">60</option>
	</select>
	
	<input type = "submit" value ="Search">
	<!-- </form> -->
	</p>
	</div>
	</div>
	 
PAGEHEADER

}
	
sub BuildPageNav{
	
    print <<"PAGENAV";
    <div id = "nav">
            <br>
            <br>
            &nbsp &nbsp &nbsp
            <a href="../FIND_client.html">
                Back To Home Page
            </a>
    </div>
PAGENAV

}

sub BuildPageBody
{

if( $results )
{	
    print <<"PAGEBODY";
        <div id ="section">
        <p><b> Search Results: </b><br>
PAGEBODY

    print<<"SCRIPT";
        <script type="text/javascript">
            var param="";
            
            function PopupMsgWindow(param) 
            {
                var myWindow = window.open("", "MsgWindow", "width=800,height=800");
                myWindow.document.write( "<p>"+param+"</p>" );
            }
        </script>
SCRIPT
	
	my $LINK="http://www.pubmed.com";	
	
	for $i(1..$results){
	
	# AuthorList and AbstractList Are Arrays of Array References
	# They must be Dereferenced prior to use, such as below.
	# or "@authors = @{$authorList[$i-1]};"
	#    "@abstract = @{$abstractList[$i-1]};"
	# In order to manipulate each individual author and abstract separately.
	
	my @authorEntries = @{$authorList[$i-1]};
	my $abstract = join( '<br>', @{$abstractList[$i-1]} );
	
	# Replace String "No NlmCategory" with "(No Category)"
	$abstract =~ s/No NlmCategory/(No Category)/g;
	$abstract =~ s/\'/\\'/g;        # Replace ' with \'
        $abstract =~ s/\"/\\'/g;        # Replace " with \'
	
	my $arrSize = @authorEntries;
	my $index = $retStart + $i;
        
        #########################################################################################
	
	my $loc = index($authorEntries[0], "Affiliation");
	my $temp = substr($authorEntries[0],0,$loc);
	
	print << "SEARCHRESULTS1";
	<div class = "result">
	$index.<b> $articleTitle[$i-1]</b>
	<ul style = "list-style-type:none">
	<table>
	<tr style="border-bottom: 0.25px solid; border-color: red">
		<td > 
			<li><b>Source Title:</b> 
		</td>
		<td style="border-top: 0.25px solid; border-color: grey">
			$journalTitle[$i-1]
		</td>
	</tr>
	<tr style="border-bottom: 0.25px solid; border-color: red">
		<td > 
			<li><b>AUTHOR:</b> 
		</td>
		<td style="border-top: 0.25px solid; border-color: grey">
SEARCHRESULTS1

                    # Format "Authors" For Display In Main Page
                    for( my $j = 0; $j < $arrSize; $j++ )
                    {
                        # Print First Two Authors and Last Author
                        if( $j < 2 || $j == $arrSize - 1 )
                        {
                            # Locate "Author Affiliation" Index
                            my $affIndex = index( $authorEntries[$j], "Affiliation" );
                            
                            # Print "Author First And Last Name" If Affiliation Not Found
                            print $authorEntries[$j] . "<br>" if ( $affIndex == -1 );
                            
                            # Print Only "Author First And Last Name" If Affiliation Found
                            print substr( $authorEntries[$j], 0, $affIndex ) . "<br>" if ( $affIndex != -1 );
                        }
                    }
                    
                    my $authorStr = "";
                    
                    # Format "Authors" For Display In Pop-Up Window
                    for my $author( @authorEntries )
                    {
                        # Locate "Author Affiliation" Index
                        my $affIndex = index( $author, "Affiliation" );
                        
                        # Concatenate $author If No Affiliation Found
                        $authorStr .= $author . "<br><br>" if ( $affIndex == -1 );
                        
                        # Concatenate Author Name, Then Affiliation On Line Below
                        $authorStr .= substr( $author, 0, $affIndex ) . "<br>" if ( $affIndex != -1 );
                        $authorStr .= substr( $author, $affIndex ) . "<br><br>" if ( $affIndex != -1 );
                    }
                    
                    # Replace Character ' With \' In Authors String (Escape Comma Character)
                    $authorStr =~ s/\'/\\'/g;           # Replace ' with \'
                    $authorStr =~ s/\"/\\'/g;           # Replace " with \'
                        
        print << "SEARCHRESULTS2";
                <li onclick="PopupMsgWindow('$authorStr')"><u><font color="blue" size="2">Details</font></u></li>
                </td>
                </tr>
                <tr>
		<td>
			<li><b>CITATION:</b>
		</td>
		<td style="border-top: 0.25px solid; border-color: grey">
SEARCHRESULTS2

                    # Clear Author String
                    $authorStr = "";
                    
                    for( my $j = 0; $j < $arrSize; $j++ )
                    {
                        my $affIndex = index( $authorEntries[0], "Affiliation" );
                        
                        if( $arrSize == 1 )
                        {
                            $authorStr .= ( $authorEntries[$j] . "." );
                        }
                        # Format Author If There Are Less Than Three
                        elsif( $arrSize < 3 && $affIndex != -1 )
                        {
                            # Add "and" Between Two Authors
                            if( $j == $arrSize - 1 && $arrSize != 1 )
                            {
                                $authorStr .= (  " and " . substr( $authorEntries[$j], 0, $affIndex ) . "." );
                            }
                            else
                            {
                                # If Only One Author Print Name And Remove Trailing Whitespace
                                if( $j == $arrSize - 1 && $arrSize == 1 )
                                {
                                    $authorStr .= substr( $authorEntries[$j], 0, $affIndex );
                                    $authorStr =~ s/\s+$//;     # Remove Trailing Whitespace
                                    $authorStr .= ".";
                                }
                                else
                                {
                                    $authorStr .= substr( $authorEntries[$j], 0, $affIndex );
                                }
                            }
                        }
                        # Use "et al." In Citation If Number Of Authors > 3
                        elsif( $arrSize >= 3 && $affIndex != -1 )
                        {
                            $authorStr .= ( substr( $authorEntries[$j], 0, $affIndex ) . ", et al." );
                            last;               # Jump To Last Index
                        }
                    }
                    
                    print $authorStr;
                    
                    # Clear Author String
                    $authorStr = "";
                    undef $authorStr;
                    
                    $temp = "";
                    my $char = '.';
                    my $offset = 300;
                    my $location = index( $abstract, $char, $offset );
                    $temp = substr( $abstract, 0, $location + 1 );
			
			
		print<<SEARCHRESULTS;		
			<i>"$articleTitle[$i-1]"</i>&nbsp
			$journalTitle[$i-1]&nbsp
			($publishYear[$i-1]).&nbspPubmed.
			Today's Date.&nbsp
			< $urlList[$i-1] >.
		</td>
	</tr>
	<tr>
		<td>
			<li><b>ABSTRACT:</b>
		</td>
		<td style="border-top: 0.25px solid; border-color: grey;">
                    
                        $temp
                        
                        <li onclick="PopupMsgWindow('$abstract')"><u><font color="blue" size="2">Show More</font></u></li>    
                </td>
	
	</tr>
	
	
	<tr>
		<td>
			<li><b>PMID:</b>
		</td>
		<td style="border-top: 0.25px solid; border-color: grey">
			
			$pmid[$i-1]
		</td>
	</tr>
	<tr>
		<td>
			<li><b>Date:</b>
		</td>
		<td>
			
			Start Date: $dateCreated[$i-1] &nbsp End Date: $dateCompleted[$i-1]
			
		</td>
	</tr>
	<tr>
		<td>
			<li><b>Source Link:</b>
		</td>
		<td>
			<a href = "$urlList[$i-1]" target="_blank">
			$urlList[$i-1]
			</a>
		</td>
	</tr>
	<tr>
		<td>
			<li><b>Repository: </b>
		</td>
		<td >
			<a  href = "http://www.pubmed.com" target="_blank"> PubMed</a>
		</td>
	</tr>
	</table>
	</ul>
	</div>
	

SEARCHRESULTS
}

if( $retStart != 0 )
{
    print << "PREVPAGE"
	<div style="margin-left:350px">
            <button name="prevPage" type="submit" value="$prevPage" style="margin-left:auto;margin-right:auto">Prev Page</button>
PREVPAGE
}

if( $prevResults == $results )
{
    print "<div style=\"margin-left:350px\">" if ( $retStart == 0 );
    print << "NEXTPAGE"
            <button name="nextPage" type="submit" value="$nextPage" style="margin-left:auto;margin-right:auto">Next Page</button>
NEXTPAGE
}

print <<"SUBMITRESULTS"
	<script language="JavaScript">
	
		function formReset ()
		{
			
			alert("Form has been Reset.");
		}
		
	</script>
	</form>
	</div>
	</body>
	</html>
SUBMITRESULTS

}
else
{
    print <<"PAGEBODY";
    <div id ="section">
    <p><b> Search Results: </b></p>
PAGEBODY
    
    print "No Results Returned from Server.\n";
}

}