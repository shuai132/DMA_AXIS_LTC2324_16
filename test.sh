#!/usr/bin/env bash
mkdir -p tmp                                            \
&& iverilog -o tmp/test.vvp testbench.v LTC2324_16.v    \
&& cd tmp                                               \
&& ./test.vvp > /dev/null                               \
&& open -a Scansion test.vcd
