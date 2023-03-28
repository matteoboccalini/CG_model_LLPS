#/bin/env python3

#====== README =======
#
#  help: build index file out of a .gro file.
#        python3 make_ndx.py <file.gro>
#
#
#  07.03.2023: modified for new topology
#  28.03.2023: added lines for single chain index
#              + modified gro input file (now argparse)
#              + fixed output (a bit tidier)
#=====================

import sys
import numpy as np
import argparse


# EXAMPLE for GROfile with N PolyA of length L
# ./make_ndx.py -gro GROfile -n N -l L


parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, epilog=" ")
parser.add_argument("-gro", dest="GROfile", required=True, type=str, help='File .gro of the starting structure.')
parser.add_argument("-n", dest="num_A", required=True, type=int, help='Number of PolyA.')
parser.add_argument("-l", dest="length_A", required=True, type=int, help='Length of PolyA.')

args = parser.parse_args()

struct_gro = args.GROfile
num_A = args.num_A
length_A = args.length_A


#struct_gro = sys.argv[1]
#struct_gro = '40_b.gro'               

atom_type={"C":"C", "S":"S","A":"A"}
index_group = {"C":[],"S":[], "A":[], "AS":[], "B":[]}

with open(struct_gro,'r') as f:
    nlines=0
    nres=np.inf
    for line in f:
        cols=line.split()
        if nlines==1:
            nres=int(cols[0])
        if ((nlines>1) & (nlines<nres+2)):
            res=cols[1]
            resid=int(cols[2])
            #print(res, resid, nlines, nres)
            index_group[atom_type[res]].append(resid)
        nlines+=1

index_group["AS"] = index_group["A"] + index_group["S"]
index_group["B"] = index_group["C"] + index_group["S"]


with open("index.ndx",'w') as f:
    f.write("[ system ]\n")
    counter = 0
    for rid in range(nres):
        f.write('{:>5}'.format(rid+1))
        counter+=1
        if counter >= 10:
            f.write("\n")
            counter = 0
    f.write("\n")
    for r in index_group:
        f.write("[ %s ]\n" % (r))
        counter=0
        for i in range(len(index_group[r])):
            f.write('{:>5}'.format(index_group[r][i]))
            counter+=1
            if counter >= 10:
                f.write("\n")
                counter=0
        f.write("\n")

    # making index for each PolyA chain

    for n in range(1, num_A + 1):
        f.write('[ A%s ]\n' %(n))
        counter = 0
        for l in range(1, length_A + 1):
            f.write('{:>5}'.format(length_A * (n - 1) + l))
            counter+=1
            if counter >= 10:
                f.write('\n')
                counter = 0

    # making index to compute end-to-end distances
    # for each polyA chain with pairdist
    
    for n in range(1, num_A + 1):
        f.write('[ EE%s ]\n' %(n))
        f.write('{:>5} {:>5}\n'.format(length_A * (n-1) + 1, length_A * n))








