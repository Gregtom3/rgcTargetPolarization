#!/bin/bash

clas12root -b -q '/work/clas12/users/gmat/rgcTargetPolarization/slurm/scanRecon.C('${1}',"'${2}'","'${4}'")'

mv "${2}-${1}-HELScaler.csv" "${3}/run${1}_HELScaler.csv"
mv "${2}-${1}-RUNScaler.csv" "${3}/run${1}_RUNScaler.csv"

clas12root -b -q '/work/clas12/users/gmat/rgcTargetPolarization/slurm/scanReconBig.C('${1}',"'${2}'","'${4}'")'

mv "${2}-${1}-HELScaler-all.csv" "${3}/run${1}_HELScaler-all.csv"
mv "${2}-${1}-RUNScaler-all.csv" "${3}/run${1}_RUNScaler-all.csv"



