######################################################################
#
# conv2kr.pm - Korean transliteration Perl library.
# Copyright (C) 2005-2009 Younghong "Hong" Cho <hongchoatsoridotorg>
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
# This library uses an external tool "iconv" to convert the Korean
# string into "Johab" so that it can be easily parsed.
#
# == References
# http://www.korean.go.kr/08_new/data/rule02.jsp
#
# == History
# 2005-08-30 Started out as conv2kr.cgi
# 2009-05-28 Created from conv2kr.cgi
######################################################################

package conv2kr;
use strict;

######################################################################
########## EXPORTED NAMES
######################################################################

our @EXPORT = qw(configure
                 euckr2Johab
                 johab2Mct
                 mct2Johab
                 jamo2Johab
                 johab2Jamo
                 johab2Html
                 trimString
                 convertQueryString
                 escapeHtmlText);

######################################################################
########## VARIABLES AND TABLES
######################################################################

######################################################################
# Environments.

# Set up using "configure".
my $ICONV = "/usr/local/bin/iconv";
my $TMP_FILE = "/tmp/temp.r2k." . $$;

# Don't change.
my $ICONV_OPT = "-c -s";

######################################################################
# Conversion tables (MCT to JOHAB).

my %R2K_J0 = (0  => 1,  G  => 2,  KK => 3,  N  => 4,  D  => 5,  DH => 5,
              TT => 6,  R  => 7,  L  => 7,  M  => 8,  B  => 9,  V  => 9,
              BH => 9,  PP => 10, S  => 11, SH => 11, C  => 11, X  => 11,
              SS => 12, O  => 13, J  => 14, Z  => 14, JJ => 15, CH => 16,
              K  => 17, Q  => 17, T  => 18, P  => 19, F  => 19, PH => 19,
              H  => 20);
my %R2K_J1 = (0   => 2,  A   => 3,  AE  => 4,  YA  => 5,  YAE => 6,
              EO  => 7,  E   => 10, YEO => 11, YE  => 12, O   => 13,
              WA  => 14, WAE => 15, OE  => 18, YO  => 19, U   => 20,
              OO  => 20, WO  => 21, WE  => 22, WI  => 23, YU  => 26,
              EU  => 27, UI  => 28, EUI => 28, I   => 29, Y   => 29,
              YI  => 29, EE  => 29);
my %R2K_J2 = (0  => 1,  K  => 2,  C  => 2,  X  => 2,  T  => 8, N  => 5,
              L  => 9,  M  => 17, P  => 19, NG => 23);

my $JS0_2 = "KK|TT|PP|SS|JJ|CH|PH|SH|DH|BH";
my $JS0_1 = "G|N|D|R|L|M|B|V|S|C|X|J|Z|K|Q|T|P|F|H";
my $JS0   = "$JS0_2|$JS0_1";
my $JS1_Y = "YAE|YEO|YOO|YA|YE|YO|YU|YI|I|Y";
my $JS1_3 = "YAE|YEO|YOO|WAE|WOO|EUI";
my $JS1_2 = "AE|YA|EO|YE|WA|OE|YO|WO|WE|WI|WU|OO|YU|EU|UI|YI|EE";
my $JS1_1 = "A|E|O|U|I|Y";
my $JS1   = "$JS1_3|$JS1_2|$JS1_1";
my $JS2_2 = "NG|TR|PH|CH|SH|DH|BH";
my $JS2_1 = "K|C|X|T|N|L|M|P|R|H";

######################################################################
# Conversion tables (Jamo to JOHAB).

my %J2K_J0 = ('0'  => 1,  'G'  => 2,  'KK' => 3,  'N'  => 4,  'D'  => 5,
              'TT' => 6,  'R'  => 7,  'L'  => 7,  'M'  => 8,  'B'  => 9,
              'PP' => 10, 'S'  => 11, 'SS' => 12, 'O'  => 13, 'J'  => 14,
              'JJ' => 15, 'CH' => 16, 'K'  => 17, 'T'  => 18, 'P'  => 19,
              'H'  => 20);
my %J2K_J1 = ('0'  => 2,  'A'   => 3,  'AE'  => 4,  'YA' => 5,  'YAE' => 6,
              'EO' => 7,  'E'   => 10, 'YEO' => 11, 'YE' => 12, 'O'   => 13,
              'WA' => 14, 'WAE' => 15, 'OE'  => 18, 'YO' => 19, 'U'   => 20,
              'WO' => 21, 'WE'  => 22, 'WI'  => 23, 'YU' => 26, 'EU'  => 27,
              'UI' => 28, 'EUI' => 28, 'I'   => 29);
my %J2K_J2 = ('0'  => 1,  'G'  => 2,  'KK' => 3,  'GS' => 4,  'N'  => 5,
              'NJ' => 6,  'NH' => 7,  'D'  => 8,  'L'  => 9,  'R'  => 9,
              'LG' => 10, 'LM' => 11, 'LB' => 12, 'LS' => 13, 'LT' => 14,
              'LP' => 15, 'LH' => 16, 'M'  => 17, 'B'  => 19, 'BS' => 20,
              'S'  => 21, 'SS' => 22, 'NG' => 23, 'J'  => 24, 'CH' => 25,
              'K'  => 26, 'T'  => 27, 'P'  => 28, 'H'  => 29);

my $JK0_2 = 'KK|TT|PP|SS|JJ|CH';
my $JK0_1 = 'G|N|D|R|L|M|B|S|J|K|T|P|H';
my $JK0 = "$JK0_2|$JK0_1";
my $JK1_3 = 'YAE|YEO|WAE|EUI';
my $JK1_2 = 'AE|YA|EO|YE|WA|OE|YO|WO|WE|WI|YU|EU|UI';
my $JK1_1 = 'A|E|O|U|I';
my $JK1 = "$JK1_3|$JK1_2|$JK1_1";
my $JK2_2 = 'KK|GS|NJ|NH|LG|LM|LB|LS|LT|LP|LH|BS|SS|NG|CH';
my $JK2_1 = 'G|N|D|L|R|M|B|S|J|K|T|P|H';
my $JK2 = "$JK2_2|$JK2_1";

######################################################################
# Conversion tables (JOHAB to Jamo).

my %K2J_J0 = (2  => 'g',  3  => 'kk', 4  => 'n',  5  => 'd',  6  => 'tt',
              7  => 'r',  8  => 'm',  9  => 'b',  10 => 'pp', 11 => 's',
              12 => 'ss', 14 => 'j',  15 => 'jj', 16 => 'ch', 17 => 'k',
              18 => 't',  19 => 'p',  20 => 'h');
my %K2J_J1 = (3  => 'a',   4  => 'ae',  5  => 'ya', 6  => 'yae', 7  => 'eo',
              10 => 'e',   11 => 'yeo', 12 => 'ye', 13 => 'o',   14 => 'wa',
              15 => 'wae', 18 => 'oe',  19 => 'yo', 20 => 'u',   21 => 'wo',
              22 => 'we',  23 => 'wi',  26 => 'yu', 27 => 'eu',  28 => 'ui',
              29 => 'i');
