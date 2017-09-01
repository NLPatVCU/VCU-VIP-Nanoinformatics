#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/26/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - PubMed EUtilities Module        #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 This script will attempt to query eSearch, eSummary and eFetch     #
#                 with a user submitted query and return data from each respective   #
#                 tool. Primarily used by PubMedXMLParser for fetch data to parse    #
#                 into PubEntry object.                                              #
#                                                                                    #
######################################################################################





use strict;
use warnings;

# CPAN Dependencies
use Net::Ping;                          # Used for pinging internet connectivity
use LWP::Simple;
use Cwd;                                # Used for directory/file operations
use Path::Class;                        # Used for directory/file operations
use autodie;                            # Used for directory/file operations




package Find::EUtilities;




######################################################################################
#    Constructor
######################################################################################

BEGIN
{
    # CONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    Destructor
######################################################################################

END
{
    # DECONSTRUCTOR : DO SOMETHING HERE
    
    my ( $self ) = @_;
    close( $self->{ _fileHandle } ) if( $self->{ _fileHandle } )
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog => shift,             # Boolean (Binary): 0 = False, 1 = True
        _writeLog => shift,             # Boolean (Binary): 0 = False, 1 = True
        _sourceName => shift,           # String
        _outputFormat => shift,         # Boolean (Binary): 0 = XML, 1 = TXT (PubMed)
        _repositoryDB => shift,         # String
        _baseURL => shift,              # String
        _useHistory => shift,           # String
        _lastQuery => shift,            # String
        _eSearchURL => shift,           # String
        _eSummaryURL => shift,          # String
        _eFetchURL => shift,            # String
        _eSearchData => shift,          # String
        _eSummaryData => shift,         # String
        _eFetchDataAry => shift,        # Array - ( Array Reference When Passed As Argument )
        _fileHandle => shift,           # File Handle
        _statusMessage => shift,        # String
        _retStart => shift,             # Int
        _retMax => shift,               # Int
        _prevRetStart => shift,         # Int
        _prevRetMax => shift,           # Int
        _eSearchCount => shift,         # Int
        _queryKey => shift,             # Int
        _webEnv => shift,               # String
    };
    
    # Set variables to default values
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _sourceName } = "" if !defined ( $self->{ _sourceName } );
    $self->{ _outputFormat } = "" if !defined ( $self->{ _outputFormat } );
    $self->{ _repositoryDB } = "" if !defined ( $self->{ _repositoryDB } );
    $self->{ _baseURL } = "" if !defined ( $self->{ _baseURL } );
    $self->{ _useHistory } = "" if !defined ( $self->{ _useHistory } );
    $self->{ _lastQuery } = "" if !defined ( $self->{ _lastQuery } );
    $self->{ _eSearchURL } = "" if !defined ( $self->{ _eSearchURL } );
    $self->{ _eSummaryURL } = "" if !defined ( $self->{ _eSummaryURL } );
    $self->{ _eFetchURL } = "" if !defined ( $self->{ _eFetchURL } );
    $self->{ _eSearchData } = "" if !defined ( $self->{ _eSearchData } );
    $self->{ _eSummaryData } = "" if !defined ( $self->{ _eSummaryData } );
    @{ $self->{ _eFetchDataAry } } = @{ $self->{ _eFetchDataAry } } if defined( $self->{ _eFetchDataAry } );   # De-Reference Specified Array Reference
    @{ $self->{ _eFetchDataAry } } = () if !defined( $self->{ _eFetchDataAry } );                              # No Array Reference Specified / Empty Array
    $self->{ _sourceName } = "" if !defined ( $self->{ _sourceName } );
    $self->{ _statusMessage } = "(null)" if !defined ( $self->{ _statusMessage } );
    $self->{ _retStart } = 0 if !defined ( $self->{ _retStart } );
    $self->{ _retMax } = 0 if !defined ( $self->{ _retMax } );
    $self->{ _prevRetStart } = 0 if !defined ( $self->{ _prevRetStart } );
    $self->{ _prevRetMax } = 0 if !defined ( $self->{ _prevRetMax } );
    $self->{ _eSearchCount } = -1 if !defined ( $self->{ _eSearchCount } );
    $self->{ _queryKey } = -1 if !defined ( $self->{ _queryKey } );
    $self->{ _webEnv } = "(null)" if !defined ( $self->{ _webEnv } );

    
    # Filename = IP Address + Module Name
    $self->{ _sourceName } = $self->{ _sourceName } . '_' if( $self->{ _sourceName } ne "" );
    
    my $_fileName = $self->{ _sourceName } . 'EUtilitiesLog.txt';
    
    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', $_fileName );
        $self->{ _fileHandle }->autoflush( 1 );             # Flushes writes to file with used in server
    }
    
    bless $self, $class;
    
    $self->WriteLog( "New: Debug On" );
    
    return $self;
}




