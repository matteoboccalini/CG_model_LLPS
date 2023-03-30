#!/bin/bash

# ./analysis.sh number_of_A_chain

gmx=/MASTER/PROG/gromacs-2019.6-gpu/bin/gmx

nA=$1

en_scale=(11 13 17 19)
lambda=1.2
temp=(300 325 350 375 400) # 405 410 415 420 425 450 450)

# cutoff for Wingreen potential in [nm]
cutoffWG=1

cd lambda$lambda/

for es in ${en_scale[@]}
do
	cd es$es

	for t in ${temp[@]}
	do
		cd T$t
		# gyration radius of each chain.
		# for each computed quantity, we
	        # take then its time average,
		# from which we compute the mean
		# and the error.                	
		for ((n=1;n<=nA;n++))
		do
			ind=$(( n + 5 ))

		# GYRATION RADIUS
			echo -e "$ind\n" | gmx gyrate -f pbc.xtc -s md_slab.tpr -n ../../../index.ndx -o gyrate-chain$n.xvg -b 100000 -e 1000000
			sed '/^#/d;/^@/d' gyrate-chain$n.xvg | awk '{nframe++; sum_rgyr+=$2; print sum_rgyr / nframe}' > timeavg-chain$n.dat
			avgrgchain=$( tail -n 1 timeavg-chain$n.dat )

cat>>rep-rgyr.dat<<EOF
$n	$avgrgchain
EOF
		# END-TO-END DISTANCE
			gmx pairdist -f pbc.xtc -s md_slab.tpr -n ../../../index.ndx -ref EE$n -sel EE$n -refgrouping all -selgrouping all -b 100000 -e 1000000 -o end-to-end_$n.xvg
			sed '/^@/d;/^#/d' end-to-end_$n.xvg | awk '{nframe++; sum_ee+=$2; print sum_ee / nframe}' > timeavg-EE$n.dat
			avgEEchain=$( tail -n 1 timeavg-EE$n.dat )

cat>>rep-EtoE.dat<<EOF
$n	$avgEEchain
EOF

		# AVERAGE OCCUPATION OF POLYA
			gmx pairdist -f pbc.xtc -s md_slab.tpr -n ../../../index.ndx -ref A${n} -refgrouping none -sel S -selgrouping all -b 100000 -e 10000000 -dt 25000 -o paird-A${n}.xvg
			# occupation at each frame
			sed '/^@/d;/^#/d' paird-A${n}.xvg | awk -v cutoff=$cutoff '{ count=0; for(c=2;c<=NF;c++) { if($c>cutoff) {count++} }; print count/(NF-1)}' > occupation-A$n.dat
			# timeaverage of occupation
			awk '{nframe++; sum_occ+=1; print sum_occ/nframe}' occupation-A$n.dat > timeavg-A$n.dat
			# last value of timeavg of occupation
			avgOcc=$( tail -n 1 timeavg-A$n.dat )
cat>>polyA-occ.dat<<EOF
$n	$avgOcc
EOF


		done

# GYRATION RADIUS		
		# average and error over all chains
		avgRtemp=$( awk '{sum+=$2} END {printf "%.4E" sum/NR}' rep-rgyr.dat )
		errRtemp=$( awk -v avg=avgRtemp '{sum+=($2-avg)^2} END { printf "%.4E", sqrt(sum/(NR-1))}' rep-rgyr.dat )

cat>>../temp-rgyr.dat<<EOF
$t	$avgRtemp	$errRtemp
EOF

cat>>../../es-temp-rgyr.dat<<EOF
$es	$t	$avgRtemp	$errRtemp
EOF

# END-TO-END DISTANCE
		# average and error over all chains
                avgEEtemp=$( awk '{sum+=$2} END {printf "%.4E" sum/NR}' rep-EtoE.dat )
                errEEtemp=$( awk -v avg=avgRtemp '{sum+=($2-avg)^2} END { printf "%.4E", sqrt(sum/(NR-1))}' rep-EtoE.dat )

cat>>../temp-rgyr.dat<<EOF
$t      $avgEEtemp       $errEEtemp
EOF

cat>>../../es-temp-rgyr.dat<<EOF
$es     $t      $avgEEtemp	$errEEtemp
EOF

# OCCUPATION OF POLYA
		# average and error over all chains
		avgOCCtemp=$( awk '{sum+=$2} END {printf "%.4E" sum/NR}' polyA-occ.dat )
		errOCCtemp=$( awk -v avg=avgOCCtemp '{sum+=($2-avg)^2} END { printf "%.4E", sqrt(sum/(NR-1))}' polyA-occ.dat )

cat>>../temp-occ.dat<<EOF
$t	$avgOCCtemp	$errOCCtemp
EOF

cat>>../../es-temp-occ.dat<<EOF
$es	$t	$avgOCCtemp	$avgOCCtemp
EOF






		cd ../
	done

	cd ..

done












