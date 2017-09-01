#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    01/22/2015                                                             #
#    Revised: 04/26/2017                                                             #
#    Part of CMSC 452 - Data Mining Nanotechnology - Server                          #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 Server: - Accepts commands from clients and returns                #
#                            information/status messages based on client             #
#                            issued commands.                                        #
#                         - Supports multiple concurrent clients.                    #
#                                                                                    #
######################################################################################





use strict;
use warnings;

# CPAN Dependencies
use threads;
use threads::shared;
use IO::Socket::INET;
use Scalar::Util qw( looks_like_number );

# Local Dependencies
use Find::SocketPackage;



######################################################################################
#    Main
######################################################################################

sub ProcessCommand;                             # Forward Subroutine Declaration
sub TerminateAllActiveSockets;                  # Forward Subroutine Declaration


# Auto-Flush on socket
$| = 1;

my $enableServerMessages = 1;

# Terminate Server Thread Shared Variable
my $keepAlive :shared = 1;

# Creating a listening socket
my $listeningSocket = new IO::Socket::INET (
    LocalHost => 'localhost',
    LocalPort => '7777',
    Proto => 'tcp',
    Listen => SOMAXCONN,                                # Five Connections Max
    Reuse => 1
);
die "Error: Listening Socket Cannot Be Created $!\n" unless $listeningSocket;

my $localPort = $listeningSocket->sockport(); 
WriteLog( "Initialized: Waiting For Client Connection(s) On Port $localPort" );


######################################################
#
#       Start Listening For Client(s)
#
######################################################

while( $keepAlive && ( my $newSocket = $listeningSocket->accept() ) )
{
    threads->create( \&HandleClient, $newSocket )->detach();
}
 
$listeningSocket->close();
WriteLog( "Server Terminated" );

### End Of Main ###



######################################################################################
#    Module Functions
######################################################################################


sub HandleClient
{
    my $client_socket = shift;
    
    my $socketPackage = Find::SocketPackage->new();
    $socketPackage->SetSocket( $client_socket );
    
    # Get information about a newly connected client
    my $client_address = $client_socket->peerhost();
    my $client_port = $client_socket->peerport();
    WriteLog( "New Connection From: $client_address:$client_port" );
    
    my $data = "";
    
    while( $data ne "exit" && $data ne "killserv" )
    {
        # De-reference Array Reference
        my $client_socket = $socketPackage->GetSocket();
        
        # Read up to 1024 characters from the connected client
        $data = ReceiveCommand( $socketPackage );
        
        WriteLog( "Received Command: \"$data\" from $client_address:$client_port" ) if defined $data;
        my $command = $data if defined ( $data );
        
        my $message = ProcessCommand( $socketPackage, $command ) if defined $command;
        
        # Write response data to the connected client
        SendMessage( $socketPackage, $message ) if defined ( $message );
    }
    
    $socketPackage->GetDatabaseCom()->DisconnectDatabase();
    
    WriteLog( "Exiting Connection:  $client_address:$client_port" );
}

