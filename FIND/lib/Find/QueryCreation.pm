#!/usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    11/22/2015                                                             #
#    Revised: 04/25/2017                                                             #
#    Part of CMSC 451 - Data Mining Nanotechnology - PubMed Query Creation Module    #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#                 WRITE DESCRIPTION HERE                                             #
#                                                                                    #
######################################################################################





use strict;
use warnings;




package Find::QueryCreation;




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
        _debugLog => shift,                     # Boolean (Binary): 0 = False, 1 = True
    };
    
    # Set debug log variable to false if not defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    
    WriteLog( "New: Debug On" );
    
    bless $self, $class;
    return $self;
}
######################################################################################
#    Module Functions
######################################################################################



######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    return $self->{ _debugLog };
}
######################################################################################
#    Mutators
######################################################################################

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
        
        if( ref ( $string ) eq "QueryCreation" )
        {
            print( GetDate() . " " . GetTime() . " - QueryCreation: Cannot Call WriteLog() From Outside Module!\n" );
            
        }
        else
        {
            $string = "" if !defined ( $string );
            print GetDate() . " " . GetTime() . " - QueryCreation::" . $string;
            print "\n" if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

DatabaseCom - FiND PubMed Query Creation Module

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