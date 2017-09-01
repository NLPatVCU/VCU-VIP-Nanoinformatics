#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/26/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - MySQL Database Communication    #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 WRITE DESCRIPTION HERE                                             #
#                                                                                    #
######################################################################################





use strict;
use warnings;

# CPAN Dependencies
use DBI;
use DBD::mysql;




package Find::DatabaseCom;





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
    
    # Disconnect Database Handle
    $self->{ _databaseHandle }->disconnect() if defined ( $self->{ _databaseHandle } );
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
        _writeLog => shift,                     # Boolean (Binary): 0 = False, 1 = True
        _platform => shift,                     # String
        _database => shift,                     # String
        _host => shift,                         # String
        _port => shift,                         # String
        _userID => shift,                       # String
        _password => shift,                     # String
        _databaseSourceName => shift,           # String
        _databaseHandle => shift,               # Database Handle
        _fileHandle => shift,                   # File Handle
    };
    
    # Set variables to default values
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _platform } = "(null)" if !defined ( $self->{ _platform } );
    $self->{ _database } = "(null)" if !defined ( $self->{ _database } );
    $self->{ _host } = "(null)" if !defined ( $self->{ _host } );
    $self->{ _port } = "(null)" if !defined ( $self->{ _port } );
    $self->{ _userID } = "(null)" if !defined ( $self->{ _userID } );
    $self->{ _password } = "(null)" if !defined ( $self->{ _password } );
    $self->{ _databaseSourceName } = "(null)" if !defined ( $self->{ _databaseSourceName } );
    $self->{ _databaseHandle } = "(null)" if !defined ( $self->{ _databaseHandle } );
    
    
    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', 'DatabaseComLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Flushes writes to file with used in server
    }
    
    bless $self, $class;
    
    $self->WriteLog( "New: Debug On" );
    
    return $self;
}


######################################################################################
#    Module Functions
######################################################################################

sub ConnectToDatabase
{
    my ( $self ) = @_;
    
    return if $self->IsConnected() eq 1;
    
    $self->WriteLog( "ConnectToDatabase - Setting Up Connection To: Platform: ". $self->GetPlatform() . ", Host: "
                     . $self->GetHost() . ", Port: " . $self->GetPort() . ", Database: " . $self->GetDatabaseName() );
    
    $self->SetDatabaseSourceName( "DBI:" . $self->GetPlatform() . ":database=" . $self->GetDatabaseName() . ":" . $self->GetHost() . ":" . $self->GetPort() );
    my %attr = ( PrintError => 0, RaiseError => 1, AutoCommit => 0 );
    
    $self->WriteLog( "ConnectToDatabase - Attempting Connection" );
    
    # Connect to MySQL database
    $self->SetDatabaseHandle( DBI->connect( $self->GetDatabaseSourceName(), $self->GetUserID(), $self->GetPassword(), \%attr ) ) or die $DBI::errstr;   # Database Handle Object
    
    $self->WriteLog( "ConnectToDatabase - Connected To Platform:" . $self->GetPlatform() . "," . " Host: " . $self->GetHost()
                     . ", Port: " . $self->GetPort() . ", Database: " . $self->GetDatabaseName() ) if defined ( $self->GetDatabaseHandle() );
    $self->WriteLog( "ConnectToDatabase - Unable To Connect To Database: " . $self->GetDatabaseName() ) if( !defined ( $self->GetDatabaseHandle() ) || $self->GetDatabaseHandle() eq "(null)" );
}

sub DisconnectDatabase
{
    my ( $self ) = @_;
    
    if( $self->GetDatabaseHandle() ne "(null)" && $self->GetDatabaseHandle()->ping() )
    {
        $self->GetDatabaseHandle()->disconnect();
        $self->WriteLog( "DisconnectDatabase - Disconnected From Database: " . $self->GetDatabaseName() ) if defined ( $self->GetDatabaseHandle() );
    }
}

sub IsConnected
{
    my ( $self ) = @_;
    
    return 0 if $self->GetDatabaseHandle() eq "(null)";
    
    # Returns "1" If Connected "0" If Not-Connected (Tested With DBD::mysql Only)
    return $self->GetDatabaseHandle()->ping();
}

