#!/bin/sh

export PATH=/opt/altera/quartus/bin:$HOME/.platformio/penv/bin:$PATH

echo "Building AVR sources"

cd avr

# normal firmware
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=1 -Wall"
pio run
cp .pio/build/ATmeta328/firmware.hex ../../releases/profi/karabas_pro.hex

pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=1 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/karabas_pro_revA.hex

# kvm ready firmware
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -Wall"
pio run
cp .pio/build/ATmeta328/firmware.hex ../../releases/profi/karabas_pro_kvm.hex

pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=0 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/karabas_pro_revA_kvm.hex

pio run -t clean

exit

echo "Done"

cd ..

echo "Building FPGA sources"

cd fpga/profi/syn

make clean
make version
make all
make jic
make unversion

cp karabas_pro_tda1543.jic ../../../../releases/profi/karabas_pro_tda1543.jic
cp karabas_pro_tda1543a.jic ../../../../releases/profi/karabas_pro_tda1543a.jic
cp karabas_pro.rbf ../../../../releases/profi/karabas_pro.rbf

make clean

echo "Done"

cd ../../../

echo "Building CPLD sources"

cd cpld/syn

make clean
make all

cp karabas_pro_cpld.pof ../../../releases/profi/karabas_pro_cpld.pof

make clean

echo "Done"

cd ../../

