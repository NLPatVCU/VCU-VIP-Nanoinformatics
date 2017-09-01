#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/25/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - PubMed XML Parser Module        #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 This script will attempt to parse a PubMed XML string argument     #
#                 or string passed by function argument and create PubEntry          #
#                 objects using PubEntry module, placing them in an array of         #
#                 PubEntry objects. This can be accessed by function call.           #
#                                                                                    #
#    Note:        Parses eFetch XML Document Only, No eSummary Support.              #
#                                                                                    #
######################################################################################





use strict;
use warnings;

# CPAN Dependencies
use XML::Twig;
use Cwd;                                # Used for directory/file operations
use Path::Class;                        # Used for directory/file operations
use autodie;                            # Used for directory/file operations

# Local Dependencies
use Find::PubEntry;


package Find::PubMedXMLParser;
 





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
    close( $self->{ _fileHandle } ) if( $self->{ _fileHandle } );
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog => shift,                             # Boolean (Binary): 0 = False, 1 = True
        _writeLog => shift,                             # Boolean (Binary): 0 = False, 1 = True
        _xmlStringToParse => shift,                     # String
        _pubEntryList => shift,                         # Array of PubEntry objects
        _parsedCount => shift,                          # Int
        _twigHandler => shift,                          # File Handle
        _fileHandle => shift,                           # File Handle
    };
    
    # Set variables to default values
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _xmlStringToParse } = "" if !defined ( $self->{ _xmlStringToParse } );
    @{ $self->{ _pubEntryList } } = @{ $self->{ _pubEntryList } } if defined( $self->{ _pubEntryList } );
    @{ $self->{ _pubEntryList } } = () if !defined( $self->{ _pubEntryList } );
    $self->{ _parsedCount } = 0 if !defined ( $self->{ _parsedCount } );
    $self->{ _twigHandler } = 0 if !defined ( $self->{ _twigHandler } );
    
    
    
    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', 'PubMedXMLParserLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Flushes writes to file with used in server
    }
    
    
    $self->{ _twigHandler } = XML::Twig->new(
        twig_handlers => 
        { 
            'PubmedArticleSet' => sub { ParsePubMedArticleSet( @_, $self ) },
        },
    );
    
    
    bless $self, $class;
    
    $self->WriteLog( "New: Debug On" );
    
    if( $self->{ _xmlStringToParse } ne "" )
    {
        $self->RemoveXMLVersion( \$self->{ _xmlStringToParse } );
        
        if( $self->CheckForNullData ( $self->{ _xmlStringToParse } ) )
        {
            $self->WriteLog( "New - Error: XML String is null" );
        }
        else
        {
            $self->{ _twigHandler }->parse( $self->{ _xmlStringToParse } );
        }
    }
    else
    {
        $self->WriteLog( "New - No XML String Argument To Parse" );
    }
    
    return $self;
}



######################################################################################
#    Module Functions
######################################################################################


sub CheckParseRequirements
{
    my ( $self, $string ) = @_;
    $string = "" if !defined ( $string );

    if( $string eq "" )
    {
        $self->WriteLog( "Error: Nothing To Parse" );
        return 0;
    }
    elsif( $self->GetTwigHandler() eq "(null)" )
    {
        $self->WriteLog( "Error: Unable To Parse XML Data/TwigHandler = (null)" );
        return 0;
    }
    
    return 1;
}

sub ParseXMLString
{
    my ( $self, $string ) = @_;
    $string = "" if !defined ( $string );
    
    if( $self->CheckParseRequirements( $string ) eq 0 )
    {
        return;
    }
    
    $self->RemoveXMLVersion( \$string );

    if( $self->CheckForNullData( $string ) )
    {
        $self->WriteLog( "ParseXMLString - Cannot Parse (null) string" );
    }
    else
    {
        $self->{ _twigHandler }->parse( $string );
        $self->WriteLog( "ParsePubMedArticleSet: Released PubmedArticle from memory" );
        
        # Print how many entries were parsed
        $self->WriteLog( "ParsePubMedArticleSet: Parsed " . $self->GetParsedCount()  . " entries" );
    }
}

# Checks to see if eFetch returned a null string
sub CheckForNullData
{
    my ( $self, $temp ) = @_;
    my $nullStr = "(null)";
    
    if( my $n = index( $temp, $nullStr ) != -1 )
    {
        # Return True
        return 1 if $n == 0;
    }
    
    # Return False
    return 0;
}

