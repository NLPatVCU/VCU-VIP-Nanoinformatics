#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/25/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - Publication Entry Module        #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 This script module will be utilized by PubMedXMLParser to create   #
#                 and store PubEntry object with parsed PubMed repo XML data.        #
#                                                                                    #
######################################################################################





use strict;
use warnings;




package Find::PubEntry;




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
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog => shift,                         # Boolean (Binary): 0 = False, 1 = True
        _entryType => shift,                        # String (Journal Article, Book Article, Etc.)
        _pmid => shift,                             # Int
        _dateCreated => shift,                      # Array Format: Year/Month/Day - ( Array Reference When Passed As Argument )
        _dateCompleted => shift,                    # Array Format: Year/Month/Day - ( Array Reference When Passed As Argument )
        _pubModel => shift,                         # String
        _journalIssn => shift,                      # Int
        _journalIssnType => shift,                  # String
        _journalVolume => shift,                    # Int
        _journalCitedMedium => shift,               # String
        _journalIssue => shift,                     # Int
        _journalPubDate => shift,                   # Array Format: Year/Month - ( Array Reference When Passed As Argument )
        _journalPubYear => shift,                   # Int
        _journalTitle => shift,                     # String
        _journalIsoAbbrev => shift,                 # String
        _articleTitle => shift,                     # String
        _pagination => shift,                       # Array of @_medlinePgn arrays - ( Array Reference When Passed As Argument )
        _medlinePgn => shift,                       # Int
        _abstract => shift,                         # Array Format: (All Strings) Qbjective, Methods, Results, Conclusions - ( Array Reference When Passed As Argument )
        _authorList => shift,                       # Array of @_author arrays
        _author => shift,                           # Array Format: (All Strings) Last Name, Fore Name, Initials - ( Array Reference When Passed As Argument )
        _language => shift,                         # String
        _publicationTypeList => shift,              # Array of @_publicationType arrays - ( Array Reference When Passed As Argument )
        _publicationType => shift,                  # Array Format: "Int" UI, "String" Type - ( Array Reference When Passed As Argument )
        _country => shift,                          # String
        _medlineTA => shift,                        # String
        _nlmUniqueID => shift,                      # Int
        _issnLinking => shift,                      # Int
        _chemicalList => shift,                     # Array of @_chemical arrays - ( Array Reference When Passed As Argument )
        _chemical => shift,                         # Array Format: "Int" Registry Number, "String" Name Of Substance - ( Array Reference When Passed As Argument )
        _citationSubset => shift,                   # String
        _meshHeadingList => shift,                  # Array of @_meshHeading arrays - ( Array Reference When Passed As Argument )
        _meshHeading => shift,                      # Array Format: "String" Major Topic, "Int" UI, "String" Descriptor Name - ( Array Reference When Passed As Argument )
        _history => shift,                          # Array of @_pubMedPubDate arrays - ( Array Reference When Passed As Argument )
        _pubMedPubDate => shift,                    # Array Format: Year/Month/Day/Hour/Minute - ( Array Reference When Passed As Argument )
        _publicationStatus => shift,                # String
        _articleIdList => shift,                    # Array of @_articleId arrays - ( Array Reference When Passed As Argument )
        _articleId => shift,                        # Array Format: IDType "String", ID: Int - ( Array Reference When Passed As Argument )
        _articleURL => shift,                       # String
        _isbn => shift,                             # Int
        _publisher => shift,                        # Array of publisher arrays - Array Format: Name/Location - ( Array Reference When Passed As Argument )
        _bookTitle => shift,                        # Array Format: Title/BookAbbrev - ( Array Reference When Passed As Argument )
        _collectionTitle => shift,                  # Array Format: Title/BookAbbrev - ( Array Reference When Passed As Argument )
        _sectionList => shift,                      # Array of section arrays - Array Format: Title/Part/BookAbbrev or Type/Field - ( Array Reference When Passed As Argument )
    };
    
    # Set variables to default values
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _entryType } = "(null)" if !defined ( $self->{ _entryType } );
    $self->{ _pmid } = -1 if !defined ( $self->{ _pmid } );
    @{ $self->{ _dateCreated } } = @{ $self->{ _dateCreated } } if defined ( $self->{ _dateCreated } );
    @{ $self->{ _dateCreated } } = () if !defined ( $self->{ _dateCreated } );
    @{ $self->{ _dateCompleted } } = @{ $self->{ _dateCompleted } } if defined( $self->{ _dateCompleted } );
    @{ $self->{ _dateCompleted } } = () if !defined( $self->{ _dateCompleted } );
    $self->{ _pubModel } = "(null)" if !defined ( $self->{ _pubModel } );
    $self->{ _journalIssn } = -1 if !defined ( $self->{ _journalIssn } );
    $self->{ _journalIssnType } = "(null)" if !defined ( $self->{ _journalIssnType } );
    $self->{ _journalVolume } = -1 if !defined ( $self->{ _journalVolume } );
    $self->{ _journalCitedMedium } = "(null)" if !defined ( $self->{ _journalCitedMedium } );
    $self->{ _journalIssue } = -1 if !defined ( $self->{ _journalIssue } );
    @{ $self->{ _journalPubDate } } = @{ $self->{ _journalPubDate } } if defined( $self->{ _journalPubDate } );
    @{ $self->{ _journalPubDate } } = () if !defined( $self->{ _journalPubDate } );
    $self->{ _journalTitle } = "(null)" if !defined ( $self->{ _journalTitle } );
    $self->{ _journalIsoAbbrev } = "(null)" if !defined ( $self->{ _journalIsoAbbrev } );
    $self->{ _articleTitle } = "(null)" if !defined ( $self->{ _articleTitle } );
    @{ $self->{ _pagination } } = @{ $self->{ _pagination } } if defined ( $self->{ _pagination } );
    @{ $self->{ _pagination } } = () if !defined ( $self->{ _pagination } );
    $self->{ _medlinePgn } = -1 if !defined ( $self->{ _medlinePgn } );
    @{ $self->{ _abstract } } = @{ $self->{ _abstract } } if defined ( $self->{ _abstract } );
    @{ $self->{ _abstract } } = () if !defined ( $self->{ _abstract } );
    @{ $self->{ _authorList } } = @{ $self->{ _authorList } } if defined ( $self->{ _authorList } );
    @{ $self->{ _authorList } } = () if !defined ( $self->{ _authorList } );
    @{ $self->{ _author } } = @{ $self->{ _author } } if defined ( $self->{ _author } );
    @{ $self->{ _author } } = () if !defined ( $self->{ _author } );
    $self->{ _language } = "(null)" if !defined ( $self->{ _language } );
    @{ $self->{ _publicationTypeList } } = @{ $self->{ _publicationTypeList } } if defined ( $self->{ _publicationTypeList } );
    @{ $self->{ _publicationTypeList } } = () if !defined ( $self->{ _publicationTypeList } );
    @{ $self->{ _publicationType } } = @{ $self->{ _publicationType } } if defined ( $self->{ _publicationType } );
    @{ $self->{ _publicationType } } = () if !defined ( $self->{ _publicationType } );
    $self->{ _country } = "(null)" if !defined ( $self->{ _country } );
    $self->{ _medlineTA } = "(null)" if !defined ( $self->{ _medlineTA } );
    $self->{ _nlmUniqueID } = -1 if !defined ( $self->{ _nlmUniqueID } );
    $self->{ _issnLinking } = -1 if !defined ( $self->{ _issnLinking } );
    @{ $self->{ _chemicalList } } = @{ $self->{ _chemicalList } } if defined ( $self->{ _chemicalList } );
    @{ $self->{ _chemicalList } } = () if !defined ( $self->{ _chemicalList } );
    @{ $self->{ _chemical } } = @{ $self->{ _chemical } } if defined ( $self->{ _chemical } );
    @{ $self->{ _chemical } } = () if !defined ( $self->{ _chemical } );
    $self->{ _citationSubset } = "(null)" if !defined ( $self->{ _citationSubset } );
    @{ $self->{ _meshHeadingList } } = @{ $self->{ _meshHeadingList } } if defined ( $self->{ _meshHeadingList } );
    @{ $self->{ _meshHeadingList } } = () if !defined ( $self->{ _meshHeadingList } );
    @{ $self->{ _meshHeading } } = @{ $self->{ _meshHeading } } if defined ( $self->{ _meshHeading } );
    @{ $self->{ _meshHeading } } = () if !defined ( $self->{ _meshHeading } );
    @{ $self->{ _history } } = @{ $self->{ _history } } if defined ( $self->{ _history } );
    @{ $self->{ _history } } = () if !defined ( $self->{ _history } );
    @{ $self->{ _pubMedPubDate } } = @{ $self->{ _pubMedPubDate } } if defined ( $self->{ _pubMedPubDate } );
    @{ $self->{ _pubMedPubDate } } = () if !defined ( $self->{ _pubMedPubDate } );
    $self->{ _publicationStatus } = "(null)" if !defined ( $self->{ _publicationStatus } );
    @{ $self->{ _articleIdList } } = @{ $self->{ _articleIdList } } if defined ( $self->{ _articleIdList } );
    @{ $self->{ _articleIdList } } = () if !defined ( $self->{ _articleIdList } );
    @{ $self->{ _articleId } } = @{ $self->{ _articleId } } if defined ( $self->{ _articleId } );
    @{ $self->{ _articleId } } = () if !defined ( $self->{ _articleId } );
    $self->{ _articleURL } = "(null)" if !defined ( $self->{ _articleURL } );
    $self->{ _isbn } = -1 if !defined ( $self->{ _isbn } );
    @{ $self->{ _publisher } } = @{ $self->{ _publisher } } if defined ( $self->{ _publisher } );
    @{ $self->{ _publisher } } = () if !defined ( $self->{ _publisher } );
    @{ $self->{ _bookTitle } } = @{ $self->{ _bookTitle } } if defined ( $self->{ _bookTitle } );
    @{ $self->{ _bookTitle } } = () if !defined ( $self->{ _bookTitle } );
    @{ $self->{ _collectionTitle } } = @{ $self->{ _collectionTitle } } if defined ( $self->{ _collectionTitle } );
    @{ $self->{ _collectionTitle } } = () if !defined ( $self->{ _collectionTitle } );
    @{ $self->{ _sectionList } } = @{ $self->{ _sectionList } } if defined ( $self->{ _sectionList } );
    @{ $self->{ _sectionList } } = () if !defined ( $self->{ _sectionList } );
    
    
    
    bless $self, $class;
    
    $self->WriteLog( "New: Debug On" );
    
    return $self;
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

