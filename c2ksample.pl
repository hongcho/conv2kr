#!/usr/local/bin/perl -w
######################################################################
#
# c2ksample.pl - A sample program for conv2kr.pm.
# Copyright (C) 2009 Younghong "Hong" Cho <hongcho at sori dot org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#*********************************************************************
#
# == History
# 2009-06-26 Created.
######################################################################

use strict;
use lib '.';
use conv2kr;

######################################################################
# Constants.

my $ICONV = "/usr/local/bin/iconv";
my $TMP_PREFIX = "/tmp/temp.r2k.";

######################################################################

# Initialize the library environment.
conv2kr::configure($ICONV, $TMP_PREFIX);

# Input string in EUC-KR, which is the most common Korean character
# set encoding.
my $str_i = '맑은 하늘 아래 떠있는 독도';
print("EUC-KR Input\t: $str_i\n");

# Convert the EUC-KR string to Johab first.
my $str_j = conv2kr::euckr2Johab($str_i);
print("Johab Input\t: $str_j\n");

# Convert the Johab input string to "MCT".
# This is where the actual rules are applied.
my $str_r = conv2kr::johab2Mct($str_j);
print("MCT result\t: $str_r\n");

# Convert the "MCT" result string back to Johab.
my ($str_n, $str_n2) = conv2kr::mct2Johab($str_r, 1);
print("Johab result\t: $str_n\n");
print("Johab result2\t: $str_n2\n");

# Convert the Johab result string to HTML Unicode.
my $str_h = conv2kr::johab2Html($str_n);
print("HTML result\t: $str_h\n");

######################################################################
# End.
exit(0);
######################################################################