# Removes the XML Version string prior to parsing the XML string
sub RemoveXMLVersion
{
    my ( $self, $temp ) = @_;
    
    # Checking For XML Version
    my $xmlVersion = '<?xml version="1.0"?>';
    my $docType = '!DOCTYPE';
    
    my $line = "";
    my $newXMLString = "";

    foreach $line ( split /\n/ , ${$temp} )
    {
        if( index( $line, $xmlVersion ) == -1 && index( $line, $docType ) == -1  )
        {
            $newXMLString .= ( $line . "\n" );
        }
    }
    
    ${$temp} = $newXMLString;
}

sub ParsePubMedArticleSet
{
    my ( $twigSelf, $root, $self ) = @_;
    my @pubMedArticles = $root->children();

    my $parsedData = 0;

    foreach my $pubMedArticle ( @pubMedArticles )
    {
        # Create New PubEntry
        my $tempPubEntry =  Find::PubEntry->new();
        $self->WriteLog( "ParsePubMedArticleSet: Created PubEntry object" );
        
        $parsedData = $self->ParsePubMedArticle( $tempPubEntry, $pubMedArticle ) if $pubMedArticle->tag() eq "PubmedArticle";
        $parsedData = $self->ParsePubMedBookArticle( $tempPubEntry, $pubMedArticle ) if $pubMedArticle->tag() eq "PubmedBookArticle";
        
        # Store PubEntry object into PubEntry List
        push( @{ $self->{ _pubEntryList } }, $tempPubEntry );
        $self->WriteLog( "ParsePubMedArticleSet: Stored PubEntry object within PubEntryList\n" );
        
        # Increment Parsed Counter
        $self->{ _parsedCount }++ if ( $parsedData == 1 );
        
        # Release the stored xml section from memory (not fully tested)
        $pubMedArticle->purge() if defined( $pubMedArticle );
        
        # Reset Parsed Data Flag
        $parsedData = 0;
    }
    
    # Release the stored xml section from memory (not fully tested)
    $root->purge();
    $self->WriteLog( "ParsePubMedArticleSet: Released PubmedArticleSet group from memory" );
}

sub ParsePubMedArticle
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;

    my @pubMedArticle = $currDir->children();
  
    for my $article ( @pubMedArticle )
    {
        # MedlineCitation / Journal / Other Articles
        if( $article->tag() eq "MedlineCitation" )
        {
            $self->WriteLog( "ParsePubMedArticle - Pub Entry: XML Parse Begin" );
            $self->ParseMedlineCitation( $pubEntry, $article );
        }
        # PubMedData
        elsif( $article->tag() eq "PubmedData" )
        {
            $self->ParsePubData( $pubEntry, $article );
            $self->WriteLog( "ParsePubMedArticle - Pub Entry: XML Parse End" );
        }
        else
        {
            # Statement below should not print any data, but left for testing purposes and future use.
            $self->WriteLog( "(!!! New Data !!!)ParsePubMedArticle - Tag: " . $article->tag() . "ParsePubMedArticle - Field: " . $article->field() );
        }
    }
    
    # Set Entry Type
    $pubEntry->SetEntryType( "JournalArticle" );
    
    # Assemble and Set PubMed URL
    $pubEntry->SetArticleURL( 'http://www.ncbi.nlm.nih.gov/pubmed/' . $pubEntry->GetPMID() );
    $self->WriteLog( "ParsePubMedArticle - URL: " . $pubEntry->GetArticleURL );
    
    return 1;
}

sub ParsePubMedBookArticle
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;

    my @pubMedArticle = $currDir->children();
  
    for my $article ( @pubMedArticle )
    {
        # Book Document
        if( $article->tag() eq "BookDocument" )
        {
            $self->WriteLog( "ParsePubMedArticle - Pub Entry: XML Parse Begin" );
            $self->ParseBookDocument( $pubEntry, $article );
        }
        # PubMedData
        elsif( $article->tag() eq "PubmedBookData" )
        {
            $self->ParsePubData( $pubEntry, $article );
            $self->WriteLog( "ParsePubMedArticle - Pub Entry: XML Parse End" );
        }
        else
        {
            # Statement below should not print any data, but left for testing purposes and future use.
            $self->WriteLog( "ParsePubMedArticle - Tag: " . $article->tag() . "ParsePubMedArticle - Field: " . $article->field() );
        }
    }
    
    # Set Entry Type
    $pubEntry->SetEntryType( "BookArticle" );
    
    # Assemble and Set PubMed URL
    $pubEntry->SetArticleURL( 'http://www.ncbi.nlm.nih.gov/pubmed/' . $pubEntry->GetPMID() );
    $self->WriteLog( "ParsePubMedArticle - URL: " . $pubEntry->GetArticleURL );
    
    return 1;
}

