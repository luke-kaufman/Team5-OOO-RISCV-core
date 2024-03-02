FLAGS='-g2012 -Wall -Wno-implicit -Wno-portbind -tnull'

MODULE_PATH=$(find . -name ${1}.v)

iverilog ${FLAGS} ${MODULE_PATH}
