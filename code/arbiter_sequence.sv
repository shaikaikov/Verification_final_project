
/*
Author-Shai Kaikov.

Here the class of the host sequence(arbiter_sequence).
The class inherit from uvm_sequence class.
The sequence is inside the test(arbiter_test).
Here I have the constructor("new") of this class and the task body.

The role of this class is to create randomize transactions and to send them to the driver.
*/
class arbiter_sequence extends uvm_sequence#(arbiter_transaction);
  `uvm_object_utils(arbiter_sequence)
 
  /*
  The constructor of the arbiter_sequence-
  class that inherit from uvm_sequence.
  The default parameter of the constructor is string(name).
  */
  function new(string name = "");
    super.new(name);
  endfunction

  /*
  Here the task body.In this task I create a new transaction in every loop
  -and randomize data to this transaction-the randomize is done  
  after the sequencer knows that a new transaction can be send(start_item).
  After the randomization the transaction need to be send to the driver(by finish_item).
  */
  task body();
    arbiter_transaction arbiter_tran;
    repeat(3001) begin
	  arbiter_tran = arbiter_transaction::type_id::create("arbiter_tran");
	  start_item(arbiter_tran);
	  assert(arbiter_tran.randomize());
	  finish_item(arbiter_tran);
	end
    `uvm_info("end",$sformatf("finsih!"),UVM_LOW)//host finished with the transactions(at least one of them)
  endtask
endclass

