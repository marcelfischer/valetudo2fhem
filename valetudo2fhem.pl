#!/usr/bin/perl
use JSON;
use LWP::Simple;
use Data::Dumper;

# quit unless we have the correct number of args
$num_args = $#ARGV + 1;
if ($num_args < 1) {
  help();
}

my $fhem_out;
# create a virtual zone called "all"
my $fhem_out_tmp_all     = "all:";
my $vaccum               = $ARGV[0];
my $debug                = $ARGV[1];
# get valetudo config
my $valetudo_config_json = get "http://$vaccum/api/get_config";
# decode the json data
my $valetudo_config      = decode_json( $valetudo_config_json );

debug_out("using hostname $vaccum");

for my $level1 (@{$valetudo_config->{areas}}) {
  for my $level2 (@$level1) {
    if(ref($level2) eq 'ARRAY'){
      debug_out("we have the coordinates for zone: $zonename");
      $zone_counter=0;
      for my $level3 (@$level2) {
	$x1    = $level3->[0];
	$y1    = $level3->[1];
	$y1    = 51200 - $y1;
	$x2    = $level3->[2];
	$y2    = $level3->[3];
	$y2    = 51200 - $y2;
	$times = $level3->[4];
	if ($x1 > $x2) {
          $x1_temp = $x1;
	  $x1      = $x2;
	  $x2      = $x1_temp;
        }
	if ($y1 > $y2) {
          $y1_temp = $y1;
	  $y1      = $y2;
	  $y2      = $y1_temp;
        }
	if ($zone_counter > 0) {
          debug_out("we have more zones for $zonename:");
	  $fhem_out         = "$fhem_out,[$x1,$y1,$x2,$y2,$times]";
	  $fhem_out_tmp_all = "$fhem_out_tmp_all\[$x1,$y1,$x2,$y2,$times\],";
	} else {
          debug_out("this is the first zone for $zonename:");
	  $fhem_out         = "$fhem_out $zonename:[$x1,$y1,$x2,$y2,$times]";
	  $fhem_out_tmp_all = "$fhem_out_tmp_all\[$x1,$y1,$x2,$y2,$times\],";
	}
	debug_out("\t$level3->[0],$level3->[1],$level3->[2],$level3->[3],$level3->[4]");
	$zone_counter++;
      }
    } else {
      $zonename = $level2;
    }
  }
}
$fhem_out_tmp_all =~ s/,$//;
$fhem_out =~ s/^\s+|\s+$//g;
$fhem_out = "$fhem_out $fhem_out_tmp_all";
print "$fhem_out\n";

# show the help and exit
sub help {
  print "\nUsage: $0 hostname/ip of vaccum with valetudo [debug]\n";
  exit 1;
}

sub debug_out {
  if ($debug eq "debug") {
    $message = shift;
    print "DEBUG: $message\n";
  }
}
