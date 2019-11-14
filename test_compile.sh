#!/usr/bin/env bash

# 编译测试AXI_DMA_LTC2324_16.v语法问题

mkdir -p tmp                                            \
&& iverilog -o tmp/test_compile.vvp AXI_DMA_LTC2324_16.v LTC2324_16.v fake/afifo.v  \
&& cd tmp                                               \
&& ./test_compile.vvp
