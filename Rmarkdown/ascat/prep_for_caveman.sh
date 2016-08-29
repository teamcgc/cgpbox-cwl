#!/bin/sh

perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join(\"\t\",@F).\"\n\";' < ascat_output/copynumber.caveman.csv > ./normal_cn.bed 
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join(\"\t\",@F).\"\n\";' < ascat_output/copynumber.caveman.csv > ./tumour_cn.bed
