#  This file is part of OpenSearchServer PERL Client.
#
#  Copyright (C) 2013 Emmanuel Keller / Jaeksoft
#
#  http://www.open-search-server.com
#
#  OpenSearchServer PERL Client is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  OpenSearchServer PERL Client is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with OpenSearchServer PERL Client.  If not, see <http://www.gnu.org/licenses/>.
# 
package OpenSearchServer;

use strict;
use warnings;

our $VERSION = '1.00';

use base 'Exporter';

our @EXPORT = qw( 
	search search_num_found
	search_max_score
	search_documents_returned
	search_document_field
	search_document_snippet
	search_document_score
	search_get_facet_number
	search_get_facet_term
	search_get_facet_count
);

use REST::Client;
use JSON;
use URI::Escape;
use Data::Dumper;

#
sub search {
	my $server = shift;
	my $login = shift;
	my $apikey = shift;
	my $index = shift;
	my $template = shift;
	my $query = shift;
	my $start = shift;
	my $rows = shift;
	my $lang = shift;

	if (not defined $server) {
		warn 'The server URL is required';
		return;
	}	
	if (not defined $index) {
		warn 'The index name is required';
		return;
	}	
	my $request = $server.'/services/rest/select/search/'.uri_escape($index).'/json?';
	if (defined $login) {
		$request.='login='.uri_escape($login).'&';
	}
	if (defined $apikey) {
		$request.='key='.uri_escape($apikey).'&';
	}
	if (defined $template) {
		$request.='template='.uri_escape($template).'&';
	}
	if (defined $query) {
		$request.='query='.uri_escape($query).'&';
	}
	if (defined $start) {
		$request.='start='.uri_escape($start).'&';
	}
	if (defined $rows) {
		$request.='rows='.uri_escape($rows).'&';
	}
	if (defined $lang) {
		$request.='lang='.uri_escape($lang).'&';
	}
		
    my $client = REST::Client->new();
    $client->GET($request);
   	if ($client->responseCode() ne '200') {
		warn 'Wrong HTTP response code: '.$client->responseCode();
		return;
	}
    return JSON::decode_json($client->responseContent());
}

# Returns the number of document found
sub search_num_found {
	my $json = shift;
	return $json->{'result'}->{'@numFound'};
}

sub search_max_score {
	my $json = shift;
	return $json->{'result'}->{'@maxScore'};
}

sub search_documents_returned {
	my $json = shift;
	my $documents = $json->{'result'}->{'document'};
	return @$documents; 
}

# Returns the named field of one document
sub search_document_field {
	my $json = shift;
	my $pos = shift;
	my $field_name = shift;
	my $fields = $json->{'result'}->{'document'}->[$pos]->{'field'};
	# Loop over fields
	for my $field (@$fields) {
		if ($field_name eq $field->{'name'}) {
			return $field->{'value'};
		}
	}
}

# Returns the named snippet of one document
sub search_document_snippet {
	my $json = shift;
	my $pos = shift;
	my $field_name = shift;
	my $snippets = $json->{'result'}->{'document'}->[$pos]->{'snippet'};
	# Loop over snippets
	for my $snippet (@$snippets) {
		if ($field_name eq $snippet->{'name'}) {
			return $snippet->{'value'};
		}
	}
}

# Returns the score of the document at the given position
sub search_document_score {
	my $json = shift;
	my $pos = shift;
	return $json->{'result'}->{'document'}->[$pos]->{'@score'};
}


# Returns the facet hash relate to a field name
sub search_get_facet {
	my $json = shift;
	my $field_name = shift;
	my $facets = $json->{'result'}->{'facet'};
	for my $facet (@$facets) {
		if ($field_name eq $facet->{'fieldName'}) {
			return $facet;
		}
	}
	return undef;
}

# Returns the number of terms for a facet
sub search_get_facet_number {
	my $facet = search_get_facet(@_);
	if (!defined($facet)) {
		return 0;
	}
	my $term_array = $facet->{'terms'};
	return @$term_array;
}


# Returns the term of one facet array at a given position
sub search_get_facet_term {
	my $facet = search_get_facet(@_);
	if (!defined($facet)) {
		return 0;
	}
	my $json = shift;
	my $field_name = shift;
	my $pos = shift;
	return $facet->{'terms'}->[$pos]->{'term'};
}

# Returns the number of document for one facet term at a given position
sub search_get_facet_count {
	my $facet = search_get_facet(@_);
	if (!defined($facet)) {
		return 0;
	}
	my $json = shift;
	my $field_name = shift;
	my $pos = shift;
	return $facet->{'terms'}->[$pos]->{'count'};
}

1;