sub GetEntryType
{
    my ( $self ) = @_;
    $self->{ _entryType } = "(null)" if !defined ( $self->{ _entryType } );
    return $self->{ _entryType };
}

sub GetPMID
{
    my ( $self ) = @_;
    $self->{ _pmid } = -1 if !defined $self->{ _pmid };
    return $self->{ _pmid };
}

sub GetDateCreated
{
    my ( $self ) = @_;
    @{ $self->{ _dateCreated } } = ( -1, -1, -1 ) if ( @{ $self->{ _dateCreated } } eq 0 );
    return @{ $self->{ _dateCreated } };
}

sub GetDateCompleted
{
    my ( $self ) = @_;
    @{ $self->{ _dateCompleted } } = ( -1, -1, -1 ) if ( @{ $self->{ _dateCompleted } } eq 0 );
    return @{ $self->{ _dateCompleted } };
}

sub GetPubModel
{
    my ( $self ) = @_;
    $self->{ _pubModel } = "(null)" if !defined $self->{ _pubModel };
    return $self->{ _pubModel };
}

sub GetJournalISSN
{
    my ( $self ) = @_;
    $self->{ _journalIssn } = -1 if !defined $self->{ _journalIssn };
    return $self->{ _journalIssn };
}

sub GetJournalISSNType
{
    my ( $self ) = @_;
    $self->{ _journalIssnType } = "(null)" if !defined $self->{ _journalIssnType };
    return $self->{ _journalIssnType };
}

