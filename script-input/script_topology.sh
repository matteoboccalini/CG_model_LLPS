#!/bin/bash

#======= README ================
#
#
#
#
#   07.03.2023  Modified with Davide.
#               New params.
#
#===============================

name=lambda_1.2_V0_15
#---------------------------------------
lambda=1.2
eps_AH=`echo "$lambda * 2.479" | bc `
en_scale=15
V0=`echo "$en_scale * 2.479" | bc `
#--------------------------------------
n_polyA=20
n_B=2000
lenght_polyA=100
#---------------------------------------
sigma_A=1
sigma_B_site=1
sigma_B_core=3
#----------------------------------------
r0_B=2.3   #`echo "0.5*$sigma_B_site + 0.5*$sigma_B_core" | bc`
kb_B=1000
r0_polyA=1.5
kb_polyA=1000
#---------------------------------------
echo "                                  "
echo "----------------------------------"
echo "       SCRIPT FOR TOPOLOGY        "
echo "          CG_model_LLPS           "
echo "----------------------------------"
echo "                                  "
echo "                                  "
echo "  Parametres:                     "
echo "  name            = " $name
echo "  number of polyA = " $n_polyA
echo "  number of B     = " $n_B
echo "  lenght of polyA = " $lenght_polyA
echo "                                  "
echo "  sigma_A         = " $sigma_A
echo "  sigma_B_core    = " $sigma_B_core
echo "  sigma_B_site    = " $sigma_B_site
echo "                                  "
echo "  Bond params:                    "
echo "  r0_polyA []     = " $r0_polyA
echo "  k0_polyA []     = " $kb_polyA
echo "  r0_B []         = " $r0_B
echo "  k0_B []         = " $kb_B
echo "                                  "
echo "  Nonbond params:                 "
echo "  eps_eff (A-H)   = " $eps_AH
echo "  lambda (A-H)    = " $lambda
echo "  V_0 (Wingreen)  = " $V0
echo "  en. scale (W.)  = " $en_scale
echo "----------------------------------"
echo "                                  "
echo "  generated file:" topol.top
echo "                                  "
echo "----------------------------------"
echo "                                  "

cat > topol.top<<EOF

;  ---------------------------------- 
;         SCRIPT FOR TOPOLOGY         
;            CG_model_LLPS            
;
;       created:  $(date)
;       location: $(pwd)
;       
; 
;  ---------------------------------- 
;                                     
;                                     
;    Parametres:                      
;    name            =   $name
;    number of polyA =   $n_polyA
;    number of B     =   $n_B
;    lenght of polyA =   $lenght_polyA
;                                     
;    sigma_A         =   $sigma_A
;    sigma_B_core    =   $sigma_B_core
;    sigma_B_site    =   $sigma_B_site
;    
;                                     
;    Bond params:                     
;    r0_polyA []     =   $r0_polyA
;    k0_polyA []     =   $kb_polyA
;    r0_B []         =   $r0_B
;    k0_B []         =   $kb_B
;  
;    Nonbond params:                 
;    eps_eff (A-H)   =   $eps_AH
;    lambda          =   $lambda
;    V_0             =   $V0
;    energy scale    =   $en_scale
;                                  
;  ---------------------------------- 

EOF

cat >> topol.top<<EOF
; Topology file for Gromacs.          
 [ defaults ]
; nbfunc comb-rule gen-pairs 
   1         1      yes

EOF

cat >> topol.top<<EOF

 [ atomtypes ]
;name      mass     charge   ptype    V      W
 A         100.	    0.00       A      1      0
 C	   100.	    0.00       A      1	     $eps_AH
 S         100.     0.00       A      1      0

EOF

cat>>topol.top<<EOF
 [ nonbond_params ]
;ai      aj        func     V     W                                                                                        
 A       A 	    1       1	  0
 A       C          1       1     0
 A       S	    1       0	  $V0
 C       C	    1       1     $eps_AH
 S       C	    1	    1	  0
 S       S	    1	    1	  0

EOF


cat >> topol.top<<EOF
 [ moleculetype ]
 ;name   nrexcl
 polyA      1

 [ atoms ]
; nr    type    resnr    residue atom  cgnr 
EOF

for (( A_i=1; A_i<=$lenght_polyA; A_i++  ))

    do
 
    printf "  %i\t%s\t%i\t%s\t%s\t%i\n" $A_i  A $A_i A A $A_i >> topol.top # ;nr  type  resnr residue atom  cgnr charge  mass 
    
    done

cat >> topol.top<<EOF

 [ bonds ]
 ;ai     aj      func       r0(nm)          Kb
EOF

for (( A_i=1; A_i<$lenght_polyA; A_i++  ))

   do

   printf "  %i\t%i\t%i\t%f\t%f\n" $A_i  $(($A_i + 1))  1  $r0_polyA  $kb_polyA >> topol.top  
       
   done

cat >> topol.top<<EOF

 [ moleculetype ]                                                                                                                    
 ;name   nrexcl                                                                                                                       
 B      1                                                                                                                         
                                                                                                                                      
 [ atoms ]                                                                                                                            
;nr   type    resnr residue  atom    cgnr       
  1    C         1    B	      C       1   
  2    S         2    B       S       2   

 [ bonds ]                                                                                                                             
 ;ai     aj      func     r0(nm)   Kb 
   1      2        1      $r0_B    $kb_B

EOF


cat >> topol.top<<EOF 
 [ system ]
;name
 $name

 [ molecules ]
;name      #mol
 polyA      $n_polyA
 B	    $n_B

EOF