my %K2J_J2 = (2  => 'g',  3  => 'kk', 4  => 'gs', 5  => 'n',  6  => 'nj',
              7  => 'nh', 8  => 'd',  9  => 'l',  10 => 'lg', 11 => 'lm',
              12 => 'lb', 13 => 'ls', 14 => 'lt', 15 => 'lp', 16 => 'lh',
              17 => 'm',  19 => 'b',  20 => 'bs', 21 => 's',  22 => 'ss',
              23 => 'ng', 24 => 'j',  25 => 'ch', 26 => 'k',  27 => 't',
              28 => 'p',  29 => 'h');

my $KJ0_NM = "n|m";
my $KJ0_RL = "r|l";
my $KJ0_X5 = "g|d|b|s|j";
my $KJ0_X4 = "g|d|s|j";
my $KJ1_Y = "yae|yeo|ya|ye|yo|yu|i";

my %KJ2_RH = ('g'  => \&applyPRule2G,  'kk' => \&applyPRule2KK,
              'gs' => \&applyPRule2GS, 'n'  => \&applyPRule2N,
              'nj' => \&applyPRule2NJ, 'nh' => \&applyPRule2NH,
              'd'  => \&applyPRule2D,  'l'  => \&applyPRule2L,
              'lg' => \&applyPRule2LG, 'lm' => \&applyPRule2LM,
              'lb' => \&applyPRule2LB, 'ls' => \&applyPRule2LS,
              'lt' => \&applyPRule2LT, 'lp' => \&applyPRule2LP,
              'lh' => \&applyPRule2LH, 'm'  => \&applyPRule2M,
              'b'  => \&applyPRule2B,  'bs' => \&applyPRule2BS,
              's'  => \&applyPRule2S,  'ss' => \&applyPRule2SS,
              'ng' => \&applyPRule2NG, 'j'  => \&applyPRule2J,
              'ch' => \&applyPRule2CH, 'k'  => \&applyPRule2K,
              't'  => \&applyPRule2T,  'p'  => \&applyPRule2P,
              'h'  => \&applyPRule2H);


######################################################################
########## EXPOSED / PUBLIC SUBROUTINES
######################################################################

######################################################################
# Configure the environment.
# - $iconv_path: where to find the external program, "iconv".
# - $tmp_prefix: prefix for the temp file used by "iconv".
# + Nothing returned.
sub configure
{
    my ($iconv_path, $tmp_prefix) = @_;
    $ICONV = $iconv_path;
    $TMP_FILE = $tmp_prefix . $$;
}

######################################################################
# EUC-KR to Johab.
# - $str: EUC-KR string.
# + Johab string.
sub euckr2Johab
{
    my ($str) = @_;
    my $iconv_opt = "$ICONV_OPT -f EUC-KR -t JOHAB";

    # Create a temporary file.
    open(FD_TMP, ">$TMP_FILE") or die("Cannot create a temporary file");
    print(FD_TMP $str);
    close(FD_TMP);

    # Use iconv to convert the text.
    open(FD_CMD, "$ICONV $iconv_opt $TMP_FILE|")
        or die("Cannot execute $ICONV");
    $str = '';
    while (my $line = <FD_CMD>) {
        $str .= $line;
    }
    close(FD_CMD);

    # Remove the temporary file.
    `rm -f $TMP_FILE`;

    return ($str);
}

######################################################################
# Johab to MCT - Applies all the pronunciation rules.
# - $s: Johab string.
# + MCT string.
sub johab2Mct
{
    my ($s) = @_;
    my $jl = parseStr2JList($s);
    applyPRulesJList($jl);
    return (combineJList2Str($jl));
}