sub GetJournalVolume
{
    my ( $self ) = @_;
    $self->{ _journalVolume } = -1 if !defined $self->{ _journalVolume };
    return $self->{ _journalVolume };
}

sub GetJournalCitedMedium
{
    my ( $self ) = @_;
    $self->{ _journalCitedMedium } = "(null)" if !defined $self->{ _journalCitedMedium };
    return $self->{ _journalCitedMedium };
}

sub GetJournalIssue
{
    my ( $self ) = @_;
    $self->{ _journalIssue } = -1 if !defined $self->{ _journalIssue };
    return $self->{ _journalIssue };
}

sub GetJournalPubDate
{
    my ( $self ) = @_;
    @{ $self->{ _journalPubDate } } = ( -1, -1 ) if ( @{ $self->{ _journalPubDate } } eq 0 );
    return @{ $self->{ _journalPubDate } };
}

sub GetJournalPubYear
{
    my ( $self ) = @_;
    $self->{ _journalPubYear } = -1 if !defined $self->{ _journalPubYear };
    return $self->{ _journalPubYear };
}

sub GetJournalTitle
{
    my ( $self ) = @_;
    $self->{ _journalTitle } = "(null)" if !defined $self->{ _journalTitle };
    return $self->{ _journalTitle };
}

sub GetJournalISOAbbrev
{
    my ( $self ) = @_;
    $self->{ _journalIsoAbbrev } = "(null)" if !defined $self->{ _journalIsoAbbrev };
    return $self->{ _journalIsoAbbrev };
}

