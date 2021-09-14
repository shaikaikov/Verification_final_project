
/*
Author-Shai Kaikov.

Here the class of the arbiter_transaction(transaction).
The class inherit from uvm_sequence_item class.
The class contains the variables-cpu flag-cpu_general,addr_general(address),
be_general(enbale),write flag-wr_general,read flag-rd_general,
data write-dwr_general,data read-drd_general and ack_host_general(ack).
In addition I have constraint with compelling that the two flags
of read and write(together) will not be one.
In addition here I have constructor(new) for this class. 
*/
class arbiter_transaction extends uvm_sequence_item;
  `uvm_object_utils(arbiter_transaction)      
  bit cpu_general;
  rand bit [31:0]addr_general;
  rand bit rd_general;
  rand bit wr_general;
  rand bit [3:0] be_general;
  rand bit [31:0] dwr_general;
  rand bit [31:0] drd_general;
  bit[1:0] ack_host_general;
  rand bit ack_slave;
  constraint if_rd_wr_is_both_one{
    ((rd_general==1 && wr_general==1)!=1);
  }

  /*
  The constructor of the arbiter_transaction-
  class that inherit from uvm_sequence_item.
  The default parameter of the constructor is string(name).
  */
  function new(string name = "");
    super.new(name);
  endfunction
endclass