######################################################################################
#    Module Functions
######################################################################################

sub ConnectedToInternet
{
    my ( $self ) = @_;
    
    my $url = "www.vcu.edu";
    my $conn = Net::Ping->new( "tcp", 2 );
    $conn->port_number( scalar( getservbyname( "http", "tcp" ) ) );
    
    # Internet Connection
    return 1 if ( $conn->ping( $url ) );
    
    # No Internet Connection
    return 0;
}

sub FetchQuery
{
    my ( $self, $temp ) = @_;
    
    # If search requirements aren't met, do not proceed.
    if( $self->CheckSearchRequirements() == 0 )
    {
        return;
    }
    
    if( $self->GetRepositoryDB() eq 'pubmed' )
    {
        # Checks to see if new query is the same as the last query
        # and increments retStart and retMax if true.
        if( $temp eq $self->GetLastQuery() && $self->GetPrevRetStart() == $self->GetRetStart()
            && $self->GetPrevRetMax() == $self->GetRetMax() )
        {
            # Set RetStart Value to Collect Next Data Set
            $self->SetRetStart( $self->GetRetStart() + $self->GetRetMax() );
        }
        else
        {
            $self->SetLastQuery( $temp );
        }
    
        if( $self->GetESearchData() eq "" && $temp eq $self->GetLastQuery() )
        {
            $self->WriteLog( "FetchQuery - Query: " . $self->GetLastQuery() );
            
            $self->SetBaseURL( 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/' );
            $self->WriteLog( "FetchQuery - Base URL: " . $self->GetBaseURL() );
            
            # Assemble eSearch URL
            $self->SetESearchURL( $self->GetBaseURL() . "esearch.fcgi?db=" . $self->GetRepositoryDB() .
                                 "&term=" . $self->GetLastQuery() . "&usehistory=" . $self->GetUseHistory() );
            $self->WriteLog( "FetchQuery - eSearch: URL Assembled" );
            $self->WriteLog( "FetchQuery - eSearch: URL = " . $self->GetESearchURL() );
            
            $self->SetESearchData( LWP::Simple::get( $self->GetESearchURL() ) );
            $self->WriteLog( "FetchQuery - eSearch: Data Acquired" );
        }
        
        #parse WebEnv and QueryKey
        my $web   = $1 if ( $self->GetESearchData() =~ /<WebEnv>(\S+)<\/WebEnv>/ );
        my $key   = $1 if ( $self->GetESearchData() =~ /<QueryKey>(\d+)<\/QueryKey>/ );
        my $count = $1 if ( $self->GetESearchData() =~ /<Count>(\d+)<\/Count>/ );
        
        $self->WriteLog( "FetchQuery - eSearch: WebEnv = $web" );
        $self->WriteLog( "FetchQuery - eSearch: QueryKey = $key" );
        $self->WriteLog( "FetchQuery - eSearch: Count = $count" );
        
        $self->WriteLog( "FetchQuery - Preparing eFetch URL and Parameters" );
        
        # Setup Output Format
        my $format = "xml";
        
        if( $self->GetOutputFormat() == 0 )
        {
            $format = "xml";
        }
        else
        {
            $format = "txt";
        }
        
        $self->WriteLog( "FetchQuery - eFetch: Output Format = $format" );
        
        # Setup EFetch Routine
        my $retStart = 0;
        my $retMax = $self->GetRetMax();
        my $eFetchData = "";
        my $eSearchCount = $self->GetESearchCount();
        
        # Safety Checks
        $eSearchCount = $count if $self->GetESearchCount() != $count;
        
        if( $retMax > $eSearchCount )
        {
            $retMax = $eSearchCount;
        }
        
        if( $retMax == -1 || $retMax == 0 )
        {
            WriteLog( "FetchQuery - Error: RetStart == RetMax" );
            return;
        }
        
        $self->WriteLog( "FetchQuery - eFetch: Fetching Data" );
        $self->WriteLog( "FetchQuery - eFetch: Queries Listed Below" );
        
        $self->ClearEFetchDataArray();
        
        my $fetchTotal = $retMax + $self->GetRetStart();
        
        $self->WriteLog( "FetchQuery - eSearch: Count = $retMax, eFetch: Fetching Data In One Query" );
        $self->WriteLog( "FetchQuery - eFetch: Fetching Data" );
        $self->WriteLog( "FetchQuery - eFetch: Queries Listed Below" );
        
        ### Include this code for ESearch-EFetch
        # Assemble the efetch URL and place data (TXT/XML Format) to member variable
        # Retrieve data in batches of $retMax value (500 max value)
        for ( $retStart = $self->GetRetStart(); $retStart < $fetchTotal; $retStart += $retMax )
        {
            my $_eFetchURL = $self->GetBaseURL() . "efetch.fcgi?db=" . $self->GetRepositoryDB() . "&query_key=$key&WebEnv=$web";
            $_eFetchURL .= "&retstart=$retStart&retmax=$retMax&rettype=abstract&retmode=$format";
            $self->SetEFetchURL( $_eFetchURL );
            $self->WriteLog( "FetchQuery - eFetch: Query URL = " . $self->GetEFetchURL() );
            $self->AppendToEFetchDataArray( LWP::Simple::get( $self->GetEFetchURL() ) );
        }
        
        $self->WriteLog( "FetchQuery - eFetch: Data Stored In Module Member Variable" );
        $self->WriteLog( "FetchQuery - eFetch: Data Fetching Complete" );
        
        $self->SetPrevRetStart( $retStart );
        $self->SetPrevRetMax( $retMax );
    }
}

sub FetchAllQueryEntries
{
    my ( $self, $temp ) = @_;
    $self->SetLastQuery( $temp );
    
    # If search requirements aren't met, do not proceed.
    if( $self->CheckSearchRequirements() == 0 )
    {
        return;
    }
    
    if( $self->GetRepositoryDB() eq 'pubmed' )
    {
        $self->WriteLog( "FetchAllQueryEntries - Query: " . $self->GetLastQuery() );
        
        $self->SetBaseURL( 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/' );
        $self->WriteLog( "FetchAllQueryEntries - Base URL: " . $self->GetBaseURL() );
        
        # Assemble eSearch URL
        $self->SetESearchURL( $self->GetBaseURL() . "esearch.fcgi?db=" . $self->GetRepositoryDB() .
                             "&term=" . $self->GetLastQuery() . "&usehistory=" . $self->GetUseHistory() );
        $self->WriteLog( "FetchAllQueryEntries - eSearch: URL Assembled" );
        $self->WriteLog( "FetchAllQueryEntries - eSearch: URL = " . $self->GetESearchURL() );
        
        $self->SetESearchData( LWP::Simple::get( $self->GetESearchURL() ) );
        $self->WriteLog( "FetchAllQueryEntries - eSearch: Data Acquired" );
        
        #parse WebEnv and QueryKey
	my $web = $1 if ( $self->GetESearchData() =~ /<WebEnv>(\S+)<\/WebEnv>/ );
	my $key = $1 if ( $self->GetESearchData() =~ /<QueryKey>(\d+)<\/QueryKey>/ );
	my $count = $1 if ( $self->GetESearchData() =~ /<Count>(\d+)<\/Count>/ );
	
	$self->WriteLog( "FetchAllQueryEntries - eSearch: WebEnv = $web" );
	$self->WriteLog( "FetchAllQueryEntries - eSearch: QueryKey = $key" );
	$self->WriteLog( "FetchAllQueryEntries - eSearch: Count = $count" );
        
        $self->WriteLog( "FetchAllQueryEntries - Preparing eFetch URL and Parameters" );
        
        # Setup Output Format
        my $format = "xml";
        
        if( $self->GetOutputFormat() == 0 )
	{
	    $format = "xml";
	}
	else
	{
	    $format = "txt";
	}
	
	$self->WriteLog( "FetchAllQueryEntries - eFetch: Output Format = $format" );
	
	# Setup EFetch Routine
	my $retStart = 0;
	my $retMax = 0;
	my $eFetchData;
	
	if( $count > 100 )
	{
	    $self->WriteLog( "FetchAllQueryEntries - eSearch: Count = $count, eFetch: Fetching Data In Multiple Queries" );
	    $retMax = 500;
	}
	else
	{
	    $self->WriteLog( "FetchAllQueryEntries - eSearch: Count = $count, eFetch: Fetching Data In One Query" );
	    $retMax = $count;
	}
	
	$self->WriteLog( "FetchAllQueryEntries - eFetch: Fetching Data" );
	$self->WriteLog( "FetchAllQueryEntries - eFetch: Queries Listed Below" );
	
	### Include this code for ESearch-EFetch
	# Assemble the efetch URL and place data (TXT/XML Format) to member variable
	# Retrieve data in batches of $retMax value (500 max value)
        for ( $retStart = 0; $retStart < $count; $retStart += $retMax )
        {
            my $_eFetchURL = $self->GetBaseURL() . "efetch.fcgi?db=" . $self->GetRepositoryDB() . "&query_key=$key&WebEnv=$web";
            $_eFetchURL .= "&retstart=$retStart&retmax=$retMax&rettype=abstract&retmode=$format";
            $self->SetEFetchURL( $_eFetchURL );
            $self->WriteLog( "FetchAllQueryEntries - eFetch: Query URL = " . $self->GetEFetchURL() );
            $self->AppendToEFetchDataArray( LWP::Simple::get( $self->GetEFetchURL() ) );
        }
        
        $self->WriteLog( "FetchAllQueryEntries - eFetch: Data Stored In Module Member Variable" );
        
        # Assemble eSummary URL
        $self->SetESummaryURL(  $self->GetBaseURL() . "esummary.fcgi?db=" . $self->GetRepositoryDB() . "&query_key=$key&WebEnv=$web" );
        $self->WriteLog( "FetchAllQueryEntries - eSummary: URL Assembled" );
        $self->WriteLog( "FetchAllQueryEntries - eSummary: URL = " . $self->GetESummaryURL() );
        
        $self->SetESummaryData( LWP::Simple::get( $self->GetESummaryURL() ) );
        $self->WriteLog( "FetchAllQueryEntries - eSummary: Data Acquired" );
        $self->WriteLog( "FetchAllQueryEntries - eFetch: Data Fetching Complete" );
    }
}

sub ParseESearch
{
    my ( $self, $query ) = @_;
    
    if( $self->GetRepositoryDB() eq "pubmed" && $query ne "" )
    {
        $self->WriteLog( "ParseESearch - Query: " . $query );
        
        $self->SetBaseURL( 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/' );
        $self->WriteLog( "ParseESearch - Base URL: " . $self->GetBaseURL() );
        
        # Assemble eSearch URL
        $self->SetESearchURL( $self->GetBaseURL() . "esearch.fcgi?db=" . $self->GetRepositoryDB() .
                             "&term=" . $query . "&usehistory=" . $self->GetUseHistory() );
        $self->WriteLog( "ParseESearch - eSearch: URL Assembled" );
        $self->WriteLog( "ParseESearch - eSearch: URL = " . $self->GetESearchURL() );
        
        $self->SetESearchData( LWP::Simple::get( $self->GetESearchURL() ) );
        $self->WriteLog( "ParseESearch - eSearch: Data Acquired" );
        
        #parse WebEnv and QueryKey
	my $web = $1 if ( $self->GetESearchData() =~ /<WebEnv>(\S+)<\/WebEnv>/ );
	my $key = $1 if ( $self->GetESearchData() =~ /<QueryKey>(\d+)<\/QueryKey>/ );
	my $count = $1 if ( $self->GetESearchData() =~ /<Count>(\d+)<\/Count>/ );
	
	$self->SetWebEnv( $web ) if defined ( $web );
	$self->SetQueryKey( $key ) if defined ( $key );
	$self->SetESearchCount( $count ) if defined ( $count );
    }
}

sub CheckSearchRequirements
{
    my ( $self ) = @_;
    
    if( $self->GetRepositoryDB() eq "" )
    {
        $self->SetStatusMessage( "CheckSearchRequirements - Error: Cannot Retrieve Data/No Repository Database Set" );
        return 0;
    }
    
    if( $self->GetRepositoryDB() eq "pubmed" && $self->GetUseHistory() eq "" )
    {
        $self->SetStatusMessage( "CheckSearchRequirements - Error: PubMed Requires UseHistory To Be Set (Y/N)/UseHistory NULL" );
        return 0;
    }
    
    if( $self->GetRepositoryDB() eq "pubmed" && $self->GetOutputFormat() eq "" )
    {
        $self->SetStatusMessage( "CheckSearchRequirements - Error: PubMed Requires OutputFormat To Be Set (0=XML/1=TXT)/OutputFormat NULL" );
        return 0;
    }
    
    return 1;
}

sub ReadEFetchDataFromFile
{
    my ( $self, $fileName ) = @_;
    
    # Check(s)
    $self->WriteLog( "ReadEFetchDataFromFile - Checking if directory/file exists..." );
    $self->WriteLog( "ReadEFetchDataFromFile - File Exists\n" ) if ( -e $fileName );
    $self->WriteLog( "ReadEFetchDataFromFile - File Does Not Exist\n" ) if !( -e $fileName );
    return if !( -e $fileName );
    
    # Read eFetch Data From File
    my $data = "";
    open( my $fileHandle, '<:encoding(UTF-8)', $fileName );
    
    while( my $row = <$fileHandle> )
    {
        chomp $row;
        $data .= "$row\n";
    }
    
    close( $fileHandle );
    
    $self->AppendToEFetchDataArray( $data );
    $data = "";
    
    $self->WriteLog( "ReadEFetchDataFromFile - Reading eFetch Data Complete/Data Stored\n" );
    return 1;
}

sub DumpEFetchDataToFile
{
    my ( $self, $appendToFile ) = @_;
    
    $appendToFile = 0 if !defined ( $appendToFile );
    
    my $currDir = Cwd::getcwd();
    $self->WriteLog( "DumpEFetchDataToFile - Working Directory: $currDir\n" );
    $self->WriteLog( "DumpEFetchDataToFile - Checking if directory exists..." );
    $self->WriteLog( "DumpEFetchDataToFile - Directory Exists\n" ) if ( -e $currDir );
    $self->WriteLog( "DumpEFetchDataToFile - Directory Does Not Exist\n" ) if !( -e $currDir );
    return if !( -e$currDir );
    
    my $fileHandle = undef;
    
    # Write eFetch Data To File (Over Write Previous Data)
    open( $fileHandle, '>:encoding(UTF-8)', 'eFetch Data.txt' ) if $appendToFile == 0;
    
    # Write eFetch Data To File (Append To End Of File)
    open( $fileHandle, '>>:encoding(UTF-8)', 'eFetch Data.txt' ) if $appendToFile == 1;
    
    my @dataArray = $self->GetEFetchDataArray();

    # Return If No Data Fetched
    $self->WriteLog( "DumpEFetchDataToFile - No EFetch Data To Write To File/Has Data Been Fetched Prior?" ) if @dataArray == 0;
    return 0 if @dataArray == 0;
    
    foreach my $data ( @dataArray )
    {
        print( $fileHandle $data );
    }
    
    close( $fileHandle );
    
    $self->WriteLog( "DumpEFetchDataToFile - Writing eFetch Data Complete\n" );
    return 1;
}

sub ClearData
{
    my ( $self ) = @_;
    
    $self->SetRetStart( 0 );
    $self->SetRetMax( 0 );
    $self->SetPrevRetStart( 0 );
    $self->SetPrevRetMax( 0 );
    $self->SetBaseURL( "" );
    $self->SetESearchURL( "" );
    $self->SetESummaryURL( "" );
    $self->SetEFetchURL( "" );
    $self->SetESearchData( "" );
    $self->SetESummaryData( "" );
    $self->ClearEFetchDataArray();
}


######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined $self->{ _debugLog };
    return $self->{ _debugLog };
}

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined $self->{ _writeLog };
    return $self->{ _writeLog };
}

sub GetSourceName
{
    my ( $self ) = @_;
    $self->{ _sourceName } = "" if !defined $self->{ _sourceName };
    return $self->{ _sourceName };
}

sub GetOutputFormat
{
    my ( $self ) = @_;
    $self->{ _outputFormat } = "(null)" if !defined $self->{ _outputFormat };
    return $self->{ _outputFormat };
}

sub GetBaseURL
{
    my ( $self ) = @_;
    $self->{ _baseURL } = "(null)" if !defined $self->{ _baseURL };
    return $self->{ _baseURL };
}

sub GetUseHistory
{
    my ( $self ) = @_;
    $self->{ _useHistory } = 'y' if !defined $self->{ _useHistory };
    return $self->{ _useHistory };
}

sub GetLastQuery
{
    my ( $self ) = @_;
    $self->{ _lastQuery } = "(null)" if !defined $self->{ _lastQuery };
    return $self->{ _lastQuery };
}

sub GetSimplifiedLastQuery
{
    my ( $self ) = @_;
    
    my $lastQuery = $self->GetLastQuery();
    
    return "(null)" if( $lastQuery eq "(null)" || $lastQuery eq "" );
    
    # Remove/Replace Characters/Words
    $lastQuery =~ s/\+/ /g;              # Replace "+" With " "
    $lastQuery =~ s/AND//g;              # Remove "AND"
    $lastQuery =~ s/OR//g;               # Remove "OR"
    $lastQuery =~ s/NOT//g;              # Remove "NOT"
    $lastQuery =~ s/\(//g;               # Remove "("
    $lastQuery =~ s/\)//g;               # Remove ")"
    $lastQuery =~ s/\://g;               # Remove ":"
    $lastQuery =~ s/[0123456789]//g;     # Remove Characters "0123456789"
    $lastQuery =~ s/\[ad\]//g;           # Remove "[ad]" Tag
    $lastQuery =~ s/\[au\]//g;           # Remove "[au]" Tag
    $lastQuery =~ s/\[1au\]//g;          # Remove "[1au]" Tag
    $lastQuery =~ s/\[ip\]//g;           # Remove "[ip]" Tag
    $lastQuery =~ s/\[mesh\]//g;         # Remove "[mesh]" Tag
    $lastQuery =~ s/\[majr\]//g;         # Remove "[majr]" Tag
    $lastQuery =~ s/\[pg\]//g;           # Remove "[pg]" Tag
    $lastQuery =~ s/\[pdat\]//g;         # Remove "[pdat]" Tag
    $lastQuery =~ s/\[dp\]//g;           # Remove "[dp]" Tag
    $lastQuery =~ s/\[pt\]//g;           # Remove "[pt]" Tag
    $lastQuery =~ s/\[sh\]//g;           # Remove "[sh]" Tag
    $lastQuery =~ s/\[nm\]//g;           # Remove "[nm]" Tag
    $lastQuery =~ s/\[tw\]//g;           # Remove "[tw]" Tag
    $lastQuery =~ s/\[ti\]//g;           # Remove "[ti]" Tag
    $lastQuery =~ s/\[tiab\]//g;         # Remove "[tiab]" Tag
    $lastQuery =~ s/\[vi\]//g;           # Remove "[vi]" Tag

    $lastQuery = join( ' ', split( ' ', $lastQuery ) );         # Remove Extra White Space
    
    return $lastQuery;
}

sub GetRepositoryDB
{
    my ( $self ) = @_;
    $self->{ _repositoryDB } = "(null)" if !defined $self->{ _repositoryDB };
    return $self->{ _repositoryDB };
}

sub GetESearchURL
{
    my ( $self ) = @_;
    $self->{ _eSearchURL } = "(null)" if !defined $self->{ _eSearchURL };
    return $self->{ _eSearchURL };
}

sub GetESummaryURL
{
    my ( $self ) = @_;
    $self->{ _eSummaryURL } = "(null)" if !defined $self->{ _eSummaryURL };
    return $self->{ _eSummaryURL };
}

sub GetEFetchURL
{
    my ( $self ) = @_;
    $self->{ _eFetchURL } = "(null)" if !defined $self->{ _eFetchURL };
    return $self->{ _eFetchURL };
}

sub GetESearchData
{
    my ( $self ) = @_;
    $self->{ _eSearchData } = "(null)" if !defined $self->{ _eSearchData };
    return $self->{ _eSearchData };
}

sub GetESummaryData
{
    my ( $self ) = @_;
    $self->{ _eSummaryData } = "(null)" if !defined $self->{ _eSummaryData };
    return $self->{ _eSummaryData };
}

sub GetEFetchDataArray
{
    my ( $self ) = @_;
    @{ $self->{ _eFetchDataAry } } = () if ( @{ $self->{ _eFetchDataAry } } eq 0 );
    return @{ $self->{ _eFetchDataAry } };
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = "(null)" if !defined $self->{ _fileHandle };
    return $self->{ _fileHandle };
}

sub GetStatusMessage
{
    my ( $self ) = @_;
    $self->{ _statusMessage } = "(null)" if !defined $self->{ _statusMessage };
    return $self->{ _statusMessage };
}

sub GetRetStart
{
    my ( $self ) = @_;
    $self->{ _retStart } = -1 if !defined $self->{ _retStart };
    return $self->{ _retStart };
}

sub GetRetMax
{
    my ( $self ) = @_;
    $self->{ _retMax } = -1 if !defined $self->{ _retMax };
    return $self->{ _retMax };
}

sub GetPrevRetStart
{
    my ( $self ) = @_;
    $self->{ _prevRetStart } = -1 if !defined $self->{ _prevRetStart };
    return $self->{ _prevRetStart };
}

sub GetPrevRetMax
{
    my ( $self ) = @_;
    $self->{ _prevRetMax } = -1 if !defined $self->{ _prevRetMax };
    return $self->{ _prevRetMax };
}

sub GetESearchCount
{
    my ( $self ) = @_;
    $self->{ _eSearchCount } = -1 if !defined $self->{ _eSearchCount };
    return $self->{ _eSearchCount };
}

sub GetQueryKey
{
    my ( $self ) = @_;
    $self->{ _queryKey } = -1 if !defined $self->{ _queryKey };
    return $self->{ _queryKey };
}

sub GetWebEnv
{
    my ( $self ) = @_;
    $self->{ _webEnv } = "(null)" if !defined $self->{ _webEnv };
    return $self->{ _webEnv };
}


######################################################################################
#    Mutators
######################################################################################

sub SetBaseURL
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "Base URL Set To: $temp" );
    return $self->{ _baseURL } = $temp;
}

