
/*
Author-Shai Kaikov.

Here the interface of the host.The interface include address(addr_general),
enbale(be_general),write flag(wr_general),read flag(rd_general),
data write(dwr_general),data read(drd_general) and ack(ack_host_general).
In addition its include clock(clk),reset flag(reset_n) and cpu flag(cpu_general) that are
can change in the arbiter_top module. 
*/
interface arbiter_if_host(input logic clk,input logic reset_n,input logic cpu_general);
  logic [31:0] addr_general;
  logic [3:0] be_general;
  logic wr_general;
  logic rd_general;
  logic [31:0] dwr_general;
  logic [31:0] drd_general;
  logic [1:0] ack_host_general;
  modport DUT_MASTER (input cpu_general,input addr_general,input rd_general,input wr_general,input be_general,input dwr_general,output drd_general,output ack_host_general,input clk,input reset_n);   
endinterface

