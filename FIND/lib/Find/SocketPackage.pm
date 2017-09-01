#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/25/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - Client Socket Handler           #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description: Module housing Client Socket, DatabaseCom, EUtilities and          #
#                 PubMedXMLParser objects as well as advanced methods using those    #
#                 modules.                                                           #
#                                                                                    #
#                 Note: Originally intended house all commands that are now in the   #
#                 server. They will eventually be moved over to simplify the server. #
#                                                                                    #
######################################################################################





use strict;
use warnings;

# CPAN Dependencies
use utf8;
use Text::Unidecode;
use IO::Socket::INET;

# Local Dependencies
use Find::DatabaseCom;
use Find::EUtilities;
use Find::PubMedXMLParser;




package Find::SocketPackage;




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
    undef $self->{ _eUtil };
    undef $self->{ _databaseCom };
    undef $self->{ _pubMedXMLParser };
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog => shift,                     # Boolean (Binary): 0 = False, 1 = True
        _socket => shift,
        _eUtil => shift,
        _databaseCom => shift,
        _pubMedXMLParser => shift,
        _removeExistingEntries => shift,        # Boolean (Binary): 0 = False, 1 = True
    };
    
    # Set debug log variable to false if not defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    
    
    # eFetch Module Instantiation
    $self->{ _eUtil } = Find::EUtilities->new( 0, 1 );                        # No print debug log, Yes write log to file and no string argument to parse
    $self->{ _databaseCom } = Find::DatabaseCom->new( 0, 1 );                 # No print debug log, Yes write log to file and no string argument to parse
    $self->{ _pubMedXMLParser } = Find::PubMedXMLParser->new( 0, 1 );         # No print debug log, Yes write log to file and no string argument to parse
    
    # Setting Up MySQL Database
    $self->{ _databaseCom }->SetPlatform( "mysql" );
    $self->{ _databaseCom }->SetDatabaseName( "find" );
    $self->{ _databaseCom }->SetHost( "127.0.0.1" );
    $self->{ _databaseCom }->SetPort( "3306" );
    $self->{ _databaseCom }->SetUserID( "root" );
    $self->{ _databaseCom }->SetPassword( "password" );
    
    bless $self, $class;
    
    $self->WriteLog( "New: Debug On" );
    
    return $self;
}


######################################################################################
#    Module Functions
######################################################################################