sub ParseMedlineCitation
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @medlineCitation = $currDir->children();

    for my $mCitation ( @medlineCitation )
    {
        # DateCreated
        if( $mCitation->tag() eq "DateCreated" )
        {
            $self->ParseDateCreated( $pubEntry, $mCitation );
        }
        # DateCompleted
        elsif( $mCitation->tag() eq "DateCompleted" )
        {
            $self->ParseDateCompleted( $pubEntry, $mCitation );
        }
        # PubModel
        elsif( $mCitation->tag() eq "Article" )
        {
            $self->ParsePubModel( $pubEntry, $mCitation );
            $self->ParseArticle( $pubEntry, $mCitation );
        }
        # MedlineJournalInfo
        elsif( $mCitation->tag() eq "MedlineJournalInfo" )
        {
            $self->ParseMedlineJournalInfo( $pubEntry, $mCitation );
        }
        # ChemicalList
        elsif( $mCitation->tag() eq "ChemicalList" )
        {
            $self->ParseChemicalList( $pubEntry, $mCitation );
        }
        # MeshHeadingList
        elsif( $mCitation->tag() eq "MeshHeadingList" )
        {
            $self->ParseMeshHeading( $pubEntry, $mCitation );
        }
        else
        {
            $self->WriteLog( "ParseMedlineCitation: - Tag: " . $mCitation->tag() . ", Field: " . $mCitation->field() );
            
            # Store Field Data in respective PubEntry object member variables
            if( $mCitation->tag() eq "PMID" )
            {
                $pubEntry->SetPMID( $mCitation->field() );
            }
            elsif( $mCitation->tag() eq "CitationSubset" )
            {
                $pubEntry->SetCitationSubset( $mCitation->field() );
            }
        }
    }
}

sub ParseBookDocument
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @bookDocument = $currDir->children();

    for my $bDocument ( @bookDocument )
    {
        if( $bDocument->tag() eq "Abstract" )
        {
            $self->ParseAbstract( $pubEntry, $bDocument );
        }
        elsif( $bDocument->tag() eq "Book" )
        {
            $self->ParseBook( $pubEntry, $bDocument );
        }
        elsif( $bDocument->tag() eq "Sections" )
        {
            $self->ParseSections( $pubEntry, $bDocument );
        }
        else
        {
            $self->WriteLog( "ParseBookDocument - Tag: " . $bDocument->tag() . ", Field: " . $bDocument->field() );
            
            # Store Field Data in respective PubEntry object member variables
            if( $bDocument->tag() eq "PMID" )
            {
                $pubEntry->SetPMID( $bDocument->field() );
            }
            elsif( $bDocument->tag() eq "ArticleTitle" )
            {
                $pubEntry->SetArticleTitle( $bDocument->field() );
            }
            elsif( $bDocument->tag() eq "Language" )
            {
                $pubEntry->SetLanguage( $bDocument->field() );
            }
            elsif( $bDocument->tag() eq "PublicationType" )
            {
                my @pubTypeList = $pubEntry->GetPublicationTypeList();
                
                $self->WriteLog( "ParseBookDocument - Tag: " . $bDocument->tag() . ", UI: " . $bDocument->att( 'UI' ) . ", Field: " . $bDocument->field() );
                my @temp = ( $bDocument->att( 'UI' ), $bDocument->field() );
                push( @pubTypeList, \@temp );
                
                $pubEntry->SetPublicationTypeList( @pubTypeList );
            }
            elsif( $bDocument->tag() eq "ArticleIdList" )
            {
                my @articleIDArray = $pubEntry->GetArticleIDList();
                my @articleIdList = $bDocument->children();
                
                for my $articleID ( @articleIdList )
                {
                    $self->WriteLog( "ParseBookDocument - Tag: " . $articleID->tag() . ", IdType: " . $articleID->att( 'IdType' ) . ", Field: " . $articleID->field() );
                    my @arID = ( $articleID->att( 'IdType' ), $articleID->field() );
                    push( @articleIDArray, \@arID );
                }
                
                $pubEntry->SetArticleIDList( @articleIDArray );
            }
        }
    }
}

