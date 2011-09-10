use WWW::Mechanize;
use HTML::TokeParser;
use File::Path;

my $year  = '2011';
my $urlQB = 'http://www.nfl.com/stats/categorystats?archive=false&conference=0015&statisticPositionCategory=QUARTERBACK&season=' . year . '&seasonType=REG&experience=null&tabSeq=1&qualified=true&Submit=Go';
my $urlRB = 'http://www.nfl.com/stats/categorystats?archive=false&conference=0015&statisticPositionCategory=RUNNING_BACK&season=' . year . '&seasonType=REG&experience=null&tabSeq=1&qualified=true&Submit=Go';
my $urlWR = 'http://www.nfl.com/stats/categorystats?archive=false&conference=0015&statisticPositionCategory=WIDE_RECEIVER&season=' . year . '&seasonType=REG&experience=null&tabSeq=1&qualified=true&Submit=Go';
#my $urlDF = '': #Haven't done defense yet...
my $urlK  = 'http://www.nfl.com/stats/categorystats?archive=false&conference=0015&statisticPositionCategory=FIELD_GOAL_KICKER&season=' . year . '&seasonType=REG&experience=null&tabSeq=1&qualified=true&Submit=Go';
my $urlTE = 'http://www.nfl.com/stats/categorystats?archive=false&conference=0015&statisticPositionCategory=TIGHT_END&season=' . year . '&seasonType=REG&experience=null&tabSeq=1&qualified=true&Submit=Go';

my @urls;
push(@urls, {position => 'QB', url => $urlQB});
push(@urls, {position => 'RB', url => $urlRB});
push(@urls, {position => 'WR', url => $urlWR});
push(@urls, {position => 'K' , url => $urlK});
push(@urls, {position => 'TE', url => $urlTE});

my $m = WWW::Mechanize->new(autocheck => 0);

foreach my $entry (@urls){
    my @links;
    my $url = $entry->{url};
    $m->get($url);

    rmtree('./' . $entry->{position});
    mkdir( './' . $entry->{position});

    my $p = HTML::TokeParser->new(\$m->{content});

    my $stop = 0; #In case I want to cap it.
    while (my $token = $p->get_tag("tr") && $stop < 1) {
        my $link = $p->get_tag("a")->[1]{href};
        if ($link =~ m/player/){
            push(@links, 'http://www.nfl.com' . $link);
            #$stop++;
        }
    }

    foreach(@links) {
        $_ =~ s/profile/gamelogs/;
        my $gamelogUrl = $_;
        print "$gamelogUrl\n";

        &goGet($m, $gamelogUrl, 0);

        my $p = HTML::TokeParser->new(\$m->{content});

        $_ =~ /players\/(.*)\//;
        my $filename = $1 . ".txt";

        open(FILE,">" . $entry->{position} . "\/" . $filename) || die("Cannot Open File"); 

        my $title = $p->get_tag("title");
        my $name  = $p->get_trimmed_text("/title");
        
        $name =~ /^(.*):/;
        $name = $1;
        print FILE "\n$name\n";

        while (my $token = $p->get_tag("tr")) {
            my $td = $p->get_tag("td");
            if ($p->get_trimmed_text("/td") =~ m/Regular Season/){
                #A lot of the formatting on NFL.com is F'd up.  I should
                #come up with a better way to deal with it, but I'm tired.
                #These next three lines are a hack.
                $p->get_tag("tr");
                my $game  = $p->get_tag("tr");  
                my $stats = $p->get_trimmed_text("tr");
                print FILE "$stats\n";

                until($stats =~ m/TOTAL/){
                    $game  = $p->get_tag("tr");
                    $stats = $p->get_trimmed_text("/tr");
                    $stats =~ s/\@ /\@/;
                    $stats =~ s/\[IMG\]/ /;
                    #Above line leaves an extra space.  Line below is
                    #a hack of a fix.
                    $stats =~ s/  //;
                    print FILE "$stats\n";
                }
            }
        }
        print "Parsed $name.\n\n";
        close(FILE);
    }
}

sub goGet {
    my $lM    = $_[0];
    my $lUrl  = $_[1];
    my $tries = $_[2];
    $tries++;

    if ($tries < 3){
        my $res = $lM->get($lUrl);

        if($res->is_success()){
           return; 
        } 
        else {
            print "Download attempt $tries failed.  Trying again...\n";
            &goGet($lM, $lUrl, $tries);
        }
    }
}
