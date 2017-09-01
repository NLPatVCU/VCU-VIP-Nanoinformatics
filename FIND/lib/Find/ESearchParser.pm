#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/26/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - PubMed ESearch Parser Module    #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 eSearch XML Parser - Used for parsing large data-sets              #
#                                                                                    #
######################################################################################

Note: #REMOVEME Tag indicates possibly unrequired functions/code



use strict;
use warnings;

# CPAN Dependencies
use XML::Twig;




package Find::ESearchParser;




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
        _debugLog => shift,                             # Boolean (Binary): 0 = False, 1 = True
        _xmlParseStr => shift,                          # String
        _twigHandler => shift,                          # File Handle
        _count => shift,                                # Int
        _retMax => shift,                               # Int
        _retStart => shift,                             # Int
        _queryKey => shift,                             # String
        _webEnv => shift,                               # String
        _idList => shift,                               # Array
    };
    
    # Set variables to default values
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _xmlParseStr } = "(null)" if !defined ( $self->{ _xmlParseStr } );
    $self->{ _twigHandler } = "(null)" if !defined ( $self->{ _twigHandler } );
    $self->{ _count } = -1 if !defined ( $self->{ _count } );
    $self->{ _retMax } = -1 if !defined ( $self->{ _retMax } );
    $self->{ _retStart } = -1 if !defined ( $self->{ _retStart } );
    $self->{ _queryKey } = "(null)" if !defined ( $self->{ _queryKey } );
    $self->{ _webEnv } = "(null)" if !defined ( $self->{ _webEnv } );
    @{ $self->{ _idList } } = () if @{ $self->{ _idList } } == 0;

    
    $self->{ _twigHandler } = XML::Twig->new(
        twig_handlers => { 'eSearchResult' => sub { ParseESearchXML( @_, $self ) } },
    );
    
    
    bless $self, $class;
    
    if( $self->{ _xmlParseStr } ne "(null)" )
    {
        #REMOVEME RemoveXMLVersion( \$_xmlParseStr );
        
        if( $self->CheckForNullData( $self->{ _xmlParseStr } ) )
        {
            $self->WriteLog( "New - Error: XML String is null" );
        }
        else
        {
            $self->{ _twigHandler }->parse( $self->{ _xmlParseStr } );
        }
    }
    else
    {
        $self->WriteLog( "New - No XML String Argument To Parse" );
    }
    
    $self->WriteLog( "New: Debug On" );
    
    return $self;
}


######################################################################################
#    Module Functions
######################################################################################

sub ParseXMLString
{
    my ( $self, $string ) = @_;
    $string = "" if !defined ( $string );
    #REMOVEME RemoveXMLVersion( \$string );
    
    if( $self->CheckForNullData( $string ) )
    {
        $self->WriteLog( "ParseXMLString - Cannot Parse (null) string" );
    }
    else
    {
        $self->GetTwigHandler()->parse( $string );
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
        return 1;
    }
    
    # Return False
    return 0;
}

# Removes the XML Version string prior to parsing the XML string
sub RemoveXMLVersion
{
    my ( $self, $temp ) = @_;
    
    # Checking For XML Version
    my $xmlVersion = '<?xml version="1.0" encoding="UTF-8"?>';

    if( my $n = index( ${$temp}, $xmlVersion ) != -1 )
    {
        substr( ${$temp}, $n, length( $xmlVersion ) ) = "";
    }
    
    return $temp;
}

sub ParseESearchXML
{
    my ( $twigSelf, $temp, $self ) = @_;
    
    if( defined ( $temp ) )
    {
        my $root = $temp->root();
        my @children = $root->children();
        
        foreach my $child ( @children )
        {
            $self->WriteLog( "ParseESearchXML: " . $child->tag() . ", Field: " . $child->field() );
            
            if( $child->tag() eq "Count" )
            {
                $self->SetCount( $child->field() );
            }
            elsif( $child->tag() eq "RetMax" )
            {
                $self->SetRetMax( $child->field() );
            }
            elsif( $child->tag() eq "RetStart" )
            {
                $self->SetRetStart( $child->field() );
            }
            elsif( $child->tag() eq "QueryKey" )
            {
                $self->SetQueryKey( $child->field() );
            }
            elsif( $child->tag() eq "WebEnv" )
            {
                $self->SetWebEnv( $child->field() );
            }
            elsif( $child->tag() eq "IdList" )
            {
                ;       #DO SOMETHING
            }
            elsif( $child->tag() eq "TranslationSet" )
            {
                ;       #DO SOMETHING
            }
            elsif( $child->tag() eq "TranslationStack" )
            {
                ;       #DO SOMETHING
            }
            elsif( $child->tag() eq "QueryTranslation" )
            {
                ;       #DO SOMETHING
            }
        }
    }
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

sub GetXMLParseStr
{
    my ( $self ) = @_;
    $self->{ _xmlParseStr } = "(null)" if !defined ( $self->{ _xmlParseStr } );
    return $self->{ _xmlParseStr };
}

sub GetTwigHandler
{
    my ( $self ) = @_;
    $self->{ _twigHandler } = "(null)" if !defined ( $self->{ _twigHandler } );
    return $self->{ _twigHandler };
}

sub GetCount
{
    my ( $self ) = @_;
    $self->{ _count } = -1 if !defined ( $self->{ _count } );
    return $self->{ _count };
}

sub GetRetMax
{
    my ( $self ) = @_;
    $self->{ _retMax } = -1 if !defined ( $self->{ _retMax } );
    return $self->{ _retMax };
}

sub GetRetStart
{
    my ( $self ) = @_;
    $self->{ _retStart } = -1 if !defined ( $self->{ _retStart } );
    return $self->{ _retStart };
}

sub GetQueryKey
{
    my ( $self ) = @_;
    $self->{ _queryKey } = -1 if !defined ( $self->{ _queryKey } );
    return $self->{ _queryKey };
}

sub GetWebEnv
{
    my ( $self ) = @_;
    $self->{ _webEnv } = "(null)" if !defined ( $self->{ _webEnv } );
    return $self->{ _webEnv };
}


######################################################################################
#    Mutators
######################################################################################

sub SetXMLParseStr
{
    my ( $self, $temp ) = @_;
    return $self->{ _xmlParseStr } = $temp if defined ( $temp );
}

sub SetCount
{
    my ( $self, $temp ) = @_;
    return $self->{ _count } = $temp if defined ( $temp );
}

sub SetRetMax
{
    my ( $self, $temp ) = @_;
    return $self->{ _retMax } = $temp if defined ( $temp );
}

sub SetRetStart
{
    my ( $self, $temp ) = @_;
    return $self->{ _retStart } = $temp if defined ( $temp );
}

sub SetQueryKey
{
    my ( $self, $temp ) = @_;
    return $self->{ _queryKey } = $temp if defined ( $temp );
}

sub SetWebEnv
{
    my ( $self, $temp ) = @_;
    return $self->{ _webEnv } = $temp if defined ( $temp );
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
    
    if( $self->GetDebugLog() )
    {
        my $string = shift;
        my $printNewLine = shift;
        
        return if !defined ( $string );
        $printNewLine = 1 if !defined ( $printNewLine );
        
        if( ref ( $string ) eq "ESearchParser" )
        {
            print( GetDate() . " " . GetTime() . " - ESearchParser: Cannot Call WriteLog() From Outside Module!\n" );
            
        }
        else
        {
            $string = "" if !defined ( $string );
            print GetDate() . " " . GetTime() . " - ESearchParser::" . $string;
            print "\n" if( $printNewLine != 0 );
        }
    }
}


#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND PubMed ESearch Parser Module

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