######################################################################
# MCT to Johab.
# - $s: MCT string
# - $m: 0 = strict translation (for displaying things as is).
#       1 = more common translation (e.g., adds "EU" if a consonent
#           gets dangled).
# + A list: [0]: Johab string
#           [1]: Bracketed MCT string for display
sub mct2Johab
{
    my ($s, $m) = @_;
    my $rs = '';
    my $ns = '';
    my $inMCT = 0;
    my $prevL = 0;
    my @js;
    defined($m) or $m = 0;

    $s =~ tr/a-z/A-Z/;
    $s =~ s/L+/L/g;
    clearJSet(\@js);

    my $state = 1;
    while (length($s)) {
        if (1 == $state) {
            if (($s =~ /^($JS0_2)(.*)$/o) or
                ($m and ($s =~ /^(NG)(.*)$/o))) {
                $s = $2;
                my $jm = $1;
                if ($jm eq 'PH') {
                    $jm = 'P';
                } elsif ($jm eq 'SH') {
                    $jm = 'S';
                    if ($s =~ /^($JS0)/o) {
                        $s = 'YU'.$s;
                    } elsif ($s =~ /^($JS1)/o and $s !~ /^($JS1_Y)/o) {
                        $s = 'Y' . $s;
                    }
                } elsif ($jm eq 'CH' and $s =~ /^R/o) {
                    $jm = 'K';
                } elsif ($m and $jm eq 'NG') {
                    $jm = 'O';
                }
                $js[0] = $jm;
                $inMCT or $ns .= '[', $inMCT = 1;
                $ns .= $jm;
                $state = 2;
            } elsif ($s =~ /^($JS0_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                if ($jm eq 'C' and $s !~ /^(E|I|Y)/o) {
                    $jm = 'K';
                }
                ($jm eq 'L' and !$prevL) and $jm = 'R';
                $js[0] = $jm;
                $jm =~ tr/VFZCXQ/BPJSSK/;
                $inMCT or $ns .= '[', $inMCT = 1;
                $ns .= $jm;
                $state = 2;
            } elsif ($s =~ /^($JS1)/o) {
                $js[0] = 'O';
                $inMCT or $ns .= '[', $inMCT = 1;
                $state = 2;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $1;
                $ns .= '-';
                $state = 1;
            } else {
                $s =~ /^(.)(.*)$/o;
                $s = $2;
                my $jm = $1;
                $rs .= $jm;
                $inMCT and $ns .= ']', $inMCT = 0;
                $ns .= $jm;
                $state = 1;
                $prevL = 0;
            }
        } elsif (2 == $state) {
            if ($s =~ /^($JS1_3)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $jm =~ s/YOO/YU/g;
                $jm =~ s/WOO/U/g;
                $jm =~ s/EUI/UI/g;
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^($JS1_2)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $jm =~ s/OO/U/g;
                $jm =~ s/WU/U/g;
                $jm =~ s/EE/I/g;
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^($JS1_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $jm =~ tr/Y/I/;
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $2;
                if (!$m) {
                    $js[1] = 'EU';
                    $ns .= 'EU';
                }
                if ($s =~ /^L/o) {
                    $js[2] = 'L';
                    $ns .= 'L';
                    $prevL = 1;
                } else {
                    $prevL = 0;
                }
                $ns .= '-';
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                $state = 1;
            } else {
                if ($js[0] eq 'SH') {
                    $js[1] = 'I';
                    $ns .= 'I';
                } elsif (!$m) {
                    $js[1] = 'EU';
                    $ns .= 'EU';
                }
                if ($s =~ /^L/o) {
                    $js[2] = 'L';
                    $ns .= 'L';
                    $prevL = 1;
                } else {
                    $prevL = 0;
                }
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                ($s =~ /^($JS0|$JS1)/o) and $ns .= '-';
                $state = 1;
            }
        } elsif (3 == $state) {
            if ($s =~ /^($JS2_2)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[2] = $jm;
                # Look ahead.
                if ($s =~ /^($JS1)/o) {
                    if ($jm eq 'NG') {
                        # Only for 'NG'...
                        $s = 'G' . $s;
                        $js[2] = 'N';
                        $ns .= $js[2];
                    } else {
                        $s = $jm . $s;
                        $js[2] = undef;
                    }
                } elsif ($jm eq 'NG') {
                    $ns .= $jm;
                } else {
                    $s = $jm . $s;
                    $js[2] = undef;
                }
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                ($s =~ /^($JS0|$JS1)/o) and $ns .= '-';
                $state = 1;
                $prevL = 0;
            } elsif ($s =~ /^($JS2_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[2] = $jm;
                # Special 'X'.
                if ($jm eq 'X') {
                    $js[2] = 'K';
                    $s = 'S' . $s;
                }
                # Look ahead.
                if ($s =~ /^($JS1)/o) {
                    $s = $jm . $s;
                    ($jm eq 'L') and $ns .= $jm or $js[2] = undef;
                } elsif ($jm eq 'R') {
                    if ($js[1] eq 'E') {
                        $js[1] = 'EO';
                        $ns .= 'O';
                    }
                    if ($s =~ /^L/o) {
                        $js[2] = 'L';
                        $ns .= 'L';
                    }
                } elsif ($jm eq 'H') {
                    # Nothing.
                } else {
                    my $jm0 = $jm;
                    $jm0 =~ tr/C/K/;
                    $ns .= $jm0;
                }
                (defined($js[2]) and ($js[2] eq 'L'))
                    and $prevL = 1 or $prevL = 0;
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                ($s =~ /^($JS0|$JS1)/o) and $ns .= '-';
                $state = 1;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $1;
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                $ns .= '-';
                $state = 1;
                $prevL = 0;
            } else {
                $rs .= buildJohabMCT(\@js);
                clearJSet(\@js);
                ($s =~ /^($JS0|$JS1)/o) and $ns .= '-';
                $state = 1;
                $prevL = 0;
            }
        } else {
            die("Unknown parsing state $state ");
        }
    }
    if (defined($js[0]) or defined($js[1])) {
        if (!defined($js[1]) and defined($js[0])) {
            if ($js[0] eq 'SH') {
                $js[1] = 'I';
                $ns .= 'I';
            } elsif ($js[0] eq 'CH') {
                $js[1] = 'I';
                $ns .= 'I';
            } elsif (!$m) {
                $js[1] = 'EU';
                $ns .= 'EU';
            }
        }
        (!defined($js[0]) and defined($js[1]))
            and $js[0] = 'O';
        $rs .= buildJohabMCT(\@js);
    }
    $inMCT and $ns .= ']';

    $ns =~ tr/a-z/A-Z/;
    return ($rs, $ns);
}

######################################################################
# Jamo to Johab.
# - $s: Jamo string
# + A list: [0]: Johab string
#           [1]: Bracketed Jamo string for display
sub jamo2Johab
{
    my ($s) = @_;
    my $rs = '';
    my $ns = '';
    my $inJamo = 0;
    my @js;

    $s =~ tr/a-z/A-Z/;
    clearJSet(\@js);

    my $state = 1;
    while (length($s)) {
        if (1 == $state) {
            if ($s =~ /^($JK0_2)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[0] = $jm;
                $inJamo or $ns .= '[', $inJamo = 1;
                $ns .= $jm;
                $state = 2;
            } elsif ($s =~ /^($JK0_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                ($jm eq 'L') and $jm = 'R';
                $js[0] = $jm;
                $inJamo or $ns .= '[', $inJamo = 1;
                $ns .= $jm;
                $state = 2;
            } elsif ($s =~ /^($JK1)/o) {
                $js[0] = 'O';
                $inJamo or $ns .= '[', $inJamo = 1;
                $state = 2;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $2;
                $ns .= '-';
                $state = 1;
            } else {
                $s =~ /^(.)(.*)$/o;
                $s = $2;
                my $jm = $1;
                $rs .= $jm;
                $inJamo and $ns .= ']', $inJamo = 0;
                $ns .= $jm;
                $state = 1;
            }
        } elsif (2 == $state) {
            if ($s =~ /^($JK1_3)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                ($jm eq 'EUI') and $jm = 'UI';
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^($JK1_2)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^($JK1_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[1] = $jm;
                $ns .= $jm;
                $state = 3;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $1;
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                $ns .= '-';
                $state = 1;
            } else {
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                ($s =~ /^($JK0|$JK1)/o) and $ns .= '-';
                $state = 1;
            }
        } elsif (3 == $state) {
            if ($s =~ /^($JK2_2)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                $js[2] = $jm;
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                $ns .= $jm;
                ($s =~ /^($JK0|$JK1)/o) and $ns .= '-';
                $state = 1;
            } elsif ($s =~ /^($JK2_1)(.*)$/o) {
                $s = $2;
                my $jm = $1;
                ($jm eq 'R') and $jm = 'L';
                $js[2] = $jm;
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                $ns .= $jm;
                ($s =~ /^($JK0|$JK1)/o) and $ns .= '-';
                $state = 1;
            } elsif ($s =~ /^-(.*)$/o) {
                $s = $1;
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                $ns .= '-';
                $state = 1;
            } else {
                $rs .= buildJohabJamo(\@js);
                clearJSet(\@js);
                ($s =~ /^($JK0|$JK1)/o) and $ns .= '-';
                $state = 1;
            }
        } else {
            die("Unknown parsing state $state ");
        }
    }
    if (defined($js[0]) or defined($js[1]) or defined($js[2])) {
        $rs .= buildJohabJamo(\@js);
    }
    $inJamo and $ns .= ']';

    $ns =~ tr/a-z/A-Z/;
    return ($rs, $ns);
}

######################################################################
# Johab to Jamo
# - $s: Johab string
# + Jamo string
sub johab2Jamo
{
    my ($s) = @_;
    my $first = 1;
    my $rs = '';
    while (length($s)) {
        $s =~ /^(.)(.*)$/o;
        $s = $2;
        my $c1 = $1;
        if (ord($c1) >= 0x80 and length($s)) {
            $s =~ /^(.)(.*)$/o;
            $s = $2;
            my $c2 = $1;
            my $js = buildJohabJSet($c1, $c2);
            if (!isJSetEmpty($js)) {
                !$first and $rs .= '-' or $first = 0;
                if (isJSetMatch($js, 'o', undef, undef)) {
                    $rs .= 'ng';
                } else {
                    defined($$js[0]) and $rs .= $$js[0];
                    defined($$js[1]) and $rs .= $$js[1];
                    defined($$js[2]) and $rs .= $$js[2];
                }
            } else {
                $rs .= $c1 . $c2;
                $first = 1;
            }
        } else {
            $rs .= $c1;
            $first = 1;
        }
    }
    return ($rs);
}

######################################################################
# Johab to HTML Unicode.
# - $str: Johab string
# + HTML Unicode string
sub johab2Html
{
    my ($str) = @_;
    my $iconv_opt = "$ICONV_OPT -f JOHAB -t UTF-32BE";

    # Create a temporary file.
    open(FD_TMP, ">$TMP_FILE") or die("Cannot create a temporary file");
    print(FD_TMP $str);
    close(FD_TMP);

    # Use iconv to convert the text.
    open(FD_CMD, "$ICONV $iconv_opt $TMP_FILE|")
        or die("Cannot execute $ICONV");
    $str = '';
    while (my $line = <FD_CMD>) {
        my @cs = split(//, $line);

        for (my $i = 0; $i <= $#cs; $i += 4) {
            my $v = ord($cs[$i + 3])
                + 256 * (ord($cs[$i + 2])
                          + 256 * (ord($cs[$i + 1])
                                    + 256 * ord($cs[$i])));
            if ($v == ord("\n")) {
                $str .= "<BR>\n";
            } elsif ($v == ord("\r") or $v == ord("\b")) {
                # Ignored.
            } elsif ($v == ord("\t")
                     or ($v < 128 and $v >= ord(' ')
                         and $v != ord('&') and $v != ord('<'))) {
                $str .= chr($v);
            } else {
                $str .= '&#' . $v . ';';
            }
        }
    }
    close(FD_CMD);

    # Remove the temporary file.
    `rm -f $TMP_FILE`;

    return ($str);
}    

######################################################################
# Trim the string.
sub trimString
{
    my ($str) = @_;
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    return ($str);
}

######################################################################
# Convert the query string with encoding.
sub convertQueryString
{
    my ($str) = @_;
    $str =~ tr/+/ /;
    $str =~ s/%([0-9A-F]{2})/chr(hex($1))/ieg;
    return ($str);
}

######################################################################
# Escape HTML text.
sub escapeHtmlText
{
    my ($str) = @_;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&gt;/g;
    return ($str);
}


######################################################################
########## INTERNAL / PRIVATE SUBROUTINES
######################################################################

######################################################################
# Clear johab set.
sub clearJSet
{
    my ($js) = @_;
    $$js[0] = undef;
    $$js[1] = undef;
    $$js[2] = undef;
    $$js[3] = undef;
}

######################################################################
# Empty jamo set?
sub isJSetEmpty
{
    my ($js) = @_;
    return (!defined($js) or
            (!defined($$js[0]) and !defined($$js[1]) and !defined($$js[2])));
}

######################################################################
# Build a jamo set from Johab.
sub buildJohabJSet
{
    my ($c1, $c2) = @_;
    my $v1 = ord($c1);
    my $v2 = ord($c2);
    my $j0 = ($v1 & 0x7c) >> 2;
    my $j1 = (($v1 & 0x03) << 3) | (($v2 & 0xe0) >> 5);
    my $j2 = ($v2 & 0x1f);
    my $js;
    if (($j0 == 13) and ($j1 == 2) and ($j2 == 1)) {
        $js = ['o', undef, undef];
    } else {
        $js = [$K2J_J0{$j0}, $K2J_J1{$j1}, $K2J_J2{$j2}];
    }
    return ($js);
}

######################################################################
# Build a Johab character.
sub buildJohab
{
    my ($j0, $j1, $j2) = @_;
    my $c1 = chr(0x80 | (($j0 & 0x1f) << 2) | (($j1 & 0x18) >> 3));
    my $c2 = chr((($j1 & 0x7) << 5) | ($j2 & 0x1f));
    return ($c1 . $c2);
}

######################################################################
# Build a Johab character from MCT.
sub buildJohabMCT
{
    my ($js) = @_;
    my ($j0, $j1, $j2) = @$js;
    defined($j0) and $j0 = $R2K_J0{$j0} or $j0 = $R2K_J0{0};
    defined($j1) and $j1 = $R2K_J1{$j1} or $j1 = $R2K_J1{0};
    defined($j2) and $j2 = $R2K_J2{$j2} or $j2 = $R2K_J2{0};
    return (buildJohab($j0, $j1, $j2));
}

######################################################################
# Match jamo 1:1.
sub isJamoMatch
{
    my ($jm0, $jm1) = @_;
    if (defined($jm0) and defined($jm1)) {
        return ($jm0 eq $jm1);
    }
    !defined($jm0) and !defined($jm1) and return (1);
    return (0);
}

######################################################################
# Match jamo 1:1 with additional wild characters.
# '*' matches everything including 'undef'
# '+' matches everything but 'undef'
sub isJamoMatchWild
{
    my ($jm, $m) = @_;
    if (!defined($m)) {
        defined($jm) and return (0);
    } else {
        if ($m ne '*') {
            if ($m ne '+') {
                defined($jm) or return (0);
                isJamoMatch($jm, $m) or return (0);
            } else {
                defined($jm) or return (0);
            }
        }
    }
    return (1);
}

######################################################################
# Match jamo 1:many.
# ex) "a|b|c"
sub isJamoMatchMulti
{
    my ($j, $pat) = @_;
    defined($j) and defined($pat) or return (0);
    return ($j =~ /^($pat)$/);
}

######################################################################
# Match jamo set.
sub isJSetMatch
{
    my ($js, $jm0, $jm1, $jm2) = @_;
    defined($js) or return (0);
    isJamoMatch($$js[0], $jm0) or return (0);
    isJamoMatch($$js[1], $jm1) or return (0);
    isJamoMatch($$js[2], $jm2) or return (0);
    return (1);
}

######################################################################
# Match jamo set with additional wild characters.
# '*' matches everything including 'undef'
# '+' matches everything but 'undef'
sub isJSetMatchWild
{
    my ($js, $jm0, $jm1, $jm2) = @_;
    defined($js) or return (0);
    isJamoMatchWild($$js[0], $jm0) or return (0);
    isJamoMatchWild($$js[1], $jm1) or return (0);
    isJamoMatchWild($$js[2], $jm2) or return (0);
    return (1);
}

######################################################################
# Make the consonent stronger.
sub jamo2Stronger
{
    my ($jm) = @_;
    ($jm eq 'g') and return ('kk');
    ($jm eq 'd') and return ('tt');
    ($jm eq 'b') and return ('pp');
    ($jm eq 's') and return ('ss');
    ($jm eq 'j') and return ('jj');
    return ($jm);
}

######################################################################
# Get the jamo set at index.
sub getJSetAtIdx
{
    my ($jl, $i) = @_;
    (($i < 0) or ($i >= scalar(@$jl))) and return (undef);
    return ($$jl[$i]->[0]);
}

######################################################################
# Final jamo rules.

sub applyPRule2G
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if (defined($c) and ($c eq '-')) {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'k';   # R12.1-A1
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'ng';  # R18
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsC[2] = 'ng';
            $$jsN[0] = 'n';   # R19-A1
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'g';       # R13
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2KK
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'ng';  # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'g';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'g';   # R9
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'kk';      # R13
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2GS
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'ng';  # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'g';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'g';   # R10
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'g';
        $$jsN[0] = 'ss';      # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2N
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m)
    {
        my $c = $$jl[$i + 1]->[1];
        if (defined($c) and $c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'l'; # R20.1
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'n';       # R13
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2NJ
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = 'n';
            $$jsN[0] = 'ch';  # R12.1-A1
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'n';   # R10
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'n';
        $$jsN[0] = 'j';       # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2NH
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'g')) {
            $$jsC[2] = 'n';
            $$jsN[0] = 'k';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'd')) {
            $$jsC[2] = 'n';
            $$jsN[0] = 't';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'j')) {
            $$jsC[2] = 'n';
            $$jsN[0] = 'ch'; # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 's')) {
            $$jsC[2] = 'n';
            $$jsN[0] = 'ss'; # R12.2
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'n')) {
            $$jsC[2] = 'n';   # R12.3-A1
        } else {
            $$jsC[2] = 'n';   # R???
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'n';       # R12.4
    }
    # Always changed.
    return (1);
}

sub applyPRule2D
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if ($c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            if (isJamoMatch($$jsN[1], 'i')) {
                $$jsN[0] = 'ch'; # R17-A1
            } else {
                $$jsN[0] = 't'; # R12.1-A1
            }
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'd', 'i', undef)
            and isJSetMatch($jsC, 'g', 'eu', 'd')) {
            $$jsN[0] = 's';   # R16
        } elsif ($$jsN[1] eq 'i') {
            $$jsN[0] = 'j';   # R17
        } else {
            $$jsN[0] = 'd';   # R13
        }
        $$jsC[2] = undef;
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2L
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if ($c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'n')) {
            $$jsN[0] = 'l';   # R20.2
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)
                 and (isJSetMatchWild($jsC, '*', 'a', 'l')
                      or isJSetMatchWild($jsC, '*', 'eu', 'l'))) {
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R27
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsN[0] = 'l';
            $fChanged = 1;
        } else {
            my $jsNN = getJSetAtIdx($jl, $i + 2);
            if (isJamoMatchMulti($$jsNN[0], $KJ0_X5)
                and (isJSetMatchWild($jsC, '*', 'a', 'l')
                     or isJSetMatchWild($jsC, '*', 'eu', 'l'))) {
                $$jsNN[0] = jamo2Stronger($$jsNN[0]); # R27
                $fChanged = 1;
            }
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'r';       # R13
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2LG
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        my $jsNN = getJSetAtIdx($jl, $i + 2);
        if (isJSetMatch($jsN, 'g', 'e', undef)
            or isJSetMatch($jsN, 'g', 'o', undef)
            or isJSetMatch($jsN, 'g', 'i', undef)
            or (isJSetMatch($jsN, 'g', 'eo', undef)
                and isJSetMatch($jsNN, 'n', 'a', undef))) {
            $$jsN[0] = 'kk';
            $$jsC[2] = 'l';   # R11-E1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'k';   # R12.1-A1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'ng';  # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'g';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'g';   # R11
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'l';
        $$jsN[0] = 'g';       # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2LM
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        $$jsC[2] = 'm';       # R11
    } else {
        # Before a vowel.
        $$jsC[2] = 'l';
        $$jsN[0] = 'm';       # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2LB
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'p';   # R12.1-A1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'm';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'b';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23, R25
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'l';   # R10
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'l';
        $$jsN[0] = 'b';       # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2LS
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        $$jsC[2] = 'l';       # R10
    } else {
        # Before a vowel.
        $$jsC[2] = 'l';
        $$jsN[0] = 'ss';      # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2LT
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'n')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'l';   # R20-A1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X4)) {
            $$jsC[2] = 'l';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R25
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'l';   # R10
        }
    } else {
        # Before a vowel.
        if (isJamoMatch($$jsN[1], 'i')) {
            $$jsN[0] = 'ch';  # R17
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 't';   # R14
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = 'l';
    }
    # Always changed.
    return (1);
}

