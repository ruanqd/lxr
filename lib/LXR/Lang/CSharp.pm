# -*- tab-width: 4 -*-
###############################################
#
# Enhances the support for the C# language over that provided by
# Generic.pm
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
###############################################

package LXR::Lang::CSharp;

use strict;
use LXR::Common;
use LXR::Lang;
require LXR::Lang::Generic;

@LXR::Lang::CSharp::ISA = ('LXR::Lang::Generic');

# Only override the include handling.  For C#, this is really package
# handling, as there is no include mechanism, so deals with "package"
# and "import" keywords
sub processinclude {
	my ($self, $frag, $dir) = @_;

	my $source = $$frag;
	my $dirname;	# directive name and spacing
	my $file;		# language path
	my $path;		# OS file path
	my $link;		# link to file
	my $class;		# C# class

	# Deal with package declaration of the form
	# "namespace Company.fubar"
	if ($source =~ s/^
				(namespace\s+)
				([\w.]+)	# package 'path'
				//sx) {
		$dirname = $1;
		$file    = $2;
		$path    = $file;
		$path =~ s@\.@/@g;		# Replace C# delimiters
		$link = $self->_linkincludedirs
					( &LXR::Lang::incdirref
						($file, "include", $path, $dir)
					, $file
					, '.'
					, $path
					, $dir
					);
	}

	# Deal with import declaration of the form
	# - "using System.*" by providing link to the package
	# - "using System.Runtime.classname" by providing links to the
	#		package and the class
	elsif ($source =~ s/^
				(using\s+(?:static\s+)?)
				([\w.]+)	# package 'path'
				\.(\*|\w+)	# class or *
				//sx) {
		$dirname = $1;
		$file    = $2;
		$path    = $file;
		$class   = $3;
		$path =~ s@\.@/@g;		# Replace C# delimiters
		$link = $self->_linkincludedirs
					( &LXR::Lang::incdirref
							($file, "include", $path, $dir)
					, $file
					, '.'
					, $path
					, $dir
					)
			.	'.'
			.	( $index->issymbol($class, $releaseid)
				? join($class, @{$$self{'itag'}})
				: $class
				);

	} else {
		# Guard against syntax error or variant
		# Advance past keyword, so that parsing may continue without loop.
		$source =~ s/^([\w]+)//;	# Erase keyword
		$dirname = $1;
		$link = '';
	}

	# As a goodie, rescan the tail of package/import for C# code
	&LXR::SimpleParse::requeuefrag($source);

	# Assemble the highlighted bits
	$$frag =	"<span class='reserved'>$dirname</span>"
			.	$link;
}

1;