sub SetUseHistory
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "Use History Set To: $temp" );
    return $self->{ _useHistory } = $temp;
}

sub SetLastQuery
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "Last Query Set To: $temp" );
    return $self->{ _lastQuery } = $temp;
}

sub SetESearchURL
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "ESearch URL Set To: $temp" );
    return $self->{ _eSearchURL } = $temp;
}

sub SetESummaryURL
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "ESummary URL Set To: $temp" );
    return $self->{ _eSummaryURL } = $temp;
}

sub SetEFetchURL
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "EFetch URL Set To: $temp" );
    return $self->{ _eFetchURL } = $temp;
}

sub SetESearchData
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "ESearch Data Changed" );
    return $self->{ _eSearchData } = $temp;
}

sub SetESummaryData
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "ESummary Data Changed" );
    return $self->{ _eSummaryData } = $temp;
}

sub SetRepositoryDB
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "Repository Set To: $temp" );
    return $self->{ _repositoryDB } = $temp;
}

sub SetOutputFormat
{
    my ( $self, $temp ) = @_;
    
    if( $temp eq 0 )
    {
        $self->WriteLog( "Output Format Set to: XML" );
    }
    elsif( $temp eq 1 )
    {
        $self->WriteLog( "Output Format Set to: TXT" );
    }
    
    return $self->{ _outputFormat } = $temp;
}