sub applyPRule2LP
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'm';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'b';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'b';   # R11
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'l';
        $$jsN[0] = 'p';       # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2LH
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'g')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'k';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'd')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 't';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'j')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'ch';  # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 's')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'ss';  # R12.2
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'n')) {
            $$jsC[2] = 'l';
            $$jsN[0] = 'l';   # R20-A1
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'l';
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'r';       # R12.4
    }
    # Always changed.
    return (1);
}

sub applyPRule2M
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if ($c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final. 
        if (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsN[0] = 'n';   # R19
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'm';       # R13
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2B
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if ($c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'p';   # R12.1-A1
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'm';   # R18
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $fChanged = 1;
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsC[2] = 'm';
            $$jsN[0] = 'n';   # R19-A1
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'b';       # R13
        $fChanged = 1;
    }
    return ($fChanged);
}

sub applyPRule2BS
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'm';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'b';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'b';   # R10
        }
    } else {
        # Before a vowel.
        $$jsC[2] = 'b';
        $$jsN[0] = 'ss';      # R14
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2S
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18, R30.2
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'd';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23, R30.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            $$jsN[0] = 't';
        } else {
            $$jsC[2] = 'd';   # R9
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 's';       # R13
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2SS
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'd';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'd';   # R9
        }
    } else {
        # Before a vowel.
        $$jsC[2] = undef;
        $$jsN[0] = 'ss';      # R13
        $$jsC[3] = 1;         # No further change.
    }
    # Always changed.
    return (1);
}

