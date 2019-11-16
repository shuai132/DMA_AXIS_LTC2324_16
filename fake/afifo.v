module afifo(
    input           rst             ,
    input           wr_clk          ,
    input           rd_clk          ,
    input[15:0]      din            ,
    input           wr_en           ,
    input           rd_en           ,
    input[15:0]      dout           ,
    output          full            ,
    output          empty           ,
    output[9:0]     rd_data_count   ,
    output[9:0]     wr_data_count  );

endmodule