sub AppendToEFetchDataArray
{
    my ( $self, $temp ) = @_;
    push( @{ $self->{ _eFetchDataAry } }, $temp );
}

sub ClearEFetchDataArray
{
    my ( $self ) = @_;
    $self->WriteLog( "EFetch Data Array Cleared" );
    @{ $self->{ _eFetchDataAry } } = ();
}

sub SetStatusMessage
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( $temp );
    $self->{ _statusMessage } = $temp;
}

sub SetRetStart
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "RetStart Set To: $temp" );
    $self->{ _retStart } = $temp;
}

sub SetRetMax
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "RetMax Set To: $temp" );
    $self->{ _retMax } = $temp;
}

sub SetPrevRetStart
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "PrevRetStart Set To: $temp" );
    $self->{ _prevRetStart } = $temp;
}

sub SetPrevRetMax
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "PrevRetMax Set To: $temp" );
    $self->{ _prevRetMax } = $temp;
}

sub SetESearchCount
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "ESearchCount Set To: $temp" );
    $self->{ _eSearchCount } = $temp;
}

sub SetQueryKey
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "QueryKey Set To: $temp" );
    $self->{ _queryKey } = $temp;
}

sub SetWebEnv
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "WebEnv Set To: $temp" );
    $self->{ _webEnv } = $temp;
}