sub applyPRule2NG
{
    my ($jl, $i, $m) = @_;
    my $fChanged = 0;
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);

    if ($m) {
        my $c = $$jl[$i + 1]->[1];
        if ($c eq '-') {
            $jsN = getJSetAtIdx($jl, $i + 2);
        } else {
            return (0);
        }
    }
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_RL)) {
            $$jsN[0] = 'n';   # R19
            $fChanged = 1;
        }
    } else {
        # Before a vowel.
    }
    return ($fChanged);
}

sub applyPRule2J
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'h')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'ch';  # R12.1-A1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'd';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'd';   # R9
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'j', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 'j')) {
            $$jsN[0] = 's';   # R16
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 'j';   # R13
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;
    }
    # Always changed.
    return (1);
}

sub applyPRule2CH
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'd';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'd';   # R9
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'ch', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 'ch')) {
            $$jsN[0] = 's';   # R16
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 'ch';  # R13
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;
    }
    # Always changed.
    return (1);
}

sub applyPRule2K
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'ng';  # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'g';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'g';   # R9
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'k', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 'k')) {
            $$jsN[0] = 'g';   # R16
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 'k';   # R13
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;
    }
    # Always changed.
    return (1);
}

sub applyPRule2T
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'd';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'd';   # R9
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 't', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 't')) {
            $$jsN[0] = 's';   # R16
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[1], 'i')) {
            $$jsN[0] = 'ch';  # R17
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 't';   # R13
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;
    }
    # Always changed.
    return (1);
}

