MODULE_PATH=$(find . -name ${1}.v -o -name ${1}.sv -o -name ${1}.vh -o -name ${1}.svh)

if [[ "$(hostname)" == "iam-ssh1" ]] || [[ "$(hostname)" == "vsc"* ]]; then
    FLAGS='-sv -lint -suppress 2605,2623'
    VERILOG=vlog
else
    FLAGS='-g2012 -Wall -Wno-implicit -Wno-portbind -tnull'
    VERILOG=iverilog
fi

${VERILOG} ${FLAGS} ${MODULE_PATH}
