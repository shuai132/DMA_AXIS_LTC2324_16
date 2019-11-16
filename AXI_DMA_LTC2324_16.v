module AXI_DMA_LTC2324_16(
    input               adc_clk,
    input               adc_rst_n,

    // ADC
    output              adc_CNV,
    output              adc_SCK,
    input               adc_CLKOUT,
    input               adc_SDO1,
    input               adc_SDO2,
    input               adc_SDO3,
    input               adc_SDO4,

    input[31:0]         sample_len,
    input               sample_start,
    output reg          st_clr,
    input[7:0]          ch_sel,

    output[15:0]        DMA_AXIS_tdata,
    output[1:0]         DMA_AXIS_tkeep,
    output              DMA_AXIS_tlast,
    input               DMA_AXIS_tready,
    output              DMA_AXIS_tvalid,
    input[0:0]          DMA_RST_N,
    input               DMA_CLK
);

parameter       TEST_MODE   = 1'b0;
   
localparam      S_IDLE      = 0;
localparam      S_SAMPLE    = 1;
localparam      S_SAMP_WAIT = 2;

reg[31:0]       sample_cnt;
reg[7:0]        wait_cnt;
reg[2:0]        state;
   
reg             fifo_wr_en;
reg[15:0]       fifo_din;

reg             sample_start_d0;
reg             sample_start_d1;
reg             sample_start_d2;
reg[31:0]       sample_len_d0;
reg[31:0]       sample_len_d1;
reg[31:0]       sample_len_d2;
reg[7:0]        ch_sel_d0;
reg[7:0]        ch_sel_d1;
reg[7:0]        ch_sel_d2;
                
reg[31:0]       dma_len_d0;
reg[31:0]       dma_len_d1;
reg[31:0]       dma_len_d2;
reg[31:0]       dma_len;
reg[31:0]       dma_cnt;

reg             tvalid_en;
wire[9:0]       fifo_rd_data_count;
wire            fifo_rd_en;
reg             fifo_rd_en_d0;
wire            fifo_empty;

reg             adc_buf_en;
reg[3:0]        write_cnt;
localparam      write_num   = 4'd3;

wire            adc_data_valid;
wire[15:0]      adc_ch1;
wire[15:0]      adc_ch2;
wire[15:0]      adc_ch3;
wire[15:0]      adc_ch4;


