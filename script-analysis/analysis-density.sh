#!/bin/bash

################
#
# Script to compute the density profiles from SLAB simulations,
# one profile each 250ps and then it computes the PDF using a
# Python script.
# Finally, it computes the gas and condensed concentrations
# as weighted averages for C<=C_tot and C>C_tot.
# 500ns are taken as equilibration time, then the script takes ${nslice}
# trajectory slices of 100ns each.
# From the python script, a .dat and a .png files with the PDF, and a file
# containing temperature, average and standard deviation of the slices PDF 
# are saved.
#
# EXAMPLE:
# ./density-analysis-PDF.sh lambda en_scale temp
#
# Where the xtc and tpr files md_slab.xtc/tpr are stored in the folder
# /lambda${lambda}/es${en_scale}/T${temp}
#
################


gmx=/MASTER/PROG/gromacs-2019.6-gpu/bin/gmx

source /MASTER/PROG/miniconda3/etc/profile.d/conda.sh
conda activate simul

lambda=$1
en_scale=$2
temp=$3
# equilibration time
eq_time=500000 #ps
# slice of trajectory to take into account
slice=100000 #ps
nslice=15
# timestep for a frame
dt=500 #ps

cd lambda${lambda}/es${en_scale}/T${temp}

rm -r dens
mkdir dens

cp ../../../make_hist_totconc.py .

echo -e "0\n" | gmx trjconv -f md_slab.xtc -s md_slab.tpr -n ../../../index.ndx -pbc mol -o pbc.xtc

rm \#*\#

for ((ns=0;ns<nslice;ns++))
do
            start=$(( $eq_time + $slice * $ns ))
            frame=$start
            end_frame=$(( $eq_time + $slice * $ns + $slice))
            while [ $frame -lt $end_frame ]
            do

                echo -e "1\n" | gmx density -f pbc.xtc -s md_slab.tpr -n ../../../index.ndx -sl 250 -dens number -b $frame -e $frame -o dens/density-frame$frame.xvg

                sed '/^#/d;/^@/d' dens/density-frame$frame.xvg | awk '{ print $2}' > dens/density$frame.dat

                frame=$(( $frame + $dt ))

        done

        cat dens/density*.dat > densities-slice${ns}.dat
        rm dens/density*

done

# optional variable
# nbins=

python make_hist_totconc.py -temp ${temp} # -nbins ${nbins}