sub applyPRule2P
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'm';   # R18
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_X5)) {
            $$jsC[2] = 'b';
            $$jsN[0] = jamo2Stronger($$jsN[0]); # R23
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsC[2] = 'b';   # R9
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'p', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 'p')) {
            $$jsN[0] = 'b';   # R16
            $$jsC[3] = 1;     # No further change.
        } else {
            $$jsN[0] = 'p';   # R13
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;
    }
    # Always changed.
    return (1);
}

sub applyPRule2H
{
    my ($jl, $i, $m) = @_;
    $m and return (0);     # After intra, this should not be present.
    my $jsC = getJSetAtIdx($jl, $i);
    my $jsN = getJSetAtIdx($jl, $i + 1);
    if (isJSetEmpty($jsN) or defined($$jsN[0])) {
        # Before a consonent or final.
        if (isJamoMatch($$jsN[0], 'g')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'k';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'd')) {
            $$jsC[2] = undef;
            $$jsN[0] = 't';   # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'j')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'ch';  # R12.1
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 's')) {
            $$jsC[2] = undef;
            $$jsN[0] = 'ss';  # R12.2
            $$jsC[3] = 1;     # No further change.
        } elsif (isJamoMatch($$jsN[0], 'n')) {
            $$jsC[2] = 'n';   # R12.3
        } elsif (isJamoMatchMulti($$jsN[0], $KJ0_NM)) {
            $$jsC[2] = 'n';   # R18
        } else {
            $$jsC[2] = 'd';   # R???
        }
    } else {
        # Before a vowel.
        my $jsP = getJSetAtIdx($jl, $i - 1);

        if (isJSetMatch($jsP, 'h', 'i', undef)
            and isJSetMatch($jsC, undef, 'eu', 'h')) {
            $$jsN[0] = 's';   # R16
            $$jsC[3] = 1;     # No further change.
        }
        $$jsC[2] = undef;     # R12.4
    }
    # Always changed.
    return (1);
}

######################################################################
# Apply pronunciation rules for finals.
sub applyPRulesFinal
{
    my ($jl, $m) = @_;
    my $fChanged = 0;
    for (my $i = 0; $i < scalar(@$jl); ++$i) {
        my $js = $$jl[$i]->[0];
        if (defined($js) and defined($$js[2]) and !defined($$js[3])) {
            my $fn = $KJ2_RH{$$js[2]};
            (defined($fn) and &{$fn}($jl, $i, $m))
                and $fChanged = 1;
        }
    }
    return ($fChanged);
}

######################################################################
# Apply pronunciation rules for middles.
sub applyPRulesMiddle
{
    my ($jl, $m) = @_;
    my $fChanged = 0;
    for (my $i = 0; $i < scalar(@$jl); ++$i) {
        my $js = $$jl[$i]->[0];
        if (defined($js) and defined($$js[1])) {
            if (isJamoMatch($$js[1], 'yeo')
                and isJamoMatchMulti($$js[0], "j|jj|ch")) {
                $$js[1] = 'eo'; # R5-E1
                $fChanged = 1;
            } elsif (isJamoMatch($$js[1], 'ui') and defined($$js[0])) {
                $$js[1] = 'i'; # R5-E3
                $fChanged = 1;
            }
        }
    }
    return ($fChanged);
}