sub CheckIfTableExists
{
    my ( $self, $temp ) = @_;
    
    $temp = "(null)" if !defined ( $temp );
    
    $self->WriteLog( "CheckIfTableExists - Checking If Table: \"$temp\" Exists In Database: " . $self->GetDatabaseName() );
    
    # Return false if no argument is passed to function or database handle object is undefined
    $self->WriteLog( "CheckIfTableExists - Passed Arguement Is \"(null)\", Aborting Command" ) if( $temp eq "(null)");
    return 0 if( $temp eq "(null)" || !defined ( $self->GetDatabaseHandle() ) );
    
    my @tables = $self->GetDatabaseTables();
    
    foreach my $table ( @tables )
    {
        if( $table eq "`" . $self->GetDatabaseName() . "`.`$temp`" )
        {
            $self->WriteLog( "CheckIfTableExists - Table Found In Database: " . $self->GetDatabaseName() );
            return 1;
        }
    }
    
    $self->WriteLog( "CheckIfTableExists - Table \"" . $temp . "\" Does Not Exist In Database: " . $self->GetDatabaseName() );
    
    return 0;
}

# Creates MySQL Table: Argument format ( Table Name )
# Redundant / Not Complete, ExecuteQuery Function Can Be Utilized With Appropriate Query For Same Results
sub CreateTable
{
    my ( $self, $query ) = @_;
    
    $query = "(null)" if !defined ( $query );
    
    my $tableName = $self->GetTableNameFromSQLQuery( $query );
    
    if( $self->CheckIfTableExists( $tableName ) )
    {
        $self->WriteLog( "CreateTable - Table \"$tableName\" already exists in database" );
        return;
    }
    elsif( defined ( $self->GetDatabaseHandle() ) )
    {
        $self->WriteLog( "CreateTable - Table \"$tableName\" Does Not Exist In Database" );
        $self->ExecuteQuery( $query );
        $self->WriteLog( "CreateTable - Created Table \"$tableName\" In Database" );
    }
}

sub DeleteTable
{
    my ( $self, $tableName ) = @_;
    
    $tableName = "(null)" if !defined ( $tableName );
    
    if( $self->CheckIfTableExists( $tableName ) )
    {
        $self->WriteLog( "DeleteTable - Table \"$tableName\" Deleted From Database" );
        $self->ExecuteQuery( "DROP TABLE $tableName" );
    }
    else
    {
        $self->WriteLog( "DeleteTable - Error: Table $tableName Does Not Exists In Database" );
    }
}

sub ExecuteQuery
{
    my ( $self, $query ) = @_;
    
    if( $query eq "(null)" || $query eq "" || !defined( $query ) )
    {
        WriteLog( "ExecuteQuery - Invalid Query: \"$query\"" );
        return;
    }
    
    my $queryHandle;
    
    if( defined ( $self->GetDatabaseHandle() ) && defined ( $query ) )
    {
        $queryHandle = $self->GetDatabaseHandle()->prepare( $query );
        $self->WriteLog( "ExecuteQuery - Query \"$query\" Prepared" );
        
        my $result;
        
        eval {
            $queryHandle->execute();
            $result = 1;
            1;          # Return True If Execution Succeeded
        } or do {
            # Check for MySQL query execution errors and rollback changes if error is found.
            my $error = DBI->errstr;
            $self->WriteLog( "ExecuteQuery - Error Executing Query/Rolling Back Change(s): $error" );
            $self->GetDatabaseHandle()->rollback();
        };
        
        if( defined ( $result ) )
        {
            $self->GetDatabaseHandle()->commit() or die DBI::errstr;
            $self->WriteLog( "ExecuteQuery - Query Executed" );
            return $queryHandle;
        }
    }
    elsif( !defined ( $self->GetDatabaseHandle() ) )
    {
        $self->WriteLog( "ExecuteQuery - Database Handle Not Defined/Cannot Prepare-Execute Query" );
    }
    else
    {
        $self->WriteLog( "ExecuteQuery - Invalid Query Entry: $query" );
        return;
    }
    
    return;
}

