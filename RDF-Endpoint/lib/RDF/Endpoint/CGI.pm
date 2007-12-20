package RDF::Endpoint::CGI;

use strict;
use warnings;

use CGI;
use RDF::Endpoint;

sub new {
	my $class		= shift;
	my %args		= @_;
	
	my $dsn			= $args{ DBServer };
	my $user		= $args{ DBUser };
	my $pass		= $args{ DBPass };
	my $model		= $args{ Model };
	my $prefix		= $args{ Prefix };
	my $incpath		= $args{ IncludePath };
	my $cgi			= $args{ CGI };
	
	my $host	= $cgi->server_name;
	my $port	= $cgi->server_port;
	my $hostname	= ($port == 80) ? $host : join(':', $host, $port);
	my $self		= bless({}, $class);
	my $endpoint	= RDF::Endpoint->new(
						$model,
						$dsn,
						$user,
						$pass,
						IncludePath => $incpath,
						SubmitURL	=> "http://${hostname}" . $cgi->url( -absolute => 1 ),
						AdminURL	=> "http://${hostname}" . join('?', $cgi->url( -absolute => 1 ), 'admin=1'),
					);
	$endpoint->init();
	$self->{endpoint}	= $endpoint;
	$self->{prefix}		= $prefix || '';
	return $self;
}

sub run {
	my $self	= shift;
	my $cgi		= shift;
	my $endpoint	= $self->{endpoint};
	binmode( \*STDOUT, ':utf8' );
	
	my $url		= $cgi->url( -absolute => 1 );
	my $prefix	= $self->prefix;
	my $path	= $url;
	$path		=~ s/$prefix//;
	
	no warnings 'uninitialized';
	my $host	= $cgi->server_name;
	my $port	= $cgi->server_port;
	if (my $sparql = $cgi->param('query')) {
		$endpoint->run_query( $cgi, $sparql );
	} elsif (my $q = $cgi->param('queryname')) {
		my $query	= $endpoint->run_saved_query( $cgi, $q );
	} elsif ($cgi->param('admin')) {
		if ($cgi->param('submit')) {
			$endpoint->handle_admin_post( $cgi, $host, $port, $prefix );
		} else {
			$endpoint->admin_index( $cgi, $prefix );
		}
	} else {
		$endpoint->query_page( $cgi, $prefix );
	}
}

sub prefix {
	my $self	= shift;
	return $self->{prefix};
}

sub error {
	my $self	= shift;
	my $cgi		= shift;
	my $code	= shift;
	my $name	= shift;
	my $error	= shift;
	print $cgi->header( -status => "${code} ${name}" );
	print "<html><head><title>${name}</title></head><body><h1>${name}</h1><p>${error}</p></body></html>";
	return;
}

sub redir {
	my $self	= shift;
	my $cgi		= shift;
	my $code	= shift;
	my $message	= shift;
	my $url		= shift;
	print $cgi->header( -status => "${code} ${message}", -Location => $url );
	return;
}

1;

__END__