sub GetArticleTitle
{
    my ( $self ) = @_;
    $self->{ _articleTitle } = "(null)" if !defined $self->{ _articleTitle };
    return $self->{ _articleTitle };
}

# Format: Array of Array References
sub GetPagination
{
    my ( $self ) = @_;
    @{ $self->{ _pagination } } = () if ( @{ $self->{ _pagination } } eq 0 );
    return @{ $self->{ _pagination } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetMedlinePgn
{
    my ( $self ) = @_;
    $self->{ _medlinePgn } = -1 if !defined $self->{ _medlinePgn };
    return $self->{ _medlinePgn };
}

# Format: Array of Array References
sub GetAbstractList
{
    my ( $self ) = @_;
    @{ $self->{ _abstract } } = () if ( @{ $self->{ _abstract } } eq 0 );
    return @{ $self->{ _abstract } };
}

# Format: Array of Array References
sub GetAuthorList
{
    my ( $self ) = @_;
    @{ $self->{ _authorList } } = () if ( @{ $self->{ _authorList } } eq 0 );
    return @{ $self->{ _authorList } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetAuthor
{
    my ( $self ) = @_;
    @{ $self->{ _author } } = () if ( @{ $self->{ _author } } eq 0 );
    return @{ $self->{ _author } };
}

sub GetLanguage
{
    my ( $self ) = @_;
    $self->{ _language } = "(null)" if !defined $self->{ _language };
    return $self->{ _language };
}

# Format: Array of Array References
sub GetPublicationTypeList
{
    my ( $self ) = @_;
    @{ $self->{ _publicationTypeList } } = () if ( @{ $self->{ _publicationTypeList } } eq 0 );
    return @{ $self->{ _publicationTypeList } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetPublicationType
{
    my ( $self ) = @_;
    @{ $self->{ _publicationType } } = () if ( @{ $self->{ _publicationType } } eq 0 );
    return @{ $self->{ _publicationType } };
}

sub GetCountry
{
    my ( $self ) = @_;
    $self->{ _country } = "(null)" if !defined $self->{ _country };
    return $self->{ _country };
}

sub GetMedlineTA
{
    my ( $self ) = @_;
    $self->{ _medlineTA } = "(null)" if !defined $self->{ _medlineTA };
    return $self->{ _medlineTA };
}

sub GetNlmUniqueID
{
    my ( $self ) = @_;
    $self->{ _nlmUniqueID } = -1 if !defined $self->{ _nlmUniqueID };
    return $self->{ _nlmUniqueID };
}

sub GetISSNLinking
{
    my ( $self ) = @_;
    $self->{ _issnLinking } = -1 if !defined $self->{ _issnLinking };
    return $self->{ _issnLinking };
}

# Format: Array of Array References
sub GetChemicalList
{
    my ( $self ) = @_;
    @{ $self->{ _chemicalList } } = () if ( @{ $self->{ _chemicalList } } eq 0 );
    return @{ $self->{ _chemicalList } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetChemical
{
    my ( $self ) = @_;
    @{ $self->{ _chemical } } = () if ( @{ $self->{ _chemical } } eq 0 );
    return @{ $self->{ _chemical } };
}

sub GetCitationSubset
{
    my ( $self ) = @_;
    $self->{ _citationSubset } = "(null)" if !defined $self->{ _citationSubset };
    return $self->{ _citationSubset };
}

# Format: Array of Array References
sub GetMeshHeadingList
{
    my ( $self ) = @_;
    @{ $self->{ _meshHeadingList } } = () if ( @{ $self->{ _meshHeadingList } } eq 0 );
    return @{ $self->{ _meshHeadingList } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetMeshHeading
{
    my ( $self ) = @_;
    @{ $self->{ _meshHeading } } = () if ( @{ $self->{ _meshHeading } } eq 0 );
    return @{ $self->{ _meshHeading } };
}

# Format: Array of Array References
# Dereferenced Array Format: PubStatus, Year, Month, Day, Hour, Minute
sub GetHistory
{
    my ( $self ) = @_;
    @{ $self->{ _history } }= () if ( @{ $self->{ _history } } eq 0 );
    return @{ $self->{ _history } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetPubMedPubDate
{
    my ( $self ) = @_;
    @{ $self->{ _pubMedPubDate } } = () if ( @{ $self->{ _pubMedPubDate } } eq 0 );
    return @{ $self->{ _pubMedPubDate } };
}

sub GetPublicationStatus
{
    my ( $self ) = @_;
    $self->{ _publicationStatus } = "(null)" if !defined $self->{ _publicationStatus };
    return $self->{ _publicationStatus };
}

sub GetArticleIDList
{
    my ( $self ) = @_;
    @{ $self->{ _articleIdList } }= () if ( @{ $self->{ _articleIdList } } eq 0 );
    return @{ $self->{ _articleIdList } };
}

# NOTE: Not used, REMOVE ME (After thorough testing)
sub GetArticleID
{
    my ( $self ) = @_;
    @{ $self->{ _articleId } }= () if ( @{ $self->{ _articleId } } eq 0 );
    return @{ $self->{ _articleId } };
}

sub GetArticleURL
{
    my ( $self ) = @_;
    $self->{ _articleURL } = "(null)" if !defined $self->{ _articleURL };
    return $self->{ _articleURL };
}

sub GetISBN
{
    my ( $self ) = @_;
    $self->{ _isbn } = -1 if !defined $self->{ _isbn };
    return $self->{ _isbn };
}

sub GetPublisherList
{
    my ( $self ) = @_;
    @{ $self->{ _publisher } }= () if ( @{ $self->{ _publisher } } eq 0 );
    return @{ $self->{ _publisher } };
}

sub GetBookTitle
{
    my ( $self ) = @_;
    @{ $self->{ _bookTitle } }= () if ( @{ $self->{ _bookTitle } } eq 0 );
    return @{ $self->{ _bookTitle } };
}

sub GetCollectionTitle
{
    my ( $self ) = @_;
    @{ $self->{ _collectionTitle } }= () if ( @{ $self->{ _collectionTitle } } eq 0 );
    return @{ $self->{ _collectionTitle } };
}

sub GetSectionList
{
    my ( $self ) = @_;
    @{ $self->{ _sectionList } }= () if ( @{ $self->{ _sectionList } } eq 0 );
    return @{ $self->{ _sectionList } };
}


######################################################################################
#    Mutators
######################################################################################

sub SetPMID
{
    my ( $self, $temp ) = @_;
    return $self->{ _pmid } = $temp;
}

sub SetEntryType
{
    my ( $self, $temp ) = @_;
    return $self->{ _entryType } = $temp;
}

sub SetDateCreated
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _dateCreated } } = @temp;
}

sub SetDateCompleted
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _dateCompleted } } = @temp;
}

sub SetPubModel
{
    my ( $self, $temp ) = @_;
    return $self->{ _pubModel } = $temp;
}

sub SetJournalISSN
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalIssn } = $temp;
}

sub SetJournalISSNType
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalIssnType } = $temp;
}

sub SetJournalVolume
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalVolume } = $temp;
}