######################################################################
# Apply pronunciation rules for exception words.
sub applyPRulesWordExceptions
{
    my ($jl) = @_;
    for (my $i = 0; $i < scalar(@$jl); ++$i) {
        my $jsP = getJSetAtIdx($jl, $i - 1);
        my $js = getJSetAtIdx($jl, $i);
        if (isJSetEmpty($jsP) and !isJSetEmpty($js)) {
            my $js1 = getJSetAtIdx($jl, $i + 1);
            my $js2 = getJSetAtIdx($jl, $i + 2);
            my $js3 = getJSetAtIdx($jl, $i + 3);
            if (isJSetMatch($js, undef, 'yu', undef)
                and isJSetMatch($js1, 'd', 'eu', 'l')
                and isJSetMatch($js2, undef, 'yu', undef)
                and isJSetMatch($js3, 'd', 'eu', 'l')) {
                $$js2[0] = 'l'; # R29-A1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'a', 'm')
                     and isJSetMatch($js1, 'j', 'o', 'n')
                     and isJSetMatch($js2, undef, 'yeo', undef)
                     and isJSetMatch($js3, 'b', 'i', undef)) {
                $$js2[0] = 'n'; # R29
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'j', 'i', 'g')
                     and isJSetMatch($js1, 'h', 'ae', 'ng')
                     and isJSetMatch($js2, undef, 'yeo', 'l')
                     and isJSetMatch($js3, 'ch', 'a', undef)) {
                $$js[2] = undef;
                $$js1[0] = 'k';
                $$js2[0] = 'n'; # R29
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'u', 'g')
                     and isJSetMatch($js1, 'm', 'i', 'n')
                     and isJSetMatch($js2, undef, 'yu', 'n')
                     and isJSetMatch($js3, 'r', 'i', undef)) {
                $$js[2] = 'ng';
                $$js2[0] = 'n'; # R29
                $$js2[2] = 'l';
                $$js3[0] = 'l';
                $$js[3] = $$js1[3] = $$js2[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'o', undef)
                     and isJSetMatch($js1, 'r', 'i', undef)
                     and isJSetMatch($js2, 'kk', 'ae', 's')
                     and isJSetMatch($js3, undef, 'yeo', 'l')) {
                $$js2[2] = 'n';
                $$js3[0] = 'n'; # R30.3
                $$js2[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'j', 'eo', 'j')
                     and isJSetMatch($js1, undef, 'eo', undef)
                     and isJSetMatch($js2, 'm', 'i', undef)) {
                $$js[2] = undef;
                $$js1[0] = 'd'; # R15
                $$js[3] = 1; # No further change
            } elsif (isJSetMatch($js, 'h', 'eo', 's')
                     and isJSetMatch($js1, undef, 'u', 's')
                     and isJSetMatch($js2, undef, 'eu', 'm')) {
                $$js[2] = undef;
                $$js1[0] = 'd'; # R15
                $$js1[2] = undef;
                $$js2[0] = 's';
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'u', 'n')
                     and isJSetMatch($js1, 'g', 'o', undef)
                     and isJSetMatch($js2, 'r', 'i', undef)) {
                $$js1[0] = 'kk'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'u', 'n')
                     and isJSetMatch($js1, 'd', 'o', 'ng')
                     and isJSetMatch($js2, 'j', 'a', undef)) {
                $$js1[0] = 'tt'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'a', 'n')
                     and isJSetMatch($js1, 'b', 'a', undef)
                     and isJSetMatch($js2, 'r', 'a', 'm')) {
                $$js1[0] = 'pp'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'o', 'n')
                     and isJSetMatch($js1, 'j', 'ae', undef)
                     and isJSetMatch($js2, 'j', 'u', undef)) {
                $$js1[0] = 'jj'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'u', 'l')
                     and isJSetMatch($js1, 'd', 'o', 'ng')
                     and isJSetMatch($js2, undef, 'i', undef)) {
                $$js1[0] = 'tt'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'a', 'l')
                     and isJSetMatch($js1, 'b', 'a', undef)
                     and isJSetMatch($js2, 'd', 'a', 'g')) {
                $$js1[0] = 'pp'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'a', undef)
                     and isJSetMatch($js1, 'r', 'a', 'm')
                     and isJSetMatch($js2, 'g', 'yeo', 'l')) {
                $$js2[0] = 'kk'; # R28
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'eu', undef)
                     and isJSetMatch($js1, 'm', 'eu', 'm')
                     and isJSetMatch($js2, 'd', 'a', 'l')) {
                $$js2[0] = 'tt'; # R28
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'a', undef)
                     and isJSetMatch($js1, 'ch', 'i', 'm')
                     and isJSetMatch($js2, 'b', 'a', 'b')) {
                $$js2[0] = 'pp'; # R28
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'a', undef)
                     and isJSetMatch($js1, undef, 'eu', 'm')
                     and isJSetMatch($js2, 'b', 'eo', 'n')) {
                $$js2[0] = 'pp'; # R28
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'ch', 'o', undef)
                     and isJSetMatch($js1, 's', 'eu', 'ng')
                     and isJSetMatch($js2, 'd', 'a', 'l')) {
                $$js2[0] = 'tt'; # R28
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'a', 'ng')
                     and isJSetMatch($js1, 'j', 'u', 'l')
                     and isJSetMatch($js2, 'g', 'i', undef)) {
                $$js1[0] = 'jj'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'u', 'l')
                     and isJSetMatch($js1, undef, 'yeo', undef)
                     and isJSetMatch($js2, undef, 'u', undef)) {
                $$js1[0] = 'l'; # R29-A1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'eo', undef)
                     and isJSetMatch($js1, undef, 'u', 'l')
                     and isJSetMatch($js2, undef, 'yeo', 'g')) {
                $$js2[0] = 'l'; # R29-A1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'h', 'wi', undef)
                     and isJSetMatch($js1, 'b', 'a', 'l')
                     and isJSetMatch($js2, undef, 'yu', undef)) {
                $$js2[0] = 'l'; # R29-A1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'i', undef)
                     and isJSetMatch($js1, 'j', 'e', 'l')
                     and isJSetMatch($js2, undef, 'yu', undef)) {
                $$js2[0] = 'l'; # R29-A1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'o', 'm')
                     and isJSetMatch($js1, undef, 'i', undef)
                     and isJSetMatch($js2, 'b', 'u', 'l')) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'h', 'o', 't')
                     and isJSetMatch($js1, undef, 'i', undef)
                     and isJSetMatch($js2, 'b', 'u', 'l')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'ae', undef)
                     and isJSetMatch($js1, 'b', 'o', 'g')
                     and isJSetMatch($js2, undef, 'ya', 'g')) {
                $$js1[2] = 'ng';
                $$js2[0] = 'n'; # R29
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'h', 'a', 'n')
                     and isJSetMatch($js1, undef, 'yeo', undef)
                     and isJSetMatch($js2, 'r', 'eu', 'm')) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'i', 'n')
                     and isJSetMatch($js1, undef, 'yeo', undef)
                     and isJSetMatch($js2, 's', 'eo', 'ng')) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'ae', 'g')
                     and isJSetMatch($js1, undef, 'yeo', 'n')
                     and isJSetMatch($js2, 'p', 'i', 'l')) {
                $$js[2] = 'ng';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'eu', 'g')
                     and isJSetMatch($js1, 'm', 'a', 'g')
                     and isJSetMatch($js2, undef, 'yeo', 'm')) {
                $$js[2] = 'ng';
                $$js1[2] = 'ng';
                $$js2[0] = 'n'; # R29
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'u', 'n')
                     and isJSetMatch($js1, undef, 'yo', undef)
                     and isJSetMatch($js2, 'g', 'i', undef)) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'yeo', 'ng')
                     and isJSetMatch($js1, undef, 'eo', 'b')
                     and isJSetMatch($js2, undef, 'yo', 'ng')) {
                $$js1[2] = 'm';
                $$js2[0] = 'n'; # R29
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'i', 'g')
                     and isJSetMatch($js1, undef, 'yo', 'ng')
                     and isJSetMatch($js2, undef, 'yu', undef)) {
                $$js[2] = undef;
                $$js1[0] = 'g';
                $$js2[0] = 'n'; # R29
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'ae', undef)
                     and isJSetMatch($js1, 'g', 'ae', 's')
                     and isJSetMatch($js2, undef, 'i', 's')) {
                $$js1[2] = 'n';
                $$js2[0] = 'n'; # R30.3
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'a', undef)
                     and isJSetMatch($js1, 'm', 'u', 's')
                     and isJSetMatch($js2, undef, 'i', 'p')) {
                $$js1[2] = 'n';
                $$js2[0] = 'n'; # R30.3
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'ui', undef)
                     and isJSetMatch($js1, 'g', 'yeo', 'n')
                     and isJSetMatch($js2, 'r', 'a', 'n')) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'i', 'm')
                     and isJSetMatch($js1, 'j', 'i', 'n')
                     and isJSetMatch($js2, 'r', 'a', 'n')) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'ae', 'ng')
                     and isJSetMatch($js1, 's', 'a', 'n')
                     and isJSetMatch($js2, 'r', 'ya', 'ng')) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'yeo', 'l')
                     and isJSetMatch($js1, 'd', 'a', 'n')
                     and isJSetMatch($js2, 'r', 'yeo', 'g')) {
                $$js1[0] = 'tt';
                $$js2[0] = 'n'; # R20-E1
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'o', 'ng')
                     and isJSetMatch($js1, 'g', 'wo', 'n')
                     and isJSetMatch($js2, 'r', 'yeo', 'g')) {
                $$js1[0] = 'kk';
                $$js2[0] = 'n'; # R20-E1
                $$js[3] = $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'o', 'ng')
                     and isJSetMatch($js1, undef, 'wo', 'n')
                     and isJSetMatch($js2, 'r', 'yeo', 'ng')) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'a', 'ng')
                     and isJSetMatch($js1, 'g', 'yeo', 'n')
                     and isJSetMatch($js2, 'r', 'ye', undef)) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'h', 'oe', 'ng')
                     and isJSetMatch($js1, 'd', 'a', 'n')
                     and isJSetMatch($js2, 'r', 'o', undef)) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'i', undef)
                     and isJSetMatch($js1, undef, 'wo', 'n')
                     and isJSetMatch($js2, 'r', 'o', 'n')) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, undef, 'i', undef)
                     and isJSetMatch($js1, 'b', 'wo', 'n')
                     and isJSetMatch($js2, 'r', 'yo', undef)) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'u', undef)
                     and isJSetMatch($js1, 'g', 'eu', 'n')
                     and isJSetMatch($js2, 'r', 'yu', undef)) {
                $$js2[0] = 'n'; # R20-E1
                $$js1[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'u', 'n')
                     and isJSetMatch($js1, 'g', 'i', 'l')) {
                $$js1[0] = 'kk'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'a', 's')
                     and isJSetMatch($js1, undef, 'eo', 'bs')) {
                $$js[2] = undef;
                $$js1[0] = 'd'; # R15
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'eo', 't')
                     and isJSetMatch($js1, undef, 'o', 's')) {
                $$js[2] = undef;
                $$js1[0] = 'd'; # R15
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'a', 'n')
                     and isJSetMatch($js1, 's', 'ae', undef)) {
                $$js1[0] = 'ss'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'i', 'l')
                     and isJSetMatch($js1, 'g', 'a', undef)) {
                $$js1[0] = 'kk'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'u', 'l')
                     and isJSetMatch($js1, 's', 'o', 'g')) {
                $$js1[0] = 'ss'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'u', 'l')
                     and isJSetMatch($js1, 'j', 'a', 'n')) {
                $$js1[0] = 'jj'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'o', 'l')
                     and isJSetMatch($js1, 'j', 'i', 'g')) {
                $$js1[0] = 'jj'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'g', 'a', 'ng')
                     and isJSetMatch($js1, 'g', 'a', undef)) {
                $$js1[0] = 'kk'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'eu', 'ng')
                     and isJSetMatch($js1, 'b', 'u', 'l')) {
                $$js1[0] = 'pp'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'ch', 'a', 'ng')
                     and isJSetMatch($js1, 's', 'a', 'l')) {
                $$js1[0] = 'ss'; # R28
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'eu', 'l')
                     and isJSetMatch($js1, undef, 'i', 'l')) {
                $$js1[0] = 'l'; # R29-A1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'o', 'l')
                     and isJSetMatch($js1, undef, 'i', 'p')) {
                $$js1[0] = 'l'; # R29-A1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'u', 'l')
                     and isJSetMatch($js1, undef, 'ya', 'g')) {
                $$js1[0] = 'l'; # R29-A1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'u', 'l')
                     and isJSetMatch($js1, undef, 'yeo', 's')) {
                $$js1[0] = 'l'; # R29-A1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'a', 'g')
                     and isJSetMatch($js1, undef, 'i', 'l')) {
                $$js[2] = 'ng';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 's', 'a', 'gs')
                     and isJSetMatch($js1, undef, 'i', 'l')) {
                $$js[2] = 'ng';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'ae', 'n')
                     and isJSetMatch($js1, undef, 'i', 'b')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'kk', 'o', 'ch')
                     and isJSetMatch($js1, undef, 'i', 'p')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'k', 'o', 'ng')
                     and isJSetMatch($js1, undef, 'yeo', 's')) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'a', 'm')
                     and isJSetMatch($js1, undef, 'yo', undef)) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'a', 'm')
                     and isJSetMatch($js1, undef, 'yu', 's')) {
                $$js1[0] = 'n'; # R29
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'kk', 'ae', 's')
                     and isJSetMatch($js1, undef, 'i', 'p')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R30.3
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'd', 'wi', 's')
                     and isJSetMatch($js1, undef, 'yu', 'ch')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R30.3
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'm', 'o', 's')
                     and isJSetMatch($js1, undef, 'i', 'j')) {
                $$js[2] = 'n';
                $$js1[0] = 'n'; # R30.3
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'b', 'a', 'lb')
                     and defined($js1) and defined($$js[0])) {
                $$js[2] = 'b'; # R10-E1
                $$js[3] = 1; # No further change.
            } elsif (isJSetMatch($js, 'n', 'eo', 'lb')
                     and defined($js1) and defined($$js[0])) {
                $$js[2] = 'b'; # R10-E2
                $$js[3] = 1; # No further change.
            }
        }
    }
}