sub GetAllElementData
{
    my ( $self ) = shift;
    my $index = shift;
    
    my @pubEntryList = $self->GetPubMedXMLParser()->GetPubEntryList();
    
    # PMID
    my $pmid = $pubEntryList[$index]->GetPMID() if defined ( $pubEntryList[$index] );
    
    # Date Created
    my @dateCreated = $pubEntryList[$index]->GetDateCreated() if defined ( $pubEntryList[$index] );
    my $dateCreatedString = join( '-', @dateCreated );
    
    # Date Completed
    my @dateCompleted = $pubEntryList[$index]->GetDateCompleted() if defined ( $pubEntryList[$index] );
    my $dateCompletedString = join( '-', @dateCompleted );
    
    # Publish Year
    my $publishYear = $pubEntryList[$index]->GetJournalPubYear() if defined( $pubEntryList[$index] );
    
    # Author List
    my $authorStr = "";
    
    if( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "BookArticle" )
    {
        my @publisherList = $pubEntryList[$index]->GetPublisherList();
        my @publisherNameAry = @{ $publisherList[0] };
        $authorStr = ( "LastName<:>" . $publisherNameAry[1] . "<en>" );
    }
    elsif( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "JournalArticle" )
    {
        my @authorList = $pubEntryList[$index]->GetAuthorList();
    
        for my $authorRef ( @authorList )
        {
            my @author = @{ $authorRef };
            
            for( my $i = 0; $i < @author; $i++ )
            {
                $authorStr .= ( "LastName<:>" . $author[$i] . "<sp>" ) if ( $i == 0 );
                $authorStr .= ( "FirstName<:>" . $author[$i] . "<sp>" ) if ( $i == 1 );
                $authorStr .= ( "Initials<:>" . $author[$i] . "<sp>" ) if ( $i == 2 );
                $authorStr .= ( "Affiliation<:>" . $author[$i] ) if ( $i == 3 );
            }
            
            $authorStr .= "<en>" if( $authorRef ne $authorList[-1] );
        }
    }
    
    # Pub Model
    my $pubModel = $pubEntryList[$index]->GetPubModel() if defined ( $pubEntryList[$index] );
    
    # Journal ISSN
    my $journalISSN = $pubEntryList[$index]->GetJournalISSN() if defined ( $pubEntryList[$index] );
    
    # Journal ISSN Type
    my $journalISSNType = $pubEntryList[$index]->GetJournalISSNType() if defined ( $pubEntryList[$index] );
    
    # Journal Volume
    my $journalVolume = $pubEntryList[$index]->GetJournalVolume() if defined ( $pubEntryList[$index] );
    
    # Journal Cited Medium
    my $journalCitedMedium = $pubEntryList[$index]->GetJournalCitedMedium() if defined ( $pubEntryList[$index] );
    
    # Journal Issue
    my $journalIssue = $pubEntryList[$index]->GetJournalIssue() if defined ( $pubEntryList[$index] );
    
    # Journal Pub Date
    my @dateArray = $pubEntryList[$index]->GetJournalPubDate() if defined ( $pubEntryList[$index] );
    my $dateStr = join( '-', @dateArray );
    
    # Journal Title
    my $journalTitle = "";
    
    if( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "BookArticle" )
    {
        my @bookTitleAry = $pubEntryList[$index]->GetBookTitle();
        $journalTitle = $bookTitleAry[0] if ( @bookTitleAry > 0 );
        $journalTitle = $pubEntryList[$index]->GetJournalTitle() if ( $journalTitle eq "" );
        @bookTitleAry = ();
    }
    elsif( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "JournalArticle" )
    {
        $journalTitle = $pubEntryList[$index]->GetJournalTitle();
    }
    
    # Journal ISO Abbrev
    my $journalISOAbbrev = $pubEntryList[$index]->GetJournalISOAbbrev() if defined ( $pubEntryList[$index] );
    
    # Article Title
    my $articleTitle = "";
    
    if( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "BookArticle" )
    {
        my @articleTitleAry = $pubEntryList[$index]->GetCollectionTitle();
        $articleTitle = $articleTitleAry[0] if ( @articleTitleAry > 0 );
        $articleTitle = $pubEntryList[$index]->GetArticleTitle() if ( $articleTitle eq "" );
    }
    elsif( defined ( $pubEntryList[$index] ) && $pubEntryList[$index]->GetEntryType() eq "JournalArticle" )
    {
        $articleTitle = $pubEntryList[$index]->GetArticleTitle();
    }
    
    # Pagination
    my $pagStr = "";
    my @pagAryOfRef = $pubEntryList[$index]->GetPagination() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @pagAryOfRef )
    {
        my @pagination = @{ $aryRef };
        $pagStr .= join( '<:>', @pagination );
        $pagStr .= "<en>" if( $aryRef ne $pagAryOfRef[-1] );
    }
    
    # Abstract
    my $abstractStr = "";
    my @abstractAryOfRef = $pubEntryList[$index]->GetAbstractList() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @abstractAryOfRef )
    {
        my @abstract = @{ $aryRef };
        $abstractStr .= join( '<:>', @abstract );
        $abstractStr .= "<en>" if( $aryRef ne $abstractAryOfRef[-1] );
    }
    
    # Language
    my $language = $pubEntryList[$index]->GetLanguage() if defined ( $pubEntryList[$index] );
    
    # Publication Type
    my $pubTypeStr = "";
    my @pubTypeAryOfRef = $pubEntryList[$index]->GetPublicationTypeList() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @pubTypeAryOfRef )
    {
        my @pubType = @{ $aryRef };
        
        for( my $i = 0; $i < @pubType; $i++ )
        {
            if( @pubType == 3 )
            {
                $pubTypeStr .= ( "Category<:>" . $pubType[$i] . "<sp>" ) if( $i == 0 );
                $pubTypeStr .= ( "UI<:>" . $pubType[$i] . "<sp>" ) if( $i == 1 );
                $pubTypeStr .= ( "Field<:>" . $pubType[$i] ) if( $i == 2 );
            }
            elsif( @pubType == 2 )
            {
                $pubTypeStr .= ( "Category<:>" . $pubType[$i] . "<sp>" ) if( $i == 0 );
                $pubTypeStr .= ( "Field<:>" . $pubType[$i] ) if( $i == 1 );
            }
        }
        
        $pubTypeStr .= "<en>" if ( $aryRef ne $pubTypeAryOfRef[-1] );
    }
    
    # Country
    my $country = $pubEntryList[$index]->GetCountry() if defined ( $pubEntryList[$index] );
    
    # MedlineTA
    my $medlineTA = $pubEntryList[$index]->GetMedlineTA() if defined ( $pubEntryList[$index] );
    
    # Nlm Unique ID
    my $nlmUniqueID = $pubEntryList[$index]->GetNlmUniqueID() if defined ( $pubEntryList[$index] );
    
    # ISSN Linking
    my $issnLinking = $pubEntryList[$index]->GetISSNLinking() if defined ( $pubEntryList[$index] );
    
    # Chemical List
    my $chemListStr = "";
    my @chemAryOfRef = $pubEntryList[$index]->GetChemicalList() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @chemAryOfRef )
    {
        my @chemical = @{ $aryRef };
        
        for( my $i = 0; $i < @chemical; $i++ )
        {
            $chemListStr .= ( "RegistryNum<:>" . $chemical[$i] . "<sp>" ) if( $i == 0 );
            $chemListStr .= ( "UI<:>" . $chemical[$i] . "<sp>" ) if( $i == 1 );
            $chemListStr .= ( "NameOfSubstance<:>" . $chemical[$i] ) if( $i == 2 );
        }
        
        $chemListStr .= "<en>" if ( $aryRef ne $chemAryOfRef[-1] );
    }
    
    # Citation Subset
    my $citationSubset = $pubEntryList[$index]->GetCitationSubset() if defined ( $pubEntryList[$index] );
    
    # Mesh List
    my $meshHeadingStr = "";
    my @meshHeadAryOfRef = $pubEntryList[$index]->GetMeshHeadingList() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @meshHeadAryOfRef )
    {
        my @meshHeading = @{ $aryRef };
        
        for( my $i = 0; $i < @meshHeading; $i++ )
        {
            $meshHeadingStr .= ( "Tag<:>" . $meshHeading[$i] . "<sp>" ) if( $i == 0 );
            $meshHeadingStr .= ( "Field<:>" . $meshHeading[$i] . "<sp>" ) if( $i == 1 );
            $meshHeadingStr .= ( "MajorTopic<:>" . $meshHeading[$i] . "<sp>" ) if( $i == 2 );
            $meshHeadingStr .= ( "UI<:>" . $meshHeading[$i] ) if( $i == 3 );
        }
        
        $meshHeadingStr .= "<en>" if ( $aryRef ne $meshHeadAryOfRef[-1] );
    }
    
    # History
    my $historyStr = "";
    my @historyAryOfRef = $pubEntryList[$index]->GetHistory() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @historyAryOfRef )
    {
        my @history = @{ $aryRef };
        
        for( my $i = 0; $i < @history; $i++ )
        {
            $historyStr .= ( "PubStatus<:>" . $history[$i] . "<sp>" ) if( $i == 0 );
            $historyStr .= ( "Year<:>" . $history[$i] . "<sp>" ) if( $i == 1 );
            $historyStr .= ( "Month<:>" . $history[$i] . "<sp>" ) if( $i == 2 );
            $historyStr .= ( "Day<:>" . $history[$i] . "<sp>" ) if( $i == 3 );
            $historyStr .= ( "Hour<:>" . $history[$i] . "<sp>" ) if( $i == 4 );
            $historyStr .= ( "Min<:>" . $history[$i] ) if( $i == 5 );
        }
        
        $historyStr .= "<en>" if ( $aryRef ne $historyAryOfRef[-1] );
    }
    
    # Publication Status
    my $publicationStatus = $pubEntryList[$index]->GetPublicationStatus() if defined ( $pubEntryList[$index] );
    
    # Article ID List
    my $articleIdStr = "";
    my @articleIDAryOfRef = $pubEntryList[$index]->GetArticleIDList() if defined ( $pubEntryList[$index] );
    
    for my $aryRef ( @articleIDAryOfRef )
    {
        my @articleID = @{ $aryRef };
        $articleIdStr .= join( '<:>', @articleID );
        $articleIdStr .= "<en>" if( $aryRef ne $articleIDAryOfRef[-1] );
    }
    
    # Article URL
    my $articleUrl = $pubEntryList[$index]->GetArticleURL() if defined ( $pubEntryList[$index] );
    
    
    ############################
    #   Concatenate All Data   #
    ############################
    
    my $dataStr = "";
    $dataStr .= "PMID<=>$pmid<nd>DateCreated<=>$dateCreatedString<nd>DateCompleted<=>$dateCompletedString<nd>PublishYear<=>$publishYear<nd>";
    $dataStr .= "AuthorList<=>$authorStr<nd>PubModel<=>$pubModel<nd>JournalISSN<=>$journalISSN<nd>JournalISSNType<=>$journalISSNType<nd>";
    $dataStr .= "JournalVolume<=>$journalVolume<nd>JournalCitedVolume<=>$journalCitedMedium<nd>JournalIssue<=>$journalIssue<nd>";
    $dataStr .= "JournalPubDate<=>$dateStr<nd>JournalTitle<=>$journalTitle<nd>JournalISOAbbrev<=>$journalISOAbbrev<nd>";
    $dataStr .= "ArticleTitle<=>$articleTitle<nd>Pagination<=>$pagStr<nd>Abstract<=>$abstractStr<nd>Language<=>$language<nd>";
    $dataStr .= "PublicationTypeList<=>$pubTypeStr<nd>Country<=>$country<nd>MedlineTA<=>$medlineTA<nd>NlmUniqueID<=>$nlmUniqueID<nd>";
    $dataStr .= "ISSNLinking<=>$issnLinking<nd>ChemicalList<=>$chemListStr<nd>CitationSubset<=>$citationSubset<nd>";
    $dataStr .= "MeshHeadingList<=>$meshHeadingStr<nd>History<=>$historyStr<nd>";
    $dataStr .= "PublicationStatus<=>$publicationStatus<nd>ArticleIDList<=>$articleIdStr<nd>ArticleURL<=>$articleUrl<nd>";
    
    # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
    $dataStr = Text::Unidecode::unidecode( $dataStr );
    
    return $dataStr;
}

