
/*
Author-Shai Kaikov.

Here the class of the test(arbiter_test).
The class inherit from uvm_test class.
The test is inside the top.
Here I have the Env object(arbiter_en in type of arbiter_env). 
In addition there is also constructor("new") of this class,build_phase function and run_phase function.
This class responsible for operating a verification environment.
*/
class arbiter_test extends uvm_test;
  `uvm_component_utils(arbiter_test)

  arbiter_env arbiter_en;//Env(arbiter_env) object

  /*
  The constructor of the arbiter_test-
  class that inherit from uvm_test.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function I create the arbiter_en object(type of arbiter_env). 
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    arbiter_en=arbiter_env::type_id::create("arbiter_en" , this);
  endfunction

  /*
  Here the task run_phase that get uvm_phase parameter.
  In this task I defined and created four sequence objects(in type of arbiter_sequence)- so I built four threads 
  in each of which the sequence starts working together with each of its sequencer - so that it will send transactions.
  In the end I gather all the coverage and print.   
  */
  task run_phase(uvm_phase phase);
    arbiter_sequence arbiter_seq_one;
	  arbiter_sequence arbiter_seq_two;
	  arbiter_sequence arbiter_seq_three;
	  arbiter_sequence arbiter_seq_four;
	  phase.raise_objection(.obj(this));
    arbiter_seq_one=arbiter_sequence::type_id::create("arbiter_seq_one");
    arbiter_seq_two=arbiter_sequence::type_id::create("arbiter_seq_two");
    arbiter_seq_three=arbiter_sequence::type_id::create("arbiter_seq_three");
    arbiter_seq_four=arbiter_sequence::type_id::create("arbiter_seq_four");
    fork
      arbiter_seq_one.start(arbiter_en.hos_agent_expected_actual_one.arbiter_seqr);
      arbiter_seq_two.start(arbiter_en.hos_agent_expected_actual_two.arbiter_seqr);
      arbiter_seq_three.start(arbiter_en.hos_agent_expected_actual_three.arbiter_seqr);
      arbiter_seq_four.start(arbiter_en.hos_agent_expected_actual_four.arbiter_seqr);
    join
    `uvm_info("COVERAGE",$sformatf("Coverage= %0.2f %%",$get_coverage()), UVM_LOW)
	  phase.drop_objection(.obj(this));
  endtask
endclass







