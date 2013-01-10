#!/bin/sh

generate_valid_lines_test() {
	local package_name=$1
	local name=$(echo "$package_name" | tr [:upper:] [:lower:])
	local path="$(pwd)/tests/unit/sources"
	mkdir -p $path
    cat > "${path}/${name}_valid_lines.t" <<EOF
my \$test = ${package_name}::Source->new('dist/${name}_mappings_source.csv');
\$test->run_tests();
exit;


package ${package_name}::Source;
use base 'SourcesTest';

use v5.10;
use strict;
use warnings;
use Test::More;


sub test {
    my \$self = shift;
    \$self->test_source_line(@_);
}

EOF

}

generate_regression_test() {
	local package_name=$1
	local name=$(echo "$package_name" | tr [:upper:] [:lower:])
	local path="$(pwd)/tests/regression/"
	mkdir -p $path
	cat > "${path}/${name}.t" <<EOF
my \$test = ${package_name}::Finalised->new();
\$test->input_file("dist/${name}_mappings_source.csv");
\$test->output_file("dist/${name}_all_tested.csv");
\$test->output_error_file("dist/${name}_errors.csv");
\$test->output_redirects_file("dist/${name}_redirects_chased.csv");
\$test->run_tests();
exit;


package ${package_name}::Finalised;
use base 'IntegrationTest';

use v5.10;
use strict;
use warnings;
use Test::More;


sub test {
    my \$self = shift;
    
    my ( \$passed, 
    	\$response, 
    	\$redirected_response, 
    	\$chased_redirects ) = \$self->test_closed_gones(@_);

    #i.e. it is not a 410
    if ( -1 == \$passed ) { 
    	( \$passed, 
    	\$response, 
    	\$redirected_response, 
    	\$chased_redirects ) = \$self->test_finalised_redirects(@_);
    }

    return ( \$passed, 
    	\$response, 
    	\$redirected_response, 
    	\$chased_redirects ); 
}

EOF

}