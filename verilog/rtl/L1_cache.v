`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2021 09:58:13
// Design Name: 
// Module Name: L1_cache
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


module L1_cache(clk,reset,addr,tag,index,block_offset,find_start,cache_hit_count,found_in_cache,updated,done_L1);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 256;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    parameter cache_line_width = 32-set_index-block_offset_index+1;
    
    input clk,find_start,reset;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg found_in_cache;
    output reg [9:0] cache_hit_count;
    output reg updated,done_L1;
    input [31:0] addr;
    reg [1:0]find_state;
    reg [1:0]flag;
    reg bi_flag;
    reg [way_width:0] way_index;
    reg [way_width-1:0] hit_way;
    reg [cache_line_width-1:0] cache [0:set-1][0:way-1];
    reg [cache_line_width-1:0] temp_content;
    reg [cache_line_width-1:0] temp_content1 [0:way-1];
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;        
        find_state = 0;
        flag = 0;
        bi_flag = 0;
        updated = 0;        
        for (i=0;i<set;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;
            cache_hit_count = 0;
            //cache_miss_count = 0;
            find_state = 0;
            flag = 0;
            bi_flag = 0;
            updated = 0;            
            for (i=0;i<set;i=i+1)
                for (j=0;j<way;j=j+1)
                    cache[i][j] = 0;     
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                        found_in_cache = 1'b0;                        
                        if(find_start)
                        begin                                                 
                            find_state = 2'b01;                        
                            done_L1 = 1'b0;
                        end        
                      end
                      
                2'b01: begin                                                               
                        if (done_L1)
                        begin
                                                            
                            find_state = 2'b10;
                            done_L1 = 1'b0;                              
                        end    
                        else
                        begin
                            for (way_index=0;way_index<way;way_index=way_index+1'b1)
                            begin
                                if(cache[index][way_index][cache_line_width-1]) // valid bit
                                begin
                                    if(cache[index][way_index][cache_line_width-2:0]==tag) // tag comparison
                                    begin
                                        found_in_cache = 1'b1;                                    
                                        hit_way = way_index;                                    
                                        temp_content = cache[index][way_index];
                                        cache_hit_count = cache_hit_count + 1'b1;
                                        done_L1 = 1'b1;                                    
                                    end
                               end                                                                                                                                                                                                                                                                                                                                                                                                                                
                            end                                               
                            if (way_index==way&&!found_in_cache)
                            begin
                                    //cache_miss_count = cache_miss_count + 1'b1; 
                                    found_in_cache = 1'b0;                                
                                    done_L1 = 1'b1;
                            end                                                  
                        end 
                       end
    
                2'b10: begin                    
                        if(updated)
                        begin
                         
                            find_state = 2'b00;
                            updated = 1'b0;
                            
                        end
                        
                        else
                        begin
                            if(found_in_cache) // hit
                            begin  
                                if(hit_way != 0)
                                    begin
                                        cache[index][hit_way] = cache[index][hit_way-1];
                                        hit_way = hit_way - 1;
                                    end
                                    else
                                    begin            
                                        cache[index][0] = temp_content;
                                        updated = 1'b1;
                                    end                                    
                            end 
                            
                            else // miss
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                            
                                    cache[index][way_index+1] = cache[index][way_index];                                    
        
                                cache[index][1] = cache[index][0];
                                cache[index][0] = {1'b1,tag};  
                                updated = 1'b1;                                                  
                            end                                                                                                                                                                                                              
                        end 
                                                  
                       end                     
            endcase
         end       
    end   
    
endmodule
