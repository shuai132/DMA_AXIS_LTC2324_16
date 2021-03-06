#!/usr/bin/env bash

# 编译仿真测试LTC2324_16.v时序

mkdir -p tmp                                            \
&& iverilog -o tmp/test.vvp testbench.v AXI_DMA_LTC2324_16.v LTC2324_16.v fake/afifo.v  \
&& cd tmp                                               \
&& ./test.vvp > /dev/null                               \
&& open -a Scansion test.vcd
