#!/bin/bash
scaleFile=Legacy2016_17Aug2017_pho_scales.dat
finalScaleFile=`basename $scaleFile _scales.dat`_unc_scales.dat

systFile=Moriond17syst.dat
etSystFile=etSyst.dat
gainFile=gainSwitchCorrection.dat

### adding first fake run
cat > addMCbin.awk <<EOF
BEGIN{
}

(NF!=0){
 cat=\$1 
 runLabel=\$2
 runMin=\$3
 runMax=\$4
 corr=\$5
 err[cat]=\$6

# if(firstRun[cat]=="") firstRun[cat]=runMin
# if(runMin<firstRun[cat]) firstRun[cat]=runMin

 if(runMin==0) runMin=254790 # per riparare alla cavolata di Federico

 if(firstRun[cat]=="" ||(runMin<firstRun[cat])){
   firstRun[cat]=runMin
   firstRunCorrection[cat] = corr
   firstUncertainty[cat] = err[cat]
  }

 print cat, runLabel, runMin, runMax, corr, err[cat]

}

END{
 for(cat in firstRun){
   printf("%s\trunNumber\t1\t%d\t%.4f\t%.4f\n", cat, 2, 1.0, 0.0)
   printf("%s\trunNumber\t3\t%d\t%.4f\t%.4f\n", cat, firstRun[cat]-1, firstRunCorrection[cat], firstUncertainty[cat])
  }
}
EOF

awk -f addMCbin.awk $scaleFile > scaleFileMC.dat
scaleFile=scaleFileMC.dat

cat > merge.awk <<EOF
BEGIN{

}

(NF==9){
	cat = \$1
	deltaPho[cat]=\$2*\$2/10000
	deltaMC[cat]=\$3*\$3/10000
	deltaEt[cat]=\$4*\$4/10000
	deltaSel[cat]=\$5*\$5/10000
	deltaClosure[cat]=\$6*\$6/10000
	deltaSF[cat]=\$7*\$7/10000
	deltaR9trans[cat]=\$8*\$8/10000
#	deltaSyst[cat]=
	deltaStat[cat]=\$9/100
	CATS[cat]=cat

	# deltaPho[cat]=\$2*\$2/10000
	# deltaMC[cat]=\$3*\$3/10000
	# deltaEt[cat]=\$4*\$4/10000
	# deltaSel[cat]=\$5*\$5/10000
	# deltaSyst[cat]=\$6*\$6/10000
	# deltaStat[cat]=\$7/100
	# CATS[cat]=cat

}

(NF==4){
	Et_min=\$1
	Et_max=\$2
	cat=\$3
	EtCat=sprintf("%s-Et_%d_%d", cat, Et_min, Et_max)

	deltaPho[EtCat]=deltaPho[cat]
	deltaMC[EtCat] = deltaMC[cat]
	
	deltaSel[EtCat] = deltaSel[cat]

    deltaStat[EtCat] = deltaStat[cat]
	delete deltaEt[cat]
	delete CATS[cat]
	CATS[EtCat]=EtCat

	s=1-\$4
	EtSyst[EtCat]=s*s
    maxEtSyst[cat] = (maxEtSyst[cat] < EtSyst[EtCat]) ? EtSyst[EtCat] : maxEtSyst[cat]
}

END{

	for(cat in CATS){
		if(deltaEt[cat]==""){
			totSyst= sqrt(deltaPho[cat] + deltaMC[cat] + deltaSel[cat] + EtSyst[cat])
	 	} else{
	# 		c=cat
			totSyst=0
	 		totSyst= sqrt(deltaPho[cat] + deltaMC[cat] + deltaSel[cat] + deltaEt[cat])
	 	}
	 	printf("%s\t%.4f\t%.4f\n", cat, deltaStat[cat], totSyst)
	 }
	
}

EOF

cat > etSyst.dat <<EOF
# [absEta_0_1-bad]
0 1000000 absEta_0_1-bad  1.0020 


# [absEta_0_1-gold]
0 1000000 absEta_0_1-gold  1.0013 


# [absEta_1_1.4442-bad]
0 1000000 absEta_1_1.4442-bad  1.0059 


# [absEta_1_1.4442-gold]
0 1000000 absEta_1_1.4442-gold  1.0008 

EOF


#newSyst.dat is the file with the systematics updated with the Et scale shift seen in Run I
awk -f merge.awk $systFile $etSystFile | sort | sed 's|\(.*\)-Et_|\1 \1-Et_|' > newSyst.dat
#awk -f merge.awk $systFile  | sort | sed 's|\(.*\)-Et_|\1 \1-Et_|' > newSyst.dat

# this script updates the scale.dat file from ECALELF with the uncertainties
cat > update.awk <<EOF
BEGIN{

}

# from file newSyst.dat the categories that are updated with Et
(NF==4){
  cat=\$1
  newCat=\$2
  stat[cat,newCat]=\$3
  syst[cat,newCat]=\$4
}

# from file newSyst.dat the categories not updated with Et: (EE)
(NF==3){
  cat=\$1
  stat[cat,cat]=\$2
  syst[cat,cat]=\$3
}



(NF==6){
  cat=\$1
  found=0
  for( i in stat){
    split(i, c, SUBSEP)
    if(cat==c[1]){
       printf("%s\t%s\t%s\t%s\t%s\t%s\t%.4f\t%.4f\n", c[2], \$2, \$3, \$4, \$5, \$6, stat[i], syst[i])

       found=1
    }
  }

}
END{

}
EOF



cat > gainCorrections.awk <<EOF
BEGIN{
gain12corr=1
gain6corr=1
gain1corr=1
}

(/absEta_0_/ || /absEta_1_/){
  run=sprintf("%s\t%s\t%s", \$2, \$3, \$4)
  othersysts=sprintf("%s\t%s\t%s", \$6, \$7, \$8)
  printf("%s-gainEle_12\t%s\t%.4f\t%s\t%.4f\n", \$1, run, \$5/gain12corr,      othersysts, 0.);
  printf("%s-gainEle_6\t%s\t%.4f\t%s\t%.4f\n",  \$1, run, \$5/gain6corr,othersysts, 0.001);
  printf("%s-gainEle_1\t%s\t%.4f\t%s\t%.4f\n",  \$1, run, \$5/gain1corr,   othersysts, 0.020);
}
(!(/absEta_0_/ || /absEta_1_/)){
  printf("%s\t%.4f\n", \$0, 0.0000)
}


END{
}
EOF



awk -f update.awk newSyst.dat $scaleFile | sort | uniq | awk -f gainCorrections.awk > ${finalScaleFile}