sub GetTableNameFromSQLQuery
{
    my ( $self, $query ) = @_;
    
    if( !defined( $query ) || $query eq "(null)" )
    {
        $self->WriteLog( "GetTableNameFromSQLQuery - Null Query/Not Defined" );
        return "(null)";
    }
    
    my @stringArray = split( ' ', $query );
    
    for( my $i = 0; $i < @stringArray; $i++  )
    {
        if( $i > 0 && $stringArray[$i-1] eq "TABLE" && $stringArray[$i+1] eq "(" )
        {
            $self->WriteLog( "GetTableNameFromSQLQuery - Located Table Name \"" . $stringArray[$i] . "\" In Query" );
            return $stringArray[$i];
        }
    }
    
    return "(null)";
}

# Single Row Only
# Arguments must be: Object Hash Reference, Table Name, (Array Ref)Table Categories, (Array Ref)Table Data
sub InsertDataIntoTable
{
    my ( $self, $table, $dataNameAryRef, $dataAryRef ) = @_;
    
    my @dataName = @{ $dataNameAryRef };
    
    # Check For Data Length Issues
    $self->CheckInsertDataEntryLength( $table, $dataNameAryRef, $dataAryRef );
    
    # Check If Data Already Exists In Table and Update Instead Of Insert Data
    my $dataFound = $self->SelectDataInTable( $table, $dataNameAryRef, $dataNameAryRef, $dataAryRef );
    if( defined( $dataFound ) && $dataFound > 0 )
    {
        $self->WriteLog( "InsertDataIntoTable - Specified Data Already Exists Within Database, Cannot Insert Data - Calling Update Routine" );
        $self->UpdateDataInTable( $table, $dataNameAryRef, $dataAryRef, $dataNameAryRef, $dataAryRef );
        return;
    }
    
    # Check IdData for Incorrect Characters and Adjust Accordingly ie. "'" <= (Apostrophe Character)
    for( my $index = 0; $index < @$dataAryRef; $index++ )
    {
        ${$dataAryRef}[$index] = $self->CheckDataEntry( ${$dataAryRef}[$index] );
    }
    
    my @data = @{ $dataAryRef };
    
    $table = "(null)" if !defined ( $table );
    
    my $query = "INSERT INTO $table(";
    $query .= join( ", ", @dataName );
    $query .= ") \n     VALUES('";
    $query .= join( "', '", @data );
    $query = $query . "')";
    
    $self->WriteLog( "InsertDataIntoTable - Inserting Data Into Table \"$table\"" );
    
    if( $self->CheckIfTableExists( $table ) )
    {
        $self->ExecuteQuery( $query );
    }
    else
    {
        $self->WriteLog( "InsertDataIntoTable - Cannot Insert Data Into Table/Requested Table DNE" );
    }
}

sub SelectDataInTable
{
    my ( $self, $tableName, $idNameAryRef, $dataNameAryRef, $dataAryRef ) = @_;
    
    my @idName = @{ $idNameAryRef };
    my @dataName = @{ $dataNameAryRef };
    
    my $databaseHandle = $self->GetDatabaseHandle();
    
    # Check For Data Length Issues
    $self->CheckInsertDataEntryLength( $tableName, $dataNameAryRef, $dataAryRef );
    
    # Check IdData for Incorrect Characters and Adjust Accordingly ie. "'" <= (Apostrophe Character)
    for( my $index = 0; $index < @$dataAryRef; $index++ )
    {
        ${$dataAryRef}[$index] = $self->CheckDataEntry( ${$dataAryRef}[$index] );
    }
    
    my @data = @{ $dataAryRef };
    
    if( $self->CheckIfTableExists( $tableName ) && defined ( $databaseHandle ) )
    {
        my $query = "SELECT ";
        $query .= join( ", ", @idName );
        $query .= " FROM $tableName WHERE (";
        $query .= join( ", ", @dataName );
        $query .= ") = ('";
        $query .= join( "', '", @data );
        $query .= "')";
        
        $self->WriteLog( "SelectDataInTable - Executing Query: $query" );
        
        my $queryHandle = $self->ExecuteQuery( $query );
        
        # Check for MySQL query execution errors and rollback changes if error is found.
        if( defined ( $queryHandle ) )
        {
            my @dataAryRef = ();
            
            while( my $arrayRowRef = $queryHandle->fetchrow_arrayref() )
            {
                my @tempAry = @{ $arrayRowRef };
                push( @dataAryRef, \@tempAry );
            }
            
            $queryHandle->finish();
            return @dataAryRef;
        }
        
        return ();
    }
    
    return ();
}

