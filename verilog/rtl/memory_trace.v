`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.01.2022 01:40:32
// Design Name: 
// Module Name: memory_trace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module memory_trace(clk,reset,updated,trace_ready,mem_addr);

    input clk,reset,updated;
    output reg trace_ready;
    output reg [31:0] mem_addr;
    
    reg [31:0] trace_file [0:9];
    reg [3:0] addr;
    
    initial
    begin
        trace_file[0] = 32'b00000100010000110010000010010000;
        trace_file[1] = 32'b00000100010000110010000010010001;
        trace_file[2] = 32'b00000100010000110010000010010010;
        trace_file[3] = 32'b00000100010000110010000010010011;
        trace_file[4] = 32'b00000100010000110010000010010100;
        trace_file[5] = 32'b00000100010000110010000010010101;
        trace_file[6] = 32'b00000100010000110010000010010110;
        trace_file[7] = 32'b00000100010000110010000010010111;
        trace_file[8] = 32'b00000100010000110010000010010000;
        trace_file[9] = 32'b00000100010000110010111111000101;
        addr = 3'b000;
        mem_addr = trace_file[0];
        trace_ready = 1'b1;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            mem_addr = 32'b0;
            trace_ready = 1'b0;
        end
        else
        begin 
            if(updated)
            begin
                addr = addr + 1'b1;
                trace_ready  = 1'b1;
                mem_addr = trace_file[addr];                
            end
            else
                trace_ready = 1'b0;
        end    
    end
endmodule
