module fifo_buffer (
    input  wire clk,
    input  wire rst_n,
    input  wire wr_en,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    reg [7:0] mem [0:3];
    reg [1:0] wr_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 2'b00;
            dout   <= 8'h00;
        end else if (wr_en) begin
            mem[wr_ptr] <= din;
            dout        <= din;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end
endmodule

