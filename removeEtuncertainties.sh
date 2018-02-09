#!/bin/bash

file=Moriond17_23Jan_ele_scales.dat
c="absEta_0_1-bad-Et_39_45"
cat $file       | grep -v $c | sed '/absEta_0_1-bad/d' > l1.dat
grep $c $file | sed 's|-Et_39_45||'  >> l1.dat


file=l1.dat
c="absEta_1_1.4442-gold-Et_20_40"
cat $file      | grep -v $c | sed '/absEta_1_1.4442-gold/d' > l2.dat
grep $c $file | sed 's|-Et_20_40||' >> l2.dat

file=l2.dat
c="absEta_0_1-gold-Et_43_50"
cat $file      | grep -v $c | sed '/absEta_0_1-gold/d' > l3.dat
grep $c $file | sed 's|-Et_43_50||' >> l3.dat

file=l3.dat
c="absEta_1_1.4442-bad-Et_39_45"
cat $file      | grep -v $c | sed '/absEta_1_1.4442-bad/d' > l4.dat
grep $c $file | sed 's|-Et_39_45||'  >> l4.dat


