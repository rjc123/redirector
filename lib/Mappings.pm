package Mappings;

use strict;
use warnings;

use Mappings::Rules;
use Text::CSV;
use URI::Split  qw( uri_split uri_join );



sub new {
    my $class    = shift;
    my $csv_file = shift;
    
    my $self = {};
    bless $self, $class;
    
    $self->{'csv'} = Text::CSV->new({ binary => 1 });
    open $self->{'csv_handle'}, '<:encoding(utf8)', $csv_file
        or return undef;
    
    $self->{'column_names'} = $self->read_column_names();
    return unless scalar @{$self->{'column_names'}};
    return unless $self->has_mandatory_columns();
    
    return $self;
}

sub entire_csv_as_nginx_config {
    my $self = shift;
    
    my %configs;
    my %check_for_dupes;
    
    while ( my $row = $self->get_row() ) {
        my( $host, $map, $line ) = $self->row_as_nginx_config($row);
        
        if ( defined $host && defined $map && defined $line ) {
            # check for first type of duplicate -- the same URL twice
            my $location_duplicate_key = $row->{'Old Url'};
            if ( !defined $check_for_dupes{$location_duplicate_key} ) {
                $check_for_dupes{$location_duplicate_key} = 1;
                
                my $duplicate_mapping_key = sprintf '%s:%s:%s', $host, $map, $line;
                
                if ( !defined $check_for_dupes{$duplicate_mapping_key} ) {
                    $check_for_dupes{$duplicate_mapping_key} = 1;
                }
                else {
                    $map = 'duplicate_entry_error';
                    $line = $row->{'Old Url'} . "\n";
                }
            }
            else {
                $map = 'duplicate_entry_error';
                $line = $row->{'Old Url'} . "\n";
            }
            
            $configs{$host}{$map} = []
                unless defined $configs{$host};
            push @{ $configs{$host}{$map} }, $line;
        }
    }
    
    foreach my $host ( keys %configs ) {
        foreach my $map ( keys %{ $configs{$host} } ) {
            if ( 'location' eq $map ) {
                # locations need to be sorted for b-tree insert efficiency
                $configs{$host}{$map} = join '', sort @{ $configs{$host}{$map} };
            }
            else {
                $configs{$host}{$map} = join '', @{ $configs{$host}{$map} };
            }
        }
    }
    
    return \%configs;
}
sub row_as_nginx_config {
    my $self = shift;
    my $row  = shift; 
    
    my $rules = Mappings::Rules->new( $row );
    return unless defined $rules;
    return $rules->as_nginx_config();
}


sub get_row {
    my $self = shift;
    return $self->{'csv'}->getline_hr( $self->{'csv_handle'} );
}

sub read_column_names {
    my $self = shift;
    
    my $names = $self->{'csv'}->getline( $self->{'csv_handle'} );
    return unless scalar @$names;
    
    $self->{'csv'}->column_names( @$names );
    return $names;
}
sub has_mandatory_columns {
    my $self = shift;
    
    my $has_status  = 0;
    my $has_old_url = 0;
    my $has_new_url = 0;
    foreach my $col ( @{$self->{'column_names'}} ) {
        $has_status  = 1 if 'Status'  eq $col;
        $has_old_url = 1 if 'Old Url' eq $col;
        $has_new_url = 1 if 'New Url' eq $col;
    }
    
    return 1 if $has_status && $has_old_url && $has_new_url;
    return 0;
}

1;
