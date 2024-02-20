#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import shutil
from os import path
from shutil import move
import fileinput
import os
import csv 
import sys
import subprocess
import shutil
from os import path
from shutil import move
from shutil import copyfile
import re
import itertools 
import fileinput
import argparse
import glob



parser = argparse.ArgumentParser()
parser.add_argument("-wd", "--workingdir") #directory where population folders are stored
parser.add_argument("-p", "--pfile") 	#text file containing set of comparisons to run
parser.add_argument("-sites", "--sitesdir") 	#directory to 4fold sites mask
args = parser.parse_args()


#THIS IS A 2 PART SCRIPT; LINES 41-75 REPRESENT PART 1, AND LINES 80-104 REPRESENT PART 2
#TO RUN THIS SCRIPT RUN PART 1 FIRST WITH PART 2 COMMENTED OUT
#THEN RUN PART 2 WITH THE PAIRS TEXT FILE GENERATED IN PART 1
#THE SCRIPT ASSUMES EVERY CITY IN THE WORKING DIRECTORY HAS ITS OWN FOLDER WITH SAF.IDX FILES FOR EACH POPULATION TO CALCULATE FST


#SCRIPT PART 1
os.chdir(args.workingdir)

#make empty list for pair combinations
poplist = []

for folder in os.listdir(args.workingdir):
	if not folder.endswith(".py"):
		poplist.append(folder)

#Generate all possible unique city combinations
print(poplist)
combinations = list(itertools.combinations(poplist, 2))

print(combinations)
print(len(combinations))

#Make dictionary of population combinations
POPDICT= {}
for pair in combinations:
	if pair not in POPDICT:
			POPDICT[pair]={}

#Output text file containing all pairs
for pair in POPDICT:
	print(pair)
	string = str(pair)
	#clean pop names
	pair1 = string.split(',')[0]
	pair1str = pair1.strip("'() ")
	pair2 = string.split(',')[1]
	pair2str = pair2.strip("'() ")
	print(pair1str)
	print(pair2str)
	with open('pairs.txt','a+') as out:
		out.write(pair1str + '\t' + pair2str +'\n')


# PART 2: COMMENT OUT LINES 41-75 FOR PART 1 TO RUN PART 2

#Make FST output folder
os.chdir(args.workingdir)

os.mkdir(args.workingdir+"fst")
os.chdir(args.workingdir+"fst")

#calculate FST for all pairs
with open(args.pfile, 'r') as pairs:
	for line in pairs:
		pair1 = line.split('\t')[0]
		pair1str = pair1.strip('\n')
		pair2 = line.split('\t')[1]
		pair2str = pair2.strip('\n')
		opair = pair1str + '_' + pair2str
		pop1saf = args.workingdir+pair1str+'/'+pair1str+'.saf.idx'
		print(pop1saf)
		pop2saf = args.workingdir+pair2str+'/'+pair2str+'.saf.idx'
		#make new folder for comparison output
		outdir = pair1str+'_'+pair2str+'_FST'
		os.mkdir(outdir)
		#Run FST from workdir
		print('Now Comparing '+ pair1str + " and " + pair2str)
		subprocess.call(["realSFS %s %s -cores 48 -sites %s > %s/%s.%s.ml" % (pop1saf,pop2saf,args.sitesdir,outdir,pair1str,pair2str)], shell=True)
		subprocess.call(["realSFS fst index %s %s -sfs %s/%s.%s.ml -fstout %s/%s.%s" % (pop1saf,pop2saf,outdir,pair1str,pair2str,outdir,pair1str,pair2str)], shell=True)
		#go to output folder for global FST output
		os.chdir(outdir)
		subprocess.call(["realSFS fst stats %s.%s.fst.idx > %s_%s_fst.txt" % (pair1str,pair2str,pair1str,pair2str)], shell=True)
		os.chdir(args.workingdir)


