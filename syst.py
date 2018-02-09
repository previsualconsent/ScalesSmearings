import os
import math 
import copy
import pprint
pp = pprint.PrettyPrinter(indent=4)

def printfinalfile(mydata):
    for cat in mydata.keys():
        for d in mydata[cat]:
            print '{0}\trunNumber\t{1:6d}\t{2:6d}\t{3:.4f}\t{4:.4f}\t{5:.4f}\t{6:.4f}\t{7:.4f}\t{8:.4f}'.format(
                cat, d[0][0], d[0][1] , d[1] , d[2][0], d[2][1], d[2][2], d[3], d[4])
    
#scaleFile=Legacy2016_17Aug2017_pho_scales.dat
scaleFile="Moriond18_Run2017_v1_ele_scales.dat"
finalScaleFile=os.path.basename(scaleFile)[:-11]+"_unc_scales.dat" # remove the _scales.dat

systFile="Moriond18syst.dat"
etSystFile="etSyst.dat"
gainFile="Moriond18gainSwitch.dat"


### load the scale file
mydata = { }
for l in open(scaleFile):
    if l[0] == "#":
        continue
    v = l.split()
    if v[0] not in mydata.keys():
        mydata[v[0]] = []
    mydata[v[0]].append([
        (int(v[2]), int(v[3])), 
        float(v[4]), 
        (float(v[5]), float(v[6]), float(v[7]), float(v[8]))
    ])

### load systematics (table)
syst = {}
t = []
sum2 = {}
for l in open(systFile):
    if l[0] == '#':
        t = l.split()
        #        print t
        continue
    v = l.split()
    for i in range(1, len(v)):
        if v[0] not in syst.keys():
            syst[v[0]] = {}
            sum2[v[0]] = 0
        syst[v[0]][t[i]] = float(v[i])/100.
        if t[i] != "Stat.":
            sum2[v[0]] += syst[v[0]][t[i]]**2
    syst[v[0]]["tot"] = math.sqrt(sum2[v[0]])
    syst[v[0]]["Et"] = 0.01

print "------------------------------ printing systematics"
pp.pprint(syst)
del t

### load gain corrections
gainCorr={}
for l in open(gainFile):
    v = l.split()
    gainCorr[v[0]] = [ float(v[1]), float(v[2]) ]
print "------------------------------ printing gain corrections"
pp.pprint(gainCorr)



#print v[0], mydata[v[0]]
### adding first fake run for MC
for cat in mydata.keys():
    mydata[cat].insert(0,[(1,2), 1, mydata[cat][1][2]])
    ## adding bin covering for early data
    mydata[cat].insert(1,
                       [ (2,mydata[cat][1][0][0]-1), mydata[cat][1][1], mydata[cat][1][2]])
    #print cat, mydata[cat][0], mydata[cat][1],  mydata[cat][2] 

mydatagain={}
### multiply the gain corrections
for cat in mydata.keys(): # loop over the categories
        for gaincat in gainCorr: # loop over the gains
                newcat=cat+"-"+gaincat
                mydatagain[newcat] = [] # create a new category with gain info
                for d in mydata[cat]: # loop over the time bins
                    #print d
                    if d[0][0] != 1:
                        #print d[1]
                        d[1] = d[1] * gainCorr[gaincat][0]
                    #print d[2], gainCorr[gaincat][1]
                    #d.extend([gainCorr[gaincat][1]])
                    #print d
                    dnew = copy.deepcopy(d)
                    dnew.extend([ syst[cat]["tot"], gainCorr[gaincat][1]]) # add the gain uncertainty
                    mydatagain[newcat].append(dnew)
#                    print mydatagain[newcat][0]
#pp.pprint( mydatagain)
printfinalfile(mydatagain)
                
#mydataprint(mydata, syst)
    