sub SetJournalCitedMedium
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalCitedMedium } = $temp;
}

sub SetJournalIssue
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalIssue } = $temp;
}

sub SetJournalPubDate
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _journalPubDate } } = @temp;
}

sub SetJournalPubYear
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalPubYear } = $temp;
}

sub SetJournalTitle
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalTitle } = $temp;
}

sub SetJournalISOAbbrev
{
    my ( $self, $temp ) = @_;
    return $self->{ _journalIsoAbbrev } = $temp;
}

sub SetArticleTitle
{
    my ( $self, $temp ) = @_;
    return $self->{ _articleTitle } = $temp;
}

sub SetPagination
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _pagination } } = @temp;
}

sub SetMedlinePgn
{
    my ( $self, $temp ) = @_;
    return $self->{ _medlinePgn } = $temp;
}

sub SetAbstractList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _abstract } } = @temp;
}

sub SetAuthorList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _authorList } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub SetAuthor
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _author } } = @temp;
}

sub SetLanguage
{
    my ( $self, $temp ) = @_;
    return $self->{ _language } = $temp;
}

sub SetPublicationTypeList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _publicationTypeList } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub SetPublicationType
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _publicationType } } = @temp;
}

sub SetCountry
{
    my ( $self, $temp ) = @_;
    return $self->{ _country } = $temp;
}

