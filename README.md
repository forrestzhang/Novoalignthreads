Novoalignthreads
================

novoalign mutil-threads
A perl scrtipe convert single thread novoalign/Free version to mutil-threads version, and add gzip support.

DEPENDENT: novoalign (http://www.novocraft.com), picards (http://picard.sourceforge.net)


Options:

    -help print a brief help

    -novopath Full pathname of novoalign

    -mergepath Full pathname of MergeSamFiles.jar

    -dbname Full pathname of indexed reference sequence from novoindex

    -reads1 Filenames for the read sequences for Side 1

    -reads2 Filenames for the read sequences for Side 2

    -parameters Parameters of novoalign, example: -parameters '-l 99 -r Random'

    -threads Parameters of novoalign

    -samplename Sample's name, example: -samplename 'CenH3_05u'

    -gziped raw data whether compressed by gzip, example: -gziped yes


Example:

    perl novoalignthreads.pl -dbname ~/genome/tigr7cm.ndx -novopath ~/novocraft/novoalign -mergepath ~/Software/picard-tools-1.133/picard.jar -reads1 Reads_R1.fq -reads2 Reads_R2.fq -parameters '-r Random' -threads 12 -samplename paired_novoalign