sub ParseDateCreated
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    if( $currDir->tag() eq "DateCreated" )
    {
        my @dateList = $currDir->children();
        my @dateArray = ();
        
        for my $date ( @dateList )
        {
            $self->WriteLog( "ParseDateCreated - Tag: " . $date->tag() . ", Field: " . $date->field(), 1 );
            
            # Useless checks as PubMed data is always presented in Year/Month/Day format
            if( $date->tag() eq "Year" || $date->tag() eq "Month" || $date->tag() eq "Day" )
            {
                push( @dateArray, $date->field() );
            }
        }
        
        # Store Field Data in respective PubEntry object member variables
        $pubEntry->SetDateCreated( @dateArray ) if( $currDir->tag() eq "DateCreated" );
    }
}

sub ParseDateCompleted
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    if( $currDir->tag() eq "DateCompleted" )
    {
        my @dateList = $currDir->children();
        my @dateArray = ();
        
        for my $date ( @dateList )
        {
            $self->WriteLog( "ParseDateCompleted - Tag: " . $date->tag() . ", Field: " . $date->field(), 1 );
            
            # Useless checks as PubMed data is always presented in Year/Month/Day format
            if( $date->tag() eq "Year" || $date->tag() eq "Month" || $date->tag() eq "Day" )
            {
                push( @dateArray, $date->field() );
            }
        }
        
        # Store Field Data in respective PubEntry object member variables
        $pubEntry->SetDateCompleted( @dateArray ) if( $currDir->tag() eq "DateCompleted" );
    }
}

sub ParsePubModel
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    $self->WriteLog( "ParsePubModel - PubModel : " . $currDir->att( 'PubModel' ) );
    
    # Store Field Data in respective PubEntry object member variable
    $pubEntry->SetPubModel( $currDir->att( 'PubModel' ) );
}

sub ParseArticle
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
     
    my @articleList = $currDir->children();
        
    for my $entry ( @articleList )
    {
        # Journal
        if( $entry->tag() eq "Journal" )
        {
            $self->ParseJournal( $pubEntry, $entry );
        }
        # Pagination
        elsif( $entry->tag() eq "Pagination" )
        {
            $self->ParsePagination( $pubEntry, $entry );
        }
        # Abstract
        elsif( $entry->tag() eq "Abstract" )
        {
            $self->ParseAbstract( $pubEntry, $entry );
        }
        # AuthorList
        elsif( $entry->tag() eq "AuthorList" )
        {
            $self->ParseAuthorList( $pubEntry, $entry );
        }
        # Publication Type List
        elsif( $entry->tag() eq "PublicationTypeList" )
        {
            $self->ParsePublicationTypeList( $pubEntry, $entry );
        }
        else
        {
            $self->WriteLog( "ParseArticle - Tag: " . $entry->tag() . ", Field: " . $entry->field() );
            
            # Store Field Data in respective PubEntry object member variables
            if( $entry->tag() eq "ArticleTitle" )
            {
                $pubEntry->SetArticleTitle( $entry->field() );
            }
            elsif( $entry->tag() eq "Language" )
            {
                $pubEntry->SetLanguage( $entry->field() );
            }
        }
    }
}

sub ParseBook
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
     
    my @bookData = $currDir->children();
        
    for my $entry ( @bookData )
    {
        # Publisher
        if( $entry->tag() eq "Publisher" )
        {
            $self->ParsePublisher( $pubEntry, $entry );
        }
        # BookTitle
        elsif( $entry->tag() eq "BookTitle" )
        {
            $self->ParseBookTitle( $pubEntry, $entry );
        }
        # PubDate
        elsif( $entry->tag() eq "PubDate" )
        {
            $self->ParsePubDate( $pubEntry, $entry );
        }
        # CollectionTitle
        elsif( $entry->tag() eq "CollectionTitle" )
        {
            $self->ParseCollectionTitle( $pubEntry, $entry );
        }
        else
        {
            $self->WriteLog( "ParseBook - Tag: " . $entry->tag() . ", Field: " . $entry->field() );
            
            # Store Field Data in respective PubEntry object member variables
            if( $entry->tag() eq "Isbn" )
            {
                $pubEntry->SetISBN( $entry->field() );
            }
        }
    }
}

