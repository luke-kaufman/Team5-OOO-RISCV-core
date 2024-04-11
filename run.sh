if [[ "$(hostname)" == "iam-ssh1" ]]; then
    echo "Switch to a compute node to run the simulation"
    echo "Use the command: qsub-sim"
    exit 1
fi

TESTBENCH_PATH=$(find . -name ${1}.v -o -name ${1}.sv)

if [[ "$(hostname)" == "vsc"* ]]; then
    FLAGS='-sv -lint'
    # FLAGS+=' -suppress 2605'
    # FLAGS+=',2623'
    VERILOG=vlog
else
    PARAMS=""
    for i in "${@:2}"; do
      PARAMS+="-P${1}.${i} "
    done
    FLAGS="-g2012 -Wall -Wno-implicit -o ${1}.vvp -s ${1} ${PARAMS}"
    VERILOG=iverilog
fi

rm -rf $(find . -type d -name work)
${VERILOG} ${FLAGS} ${TESTBENCH_PATH}

if [[ "$(hostname)" == "vsc"* ]]; then
    vsim -c -L stdcells -sv_seed 1 -do "run -all; quit" ${1}
else
    vvp ${1}.vvp
    rm ${1}.vvp
fi