######################################################################
# Fix up some finals.
sub fixupFinalJList
{
    my ($jl) = @_;
    foreach my $e (@$jl) {
        my ($js) = @$e;
        if (defined($js) and defined($$js[2])) {
            if (isJamoMatch($$js[2], 'g')) {
                $$js[2] = 'k';
            } elsif (isJamoMatch($$js[2], 'd')) {
                $$js[2] = 't';
            } elsif (isJamoMatch($$js[2], 'b')) {
                $$js[2] = 'p';
            }
        }
    }
}

######################################################################
# Apply pronunciation rules to jamo list.
sub applyPRulesJList
{
    my ($jl) = @_;
    applyPRulesWordExceptions($jl);
    applyPRulesMiddle($jl);
    my $MAX_ITER = 2;
    for (my $i = 0; $i < $MAX_ITER; ++$i) {
        applyPRulesFinal($jl, $i) or last;
    }
    fixupFinalJList($jl);
}

######################################################################
# Parse string to jamo list.
sub parseStr2JList
{
    my ($s) = @_;
    my @jl = ();
    while (length($s)) {
        $s =~ /^(.)(.*)$/o;
        $s = $2;
        my $c1 = $1;
        if (ord($c1) >= 0x80 and length($s)) {
            $s =~ /^(.)(.*)$/o;
            $s = $2;
            my $c2 = $1;
            my $js = buildJohabJSet($c1, $c2);
            if (!isJSetEmpty($js)) {
                push(@jl, [$js, undef])
            } else {
                push(@jl, [undef, $c1]);
                push(@jl, [undef, $c2]);
            }
        } else {
            push(@jl, [undef, $c1]);
        }
    }
    return (\@jl);
}

######################################################################
# Combine jamo list to string
sub combineJList2Str
{
    my ($jl) = @_;
    my $jsP = undef;
    my $rs = '';
    foreach my $e (@$jl) {
        my ($js, $c) = @$e;
        if (defined($js)) {
            (!isJSetEmpty($jsP) and !isJSetEmpty($js)) and $rs .= '-';
            if (isJSetMatch($js, 'o', undef, undef)) {
                $rs .= 'ng';
            } else {
                defined($$js[0]) and $rs .= $$js[0];
                defined($$js[1]) and $rs .= $$js[1];
                defined($$js[2]) and $rs .= $$js[2];
            }
        } elsif (defined($c)) {
            $rs .= $c;
        }
        $jsP = $js;
    }
    return ($rs);
}

######################################################################
# Build a Johab character from Jamo.
sub buildJohabJamo
{
    my ($js) = @_;
    my ($j0, $j1, $j2) = @$js;
    defined($j0) and $j0 = $J2K_J0{$j0} or $j0 = $J2K_J0{0};
    defined($j1) and $j1 = $J2K_J1{$j1} or $j1 = $J2K_J1{0};
    defined($j2) and $j2 = $J2K_J2{$j2} or $j2 = $J2K_J2{0};
    return (buildJohab($j0, $j1, $j2));
}

######################################################################
# Johab to EUC-KR.
sub johab2Euckr
{
    my ($str) = @_;
    my $iconv_opt = "$ICONV_OPT -f JOHAB -t EUC-KR";

    # Create a temporary file.
    open(FD_TMP, ">$TMP_FILE") or die("Cannot create a temporary file");
    print(FD_TMP $str);
    close(FD_TMP);

    # Use iconv to convert the text.
    open(FD_CMD, "$ICONV $iconv_opt $TMP_FILE|")
        or die("Cannot execute $ICONV");
    $str = '';
    while (my $line = <FD_CMD>) {
        $str .= $line;
    }
    close(FD_CMD);

    # Remove the temporary file.
    `rm -f $TMP_FILE`;

    return ($str);
}

######################################################################
1;
# End.
######################################################################
