#!/usr/bin/env bash
mkdir -p tmp                                            \
&& iverilog -o tmp/test.vvp testbench.v LTC2324_16.v    \
&& cd tmp                                               \
&& ./test.vvp                                           \
&& open -a Scansion test.vcd
