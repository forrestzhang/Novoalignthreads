#!/usr/bin/perl -w
use strict;
use threads;
use FileHandle;
use Getopt::Long;
use Pod::Usage;

#===============================================
#   File: thread_runnovoalign.pl
#   USAGE Example: perl thread_runnovoalign.pl -dbname ~/rice/tigr7/genome/tigr7cm.ndx -novopath ~/ChIPSoftware/novocraft/novoalign -mergepath ~/ChIPSoftware/picard-tools/picard-tools-1.81/MergeSamFiles.jar -reads1 JJ_OS_0_5U_CenH3_R1.fq -reads2 JJ_OS_0_5U_CenH3_R2.fq -parameters '-r Random' -threads 12 -samplename CenH3_05u
#   AUTHOR: Tao Zhang, tzhang54@wisc.edu
#   CREATED: 04/21/2013
#   REVISION: 05/01/2013
#   DEPENDENT: novoalign (http://www.novocraft.com), picards (http://picard.sourceforge.net)
#===============================================


#time perl thread_runnovoalign.pl -dbname ~/rice/tigr7/genome/tigr7cm.ndx -novopath ~/ChIPSoftware/novocraft/novoalign -mergepath ~/ChIPSoftware/picard-tools/picard-tools-1.81/MergeSamFiles.jar -reads1 JJ_OS_0_5U_CenH3_R1.fq -reads2 JJ_OS_0_5U_CenH3_R2.fq -parameters '-r Random' -threads 12 -samplename CenH3_05u

my $dbname;
my $reads1;
my $reads2;
my $novoparameters;
my $help = 0;
my $man = 0;
my $novopath='';
my $mergepath='';
my $threads = 4;
my $samplename = "novo";
my $gziped = 'no';

my $novoopt = GetOptions("dbname=s"=>\$dbname,
                         "reads1=s"=>\$reads1,
                         "reads2=s"=>\$reads2,
                         "parameters=s"=>\$novoparameters,
                         "novopath=s"=>\$novopath,
                         "mergepath=s"=>\$mergepath,
                         "threads=i"=>\$threads,
                         'help|?' => \$help,
                         man=>\$man,
                         "samplename=s"=>\$samplename,
                         "gziped=s"=>\$gziped,
                         ) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
#pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));
#pod2usage(1)  if (@ARGV == 0);
pod2usage("please input novoalign's dbname") unless $dbname;

unless ($dbname=~/ndx/){
    print "$dbname is not a novo index file (\.ndx)\n";
    exit;
}

pod2usage(1) unless $dbname;

pod2usage(1) unless $reads1;

#print "$dbname $reads1 $reads2 $novoparameters";
unless (-e $novopath){
    print "can't find novoalign\n";
    pod2usage(1);
    exit;
}else{
    my $whichnovoalign = `which $novopath`;
    print "using $whichnovoalign";
}

unless (-e $mergepath){
    print "can't find MergeSamFiles.jar\n";
    pod2usage(1);
    exit;
}else{
    print "$mergepath ";
    my $mergetjartest = `java -jar $mergepath --version`;
    
    #if ($mergetjartest){
    #    #my $mergeversion =  `java -jar $mergepath --version`;
    #    print "using MergeSamFiles.jar $mergepath Version $mergetjartest to merge samfiles to bamfile\n";
    #}else{
    #    print "can't exec MergeSamFiles.jar plase check your java and MergeSamFiles.jar\n";
    #    pod2usage(1);
    #    exit;
    #}
    
}

my $file1;

if ($gziped eq 'yes'){
    $file1 = "gunzip -c $reads1 |";
}else{
    $file1 = $reads1;
}
    


open F1,$file1;



my %filehandle;

my $read1 = 0;
my $sc1 = 0;
my $somthing;
my $nowoutname1;

my $read2 = 0;
my $sc2 = 0;

my $nowoutname2;

while (<F1>){
    
    
    $somthing = $_;
    
    if ($read1 % 1000000 == 0){
        
        $nowoutname1 = "$reads1\_$sc1";
        $filehandle{$nowoutname1} = FileHandle-> new(">$nowoutname1");
        $sc1++;
    }
    
    
    
    $filehandle{$nowoutname1}->print($somthing);
    $somthing = (<F1>);
    $filehandle{$nowoutname1}->print($somthing);
    $somthing = (<F1>); # read next (fastq qual header) line
    $filehandle{$nowoutname1}->print($somthing);
    $somthing = (<F1>); # read next (qaulity) line
    $filehandle{$nowoutname1}->print($somthing);
    $read1++;
}