sub SelectAllDataInTable
{
    my ( $self, $tableName, $idNames ) = @_;
    
    my @idNames = @{ $idNames };
    my $databaseHandle = $self->GetDatabaseHandle();
    
    if( $self->CheckIfTableExists( $tableName ) && defined ( $databaseHandle ) )
    {
        my $query = "SELECT ";
        $query .= join( ", ", @idNames );
        $query = $query . " FROM $tableName";
        
        $self->WriteLog( "SelectAllDataInTable - Executing Query: $query" );
        
        my $queryHandle = $self->ExecuteQuery( $query );
        
        # Check for MySQL query execution errors and rollback changes if error is found.
        if( defined( $queryHandle ) )
        {
            my @row = ();
            
            while( my $aryRef = $queryHandle->fetchrow_arrayref() )
            {
                my @array = @$aryRef;
                push( @row, \@array );
            }
            
            $queryHandle->finish();
            return @row;
        }
        
        return ();
    }
    
    return ();
}

# Update One Row Of MySQL Data
sub UpdateDataInTable
{
    my ( $self, $tableName, $idNamesAryRef, $idDataAryRef, $dataNameAryRef, $dataAryRef ) = @_;
    
    my @idNames = @{ $idNamesAryRef };
    my @idData = @{ $idDataAryRef };
    my @dataName = @{ $dataNameAryRef };
    my @data = @{ $dataAryRef };
    
    # Check IdData for Incorrect Characters and Adjust Accordingly ie. "'" <= (Apostrophe Character)
    for( my $index = 0; $index < @idData; $index++ )
    {
        $idData[$index] = $self->CheckDataEntry( $idData[$index] );
    }
    
    if( $self->CheckIfTableExists( $tableName ) )
    {
        my $query = "UPDATE $tableName SET ";
        
        for( my $index = 0; $index < @idNames; $index++ )
        {
            $query = $query . $idNames[$index] . " = '" . $idData[$index] . "'";
            
            if( $index < ( @idNames - 1 ) )
            {
                $query .= ", ";
            }
        }
        
        $query .= " WHERE (";
        $query .= join( ", ", @dataName );
        $query .= ") = ('";
        $query .= join( "', '", @data );
        $query .= "')";
        
        $self->WriteLog( "UpdateDataInTable - Updating Record Where (@dataName) = (@data)" );
        $self->ExecuteQuery( $query );
    }
    else
    {
        $self->WriteLog( "UpdateDataInTable - Error: Cannot Update Data In \"$tableName\"/Table DNE" );
    }
}

# Deleting One Row Of MySQL Data
sub DeleteDataFromTable
{
    my ( $self, $tableName, $columnNameAryRef, $columnDataAryRef ) = @_;
    
    my @columnName = @{ $columnNameAryRef };
    my @columnData = @{ $columnDataAryRef };
    
    if ( $self->CheckIfTableExists( $tableName ) )
    {
        my $query = "DELETE FROM $tableName WHERE (";
        $query .= join( ", ", @columnName );
        $query .= ") = ('";
        $query .= join( "', '", @columnData );
        $query .= "')";
        $self->ExecuteQuery( $query );
        $self->WriteLog( "DeleteDataFromTable - Deleting Data From Table \"$tableName\"" );
    }
    else
    {
        $self->WriteLog( "DeleteDataFromTable - Error: Cannot Delete From \"$tableName\"/Table DNE" );
    }
}