sub ParseSections
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @sectionAry = ();
    my @sections = $currDir->children();
    
    for my $section ( @sections )
    {
        my @sectionEntry = $section->children();
        
        for my $sectionData ( @sectionEntry )
        {
            # SectionTitle
            if( $sectionData->tag() eq "SectionTitle" )
            {
                $self->WriteLog( "ParseSections - Tag: " . $sectionData->tag() . ", Book: " . $sectionData->att( 'book' ) . ", Part: " . $sectionData->att( 'part' ) . ", Field: " . $sectionData->field() );
                my @title = ( $sectionData->field(), $sectionData->att( 'book' ), $sectionData->att( 'part' ) );
                push( @sectionAry, \@title );
            }
            elsif( $sectionData->tag() eq "LocationLabel" )
            {
                $self->WriteLog( "ParseSections - Tag: " . $sectionData->tag() . ", Book: " . $sectionData->att( 'Type' ) .  ", Field: " . $sectionData->field() );
                my @locationLabel = ( $sectionData->field(), $sectionData->att( 'Type' ) );
                push( @sectionAry, \@locationLabel );
            }
        }
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetSectionList( @sectionAry );
}

sub ParseJournal
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @journalList = $currDir->children();

    for my $jTemp ( @journalList )
    {
        if( $jTemp->tag() eq "ISSN" )
        {
            $self->WriteLog( "ParseJournal - IssnType : " . $jTemp->att( 'IssnType' ) . ", Tag: " . $jTemp->tag() . ", Field: " . $jTemp->field() );
            
            # Store Field Data in respective PubEntry object member variables
            $pubEntry->SetJournalISSNType( $jTemp->att( 'IssnType' ) );
            $pubEntry->SetJournalISSN( $jTemp->field() );
        }
        elsif( $jTemp->tag() eq "JournalIssue" )
        {
            $self->WriteLog( "ParseJournal - Tag: " . $jTemp->tag() . ", CitedMedium : " . $jTemp->att( 'CitedMedium' ) );
            
            # Store Field Data in respective PubEntry object member variables
            $pubEntry->SetJournalCitedMedium( $jTemp->att( 'CitedMedium' ) );
            
            my @jIssueList = $jTemp->children();
            
            for my $jIssueTemp ( @jIssueList )
            {
                if( $jIssueTemp->tag() eq "PubDate" )
                {
                    $self->ParseJournalPubDate( $pubEntry, $jIssueTemp );
                }
                else
                {
                    $self->WriteLog( "ParseJournal - Tag: " . $jIssueTemp->tag() . ", Field: " . $jIssueTemp->field() );
                }
                
                # Store Field Data in respective PubEntry object member variables
                if( $jIssueTemp->tag() eq "Volume" )
                {
                    $pubEntry->SetJournalVolume( $jIssueTemp->field() );
                }
                elsif( $jIssueTemp->tag() eq "Issue" )
                {
                    $pubEntry->SetJournalIssue( $jIssueTemp->field() );
                }
            }
        }
        else
        {
            $self->WriteLog( "ParseJournal - Tag: " . $jTemp->tag() . ", Field: " . $jTemp->field() );
        }
        
        # Store Field Data in respective PubEntry object member variables
        if( $jTemp->tag() eq "Title" )
        {
            $pubEntry->SetJournalTitle( $jTemp->field() );
        }
        elsif( $jTemp->tag() eq "ISOAbbreviation" )
        {
            $pubEntry->SetJournalISOAbbrev( $jTemp->field() );
        }
    }
}

sub ParseJournalPubDate
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @dateArray = ();
    my @dateList = $currDir->children();
    
    for my $dTemp ( @dateList )
    {
        $self->WriteLog( "ParseJournalPubDate - Tag: " . $dTemp->tag() . ", Field: " . $dTemp->field() );
        
        if( $dTemp->tag() eq "Year" || $dTemp->tag() eq "Month" || $dTemp->tag() eq "MedlineDate" )
        {
            push( @dateArray, $dTemp->field() );
        }
        
        # Set Publication Year
        $pubEntry->SetJournalPubYear( $dTemp->field() ) if( $dTemp->tag() eq "Year" );
        $pubEntry->SetJournalPubYear( substr( $dTemp->field(), 0, 4 ) ) if( $dTemp->tag() eq "MedlineDate" );
    }
    
    # Store Field Data in respective PubEntry object member variables
    # Format: Year (int), Month (string) : if tag() equal "Year"/"Month"
    # Or
    # Format: Year Month (String) : if tag() equal "MedlineDate"
    $pubEntry->SetJournalPubDate( @dateArray );
}

