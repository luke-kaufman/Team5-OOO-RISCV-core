TEST_FOLDER_LOCATION=${1}
C_FILE=${2}

riscv64-unknown-elf-gcc -O1 -march=rv32i -mabi=ilp32 ${TEST_FOLDER_LOCATION}/${C_FILE} -o ${TEST_FOLDER_LOCATION}/curr_test.out
riscv64-unknown-elf-objdump -d ${TEST_FOLDER_LOCATION}/curr_test.out > ${TEST_FOLDER_LOCATION}/curr_disasm

# parse through the disasm file and find line between main: and end of main
# awk '/<main>:/,/^$/' ${TEST_FOLDER_LOCATION}/disasm | awk '!/main:/ {sub(/:/, "]="); print "[32h" $1, "32h" $2}' > ${TEST_FOLDER_LOCATION}/main_disasm_arr.v

# Create main_disasm_arr.v with instr_locs and instr_data arrays
line_count=$(awk '/<main>:/,/^$/{count++} END{print count}' ${TEST_FOLDER_LOCATION}/curr_disasm)
line_count_adj=$(($line_count-2))
echo "int NUM_INSTRS=$line_count_adj;" > ${TEST_FOLDER_LOCATION}/main_disasm_arr.v
echo "int instr_locs[$line_count_adj];" >> ${TEST_FOLDER_LOCATION}/main_disasm_arr.v
echo "int instr_data[$line_count_adj];" >> ${TEST_FOLDER_LOCATION}/main_disasm_arr.v

awk '/<main>:/,/^$/' ${TEST_FOLDER_LOCATION}/curr_disasm | awk '!/<main>:/ {sub(/:/, ""); if ($1 != "") print "instr_locs[" NR-2 "]=" "32h"$1";  instr_data[" NR-2 "]=" "32h"$2"; // " $3,$4,$5,$6,$7,$8,$9,$10,$11,$12}' >> ${TEST_FOLDER_LOCATION}/main_disasm_arr.v
# awk '/<main>:/,/^$/' ${TEST_FOLDER_LOCATION}/disasm | awk '!/<main>:/ {sub(/:/, ""); if ($2 != "") print "}' >> ${TEST_FOLDER_LOCATION}/main_disasm_arr.v
code ${TEST_FOLDER_LOCATION}/main_disasm_arr.v
