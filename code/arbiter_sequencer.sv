
/*
Author-Shai Kaikov.

Here the class of the host sequencer(arbiter_sequencer).
The class inherit from uvm_sequencer class.
The sequencer is inside the host agent.
Here I have the constructor("new") of this class.
*/
class arbiter_sequencer extends uvm_sequencer#(arbiter_transaction);
  `uvm_component_utils(arbiter_sequencer)

  /*
  The constructor of the arbiter_sequencer-
  class that inherit from uvm_sequencer.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
	  super.new(name,parent);
  endfunction
endclass