sub ParsePagination
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @paginationArray = ();
    my @paginationList = $currDir->children();
    
    for my $pList ( @paginationList )
    {
        $self->WriteLog( "ParsePagination - Tag: " . $pList->tag() . ", Field: " . $pList->field() );
        my @pag = ( $pList->tag(), $pList->field() );
        push( @paginationArray, \@pag );
    }
  
    # Store Field Data in respective PubEntry object member variables
    # ( Note data stored as array of arrays)
    $pubEntry->SetPagination( @paginationArray );
}

sub ParseAbstract
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @abstractAry = ();
    my @abstractList = $currDir->children();
    
    for my $abstract ( @abstractList )
    {
        # Abstract has categories
        if( defined ( $abstract->att( 'NlmCategory' ) ) )
        {
            $self->WriteLog( "ParseAbstract - Nlmcategory: " . $abstract->att( 'NlmCategory' ) . ", Field: " . $abstract->field() );
            my @aAry = ( $abstract->att( 'NlmCategory' ), $abstract->field() );
            push( @abstractAry, \@aAry );
        }
        # If abstract has no categories
        else
        {
            $self->WriteLog( "ParseAbstract - Type: " . $abstract->tag() . ", Field: " . $abstract->field() );
            my @aAry = ( "No NlmCategory", $abstract->field() );
            push( @abstractAry, \@aAry );
        }
    }
    
    # Store Field Data in respective PubEntry object member variables
    $pubEntry->SetAbstractList( @abstractAry );
}

sub ParseAuthorList
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @author = ();
    my @authorList = $currDir->children();
    
    for my $author ( @authorList )
    {   
        my @temp = ();
        
        my @authorName = $author->children();
        
        for my $name ( @authorName )
        {
            $self->WriteLog( "ParseAuthorList - Tag: " . $name->tag() . ", Field: " . $name->field() );
            push( @temp, $name->field() );
        }
        
        # Format: LastName, ForeName, Initials, ( AffiliationInfo / CollectiveName )
        push( @author, \@temp );
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetAuthorList( @author );
}

sub ParsePublicationTypeList
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @pubList = ();
    my @pubTypeList = $currDir->children();
    
    for my $pubType ( @pubTypeList )
    {
        $self->WriteLog( "ParsePublicationTypeList - Tag: " . $pubType->tag() . ", UI: " . $pubType->att( 'UI' ) . ", Field: " . $pubType->field() );
        my @temp = ( $pubType->att( 'UI' ), $pubType->field() );
        push( @pubList, \@temp );
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetPublicationTypeList( @pubList );
}

sub ParseMedlineJournalInfo
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @medlineJournalList = $currDir->children();
    
    for my $medlineJournal ( @medlineJournalList )
    {
        $self->WriteLog( "ParseMedlineJournalInfo - Tag: " . $medlineJournal->tag() . ", Field: " . $medlineJournal->field() );
        
        # Store Field Data in respective PubEntry object member variables
        if( $medlineJournal->tag() eq "Country" )
        {
            $pubEntry->SetCountry( $medlineJournal->field() );
        }
        elsif( $medlineJournal->tag() eq "MedlineTA" )
        {
            $pubEntry->SetMedlineTA( $medlineJournal->field() );
        }
        elsif( $medlineJournal->tag() eq "NlmUniqueID" )
        {
            $pubEntry->SetNlmUniqueID( $medlineJournal->field() );
        }
        elsif( $medlineJournal->tag() eq "ISSNLinking" )
        {
            $pubEntry->SetISSNLinking( $medlineJournal->field() );
        }
    }
}