# TODO: Complete Database Store Entry Function
sub StoreEntriesIntoDatabase
{
    my ( $self, $pubEntryAryRef ) = @_;
    
    return if( !defined( $pubEntryAryRef ) || !defined( $self->GetDatabaseCom() ) || !defined( $self->GetPubMedXMLParser() ) );
    
    my $eUtil = $self->GetEUtilities();
    my $dCom = $self->GetDatabaseCom();
    my $xmlParser = $self->GetPubMedXMLParser();
    
    my @pubEntryAry = @{ $pubEntryAryRef };
    
    # Insertion Data Arrays
    my @dataName = ();
    my @data = ();
    
    
    for my $pubEntry ( @pubEntryAry )
    {
        my $pmid = $pubEntry->GetPMID();
        my @authorList = $pubEntry->GetAuthorList();
        
        # AuthorID Not Generated Correctly
        my $authorID = int( rand( 999999999 ) );              # TODO: Fix AuthorID Generation - NOTE: Not The Correct Way To Do This!!!!!!!
        
        # Insert Publication Data Into "publications" Table
        
        my $articleTitle = "";
        
        if( $pubEntry->GetEntryType() eq "BookArticle" )
        {
            my @collectionTitle = $pubEntry->GetCollectionTitle();
            $articleTitle = $collectionTitle[0];
            $articleTitle = $pubEntry->GetArticleTitle() if ( !defined( $articleTitle ) || $articleTitle eq "" );
        }
        elsif( $pubEntry->GetEntryType() eq "JournalArticle" )
        {
            $articleTitle = $pubEntry->GetArticleTitle();
        }
        
        my $pubYear = $pubEntry->GetJournalPubYear();
        
        my $pubQuery = $eUtil->GetSimplifiedLastQuery();
        @dataName = ( 'PublicationID', 'PublicationTitle', 'PublicationQuery', 'PublicationYear' ) ;
        @data = ( "$pmid", "$articleTitle", "$pubQuery", "$pubYear-0-0" );
        $dCom->InsertDataIntoTable( "publications", \@dataName, \@data );
        
        # Insert AuthorList Data Into "authors" Table
        if( $pubEntry->GetEntryType() eq "BookArticle" )
        {
            my @publisherList = $pubEntry->GetPublisherList();
            my @publisherNameAry = @{ $publisherList[0] };
            my $authorLastName = $publisherNameAry[1];
            
             # Insert Data Into "authors" Table
            @dataName = ( 'AuthorID', 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
            @data = ( "$authorID", "$authorLastName", "", "", "" );
            $dCom->InsertDataIntoTable( "authors", \@dataName, \@data );
            
            # Insert Author Data Into "publicationauthors" Table
            @dataName = ( "AuthorID" );
            my @columnName = ( 'AuthorsLastName', 'AuthorsFirstName', 'AffiliationName' );
            my @columnData = ( "$authorLastName", "", "" );
            my @authorIDAryRef = $dCom->SelectDataInTable( "authors", \@dataName, \@columnName, \@columnData );
            @dataName = ( 'PublicationID', 'AuthorID' );
            @data = ( "$pmid", "$authorID" );
            $dCom->InsertDataIntoTable( "publicationauthors", \@dataName, \@data );
        }
        elsif( $pubEntry->GetEntryType() eq "JournalArticle" )
        {
            for my $authorRef ( @authorList )
            {
                my @author = @{ $authorRef };
                
                # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
                my $authorLastName = Text::Unidecode::unidecode( $author[0] );
                my $authorFirstName = Text::Unidecode::unidecode( $author[1] );
                my $authorMiddleInit = Text::Unidecode::unidecode( $author[2] );
                my $authorAffiliation = Text::Unidecode::unidecode( $author[3] );
                
                # Check(s)
                $authorLastName = "" if !defined ( $authorLastName );
                $authorFirstName = "" if !defined ( $authorFirstName );
                $authorMiddleInit = "" if !defined ( $authorMiddleInit );
                $authorAffiliation = "" if !defined ( $authorAffiliation );
                
                # Clear Insertion Data Arrays
                @dataName =();
                @data = ();
                
                if( @author >= 4 )
                {
                    # Insert Data Into "authors" Table
                    @dataName = ( 'AuthorID', 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
                    @data = ( "$authorID", "$authorLastName", "$authorFirstName", "", "$authorAffiliation" );
                    $dCom->InsertDataIntoTable( "authors", \@dataName, \@data );
                }
                elsif( @author == 3 || @author == 2 )
                {
                    # Insert Data Into "authors" Table
                    @dataName = ( 'AuthorID', 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
                    @data = ( "$authorID", "$authorLastName", "$authorFirstName", "", "" );
                    $dCom->InsertDataIntoTable( "authors", \@dataName, \@data );
                }
                elsif( @author == 1 )
                {
                    # Insert Data Into "authors" Table
                    @dataName = ( 'AuthorID', 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
                    @data = ( "$authorID", "$authorLastName", "", "", "" );
                    $dCom->InsertDataIntoTable( "authors", \@dataName, \@data );
                }
                
                # Insert Author Data Into "publicationauthors" Table
                @dataName = ( "AuthorID" );
                my @columnName = ( 'AuthorsLastName', 'AuthorsFirstName', 'AffiliationName' );
                my @columnData = ( "$authorLastName", "$authorFirstName", "$authorAffiliation" );
                my @authorIDAryRef = $dCom->SelectDataInTable( "authors", \@dataName, \@columnName, \@columnData );
                @dataName = ( 'PublicationID', 'AuthorID' );
                @data = ( "$pmid", "$authorID" );
                $dCom->InsertDataIntoTable( "publicationauthors", \@dataName, \@data );
                
                $authorID += int( rand( 999 ) ) + 1;              # TODO: Fix AuthorID Generation - NOTE: Not The Correct Way To Do This!!!!!!!
            }
        }
        
        # Insert Data Into "publishers" Table
        my $country = $pubEntry->GetCountry();
        @dataName = ( 'PublisherID', 'PublisherName', 'PublisherLocation' ) ;
        @data = ( "$pmid", "", "$country" );
        $dCom->InsertDataIntoTable( "publishers", \@dataName, \@data );
        
        # Data Insert Variables (Book/Journal Articles)
        my $title = "";
        my $publishYear = join( '=', $pubEntry->GetJournalPubYear() ) if defined ( $pubEntry );
        my $url = $pubEntry->GetArticleURL();
        my $pages = $pubEntry->GetPagination();
        my $language = $pubEntry->GetLanguage();
        my @abstractAryOfRef = $pubEntry->GetAbstractList();
        
        # Insert Data Into "books" Table
        if( $pubEntry->GetEntryType() eq "BookArticle" )
        {
            my @bookTitle = $pubEntry->GetBookTitle();
            $title = $bookTitle[0];
            $title = $pubEntry->GetJournalTitle() if ( !defined( $title ) || $title eq "" );
        }
        elsif( $pubEntry->GetEntryType() eq "JournalArticle" )
        {
            $title = $pubEntry->GetJournalTitle();
        }
        
        my $abstractStr = "";
        
        for my $aryRef ( @abstractAryOfRef )
        {
            my @abstract = @{ $aryRef };
            $abstractStr .= join( '<:>', @abstract );
            $abstractStr .= "<en>" if( $aryRef ne $abstractAryOfRef[-1] );
        }
        
        # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
        $abstractStr = Text::Unidecode::unidecode( $abstractStr );
        
        @dataName =( 'BookID', 'BookTitle', 'PublishedYear', 'AuthorList', 'ISBN', 'PublisherID', 'Pages', 'Language', 'Abstract', 'Keywords', 'SourceURL' );
        @data = ( "$pmid", "$title", "$publishYear-0-0", "-1", "-2", "$pmid", "$pages", "$language", "$abstractStr", "(null)", "$url" );
        $dCom->InsertDataIntoTable( "books", \@dataName, \@data );
        
        # TODO: Continue Storing Data In Database Development
        # Insert Data Into "bookarticles" Table
        # @dataName =( 'BookArticleID', 'BookArticleTitle', 'PublishedYear', 'AuthorList', 'ISBN', 'PublisherID', 'Pages', 'Language', 'ArticleType', 'Abstarct', 'Keywords', 'SourceURL', 'BookID' );    # "Abstract" Spelled Incorrectly In Database
        # @data = ( "$pmid", "$title" );
        # $dCom->InsertDataIntoTable( "bookarticles", \@dataName, \@data );
    }
    
    return "Stored Data In Database";
}

# TODO: Complete Database Delete Entry Function
sub DeleteEntryFromDatabase
{
    my ( $self, $pmid ) = @_;
    
    return if( !defined( $pmid ) || !defined( $self->GetDatabaseCom() ) );
    
    my $dCom = $self->GetDatabaseCom();
    
    # Insertion Data Arrays
    my @dataName = ();
    my @data = ();
    
    # Delete Data From "books" Table By "PMID/BookID"
    @dataName = ( 'BookID' );
    @data = ( "$pmid" );
    $dCom->DeleteDataFromTable( "books", \@dataName, \@data );
    
    # Delete Data From "publishers" Table By "PMID/PublisherID"
    @dataName = ( 'PublisherID' );
    @data = ( "$pmid" );
    $dCom->DeleteDataFromTable( "publishers", \@dataName, \@data );
    
    # Delete Data From "publicationauthors" Table By "PMID/PublicationID"
    my @columnName = ( 'AuthorID' );
    @dataName = ( 'PublicationID' );
    @data = ( "$pmid" );
    my @authorIDAry = $dCom->SelectDataInTable( "publicationauthors", \@columnName, \@dataName, \@data );
    
    for my $authorID ( @authorIDAry )
    {
        # Delete Data From "publicationauthors" Table
        @dataName = ( 'AuthorID' );
        @data = ( "@{$authorID}" );
        $dCom->DeleteDataFromTable( "publicationauthors", \@dataName, \@data );
    }
    
    # Delete Data From "authors" Table By "AuthorID"
    for my $authorID ( @authorIDAry )
    {
        # Delete Data From "authors" Table
        @dataName = ( 'AuthorID' );
        @data = ( "@{$authorID}" );
        $dCom->DeleteDataFromTable( "authors", \@dataName, \@data );
    }
    
    # Delete Data From "publications" Table By "PMID/PublicationID"
    @dataName = ( 'PublicationID' );
    @data = ( "$pmid" );
    $dCom->DeleteDataFromTable( "publications", \@dataName, \@data );
    
    # Clean-Up
    @dataName = ();
    @data = ();
    @columnName = ();
    @authorIDAry = ();
    undef @dataName;
    undef @data;
    undef @columnName;
    undef @authorIDAry;
}

sub RetrieveDatabaseEntriesByIndex
{
    my ( $self, $startIndex, $finalIndex ) = @_;
    
    return if ( !defined( $startIndex ) || !defined( $finalIndex ) || !defined( $self->GetDatabaseCom() ) );
    
    my $dCom = $self->GetDatabaseCom();
    my @pmidArray = ();
    
    my @dataName = ( 'PublicationID', 'PublicationTitle' );
    my @data = ( "" );
    my @pmidAryRef = $dCom->SelectAllDataInTable( "publications", \@dataName );
    
    # Error Checking
    $finalIndex = @pmidAryRef - $startIndex if( $startIndex + $finalIndex > @pmidAryRef );
    
    for( my $i = $startIndex; $i < @pmidAryRef; $i++ )
    {
        my $aryRef = $pmidAryRef[$i];
        my @ary = @$aryRef;
        
        # Check(s)
        next if @ary < 2;
        
        my $pmid = $ary[0];
        push( @pmidArray, $pmid );
        
        last if ( $i > $startIndex + $finalIndex );
    }
    
    return "RetMax<=>0<nd>" if @pmidArray eq 0;
    return "RetMax<=>$finalIndex<nd>" . $self->RetrieveDatabaseEntriesByPMID( \@pmidArray );
}

sub RetrieveDatabaseEntriesByQuery
{
    my ( $self, $query, $searchBy, $searchType, $startYear, $endYear, $startIndex, $numOfResults ) = @_;
    
    return if ( !defined( $query ) || !defined( $searchBy ) || !defined( $searchType ) || !defined( $startYear ) || !defined( $endYear )
                || !defined( $startIndex ) || !defined( $numOfResults ) || !defined( $self->GetDatabaseCom() ) );
    
    my $dCom = $self->GetDatabaseCom();
    my @queryArray = split( '\+', $query );
    
    if( defined( $searchType ) && $searchType eq "exact" )
    {
        $query =~ s/\+/ /g;          # Replace "+" With A " " In Query If Exact Search
        @queryArray = ( $query );    # Set @queryArray to $query for exact search
    }
    
    my @pmidArray = ();
    
    my @dataName = ( 'PublicationID', 'PublicationTitle', 'PublicationQuery' );
    my @data = ( "" );
    my @pmidAryRef = $dCom->SelectAllDataInTable( "publications", \@dataName );
    
    # Check $startIndex For Redundancy
    $startIndex = @pmidAryRef if ( $startIndex >= @pmidAryRef );
    $startIndex = 0 if $startIndex < 0;
    
    # Check To See If $startIndex + $numOfResults > @pmidAryRef
    $numOfResults = @pmidAryRef - $startIndex if ( $startIndex + $numOfResults > @pmidAryRef );
    
    my $numFound = 0;                   # Total Entries Found By Search Query
    
    # Search Database Entries For Containing $queryStr - TODO: Needs More Testing
    for( my $i = $startIndex; $i < @pmidAryRef; $i++ )
    {
        for my $queryStr ( @queryArray )
        {
            my $found = 0;
            my $aryRef = $pmidAryRef[$i];
            my @ary = @$aryRef;
            
            # Check(s)
            return "(null)" if @ary < 3;
            
            my $pmid = $ary[0];
            my $articleTitle = $ary[1];
            my $pubQuery = $ary[2];
            
            
            # Get Data From "books" Table ( Title, Abstract and URL )
            my @columnName = ( 'BookTitle', 'PublishedYear', 'Abstract', 'SourceURL' );
            @dataName = ( 'BookID' );       # PMID
            @data = ( "$pmid" );
            my @bookAryRef = $dCom->SelectDataInTable( "books", \@columnName, \@dataName, \@data );
            
            my $journalTitle = "";
            my $publishedYear = "";
            my $abstract = "";
            my $url = "";
            
            for my $aryRef ( @bookAryRef )
            {
                my @bookAry = @$aryRef;
                return "(null)" if @bookAry < 3;
                
                $journalTitle = $bookAry[0];
                my $date = $bookAry[1];
                $date = substr( $date, 0, 4 );
                $publishedYear = $date;
                $abstract = $bookAry[2];
                $url = $bookAry[3];
            }
            
            # Search "title" For $queryStr
            if( StringContains( $searchBy, "title" ) == 1 || StringContains( $searchBy, "all" ) == 1 )
            {
                if( StringContains( $articleTitle, $queryStr ) == 1 || StringContains( $journalTitle, $queryStr ) == 1 )
                {
                    $found = 1 if ( $publishedYear == 0 || ( $publishedYear <= $startYear && $publishedYear >= $endYear ) );
                }
                # Proceed To Next Loop Iteration If Query Not Found When Searching "Title"
                elsif( StringContains( $articleTitle, $queryStr ) == 0 && StringContains( $journalTitle, $queryStr ) == 0
                    && StringContains( $searchBy, "title" ) == 1 )
                {
                    next;
                }
            }
            
            # Search "abstract" For $queryStr
            if( StringContains( $searchBy, "abstract" ) == 1 || StringContains( $searchBy, "all" ) == 1 )
            {
                if( StringContains( $abstract, $queryStr ) == 1 )
                {
                    $found = 1 if ( $publishedYear == 0 || ( $publishedYear <= $startYear && $publishedYear >= $endYear ) );
                }
                # Proceed To Next Loop Iteration If Query Not Found When Searching "Abstract"
                elsif( StringContains( $abstract, $queryStr ) == 0 && StringContains( $searchBy, "abstract" ) == 1 )
                {
                    next;
                }
            }
            
            
            # Get Data From "publicationauthors" Table ( AuthorIDs )
            @columnName = ( 'AuthorID' );
            @dataName = ( 'PublicationID' );
            @data = ( "$pmid" );
            my @pubAuthorAryRef = $dCom->SelectDataInTable( "publicationauthors", \@columnName, \@dataName, \@data );
            
            my $authorList = "";
            
            for my $aryRef ( @pubAuthorAryRef )
            {
                my @authorIDAry = @$aryRef;
                return "(null)" if @authorIDAry < 1;
                
                my $authorID = $authorIDAry[0];
                
                # Get Data From "authors" Table Using "authorID" Field ( AuthorsLastName, AuthorsFirstName, AuthorsMiddleInit, AffiliationName )
                @columnName = ( 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
                @dataName = ( 'AuthorID' );
                @data = ( "$authorID" );
                my @authorAryRef = $dCom->SelectDataInTable( "authors", \@columnName, \@dataName, \@data );
                
                for my $arrayRef ( @authorAryRef )
                {
                    my @authorAry = @$arrayRef;
                    
                    return "(null)" if @authorAry < 4;
                    
                    for( my $i = 0; $i < @authorAry; $i++ )
                    {
                        $authorList .= ( $authorAry[0] . " " ) if ( $i == 0 );
                        $authorList .= ( $authorAry[1] . " " ) if ( $i == 1 );
                        $authorList .= ( $authorAry[2] . " " ) if ( $i == 2 );
                        $authorList .= ( $authorAry[3] . " " ) if ( $i == 3 );
                    }
                }
            }
            
            # Search "authorlist" For $queryStr
            if( StringContains( $searchBy, "author" ) == 1 || StringContains( $searchBy, "all" ) == 1 )
            {
                if( StringContains( $authorList, $queryStr ) == 1 )
                {
                    $found = 1 if ( $publishedYear == 0 || ( $publishedYear <= $startYear && $publishedYear >= $endYear ) );
                }
                # Proceed To Next Loop Iteration If Query Not Found When Searching "AuthorList"
                elsif( StringContains( $authorList, $queryStr ) == 0 && StringContains( $searchBy, "author" ) == 1 )
                {
                    next;
                }
            }

            # Search "PublicationQuery" Field
            if ( StringContains( $pubQuery, $queryStr ) == 1 && StringContains( $searchBy, "all" ) == 1 )
            {
                $found = 1 if ( $publishedYear == 0 || ( $publishedYear <= $startYear && $publishedYear >= $endYear ) );
            }
            
            # Proceed To Next Loop Iteration If Query Not Found When Searching "All Fields" Or "PublicationQuery" Field
            next if( StringContains( $pubQuery, $queryStr ) == 0 && StringContains( $searchBy, "all" ) == 1 && $found == 0 );
            
            # Push PMID To Array Only If Data Contains Searched Criteria Within Specified $startIndex and $numOfResults
            if ( $found == 1 && ( $startIndex + $numFound ) >= $startIndex && $numFound < ( $startIndex + $numOfResults ) )
            {
                # Push PMID If The Array Does Not Already Contain It
                push( @pmidArray, $pmid ) if ( !grep { $_ eq $pmid } @pmidArray );
            }
            
            # Increment $numFound Index Counter If Query Is Found
            $numFound++ if $found == 1;
        }
        
        # Exit Loop If The Number Found Exceeds The Specified Amount
        last if $numFound >= $numOfResults;
    }
    
    $numFound = @pmidArray;
    return "RetMax<=>$numFound<nd>" . $self->RetrieveDatabaseEntriesByPMID( \@pmidArray );
}

# TODO: Complete Database Entry Retrieval
sub RetrieveDatabaseEntriesByPMID
{
    my ( $self, $pmidAryRef ) = @_;
    
    return if ( !defined( $pmidAryRef ) || !defined( $self->GetDatabaseCom() ) );
    
    my $dCom = $self->GetDatabaseCom();
    my @retrievePmidAry = @{$pmidAryRef};
    
    my $pmidStr = "";
    my $journalTitleStr = "";
    my $publishYear = "";
    my $articleTitleStr = "";
    my $abstractStr = "";
    my $urlStr = "";
    my $authorListStr = "";
    my $foundCount = 0;
    
    my @dataName = ( 'PublicationID', 'PublicationTitle', 'PublicationQuery' );
    my @data = ( "" );
    my @pmidAryRef = $dCom->SelectAllDataInTable( "publications", \@dataName );
    
    for( my $i = 0; $i < @pmidAryRef; $i++ )
    {
        my $aryRef = $pmidAryRef[$i];
        my @ary = @$aryRef;
        
        # Check(s)
        return "(null)" if @ary < 3;
        
        my $pmid = $ary[0];
        my $articleTitle = $ary[1];
        my $pubQuery = $ary[2];
        
        
        # Check To See If Entry Needs To Be Retrieved
        my $foundPMID = 0;
        
        for my $retPMID ( @retrievePmidAry )
        {
            if( $retPMID eq $pmid )
            {
                $foundPMID = 1;
                last;
            }
        }
        
        # Go To Next PMID In The Database List If The PMID Is Not In The PMID Retrieval List
        next if $foundPMID eq 0;
        
        $foundCount++;
        
        $articleTitleStr .= "$articleTitle<en>";
        $pmidStr .= "$pmid<en>";
        
        # Get Data From "books" Table ( Title, Abstract and URL )
        my @columnName = ( 'BookTitle', 'PublishedYear', 'Abstract', 'SourceURL' );
        @dataName = ( 'BookID' );       # PMID
        @data = ( "$pmid" );
        my @bookAryRef = $dCom->SelectDataInTable( "books", \@columnName, \@dataName, \@data );
        
        for my $aryRef ( @bookAryRef )
        {
            my @bookAry = @$aryRef;
            return "(null)" if @bookAry < 3;
            
            # Concatenate Data
            $journalTitleStr .= "$bookAry[0]<en>";
            my $date = $bookAry[1];
            $date = substr( $date, 0, 4 );
            $publishYear .= "$date<en>";
            $abstractStr .= "$bookAry[2]<ls>";
            $urlStr .= "$bookAry[3]<en>";
        }
        
        # Get Data From "publicationauthors" Table ( AuthorIDs )
        @columnName = ( 'AuthorID' );
        @dataName = ( 'PublicationID' );
        @data = ( "$pmid" );
        my @pubAuthorAryRef = $dCom->SelectDataInTable( "publicationauthors", \@columnName, \@dataName, \@data );
        
        for my $aryRef ( @pubAuthorAryRef )
        {
            my @authorIDAry = @$aryRef;
            return "(null)" if @authorIDAry < 1;
            
            my $authorID = $authorIDAry[0];
            
            # Get Data From "authors" Table Using "authorID" Field ( AuthorsLastName, AuthorsFirstName, AuthorsMiddleInit, AffiliationName )
            @columnName = ( 'AuthorsLastName', 'AuthorsFirstName', 'AuthorsMiddleInit', 'AffiliationName' );
            @dataName = ( 'AuthorID' );
            @data = ( "$authorID" );
            my @authorAryRef = $dCom->SelectDataInTable( "authors", \@columnName, \@dataName, \@data );
            
            for my $arrayRef ( @authorAryRef )
            {
                my @authorAry = @$arrayRef;
                
                return "(null)" if @authorAry < 4;
                
                for( my $i = 0; $i < @authorAry; $i++ )
                {
                    $authorListStr .= ( "LastName<:>" . $authorAry[0] . "<sp>" ) if ( $i == 0 );
                    $authorListStr .= ( "FirstName<:>" . $authorAry[1] . "<sp>" ) if ( $i == 1 );
                    $authorListStr .= ( "MiddleInitials<:>" . $authorAry[2] . "<sp>" ) if ( $i == 2 );
                    $authorListStr .= ( "Affiliation<:>" . $authorAry[3] ) if ( $i == 3 );
                }
                
                $authorListStr .= "<en>";
            }
        }
        
        $authorListStr .= "<ls>";
    }
    
    return "(null)" if $foundCount eq 0;
    
    
    ############################
    #   Concatenate All Data   #
    ############################
    
    my $dataStr = "";
    $dataStr .= "PMID<=>$pmidStr<nd>AuthorList<=>$authorListStr<nd>JournalTitle<=>$journalTitleStr<nd>PublishYear<=>$publishYear<nd>";
    $dataStr .= "ArticleTitle<=>$articleTitleStr<nd>Abstract<=>$abstractStr<nd>ArticleURL<=>$urlStr<nd>";
    
    # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
    $dataStr = Text::Unidecode::unidecode( $dataStr );
    
    return $dataStr;
}

sub RemoveExistingDatabaseData
{
    my ( $self ) = @_;
    
    return if ( $self->GetRemoveExistingEntries() == 0 );
    
    return if( !defined( $self->GetDatabaseCom() ) || !defined( $self->GetPubMedXMLParser() ) );
    
    my $eUtil = $self->GetEUtilities();
    my $dCom = $self->GetDatabaseCom();
    my $xmlParser = $self->GetPubMedXMLParser();
    
    my $retMax = $eUtil->GetRetMax();
    my $retStart = $eUtil->GetRetStart();
    my $prevRetMax = $eUtil->GetPrevRetMax();
    
    my @parsedList = $xmlParser->GetPubEntryList();
    my $prevListTotal = @parsedList;
    
    my @dataName = ( 'PublicationID' );
    my @data = ( "" );
    my @pmidAryRef = ();
    
    
    # Remove All Existing Data From Parsed Results
    for( my $i = 0; $i < @parsedList; $i++ )
    {
        my $pubData = $parsedList[$i];
        my $pmid = $pubData->GetPMID();
        @data = ( "$pmid" );

        @pmidAryRef = $dCom->SelectDataInTable( "publications", \@dataName, \@dataName, \@data );
        
        # Remove The Existing Data Element From The Array
        splice( @parsedList, $i, 1 ) if( @pmidAryRef > 0 );
        $i-- if( @pmidAryRef > 0 );
    }
    
    my $numToFetch = $prevListTotal - @parsedList;
    
    $xmlParser->SetPubEntryList( @parsedList ) if ( $numToFetch eq 0 );
    
    # Exit Recursion If The List Contains No Existing Elements
    return if( $numToFetch eq 0 );
    
    # Safety Exit Check(s)
    my $count = $eUtil->GetESearchCount();
    $xmlParser->SetPubEntryList( @parsedList ) if ( $retStart + $retMax >= $count );
    return if ( $retStart + $retMax >= $count );
    
    
    my $query = $eUtil->GetLastQuery();
    
    # Clear Old Parsed Data
    $xmlParser->ClearData();
    
    $eUtil->ClearData();
    $eUtil->SetRetStart( $retStart + $retMax );
    $eUtil->SetPrevRetStart( $retStart );
    $eUtil->SetRetMax( $numToFetch );
    $eUtil->FetchQuery( $query );
    $eUtil->SetPrevRetMax( $prevRetMax );
    
    my @dataArray = $eUtil->GetEFetchDataArray();
    
    for my $data ( @dataArray )
    {
        $xmlParser->ParseXMLString( $data );
    }
    
    my @newData = $xmlParser->GetPubEntryList();
    
    # Add New Data Array To Old Array
    push( @parsedList, @newData );
    
    $xmlParser->SetPubEntryList( @parsedList );
    
    # Clear Data
    @parsedList = ();
    @dataArray = ();
    @newData = ();
    @pmidAryRef = ();
    
    # Repeat Sub-Routine Until Desired $retMax Is Achieved (Recursion)
    $self->RemoveExistingDatabaseData();
}

sub StringContains
{
    my $command = shift;
    my $subStr = shift;
    
    # Convert String To Lowercase
    $command = lc( $command );
    $subStr = lc( $subStr );
    
    return 1 if( index( $command, $subStr ) != -1 );
    
    return 0;
}


######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    return $self->{ _debugLog };
}

sub GetSocket
{
    my ( $self ) = @_;
    $self->{ _socket } = "(null)" if !defined ( $self->{ _socket } );
    return $self->{ _socket };
}

sub GetEUtilities
{
    my ( $self ) = @_;
    $self->{ _eUtil } = "(null)" if !defined ( $self->{ _eUtil } );
    return $self->{ _eUtil };
}

sub GetDatabaseCom
{
    my ( $self ) = @_;
    $self->{ _databaseCom } = "(null)" if !defined ( $self->{ _databaseCom } );
    return $self->{ _databaseCom };
}

sub GetPubMedXMLParser
{
    my ( $self ) = @_;
    $self->{ _pubMedXMLParser } = "(null)" if !defined ( $self->{ _pubMedXMLParser } );
    return $self->{ _pubMedXMLParser };
}

sub GetRemoveExistingEntries
{
    my ( $self ) = @_;
    $self->{ _removeExistingEntries } = 1 if !defined ( $self->{ _removeExistingEntries } );
    return $self->{ _removeExistingEntries };
}

######################################################################################
#    Mutators
######################################################################################

sub SetSocket
{
    my ( $self, $temp ) = @_;
    return $self->{ _socket } = $temp if defined ( $temp );
}

sub SetRemoveExistingEntries
{
    my ( $self, $temp ) = @_;
    return $self->{ _removeExistingEntries } = $temp if defined( $temp );
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
    
    if( $self->GetDebugLog() )
    {
        my $string = shift;
        my $printNewLine = shift;
        
        return if !defined ( $string );
        $printNewLine = 1 if !defined ( $printNewLine );
        
        if( ref ( $string ) eq "SocketPackage" )
        {
            print( GetDate() . " " . GetTime() . " - SocketPackage: Cannot Call WriteLog() From Outside Module!\n" );
            
        }
        else
        {
            $string = "" if !defined ( $string );
            print GetDate() . " " . GetTime() . " - SocketPackage::" . $string;
            print "\n" if( $printNewLine != 0 );
        }
    }
}


#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND Client Socket Handler Module

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