always@(posedge adc_clk or negedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
    begin
        sample_start_d0 <= 1'b0;
        sample_start_d1 <= 1'b0;
        sample_start_d2 <= 1'b0;
        sample_len_d0   <= 32'd0;
        sample_len_d1   <= 32'd0;
        sample_len_d2   <= 32'd0;
        ch_sel_d0       <= 8'd0;
        ch_sel_d1       <= 8'd0;
        ch_sel_d2       <= 8'd0;
    end
    else
    begin
         sample_start_d0 <= sample_start;
         sample_start_d1 <= sample_start_d0;
         sample_start_d2 <= sample_start_d1;
         sample_len_d0   <= sample_len;
         sample_len_d1   <= sample_len_d0;
         sample_len_d2   <= sample_len_d1;
         ch_sel_d0       <= ch_sel;
         ch_sel_d1       <= ch_sel_d0;
         ch_sel_d2       <= ch_sel_d1;
     end
end

always@(posedge adc_clk or posedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
    begin
        state <= S_IDLE;
        wait_cnt <= 8'd0;
        sample_cnt <= 32'd0;
    end
    else
        case(state)
            S_IDLE:
            begin
              if (sample_start_d2)
              begin
                state  <= S_SAMP_WAIT;
                st_clr <= 1'b1;
              end
            end
            S_SAMP_WAIT :
            begin
              if(wait_cnt == 8'd20)
              begin
                state    <= S_SAMPLE;
                wait_cnt <= 8'd0;
              end
              else
              begin
                  wait_cnt <= wait_cnt + 8'd1;
              end
              st_clr <= 1'b0;
            end
            S_SAMPLE:
            begin
              if (adc_data_valid)
              begin
                if(sample_cnt == sample_len_d2 - 1)
                begin
                    sample_cnt <= 32'd0;
                    state <= S_IDLE;
                end
                else
                begin
                    sample_cnt <= sample_cnt + 32'd1;
                end
              end
            end
            default:
                state <= S_IDLE;
        endcase
end


always@(posedge adc_clk or posedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
       adc_buf_en <= 1'b0;
    else if (state == S_SAMPLE && adc_data_valid)
       adc_buf_en <= 1'b1;
    else if (write_cnt == write_num)
       adc_buf_en <= 1'b0;
end

always@(posedge adc_clk or posedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
       write_cnt <= 4'd0;
    else if (adc_buf_en)
       write_cnt <= write_cnt + 1'b1;
    else
       write_cnt <= 4'd0;
end

always@(posedge adc_clk or posedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
    begin
      fifo_din <= 16'd0;
    end
    else
    begin
      case(write_cnt)
        4'd0   :  fifo_din <= adc_ch1;
        4'd1   :  fifo_din <= adc_ch2;
        4'd2   :  fifo_din <= adc_ch3;
        4'd3   :  fifo_din <= adc_ch4;
        default :  fifo_din <= 16'h5AA5;
      endcase
    end
end

always@(posedge adc_clk or posedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
       fifo_wr_en <= 1'b0;
    else
       fifo_wr_en <= adc_buf_en;
end

afifo afifo_inst
(
  .rst              (~DMA_RST_N     ),
  .wr_clk           (adc_clk        ),
  .rd_clk           (DMA_CLK        ),
  .din              (fifo_din       ),
  .wr_en            (fifo_wr_en     ),
  .rd_en            (fifo_rd_en     ),
  .dout             (DMA_AXIS_tdata ),
  .full             (               ),
  .empty            (fifo_empty     ),
  .rd_data_count    (fifo_rd_data_count),
  .wr_data_count    (               )
);


LTC2324_16
#(.USE_SCK_SHIFT_DATA(TEST_MODE))
LTC2324_16_inst
(
    .clk        (adc_clk),
    .rst_n      (adc_rst_n),

    .CNV        (adc_CNV),
    .SCK        (adc_SCK),
    .CLKOUT     (adc_CLKOUT),
    .SDO1       (adc_SDO1),
    .SDO2       (adc_SDO2),
    .SDO3       (adc_SDO3),
    .SDO4       (adc_SDO4),

    .sample_en  (state == S_SAMPLE),

    .valid      (adc_data_valid),
    .ch1        (adc_ch1),
    .ch2        (adc_ch2),
    .ch3        (adc_ch3),
    .ch4        (adc_ch4)
);


assign fifo_rd_en = DMA_AXIS_tready && ~fifo_empty;

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        fifo_rd_en_d0 <= 1'b0;
    else
        fifo_rd_en_d0 <= fifo_rd_en;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        tvalid_en <= 1'b0;
    else if (fifo_rd_en_d0 & ~DMA_AXIS_tready)
        tvalid_en <= 1'b1;
    else if (DMA_AXIS_tready)
        tvalid_en <= 1'b0;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
    begin
        dma_len_d0  <= 32'd0;
        dma_len_d1  <= 32'd0;
        dma_len_d2  <= 32'd0;
    end
    else
    begin
         dma_len_d0 <= sample_len;
         dma_len_d1 <= dma_len_d0;
         dma_len_d2 <= dma_len_d1;
     end
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        dma_len <= 32'd0;
    else if (fifo_rd_data_count > 10'd0)
        dma_len <= dma_len_d2;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        dma_cnt <= 32'd0;
    else if (DMA_AXIS_tvalid & ~DMA_AXIS_tlast)
        dma_cnt <= dma_cnt + 1'b1;
    else if (DMA_AXIS_tvalid & DMA_AXIS_tlast)
        dma_cnt <= 32'd0;
end

assign DMA_AXIS_tkeep  = 2'b11;
assign DMA_AXIS_tvalid = DMA_AXIS_tready & (tvalid_en | fifo_rd_en_d0);
assign DMA_AXIS_tlast  = DMA_AXIS_tvalid & (dma_cnt == (dma_len << 2) - 1);

endmodule
