
# 1. do bam stats on both MT and WT
bam_stats -i $BAM_MT_TMP -o $BAM_MT_TMP.bas

# 2. Genotype Check
compareBamGenotypes.pl 
-o /datastore/output/$NAME_WT/genotyped 
-nb $BAM_WT_TMP 
-j /datastore/output/$NAME_WT/genotyped/result.json 
-tb $BAM_MT_TMP

# 3. VerifyBams 
# Normal
verifyBamHomChk.pl 
-d 25
-o /datastore/output/$NAME_WT/contamination
-b $BAM_WT_TMP
-j /datastore/output/$NAME_WT/contamination/result.json

# Tumour
verifyBamHomChk.pl 
-d 25
-o /datastore/output/$NAME_MT/contamination
-b $BAM_MT_TMP
-a /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/${NAME_MT}.copynumber.caveman.csv
-j /datastore/output/$NAME_MT/contamination/result.json

# 4. ASCAT
ascat.pl
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat \
-t $BAM_MT_TMP \
-n $BAM_WT_TMP \
-sg $REF_BASE/ascat/SnpGcCorrections.tsv \
-r genome.fa
-q 20
-g L
-rs '$SPECIES'
-ra $ASSEMBLY
-pr $PROTOCOL
-pl ILLUMINA
-c $CPU

# 5. Pindel
pindel.pl
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel
-t $BAM_MT_TMP
-n $BAM_WT_TMP
-r $REF_BASE/genome.fa
-s $REF_BASE/pindel/simpleRepeats.bed.gz
-f $REF_BASE/pindel/genomicRules.lst
-g $REF_BASE/pindel/indelCoding.bed.gz
-u $REF_BASE/pindel/pindel_np.gff3.gz
-sf $REF_BASE/pindel/softRules.lst
-b $REF_BASE/brass/HiDepth.bed.gz
-st $PROTOCOL
-as $ASSEMBLY
-sp '$SPECIES'
-e NC_007605,hs37d5,GL%
-c $CPU

# 6 CaVEMan

# prep ascat output for caveman:
echo -e "CaVEMan prep: `date`"
set -x
ASCAT_CN="/datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/$NAME_MT.copynumber.caveman.csv"
perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/norm.cn.bed
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/tum.cn.bed
set +x

caveman.pl
-r $REF_BASE/genome.fa.fai \
-ig $REF_BASE/caveman/HiDepth.tsv \
-b $REF_BASE/caveman/flagging \
-u $REF_BASE/caveman \
-s '$SPECIES' \
-sa $ASSEMBLY \
-t $CPU \
-st genomic \
-in /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.germline.bed  \
-tc $TMP/tum.cn.bed \
-nc $TMP/norm.cn.bed \
-tb $BAM_MT_TMP \
-nb $BAM_WT_TMP \
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman

# 7. BRASS
brass.pl -j 4 -k 4 -c $CPU
-d $REF_BASE/brass/HiDepth.bed.gz
-f $REF_BASE/brass/brass_np.groups.gz
-g $REF_BASE/genome.fa
-s '$SPECIES' -as $ASSEMBLY -pr $PROTOCOL -pl ILLUMINA
-g_cache $REF_BASE/vagrent/vagrent.cache.gz
-vi $REF_BASE/brass/viral.1.1.genomic.fa
-mi $REF_BASE/brass/all_ncbi_bacteria.20150703
-b $REF_BASE/brass/500bp_windows.gc.bed.gz
-ct $REF_BASE/brass/CentTelo.tsv
-t $BAM_MT_TMP
-n $BAM_WT_TMP
-ss /datastore/output/${NAME_MT}_vs_${NAME_WT}/ascat/*.samplestatistics.txt
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/brass

# 8 annotate vcfs

# annotate pindel
rm -f /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz
-i /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf

# annotate caveman
rm -f /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
set -x
AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
-i /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
-o /datastore/output/${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf
set +x