sub ProcessCommand
{
    my $socketPackage = shift;
    my $command = shift;
    
    my $eUtil = $socketPackage->GetEUtilities();
    my $dCom = $socketPackage->GetDatabaseCom();
    my $xmlParser = $socketPackage->GetPubMedXMLParser();
    
    my $socket = $socketPackage->GetSocket();
    my $client_address = $socket->peerhost();
    my $client_port = $socket->peerport();
    
    
    ################################################
    #
    #   General Commands
    #
    ################################################    

    if ( $command eq "exit" )
    {
        WriteLog( "Processed Termination Request From Client: $client_address:$client_port" );
        TerminateClient( $socketPackage, "Closing Client Connection" );
        return;
    }
    elsif( $command eq "killserv" )
    {
        WriteLog( "Processed Terminate Server Request From Client: $client_address:$client_port" );
        TerminateClient( $socketPackage, "Terminating Server" );
        TerminateServer();
        return;
    }
    elsif( StringContains( $command, "internettest" ) == 1 )
    {
        return $eUtil->ConnectedToInternet();
    }
    # Redundant command, I know...
    elsif( StringContains( $command, "getservermessages" ) == 1 )
    {
        return "Enable Sending Messages: true" if( GetEnableServerMessages() == 1 );
        return "Enable Sending Messages: false" if( GetEnableServerMessages() == 0 );
    }
    elsif( StringContains( $command, "setservermessages" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            SetEnableServerMessages( 1 ) if( $strArray[1] eq "true" );
            SetEnableServerMessages( 0 ) if( $strArray[1] eq "false" );
            return "Enable Sending Messages Set To: " . GetEnableServerMessages();
        }
        
        return "Error Setting Previous Command: Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "pubmeddefault" ) == 1 )
    {
        my @commandAry = TokenizeString( $command, ' ' );
        
        return "Syntax Error: No RetStart/RetMax Value Specified" if ( @commandAry == 1 );
        
        # Support Calling This Command With Only RetMax Or RetMin & RetMax
        my $retMax   = $commandAry[1] if( @commandAry == 2 && looks_like_number( $commandAry[1] ) );
        my $retStart = $commandAry[1] if( @commandAry == 3 && looks_like_number( $commandAry[1] ) );
        $retMax      = $commandAry[2] if( @commandAry == 3 && looks_like_number( $commandAry[2] ) );
        
        return "Error Setting RetStart / RetStart < 0 : Re-Evaluate Command Syntax" if( defined( $retStart ) && $retStart < 0 );
        return "Error Setting RetMax / RetMax <= 0 : Re-Evaluate Command Syntax" if( $retMax <= 0 );
        
        $retMax = 20 if !defined( $retMax );
        
        # Setting Up EUtilities
        $eUtil->SetRepositoryDB( "pubmed" );
        $eUtil->SetOutputFormat( 0 );
        $eUtil->SetUseHistory( "y" );
        $eUtil->SetRetStart( $retStart ) if defined $retStart;
        $eUtil->SetRetMax( $retMax );
        
        # Setting Up MySQL Database
        $dCom->SetPlatform( "mysql" );
        $dCom->SetDatabaseName( "find" );
        $dCom->SetHost( "127.0.0.1" );
        $dCom->SetPort( "3306" );
        $dCom->SetUserID( "root" );
        $dCom->SetPassword( "password" );
        
        $dCom->ConnectToDatabase();
        
        return "Default Settings: Repo=" . $eUtil->GetRepositoryDB() . " OutputFormat=" . $eUtil->GetOutputFormat()
                . " UseHistory=" . $eUtil->GetUseHistory() . " RetStart=" . $eUtil->GetRetStart()
                . " RetMax=" . $eUtil->GetRetMax() . " DatabaseName=" . $dCom->GetDatabaseName()
                . " Host=" . $dCom->GetHost() . " Port=" . $dCom->GetPort() . "\n!!! Connected To Database !!!";
    }
    elsif( StringContains( $command, "getrepo" ) == 1 )
    {
        my $repo = $eUtil->GetRepositoryDB();
        WriteLog( "EUtilities Repository: $repo" );
        return "EUtilities Repository: $repo";
    }
    elsif( StringContains( $command, "setrepo" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            $eUtil->SetRepositoryDB( $strArray[1] );
            WriteLog( "EUtilities Repo Set to: " . $strArray[1] );
            return "Repo Set To: $strArray[1]"
        }
        
        return "Error Setting Repository DB: Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "getformat" ) == 1 )
    {
        my $format = "";
        
        if( $eUtil->GetOutputFormat() eq "(null)" )
        {
            $format = "(null)";
        }
        elsif( $eUtil->GetOutputFormat() eq 0 )
        {
            $format = "XML";
        }
        elsif( $eUtil->GetOutputFormat() eq 1 )
        {
            $format = "TXT";
        }
        
        WriteLog( "EUtilities Output Format: " . $format );
        
        return $format;
    }
    elsif( StringContains( $command, "setformat" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            # Set Output Format as XML -> 0 = XML, 1 = TXT
            if( $strArray[1] eq "xml" )
            {
                $eUtil->SetOutputFormat( 0 );
            }
            elsif( $strArray[1] eq "txt" )
            {
                $eUtil->SetOutputFormat( 1 );
            }
            
            WriteLog( "Output Format Set To: " . $strArray[1] );
            
            return "Output Format Set To: " . $strArray[1];
        }
        
        return "Error Setting Format: Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "getusehistory" ) == 1 )
    {
        WriteLog( "EUtilities Use History: " . $eUtil->GetUseHistory() );
        return "UseHistory: " . $eUtil->GetUseHistory();
    }
    elsif( StringContains( $command, "setusehistory" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            if( $strArray[1] eq "y" || $strArray[1] eq "n" )
            {
                $eUtil->SetUseHistory( $strArray[1] );
                WriteLog( "UseHistory Set To: " . $strArray[1] );
                return "UseHistory Set To: " . $strArray[1];
            }
        }
        
        return "Error Setting UseHistory/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getretmax" ) == 1 )
    {
        WriteLog( "EUtilities RetMax: " . $eUtil->GetRetMax() );
        return "RetMax: " . $eUtil->GetRetMax();
    }
    elsif( StringContains( $command, "setretmax" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 && looks_like_number( $strArray[1] ) && $strArray[1] > 0 )
        {
            $eUtil->SetRetMax( $strArray[1] );
            WriteLog( "RetMax Set To: " . $strArray[1] );
            return "RetMax Set To: " . $strArray[1];
        }
        
        return "Error Setting RetMax/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getviewexistingdata" ) == 1 )
    {
        WriteLog( "SocketPackage RemoveExistingEntries: " . $eUtil->GetRetMax() );
        return "RemoveExistingEntries: " . $socketPackage->GetRemoveExistingEntries();
    }
    elsif( StringContains( $command, "setviewexistingdata" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 && looks_like_number( $strArray[1] ) && $strArray[1] >= 0 && $strArray[1] <= 1 )
        {
            $socketPackage->SetRemoveExistingEntries( $strArray[1] );
            WriteLog( "RemoveExistingEntries Set To: " . $strArray[1] );
            return "RemoveExistingEntries Set To: " . $strArray[1];
        }
        
        return "Error Setting RemoveExistingEntries/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "querylast" ) == 1 )
    {
        $eUtil->ParseESearch( $eUtil->GetLastQuery() );
        
        my $count = $eUtil->GetESearchCount();
        
        # Check For Query Requirements (PubMed)
        if( $count > 0 && $eUtil->GetRetMax() != 0 && $eUtil->GetLastQuery() ne ""
            && $eUtil->GetUseHistory() eq "y" && $eUtil->GetOutputFormat() eq 0 && $eUtil->GetRepositoryDB() eq "pubmed")
        {
            WriteLog( "Fetching Last Query " );
            $eUtil->FetchQuery( $eUtil->GetLastQuery() );
            WriteLog( "Data Fetching Complete" );
            return "Data Fetching Complete";
        }
        else
        {
            WriteLog( "Error: Last Query Not Set/No Prior Query Fetched" );
        }
        
        return "Error Fetching Data/Last Query Not Set";
    }
    elsif( StringContains( $command, "queryandparsedata" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            WriteLog( "Fetching Query: " . $strArray[1] );
            $eUtil->ParseESearch( $strArray[1] );
            
            my $count = $eUtil->GetESearchCount();
            my $connectedToInternet = $eUtil->ConnectedToInternet();
            
            # Check For Query Requirements (PubMed) - (Internet Connection Detected)
            if( $connectedToInternet == 1 && $count > 0 && $eUtil->GetRetMax() != 0 && $eUtil->GetUseHistory() eq "y"
                && $eUtil->GetOutputFormat() eq 0 && $eUtil->GetRepositoryDB() eq "pubmed" )
            {
                $eUtil->FetchQuery( $strArray[1] );
                WriteLog( "Data Fetching Complete" );
            }
            # No Internet Connection Detected And All Query Requirements Set (PubMed)
            elsif( $connectedToInternet == 0 && $eUtil->GetRetMax() != 0 && $eUtil->GetUseHistory() eq "y"
                && $eUtil->GetOutputFormat() eq 0 && $eUtil->GetRepositoryDB() eq "pubmed" )
            {
                WriteLog( "No Internet Connection Detected - Using Backup Files" );
                $eUtil->ReadEFetchDataFromFile( "../samples/asthma_efetch.txt" ) if ( $strArray[1] eq "asthma+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/asthmaleukotrienes_efetch.txt" ) if ( $strArray[1] eq "asthma+AND+leukotrienes+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/asthmaleukotrienes[mesh]_efetch.txt" ) if ( $strArray[1] eq "asthma[mesh]+AND+leukotrienes[mesh]+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/asthmaleukotrienes2009_efetch.txt" ) if ( $strArray[1] eq "asthma[mesh]+AND+leukotrienes[mesh]+AND+2009[pdat]:2009[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/cern_efetch.txt" ) if ( $strArray[1] eq "cern+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/heartattack_efetch.txt" ) if ( $strArray[1] eq "heart+attack+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/heart_efetch.txt" ) if ( $strArray[1] eq "heart+AND+1900[pdat]:3000[pdat]" );
                $eUtil->ReadEFetchDataFromFile( "../samples/wordsensedisambiguation_efetch.txt" ) if ( $strArray[1] eq "word+sense+disambiguation+AND+1900[pdat]:3000[pdat]" );
            }
            else
            {
                return "Requirements For Fetching Data Not Met, With Internet Connection: setrepo, setformat, setusehistory, setretmax Then query";
            }
            
            if( $xmlParser->GetParsedCount() ne 0 )
            {
                WriteLog( "Clearing Old EFetch XML Data" );
                $xmlParser->ClearData();
            }
            
            WriteLog( "Parsing Data..." );
            my @dataArray = $eUtil->GetEFetchDataArray();

            for my $data ( @dataArray )
            {
                $xmlParser->ParseXMLString( $data );
            }
            WriteLog( "Parsing Complete - Data parsed and placed in an array of PubEntry objects" );
            
            $socketPackage->RemoveExistingDatabaseData();
            
            return "Data Fetching And Parsing Complete";
        }
        
        return "Error Fetching Data via EFetch/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "query" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 2 )
        {
            WriteLog( "Fetching Query: " . $strArray[1] );
            $eUtil->ParseESearch( $strArray[1] );
            
            my $count = $eUtil->GetESearchCount();
            
            # Check For Query Requirements (PubMed)
            if( $count > 0 && $eUtil->GetRetMax() != 0 && $eUtil->GetUseHistory() eq "y"
                && $eUtil->GetOutputFormat() eq 0 && $eUtil->GetRepositoryDB() eq "pubmed" )
            {
                $eUtil->FetchQuery( $strArray[1] );
                WriteLog( "Data Fetching Complete" );
                return "Data Fetching Complete";
            }
            else
            {
                return "Requirements For Fetching Data Not Met: setrepo, setformat, setusehistory, setretmax Then query";
            }
        }
        
        return "Error Fetching Data via EFetch/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "parsedata" ) == 1 )
    {
        if( $xmlParser->GetParsedCount() ne 0 )
        {
            WriteLog( "Clearing Old EFetch XML Data" );
            $xmlParser->ClearData();
        }
        
        WriteLog( "Parsing Data..." );
        my @dataArray = $eUtil->GetEFetchDataArray();

        for my $data ( @dataArray )
        {
            $xmlParser->ParseXMLString( $data );
        }
        WriteLog( "Parsing Complete - Data parsed and placed in an array of PubEntry objects" );
        
        $socketPackage->RemoveExistingDatabaseData();
        
        return "Parsing Complete";
    }
    elsif( StringContains( $command, "numofentries" ) == 1 )
    {
        WriteLog( "Number of Parsed Array elements: " . scalar $xmlParser->GetPubEntryList() );
        return scalar $xmlParser->GetPubEntryList();
    }
    elsif( StringContains( $command, "cleareutil" ) == 1 )
    {
        WriteLog( "Clearing eUtil Data" );
        $eUtil->ClearData();
        return "Cleared eUtil Data";
    }
    elsif( StringContains( $command, "clearparser" ) == 1 )
    {
        WriteLog( "Clearing PubMed XML Parser Data" );
        $xmlParser->ClearData();
        return "Cleared XML Parser Data";
    }
    elsif( StringContains( $command, "dumpdata" ) == 1 )
    {
        WriteLog( "Writing EFetch Data To File: \"eFetch Data.txt\"" );
        my $result = $eUtil->DumpEFetchDataToFile();
        WriteLog( "Data Written To File" ) if $result;
        WriteLog( "No Data Written To File" ) if !$result;
        return "EFetch Data Dumped To File: \"eFetch Data.txt\"" if $result;
        return "No EFetch Data To Write To File/Has Data Been Fetched Prior?" if !$result;
    }
    
    ################################################
    #
    #   PubEntry List Commands
    #
    ################################################
    
    elsif( StringContains( $command, "get element" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        my $size = @strArray;
        
        if( $size == 4 && looks_like_number( $strArray[2] ) )
        {
            my $index = $strArray[2];
            my @pubEntryList = $xmlParser->GetPubEntryList();
            
            # Check(s)
            if( @pubEntryList == 0 )
            {
                return "Command Error: PubEntry List Size == 0 / No Data Has Been Parsed";
            }
            elsif( $strArray[2] < 0 )
            {
                return "Command Error: Cannot Request Element < 0";
            }
            elsif( $strArray[2] > ( @pubEntryList - 1 ) )
            {
                return "Command Error: Cannot Request Element > PubEntry List Size";
            }
            
            
            
            if( StringContains( $command, "pmid" ) == 1 )
            {
                return $pubEntryList[$index]->GetPMID() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "datecreated" ) == 1 )
            {
                my @dateCreated = $pubEntryList[$index]->GetDateCreated() if defined ( $pubEntryList[$index] );
                my $dateString = "Year:" . $dateCreated[0] . " Month:" . $dateCreated[1] . " Day:" . $dateCreated[2];
                return $dateString;
            }
            elsif( StringContains( $command, "datecompleted" ) == 1 )
            {
                my @dateCompleted = $pubEntryList[$index]->GetDateCompleted() if defined ( $pubEntryList[$index] );
                my $dateString = "Year:" . $dateCompleted[0] . " Month:" . $dateCompleted[1] . " Day:" . $dateCompleted[2];
                return $dateString;
            }
            elsif( StringContains( $command, "pubyear" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalPubYear() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "authorlist" ) == 1 )
            {
                my @authorList = $pubEntryList[$index]->GetAuthorList() if defined ( $pubEntryList[$index] );
                my $authorStr = "";
                
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
                
                return "(null)" if ( $authorStr eq "" );
                return $authorStr;
            }
            elsif( StringContains( $command, "pubmodel" ) == 1 )
            {
                return $pubEntryList[$index]->GetPubModel() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalissn" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalISSN() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalissntype" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalISSNType() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalvolume" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalVolume() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalcitedmedium" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalCitedMedium() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalissue" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalIssue() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalpubdate" ) == 1 )
            {
                my @dateArray = $pubEntryList[$index]->GetJournalPubDate() if defined ( $pubEntryList[$index] );
                my $dateStr = join( '-', @dateArray );
                
                return "(null)" if ( $dateStr eq "" );
                return $dateStr;
            }
            elsif( StringContains( $command, "journaltitle" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalTitle() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "journalisoabbrev" ) == 1 )
            {
                return $pubEntryList[$index]->GetJournalISOAbbrev() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "articletitle" ) == 1 )
            {
                return $pubEntryList[$index]->GetArticleTitle() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "pagination" ) == 1 )
            {
                my $pagStr = "";
                my @pagAryOfRef = $pubEntryList[$index]->GetPagination() if defined ( $pubEntryList[$index] );
                
                for my $aryRef ( @pagAryOfRef )
                {
                    my @pagination = @{ $aryRef };
                    $pagStr .= join( '<:>', @pagination );
                    $pagStr .= "<en>" if( $aryRef ne $pagAryOfRef[-1] );
                }
                
                return "(null)" if ( $pagStr eq "" );
                return $pagStr;
            }
            elsif( StringContains( $command, "abstract" ) == 1 )
            {
                my $abstractStr = "";
                my @abstractAryOfRef = $pubEntryList[$index]->GetAbstractList() if defined ( $pubEntryList[$index] );
                
                for my $aryRef ( @abstractAryOfRef )
                {
                    my @abstract = @{ $aryRef };
                    $abstractStr .= join( '<:>', @abstract );
                    $abstractStr .= "<en>" if( $aryRef ne $abstractAryOfRef[-1] );
                }
                
                return "(null)" if ( $abstractStr eq "" );
                return $abstractStr;
            }
            elsif( StringContains( $command, "language" ) == 1 )
            {
                return $pubEntryList[$index]->GetLanguage() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "publicationtype" ) == 1 )
            {
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
                
                return "(null)" if ( $pubTypeStr eq "" );
                return $pubTypeStr;
            }
            elsif( StringContains( $command, "country" ) == 1 )
            {
                return $pubEntryList[$index]->GetCountry() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "medlineta" ) == 1 )
            {
                return $pubEntryList[$index]->GetMedlineTA() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "nlmuniqueid" ) == 1 )
            {
                return $pubEntryList[$index]->GetNlmUniqueID() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "issnlinking" ) == 1 )
            {
                return $pubEntryList[$index]->GetISSNLinking() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "chemicallist" ) == 1 )
            {
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
                
                return "(null)" if ( $chemListStr eq "" );
                return $chemListStr;
            }
            elsif( StringContains( $command, "citationsubset" ) == 1 )
            {
                return $pubEntryList[$index]->GetCitationSubset() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "meshheadinglist" ) == 1 )
            {
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
                
                return "(null)" if ( $meshHeadingStr eq "" );
                return $meshHeadingStr;
            }
            elsif( StringContains( $command, "history" ) == 1 )
            {
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
                
                return "(null)" if ( $historyStr eq "" );
                return $historyStr;
            }
            elsif( StringContains( $command, "publicationstatus" ) == 1 )
            {
                return $pubEntryList[$index]->GetPublicationStatus() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "articleidlist" ) == 1 )
            {
                my $articleIdStr = "";
                my @articleIDAryOfRef = $pubEntryList[$index]->GetArticleIDList() if defined ( $pubEntryList[$index] );
                
                for my $aryRef ( @articleIDAryOfRef )
                {
                    my @articleID = @{ $aryRef };
                    $articleIdStr .= join( '<:>', @articleID );
                    $articleIdStr .= "<en>" if( $aryRef ne $articleIDAryOfRef[-1] );
                }
                
                return "(null)" if ( $articleIdStr eq "" );
                return $articleIdStr;
            }
            elsif( StringContains( $command, "articleurl" ) == 1 )
            {
                return $pubEntryList[$index]->GetArticleURL() if defined ( $pubEntryList[$index] );
                return "(null)";
            }
            elsif( StringContains( $command, "booktitle" ) == 1 )
            {
                my @booktitle = $pubEntryList[$index]->GetBookTitle() if defined ( $pubEntryList[$index] );
                return "@booktitle" if ( @booktitle > 0 );
                return "(null)";
            }
            elsif( StringContains( $command, "alldata" ) == 1 )
            {
                return $socketPackage->GetAllElementData( $index );
            }
        }
        
        return "Error Fetching Specific Command/Re-Evalutate Syntax";
    }
    
    ################################################
    #
    #   Database Commands
    #
    ################################################
    
    elsif( StringContains( $command, "getdbplatform" ) == 1 )
    {
        return $dCom->GetPlatform() if defined ( $dCom );
        return "(null)";
    }
    elsif( StringContains( $command, "setdbplatform" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetPlatform( $tokenizedStr[1] );
            WriteLog( "Database Platform Set To: " . $tokenizedStr[1] );
            return "Database Platform Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database Platform/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getdbname" ) == 1 )
    {
        return $dCom->GetDatabaseName() if defined ( $dCom );
        return "(null)";
    }
    elsif( StringContains( $command, "setdbname" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetDatabaseName( $tokenizedStr[1] );
            WriteLog( "Database Name Set To: " . $tokenizedStr[1] );
            return "Database Name Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database Name/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getdbhost" ) == 1 )
    {
        return $dCom->GetHost() if defined ( $dCom );
        return "(null)";
    }
    elsif( StringContains( $command, "setdbhost" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetHost( $tokenizedStr[1] );
            WriteLog( "Database Host Set To: " . $tokenizedStr[1] );
            return "Database Host Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database Host/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getdbport" ) == 1 )
    {
        return $dCom->GetPort() if defined ( $dCom );
        return "(null)";
    }
    elsif( StringContains( $command, "setdbport" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetPort( $tokenizedStr[1] );
            WriteLog( "Database Port Set To: " . $tokenizedStr[1] );
            return "Database Port Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database Port/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "getdbuserid" ) == 1 )
    {
        return $dCom->GetUserID() if defined ( $dCom );
        return "(null)";
    }
    elsif( StringContains( $command, "setdbuserid" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetUserID( $tokenizedStr[1] );
            WriteLog( "Database UserID Set To: " . $tokenizedStr[1] );
            return "Database UserID Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database UserID/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "setdbpassword" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );
        
        if( @tokenizedStr == 2 && defined ( $dCom ) )
        {
            $dCom->SetPassword( $tokenizedStr[1] );
            WriteLog( "Database Password Set To: " . $tokenizedStr[1] );
            return "Database Password Set To: " . $tokenizedStr[1];
        }
        
        return "Error Setting Database Password/Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "dbentrycount" ) == 1 )
    {
        return $dCom->GetDatabaseEntryCount() if ( defined ( $dCom ) && $dCom->IsConnected() );
        return "(null)";
    }
    elsif( StringContains( $command, "dbconnect" ) == 1 )
    {
        $dCom->ConnectToDatabase() if defined ( $dCom );
        return "Connected To Database: " . $dCom->GetDatabaseName() . " Platform: " . $dCom->GetPlatform()  . " Host: " . $dCom->GetHost() . " Port: " . $dCom->GetPort();
    }
    elsif( StringContains( $command, "dbdisconnect" ) == 1 )
    {
        $dCom->DisconnectDatabase() if defined ( $dCom );
        return "Disconnected From Database: " . $dCom->GetDatabaseName() . " Platform: " . $dCom->GetPlatform()  . " Host: " . $dCom->GetHost() . " Port: " . $dCom->GetPort();
    }
    elsif( StringContains( $command, "dbstoreentries" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );

        if( @tokenizedStr == 2 )
        {
            my @pmids = TokenizeString( $tokenizedStr[1], ':' );
            my @pubEntryList = $xmlParser->GetPubEntryList();
            my @pubEntryAry = ();
            
            for my $pmid ( @pmids )
            {
                for my $pubEntry ( @pubEntryList )
                {
                    push( @pubEntryAry, $pubEntry ) if( $pmid eq $pubEntry->GetPMID() );
                }
            }
            
            return $socketPackage->StoreEntriesIntoDatabase( \@pubEntryAry );
        }
        
        return "Error Storing Entries / Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "dbstore element" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 3 && looks_like_number( $strArray[2] ) )
        {
            my $index = $strArray[2];
            my @pubEntryList = $xmlParser->GetPubEntryList();
            my $pubEntry = $pubEntryList[$index];
            
            if( defined( $pubEntry ) )
            {
                my @pubEntryAry = ( $pubEntry );
                return $socketPackage->StoreEntriesIntoDatabase( \@pubEntryAry );
            }
            
            return "Error Storing Element In Database / Element Not Defined / Re-Evaluate Syntax";
        }
        
        return "Error Storing Element In Database / Re-Evaluate Syntax";
    }
    elsif( StringContains( $command, "dbdeleteentries" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );

        if( @tokenizedStr == 2 )
        {
            my @pmids = TokenizeString( $tokenizedStr[1], ':' );

            for my $pmid ( @pmids )
            {
                $socketPackage->DeleteEntryFromDatabase( $pmid );
            }
            
            return "Deleted Entries With Specified PMIDs From Database";
        }
        
        return "Error Storing Entries / Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "dbdelete" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        
        if( @strArray == 4 && looks_like_number( $strArray[2] ) )
        {
            my $index = $strArray[2];
            my @pubEntryList = $xmlParser->GetPubEntryList();
            
            if( StringContains( $command, "pmid" ) == 1 )
            {
                # TODO : Not Yet Implemented
                my $pmid = 0;
                
                return "Not Yet Implemented - Data Containing PMID Deleted";
            }
            elsif( StringContains( $command, "authors" ) == 1 )
            {
                # TODO : Not Yet Implemented
                my $tableName = "authors";
                
                return "Not Yet Implemented - Author Data Deleted From Database";
            }
        }
        
        return "Error Fetching Specific Command/Re-Evalutate Syntax";
    }
    elsif( StringContains( $command, "dbretrieveentries" ) == 1 )
    {
        my @tokenizedStr = TokenizeString( $command, ' ' );

        if( @tokenizedStr == 3 && looks_like_number( $tokenizedStr[1] ) && looks_like_number( $tokenizedStr[2] ) )
        {
            my $startIndex = $tokenizedStr[1];
            my $endIndex = $tokenizedStr[2];
            return $socketPackage->RetrieveDatabaseEntriesByIndex( $startIndex, $endIndex );
        }
        elsif( @tokenizedStr == 5 && !looks_like_number( $tokenizedStr[1] ) && !looks_like_number( $tokenizedStr[2] )
                && looks_like_number( $tokenizedStr[3] ) && looks_like_number( $tokenizedStr[4] ) )
        {
            my $query = $tokenizedStr[1];
            my $searchBy = $tokenizedStr[2];
            my $startIndex = $tokenizedStr[3];
            my $numOfResults = $tokenizedStr[4];
            return $socketPackage->RetrieveDatabaseEntriesByQuery( $query, $searchBy, "", 3000, 1900, $startIndex, $numOfResults );
        }
        elsif( @tokenizedStr == 6 && !looks_like_number( $tokenizedStr[1] ) && !looks_like_number( $tokenizedStr[2] )
                && !looks_like_number( $tokenizedStr[3] ) && looks_like_number( $tokenizedStr[4] ) && looks_like_number( $tokenizedStr[5] ) )
        {
            my $query = $tokenizedStr[1];
            my $searchBy = $tokenizedStr[2];
            my $searchType = $tokenizedStr[3];
            my $startIndex = $tokenizedStr[4];
            my $numOfResults = $tokenizedStr[5];
            return $socketPackage->RetrieveDatabaseEntriesByQuery( $query, $searchBy, $searchType, 3000, 1900, $startIndex, $numOfResults );
        }
        elsif( @tokenizedStr == 8 && !looks_like_number( $tokenizedStr[1] ) && !looks_like_number( $tokenizedStr[2] )
                && !looks_like_number( $tokenizedStr[3] ) && looks_like_number( $tokenizedStr[4] ) && looks_like_number( $tokenizedStr[5] )
                && looks_like_number( $tokenizedStr[6] ) && looks_like_number( $tokenizedStr[7] ) )
        {
            my $query = $tokenizedStr[1];
            my $searchBy = $tokenizedStr[2];
            my $searchType = $tokenizedStr[3];
            my $startYear = $tokenizedStr[4];
            my $endYear = $tokenizedStr[5];
            my $startIndex = $tokenizedStr[6];
            my $numOfResults = $tokenizedStr[7];
            return $socketPackage->RetrieveDatabaseEntriesByQuery( $query, $searchBy, $searchType, $startYear, $endYear, $startIndex, $numOfResults );
        }
        
        return "Error Retrieving Entries / Re-Evaluate Command Syntax";
    }
    elsif( StringContains( $command, "dbtruncate tablerows" ) == 1 )
    {
        my @strArray = TokenizeString( $command, ' ' );
        my $size = @strArray;
        
        if( $size == 3 && defined ( $dCom ) && $dCom->IsConnected() )
        {
            my $tableName = $strArray[2];
            $dCom->TruncateAllTableRows( $tableName );
            return "Table: $tableName Rows Truncated";
        }
        
        return "Error Fetching Specific Command/Re-Evalutate Syntax";
    }
    
    return "OK";
}

sub ReceiveCommand
{
    my $socketPackage = shift;
    my $command = "";
    
    my $socket = $socketPackage->GetSocket();
    
    if( $socket && defined( $socket->connected() ) )
    {
        my $data = "";
        
        while( $data !~ /<EOTEOT>/ )
        {
            # receive a response of up to 1024 characters from client
            $socket->recv( $data, 1024 );
            $command .= $data;
        }
        
        # Remove Client Termination Signal String "<EOTEOT>" From Client Fetched Data
        # Find and Replace "<EOTEOT>" In Response With "" (Nothing) Globally For The Entire $command String
        $command =~ s/<EOTEOT>//g;
    }
    
    return $command;
}

sub SendMessage
{
    my $socketPackage = shift;
    my $message = shift;
    
    my $socket = $socketPackage->GetSocket();
    
    if( GetEnableServerMessages() == 1 && defined( $message ) && $socket && defined( $socket->connected() ) )
    {
        $message .= "<EOTEOT><EOTEOT>";
        my $lengthStr = "<Length>" . length( $message ) . "<\\Length>";
        $socket->send( $lengthStr );
        $socket->send( $message );
    }
}

sub TerminateClient
{
    my $socketPackage = shift;
    my $message = shift;
    my $socket = $socketPackage->GetSocket();
    
    SendMessage( $socketPackage, $message ) if defined ( $message );
    
    # Close Database Communication
    $socketPackage->GetDatabaseCom()->DisconnectDatabase() if defined( $socketPackage->GetDatabaseCom() );
    
    # Clesr EUtilities Data
    $socketPackage->GetEUtilities()->ClearData() if defined( $socketPackage->GetEUtilities() );
    
    # Clear PubMedXMLParser Data
    $socketPackage->GetPubMedXMLParser()->ClearData() if defined( $socketPackage->GetPubMedXMLParser() );
    
    # Retrieve address of client
    my $client_address = $socket->peerhost();
    my $client_port = $socket->peerport();
    
    # Notify client that the server has finished sending and receiving messages
    shutdown( $socket, 2 );

    # Maybe we have finished with the socket
    $socket->close();
    
    WriteLog( "Closed Client Socket: $client_address:$client_port" );
    
    undef $socketPackage;
}

# NOTE: Dirty Hack Job... sigh
sub TerminateServer
{
    $keepAlive = 0;
    
    # Create New Socket Connection To Iterate Through "listeningSocket->accept()" Block
    my $socket = new IO::Socket::INET (
        PeerHost => 'localhost',
        PeerPort => '7777',
        Proto => 'tcp',
    );
    
    $socket->close();
}

# NOTE: Not utilized
sub StringEquals
{
    my $strA = shift;
    my $strB = shift;
    
    # Convert Strings To Lowercase
    $strA = lc( $strA );
    $strB = lc( $strB );
    
    return 1 if( index( $strA, $strB ) == 0 && ( length( $strA ) == length( $strB ) ) );
    
    return 0;
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

sub TokenizeString
{
    my $str = shift;
    my $delimiter = shift;
    return my @stringArray = split( $delimiter, $str );
}


######################################################################################
#    Accessors
######################################################################################

sub GetEnableServerMessages
{
    $enableServerMessages = 1 if !defined ( $enableServerMessages );
    return $enableServerMessages;
}


######################################################################################
#    Mutators
######################################################################################

sub SetEnableServerMessages
{
    my ( $temp ) = @_;
    return $enableServerMessages = $temp;
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
    
    my $string = shift;
    my $printNewLine = shift;
    
    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );
    
        
    if( ref ( $string ) eq "Server" )
    {
        print( GetDate() . " " . GetTime() . " - Server: Cannot Call WriteLog() From Outside Module!\n" );
        return;
    }
    
    $string = "" if !defined ( $string );
    print GetDate() . " " . GetTime() . " - Server: $string";
    print "\n" if( $printNewLine != 0 );
}


__END__

=head1 NAME

ServerV3.pl - FiND Server

=head1 SYNOPSIS

FiND Server - Framework for Intelligent Network Discovery

=head1 USAGE

Usage: ServerV3.pl

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