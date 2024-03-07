FLAGS='-g2012 -Wall -Wno-implicit -Wno-portbind -tnull'

MODULE_PATH=$(find . -name ${1}.v -o -name ${1}.sv)

iverilog ${FLAGS} ${MODULE_PATH}