# Table Name = Passed String Arguement
sub TruncateAllTableRows
{
    my( $self, $table ) = @_;
    if ( $self->CheckIfTableExists( $table ) )
    {
        $self->ExecuteQuery( "TRUNCATE TABLE $table" );
        $self->WriteLog( "TruncateAllTableRows - Truncating All Rows From Table\"$table\"" );
    }
    else
    {
        $self->WriteLog( "TruncateAllTableRows - Cannot Truncate Row From Table\"$table\"/Table DNE" );
    }
}

# Checks MySQL Data Entry Argument For Apostrophe And Doubles The Apostrophe For
# Insertion Into MySQL Database
# Note: Use Regex Instead $strData = s/'/''/g; <= Replace Single Apostrophe With Double Apostrophe (Needs Testing)
sub CheckDataEntry
{
    my ( $self, $strData ) = @_;
    my $index = index( $strData, "'" );
    my $dIndex = index( $strData, "''" );
    my $newStr = "";
    
    # Only Replace "'" With "''" If It Is Not Already Double Commas
    if( $index != -1 && $index ne $dIndex )
    {
        my @splitStr = split( '\'', $strData );
        $newStr = join( "''", @splitStr );
    }
    
    # Return New String If Not Already "''"
    return $newStr if ( $index != -1 && $index ne $dIndex );
    
    # Return Old String If It Is Already Double Commas ("''")
    return $strData;
}

# Checks Data To Be Inserted Into MySQL Database Against Database (Length)
# Ensures Data String Length Does Not Exceed Column Precision
sub CheckInsertDataEntryLength
{
    my ( $self, $tableName, $dataNameAryRef, $dataAryRef ) = @_;
    my @dataName = @{ $dataNameAryRef };
    my @data = @{ $dataAryRef };
    
    # Create a new statement handle to fetch table information
    my $tabsth = $self->GetDatabaseHandle()->table_info( '', '', $tableName, '' ) if defined ( $self->GetDatabaseHandle() );
    
    # Check(s)
    if( !defined( $tabsth ) )
    {
        $self->WriteLog( "CheckInsertDataEntryLength - Unable To Parse Table Information / Not Connected To Database" );
        return;
    }
    
    if( @dataName ne @data )
    {
        $self->WriteLog( "CheckInsertDataEntryLength - Error: DataName and Data Arrays # Of Elements Not Equal" );
        return;
    }
    

    # Iterate through the tables...
    my ( $qual, $owner, $name, $type ) = $tabsth->fetchrow_array();
    
    # The table to fetch data for
    my $table = $name;
    
    # Build the full table name with quoting if required
    $table = qq{"$owner"."$table"} if( defined $owner && $self->GetPlatform() ne "mysql" );
    
    # The SQL statement to fetch the table metadata
    my $statement = "SELECT * FROM $table";
    
    # Prepare and execute the SQL statement
    my $sth = $self->GetDatabaseHandle()->prepare( $statement );
    $sth->execute();
    
    my $fields = $sth->{ NUM_OF_FIELDS };
    
    # Iterate through all the fields and dump the field information
    for ( my $i = 0 ; $i < $fields ; $i++ )
    {
    
        my $name = $sth->{ NAME }->[ $i ];
    
        # Describe the NULLABLE value
        my $nullable = ( "No", "Yes", "Unknown" )[ $sth->{ NULLABLE }->[ $i ] ];
        # Tidy the other values, which some drivers don't provide
        my $scale = $sth->{ SCALE }->[ $i ];
        my $prec  = $sth->{ PRECISION }->[ $i ];
        my $type  = $sth->{ TYPE }->[ $i ];
        
        for( my $index = 0; $index < @dataName; $index++ )
        {
            if( $dataName[$index] eq $name )
            {
                my $dataSize = length( $data[$index] );
                
                if( $dataSize > $prec )
                {
                    $self->WriteLog( "CheckInsertDataEntryLength - Element Data Length Exceeds Database Precision Value, Shortening String" );
                    $self->WriteLog( "                             Columns: $name, DataLength: $dataSize, MaxLength(Precision): $prec" );
                    ${$dataAryRef}[$index] = substr( ${$dataAryRef}[$index], 0, $prec-1 );
                    $self->WriteLog( "CheckInsertDataEntryLength - Specified Data Shortened To " . ( $prec-1 ) . " Characters" );
                }
            }
        }
    }
    
    # Explicitly deallocate the statement resources
    # because we didn't fetch all the data
    $sth->finish();
}

