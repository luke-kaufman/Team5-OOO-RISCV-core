PARAMS=""
for i in "${@:2}"; do
  PARAMS+="-P${1}.${i} "
done
FLAGS="-g2012 -Wall -Wno-implicit -o ${1}.vvp -s ${1} ${PARAMS}"

TESTBENCH_PATH=$(find . -name ${1}.v)

iverilog ${FLAGS} ${TESTBENCH_PATH}
vvp ${1}.vvp
rm ${1}.vvp