sub ParseChemicalList
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @chemicalArray = ();
    my @chemicalList = $currDir->children();
    
    for my $chemical ( @chemicalList )
    {   
        my @tempChemical = ();
        
        my @chemicalInfoList = $chemical->children();
        
        for my $chemicalInfo ( @chemicalInfoList )
        {   
            if( $chemicalInfo->tag() eq "NameOfSubstance" )
            {
                $self->WriteLog( "ParseChemicalList - NameOfSubstanceUI : " . $chemicalInfo->att( 'UI' ) . ", Field: " . $chemicalInfo->field()  );
                push( @tempChemical, $chemicalInfo->att( 'UI' ) );
                push( @tempChemical, $chemicalInfo->field() );
            }
            else
            {
                $self->WriteLog( "ParseChemicalList - Tag: " . $chemicalInfo->tag() . ", Field: " . $chemicalInfo->field() );
                push( @tempChemical, $chemicalInfo->field() );
            }
        }
        
        push( @chemicalArray, \@tempChemical );
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    # Format: RegistryNumber, UI, NameOfSubstance
    $pubEntry->SetChemicalList( @chemicalArray );
}

sub ParseMeshHeading
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @meshArray = ();
    my @meshHeadingList = $currDir->children();
    
    for my $meshHeading ( @meshHeadingList )
    {
        my @meshData = ();
        my @meshInfoList = $meshHeading->children();
        
        for my $meshInfo ( @meshInfoList )
        {
            $self->WriteLog( "ParseMeshHeading - Tag: " . $meshInfo->tag() . ", Field: " . $meshInfo->field()
                             . ", MajorTopic= " . $meshInfo->att( 'MajorTopicYN' ) . ", UI: " . $meshInfo->att( 'UI' ) );
            push( @meshData, $meshInfo->tag() );
            push( @meshData, $meshInfo->field() );
            push( @meshData, $meshInfo->att( 'MajorTopicYN' ) );
            push( @meshData, $meshInfo->att( 'UI' ) );
        }
        
        push( @meshArray, \@meshData );
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    # Format: Tag (Descriptor/Qualifier Name, Actual Name, MajorTopic (Y/N), UI
    $pubEntry->SetMeshHeadingList( @meshArray );
}

sub ParsePubData
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @historyArray = ();
    my @articleIDArray = ();
    my @pubMedDataList = $currDir->children();
    
    for my $pubMedData ( @pubMedDataList )
    {
        if( $pubMedData->tag() eq "History" )
        {
            my @pubMedPubDateList = $pubMedData->children();
            
            for my $pubMedPubDate ( @pubMedPubDateList )
            {
                my @pubMedPubDateAry = ();
                
                if( $pubMedPubDate->tag() eq "PubMedPubDate" )
                {
                    $self->WriteLog( "ParsePubData - Tag: " . $pubMedPubDate->tag() . ",  PubStatus: " . $pubMedPubDate->att( 'PubStatus' ) );
                    push( @pubMedPubDateAry, $pubMedPubDate->att( 'PubStatus' ) );
                }
                
                my @dateList = $pubMedPubDate->children();
                
                for my $date ( @dateList )
                {
                    $self->WriteLog( "ParsePubData - Tag: " . $pubMedPubDate->tag() . ", Tag: " . $date->tag() . ", Field: " . $date->field() );
                    push( @pubMedPubDateAry, $date->field() );
                }
                
                push( @historyArray, \@pubMedPubDateAry );
            }
        }
        elsif( $pubMedData->tag() eq "ArticleIdList" )
        {
            my @articleIdList = $pubMedData->children();
            
            for my $articleID ( @articleIdList )
            {
                $self->WriteLog( "ParsePubData - Tag: " . $articleID->tag() . ", IdType: " . $articleID->att( 'IdType' ) . ", Field: " . $articleID->field() );
                my @arID = ( $articleID->att( 'IdType' ), $articleID->field() );
                push( @articleIDArray, \@arID );
            }
        }
        else
        {
            $self->WriteLog( "ParsePubData - Tag: " . $pubMedData->tag() . ", Field: " . $pubMedData->field() );
            
            if( $pubMedData->tag() eq "PublicationStatus" )
            {
                $pubEntry->SetPublicationStatus( $pubMedData->field() );
            }
        }
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of array references)
    # Format: PubStatus, Year, Month, Day, Hour, Minute
    $pubEntry->SetHistory( @historyArray );
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    # Format: IdType (string), ID (int)
    $pubEntry->SetArticleIDList( @articleIDArray );
}