sub PrintAvailableDrivers
{
    my ( $self ) = @_;
    my @driverAry = $self->GetAvailableDrivers();
    
    $self->WriteLog( "PrintAvailableDrivers - Available Drivers (Start)" );
    
    foreach my $driver ( @driverAry )
    {
        $self->WriteLog( "PrintAvailableDrivers - $driver" );
    }
    
    $self->WriteLog( "PrintAvailableDrivers - (End)" );
}

sub PrintSchemas
{
    my ( $self ) = @_;
    my $sth = $self->GetDatabaseHandle()->table_info( '', '%', '' ) if defined ( $self->GetDatabaseHandle() );
    my $schemas = $self->GetDatabaseHandle()->selectcol_arrayref( $sth, { Columns => [2] } );
    
    $self->WriteLog( "PrintSchemas - (START OF SCHEMAS)" );
    for my $schema ( @$schemas )
    {
        $self->WriteLog( "PrintSchemas - $schema" );
    }
    $self->WriteLog( "PrintSchemas - (END OF SCHEMAS)" );
    
    $sth->finish();
}

sub PrintDatabaseInformation
{
    my ( $self ) = @_;
    
    # Create a new statement handle to fetch table information
    my $tabsth = $self->GetDatabaseHandle()->table_info() if defined ( $self->GetDatabaseHandle() );
    
    # Check(s)
    if( !defined( $tabsth ) )
    {
        $self->WriteLog( "PrintDatabaseInformation - Unable To Parse Database Information / Not Connected To Database" );
        return;
    }
    
    
    $self->WriteLog( "(START OF TABLE INFORMATION)" );

    # Iterate through all the tables...
    while ( my ( $qual, $owner, $name, $type ) = $tabsth->fetchrow_array() )
    {

        # The table to fetch data for
        my $table = $name;
        
        # Build the full table name with quoting if required
        $table = qq{"$owner"."$table"} if( defined $owner && $self->GetPlatform() ne "mysql" );
        
        # The SQL statement to fetch the table metadata
        my $statement = "SELECT * FROM $table";
        
        $self->WriteLog( "" );
        $self->WriteLog( "Table Information" );
        $self->WriteLog( "=================" );
        $self->WriteLog( "Statement:     $statement ");
        
        # Prepare and execute the SQL statement
        my $sth = $self->GetDatabaseHandle()->prepare( $statement );
        $sth->execute();
        
        my $fields = $sth->{ NUM_OF_FIELDS };
        $self->WriteLog( "NUM_OF_FIELDS: $fields" );
        
        $self->WriteLog( "Column Name                     Type  Precision  Scale  Nullable?" );
        $self->WriteLog( "------------------------------  ----  ---------  -----  ---------" );
        
        # Iterate through all the fields and dump the field information
        for ( my $i = 0 ; $i < $fields ; $i++ )
        {
        
            my $name = $sth->{ NAME }->[ $i ];
        
            # Describe the NULLABLE value
            my $nullable = ( "No", "Yes", "Unknown" )[ $sth->{ NULLABLE }->[ $i ] ];
            # Tidy the other values, which some drivers don't provide
            my $scale = $sth->{ SCALE }->[ $i ];
            my $prec  = $sth->{ PRECISION }->[ $i ];
            my $type  = $sth->{ TYPE }->[ $i ];
        
            # Display the field information
            my $result = sprintf( "%-30s %5d      %4d   %4d   %s", $name, $type, $prec, $scale, $nullable );
            $self->WriteLog( $result );
        }
        
        # Explicitly deallocate the statement resources
        # because we didn't fetch all the data
        $sth->finish();
    }
    
    $self->WriteLog( "" );
    $self->WriteLog( "(END OF TABLE INFORMATION)" );
}