sub SetMedlineTA
{
    my ( $self, $temp ) = @_;
    return $self->{ _medlineTA } = $temp;
}

sub SetNlmUniqueID
{
    my ( $self, $temp ) = @_;
    return $self->{ _nlmUniqueID } = $temp;
}

sub SetISSNLinking
{
    my ( $self, $temp ) = @_;
    return $self->{ _issnLinking } = $temp;
}

sub SetChemicalList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _chemicalList } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub SetChemical
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _chemical } } = @temp;
}

sub SetCitationSubset
{
    my ( $self, $temp ) = @_;
    return $self->{ _citationSubset } = $temp;
}

sub SetMeshHeadingList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _meshHeadingList } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub SetMeshHeading
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _meshHeading } } = @temp;
}

sub SetHistory
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _history } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub PubMedPubDate
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _pubMedPubDate } } = @temp;
}

sub SetPublicationStatus
{
    my ( $self, $temp ) = @_;
    return $self->{ _publicationStatus } = $temp;
}

sub SetArticleIDList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _articleIdList } } = @temp;
}

# TODO : Fix setting variable within array of arrays
sub SetArticleID
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _articleId } } = @temp;
}

sub SetArticleURL
{
    my ( $self, $temp ) = @_;
    return $self->{ _articleURL } = $temp;
}

sub SetISBN
{
    my ( $self, $temp ) = @_;
    return $self->{ _isbn } = $temp;
}

sub SetPublisherList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _publisher } } = @temp;
}

sub SetBookTitle
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _bookTitle } } = @temp;
}

sub SetCollectionTitle
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _collectionTitle } } = @temp;
}

sub SetSectionList
{
    my ( $self, @temp ) = @_;
    return @{ $self->{ _sectionList } } = @temp;
}




######################################################################################
#    Debug Functions
######################################################################################

sub WriteLog
{
    my ( $self ) = shift;
    
    if( $self->GetDebugLog() )
    {
        my $string = shift;
        my $printNewLine = shift;
        
        return if !defined ( $string );
        $printNewLine = 1 if !defined ( $printNewLine );
        
        if( ref ( $string ) eq "PubEntry" )
        {
            print( "PubEntry Cannot Call WriteLog() From Outside Module!\n" );
            
        }
        else
        {
            $string = "" if !defined ( $string );
            print "PubEntry::" . $string;
            print "\n" if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND Publication Entry Module

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