sub ParsePublisher
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @pubList = ();
    my @publishers = $currDir->children();
    
    for my $publisher ( @publishers )
    {
        $self->WriteLog( "ParsePublisher - Tag: " . $publisher->tag() .  ", Field: " . $publisher->field() );
        
        if( $publisher->tag() eq "PublisherName" )
        {
            my @temp = ( $publisher->tag(), $publisher->field() );
            push( @pubList, \@temp );
        }
        elsif( $publisher->tag() eq "PublisherLocation" )
        {
            my @temp = ( $publisher->tag(), $publisher->field() );
            push( @pubList, \@temp );
        }
    }
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetPublisherList( @pubList );
}

sub ParseBookTitle
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    $self->WriteLog( "ParseBookTitle - Tag: " . $currDir->tag() . ", Book: " . $currDir->att( 'book' ) .  ", Field: " . $currDir->field() );
        
    my @bookTitle = ( $currDir->field(), $currDir->att( 'book' ) );
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetBookTitle( @bookTitle );
}

sub ParsePubDate
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    my @pubList = ();
    my @date = $currDir->children();
    
    for my $date ( @date )
    {
        $self->WriteLog( "ParsePubDate - Tag: " . $date->tag() .  ", Field: " . $date->field() );
        
        if( $date->tag() eq "Year" )
        {
            $pubEntry->SetJournalPubYear( $date->field() );
        }
    }
}

sub ParseCollectionTitle
{
    my ( $self ) = shift;
    my $pubEntry = shift;
    my $currDir = shift;
    
    $self->WriteLog( "ParseCollectionTitle - Tag: " . $currDir->tag() . ", Book: " . $currDir->att( 'book' ) .  ", Field: " . $currDir->field() );
    
    my @collectionTitle = ( $currDir->field(), $currDir->att( 'book' ) );
    
    # Store Field Data in respective PubEntry object member variables
    # (Stored in array of arrays)
    $pubEntry->SetCollectionTitle( @collectionTitle );
}

sub ResetParsedCount
{
    my ( $self ) = @_;
    $self->{ _parsedCount } = 0;
}


sub ClearDataArray
{
    my ( $self ) = @_;
    @{ $self->{ _pubEntryList } } = ();
}

sub ClearData
{
    my ( $self ) = @_;
    $self->SetXMLParseString( "" );
    $self->ResetParsedCount();
    $self->ClearDataArray();
}



######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined( $self->{ _debugLog } );
    return $self->{ _debugLog };
}

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined( $self->{ _writeLog } );
    return $self->{ _writeLog };
}

sub GetParsedCount
{
    my ( $self ) = @_;
    $self->{ _parsedCount } = 0 if !defined( $self->{ _parsedCount } );
    return $self->{ _parsedCount };
}

sub GetPubEntryList
{
    my ( $self ) = @_;
    @{ $self->{ _pubEntryList } } = () if ( @{ $self->{ _pubEntryList } } eq 0 );
    return @{ $self->{ _pubEntryList } };
}

sub GetPubEntryListSize
{
    my ( $self ) = @_;
    my $size = $self->GetPubEntryList();
    $size = 0 if !defined ( $size );
    return $size;
}

sub GetTwigHandler
{
    my ( $self ) = @_;
    $self->{ _twigHandler } = "(null)" if !defined $self->{ _twigHandler };
    return $self->{ _twigHandler };
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = "(null)" if !defined $self->{ _fileHandle };
    return $self->{ _fileHandle };
}



######################################################################################
#    Mutators
######################################################################################

sub SetXMLParseString
{
    my ( $self, $temp ) = @_;
    return $self->{ _xmlStringToParse } = $temp if defined ( $temp );
}

sub SetPubEntryList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _pubEntryList } } = @temp;
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
    my ( $self ) = shift;
    my $string = shift;
    my $printNewLine = shift;
    
    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );
    
        
    if( $self->GetDebugLog() )
    {
        if( ref ( $string ) eq "PubMedXMLParser" )
        {
            print( GetDate() . " " . GetTime() . " - PubMedXMLParser: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - PubMedXMLParser::$string";
        print "\n" if( $printNewLine != 0 );
    }
    
    if( $self->GetWriteLog() )
    {
        if( ref ( $string ) eq "PubMedXMLParser" )
        {
            print( GetDate() . " " . GetTime() . " - PubMedXMLParser: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        my $fileHandle = $self->GetFileHandle();
        
        if( $fileHandle ne "(null)" )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - PubMedXMLParser::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}



#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND PubMed XML Parse Module

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