sub GetDatabaseEntryCount
{
    my ( $self ) = @_;
    
    my @dataName = ( 'PublicationID' );
    my @data = ( "" );
    my @pmidAryRef = $self->SelectAllDataInTable( "publications", \@dataName );
    my $arraySize = @pmidAryRef;
    
    # Clean Up
    @pmidAryRef = ();
    undef( @pmidAryRef );
    
    return $arraySize;
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

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    return $self->{ _writeLog };
}

sub GetPlatform
{
    my ( $self ) = @_;
    $self->{ _platform } = "(null)" if !defined ( $self->{ _platform } );
    return $self->{ _platform };
}

sub GetDatabaseName
{
    my ( $self ) = @_;
    $self->{ _database } = "(null)" if !defined ( $self->{ _database } );
    return $self->{ _database };
}

sub GetDatabaseHandle
{
    my ( $self ) = @_;
    $self->{ _databaseHandle } = "(null)" if !defined ( $self->{ _databaseHandle } );
    return $self->{ _databaseHandle };
}

sub GetDatabaseSourceName
{
    my ( $self ) = @_;
    $self->{ _databaseSourceName } = "(null)" if !defined ( $self->{ _databaseSourceName } );
    return $self->{ _databaseSourceName };
}

sub GetHost
{
    my ( $self ) = @_;
    $self->{ _host } = "(null)" if !defined ( $self->{ _host } );
    return $self->{ _host };
}

sub GetPort
{
    my ( $self ) = @_;
    $self->{ _port } = "(null)" if !defined ( $self->{ _port } );
    return $self->{ _port };
}

sub GetUserID
{
    my ( $self ) = @_;
    $self->{ _userID } = "(null)" if !defined ( $self->{ _userID } );
    return $self->{ _userID };
}

sub GetPassword
{
    my ( $self ) = @_;
    $self->{ _password } = "(null)" if !defined ( $self->{ _password } );
    return $self->{ _password };
}

sub GetAvailableDrivers
{
    return DBI->available_drivers();      # Returns array of strings
}

sub GetInstalledDrivers
{
    return DBI->installed_drivers();        # Returns hash of installed drivers
}

sub GetDatabaseTables
{
    my ( $self ) = @_;
    return $self->{ _databaseHandle }->tables() if defined ( $self->{ _databaseHandle } );          # Returns array of database table strings
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = "(null)" if !defined ( $self->{ _fileHandle } );
    return $self->{ _fileHandle };
}


######################################################################################
#    Mutators
######################################################################################

sub SetDatabaseSourceName
{
    my ( $self, $temp ) = @_;
    return $self->{ _databaseSourceName } = $temp;
}

sub SetDatabaseHandle
{
    my ( $self, $temp ) = @_;
    return $self->{ _databaseHandle } = $temp;
}

sub SetPlatform
{
    my ( $self, $temp ) = @_;
    return $self->{ _platform } = $temp;
}

sub SetDatabaseName
{
    my ( $self, $temp ) = @_;
    return $self->{ _database } = $temp;
}

sub SetHost
{
    my ( $self, $temp ) = @_;
    return $self->{ _host } = $temp;
}

sub SetPort
{
    my ( $self, $temp ) = @_;
    return $self->{ _port } = $temp;
}

sub SetUserID
{
    my ( $self, $temp ) = @_;
    return $self->{ _userID } = $temp;
}

sub SetPassword
{
    my ( $self, $temp ) = @_;
    return $self->{ _password } = $temp;
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
        if( ref ( $string ) eq "DatabaseCom" )
        {
            print( GetDate() . " " . GetTime() . " - DatabaseCom: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - DatabaseCom::$string";
        print "\n" if( $printNewLine != 0 );
    }
    
    if( $self->GetWriteLog() )
    {
        if( ref ( $string ) eq "DatabaseCom" )
        {
            print( GetDate() . " " . GetTime() . " - DatabaseCom: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }
        
        my $fileHandle = $self->GetFileHandle();
        
        if( $fileHandle ne "(null)" )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - DatabaseCom::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}


#################### All Modules Are To Output "1"(True) at EOF ######################
1;



=head1 NAME

DatabaseCom - FiND MySQL Database Communication Module

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