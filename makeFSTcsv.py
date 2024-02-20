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
parser.add_argument("-wd", "--workingdir")
parser.add_argument("-r", "--ref")
args = parser.parse_args()

#THIS SCRIPT WILL COMPILE FST STATISTICS FOR POPULATION PAIRS GENERATED IN FSTpairs.py script
#AND GENERATE A .CSV DATAFRAME CONTAINING THE FOLLOWING COLUMNS
#Population 1 | Population 1 Region | Population 2 | Population 2 Region | Unweighted FST | Weighted FST

os.chdir(args.workingdir)

direc=os.listdir(args.workingdir)

refdir = args.workingdir + args.ref

#Write csv headers

with open('FST_MATRIX.csv', 'a+') as matrix:
	matrix.write('pop1,R1,pop2,R2,unweight,weighted'+'\n')


for folder in direc:
	if folder.endswith('_FST'):
		for file in os.listdir(folder):
			if file.endswith('.ml'):
				#get population names
				pop1 = file.split('.')[0]
				pop2 = file.split('.')[1]
				#get pop1 region
		with open(refdir, 'r') as pop1R:
			for line1 in pop1R:
				if pop1 in line1:
					R1 = line1.split(',')[1]
		#get pop2 region
		with open(refdir, 'r') as pop2R:
			for line2 in pop2R:
				if pop2 in line2:
					R2 = line2.split(',')[1]

		os.chdir(folder)
		#get unweighted and weighted FST
		with open(pop1+'_'+pop2+'_fst.txt', 'r') as fstat:
			for line in fstat:
				fsts = line.split('\t')[0]+','+line.split('\t')[1]
		os.chdir(args.workingdir)

		matrixo = open('FST_MATRIX.csv', 'a+')
		matrixo.write(pop1+','+R1+','+pop2+','+R2+','+fsts)
		