######################################################################################
#    Debug Functions
######################################################################################

sub GetTime
{
    my ( $self ) = @_;
    my( $sec, $min, $hour ) = localtime();
    
    if( $hour < 10 )
    {
        $hour = "0$hour";
    }
    
    if( $min < 10 )
    {
        $min = "0$min";
    }
    
    if( $sec < 10 )
    {
        $sec = "0$sec";
    }
    
    return "$hour:$min:$sec";
}

sub GetDate
{
    my ( $self ) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();
    
    $mon += 1;
    $year += 1900;
    
    return "$mon/$mday/$year";
}

sub WriteLog
{
    my $self = shift;
    my $string = shift;
    my $printNewLine = shift;
    
    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );
    
        
    if( $self->GetDebugLog() )
    {
        if( ref ( $string ) eq "EUtilities" )
        {
            print( GetDate() . " " . GetTime() . " - EUtilities Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - EUtilities::$string";
        print "\n" if( $printNewLine != 0 );
    }
    
    if( $self->GetWriteLog() )
    {
        if( ref ( $string ) eq "EUtilities" )
        {
            print( GetDate() . " " . GetTime() . " - EUtilities: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        my $fileHandle = $self->GetFileHandle();
        
        if( $fileHandle ne "(null)" )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - EUtilities::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}


#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND PubMed EUtilities Module

=head1 SYNOPSIS

FiND Server - Framework for Intelligent Network Discovery

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.24.0 or better) - http://www.perl.org

=back

=head1 CONTACT US

    If you have trouble installing and executing Word2vec-Interface.pl,
    please contact us at

    cuffyca at vcu dot edu.

=head1 Author

 Clint Cuffy, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T McInnes, Virginia Commonwealth University
 btmcinnes at vcu dot edu

 Clint Cuffy, Virginia Commonwealth University
 cuffyca at vcu dot edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut