#!/bin/bash

file=Moriond17_23Jan_ele_scales.dat

# select gain12 lines
# remove MC lines

grep gainEle_12 $file  | \
	awk '($3>3){print $0}' | \
	sed -r 's|-Et_[0-9]+_[0-9]+||;s|-gainEle_12||' | cut -f 1,3-5 | sort | uniq | \
	awk 'BEGIN{n=1};{cat=$1; if(cat==catOld){sum+=$4;sum2+=$4*$4; n++}else{printf("%s\t%d\t%.2f\t%.2f\n", catOld, n, (1-sum/n)*100, sqrt(sum2/n-(sum/n)*(sum/n))*100); n=1; sum=$4;sum2=$4*$4; catOld=cat}};END{printf("%s\t%d\t%.2f\t%.2f\n", catOld, n, (1-sum/n)*100., sqrt(sum2/n-(sum/n)*(sum/n))*100)}'