my $file2;

if ($reads2){
    if ($gziped eq 'yes'){
        $file2 = "gunzip -c $reads2 |";
    }else{
        $file2 = $reads2;
    }
    

    open F2,$file2;
    
    while (<F2>){
        
        
        $somthing = $_;
        
        if ($read2 % 1000000 == 0){
            
            $nowoutname2 = "$reads2\_$sc2";
            $filehandle{$nowoutname2} = FileHandle-> new(">$nowoutname2");
            $sc2++;
        }
        
        
        
        $filehandle{$nowoutname2}->print($somthing);
        $somthing = (<F2>);
        $filehandle{$nowoutname2}->print($somthing);
        $somthing = (<F2>); # read next (fastq qual header) line
        $filehandle{$nowoutname2}->print($somthing);
        $somthing = (<F2>); # read next (qaulity) line
        $filehandle{$nowoutname2}->print($somthing);
        $read2++;
    }
}

print "splited finished start to ali\n";
my $scp=0;




my $process = $threads; 
my $child_num = 0; 
my $type = $samplename;
#
#
while (1){
    
    if ($scp < $sc1){
        if ($child_num < $process){ 

        

            my $thr = threads->create(sub{
                runnova($novopath,$dbname,$reads1,$reads2,$scp,$type,$novoparameters);
            }); 

            $child_num ++; 
            $scp++;
        
        } 
    }

    foreach my $t(threads->list(threads::joinable)){ 

        $t->join(); 

        $child_num --; 

    } 


    # all tasks done and no running child, then exit 

    if ( $scp >= ($sc1-1) && $child_num==0){ 

        last; 

    } 



    
}

my $input=' ';
for (my $i=0;$i<$sc1;$i++){
    
    $input = $input." INPUT=$type\_$i.sam ";
    
}

my $mergecommand = 'java -jar  '. $mergepath .' ' .$input.' OUTPUT='.$type.'_nova.bam SORT_ORDER=coordinate   VALIDATION_STRINGENCY=LENIENT';
print "$mergecommand\n";
`$mergecommand`;

my $bamfilename = $type.'_nova.bam';

print "result: $bamfilename\n";

if (-e  $bamfilename){
    for (my $i=0;$i<$sc1;$i++){
        
        unlink "$type\_$i.sam";
        unlink "$reads1\_$i";
        if ($reads2){
            unlink "$reads2\_$i";
        }
    }
}


sub runnova{
    
    my ($novopath,$dbname,$file1,$file2,$scp,$type,$novoparameters) = (@_);
    
    if ($file2){
        print "start to aligen $file1\_$scp $file2\_$scp\n";
        
        my $command = "$novopath -d $dbname -f $file1\_$scp $file2\_$scp $novoparameters -o Sam > $type\_$scp.sam";
        print "$command\n";
        
        `$command`;
    }else{
        print "start to aligen $file1\_$scp \n";
        
        my $command = "$novopath -d $dbname -f $file1\_$scp  $novoparameters -o Sam > $type\_$scp.sam";
        print "$command\n";
        
        `$command`;
    }
}

__END__
=head1 NAME

Using threads to run novoalign

=head SYNPOSIS
perl thread_runnovoalign --dbname=dbname --reads1=paired-end reads1 --reads2=paired-end reads2 --parameters

=head1 OPTIONS

=over 8

=item B<-help>
print a brief help

=item B<-novopath>
Full pathname of novoalign

=item B<-mergepath>
Full pathname of MergeSamFiles.jar 

=item B<-dbname>
Full pathname of indexed reference sequence from novoindex

=item B<-reads1>
Filenames for the read sequences for Side 1

=item B<-reads2>
Filenames for the read sequences for Side 2

=item B<-parameters>
Parameters of novoalign, example: -parameters '-l 99 -r Random'

=item B<-threads>
Parameters of novoalign

=item B<-samplename>
Sample's name, example: -samplename 'CenH3_05u'