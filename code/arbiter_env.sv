
/*
Author-Shai Kaikov.

Here the class of the arbiter_env(Env).The class inherit from uvm_env class.
The arbiter_env is inside the test.
Here I have the all four host agents objects(in type of host_agent_expected_actual)
-hos_agent_expected_actual_one,hos_agent_expected_actual_two,
hos_agent_expected_actual_three,hos_agent_expected_actual_four 
and one slave agent(in type of slave_agent_expected_actual)-slav_agent_expected_actual.
I have scoreboard object also. 
In addition here I have the constructor("new") of this class,build_phase function
and connect_phase function.
*/
class arbiter_env extends uvm_env;
  `uvm_component_utils(arbiter_env)

  //the slave agent.
  slave_agent_expected_actual slav_agent_expected_actual;
  //all four host agents.
  host_agent_expected_actual hos_agent_expected_actual_one;
  host_agent_expected_actual hos_agent_expected_actual_two;
  host_agent_expected_actual hos_agent_expected_actual_three;
  host_agent_expected_actual hos_agent_expected_actual_four;
  //the scoreboard.
  arbiter_scoreboard arb_scb;
  
  /*
  The constructor of the arbiter_env-
  class that inherit from uvm_env.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function I create all the agents and scoreboard objects
  with "create".
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    slav_agent_expected_actual=slave_agent_expected_actual::type_id::create("slav_agent_expected_actual" , this);
    hos_agent_expected_actual_one=host_agent_expected_actual::type_id::create("hos_agent_expected_actual_one" , this);
    hos_agent_expected_actual_two=host_agent_expected_actual::type_id::create("hos_agent_expected_actual_two" , this);
    hos_agent_expected_actual_three=host_agent_expected_actual::type_id::create("hos_agent_expected_actual_three" , this);
    hos_agent_expected_actual_four=host_agent_expected_actual::type_id::create("hos_agent_expected_actual_four" , this);
    arb_scb=arbiter_scoreboard::type_id::create("arb_scb" , this);
  endfunction
  
  /*
  Here the function connect_phase that get uvm_phase parameter.
  In this function I built the connections between the agents to the scoreboard. 
  */
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    slav_agent_expected_actual.slave_agent_ap_expected_actual.connect(arb_scb.scb_export_slave);
    hos_agent_expected_actual_one.host_agent_ap_expected_actual.connect(arb_scb.scb_export_host[0]);
    hos_agent_expected_actual_two.host_agent_ap_expected_actual.connect(arb_scb.scb_export_host[1]);
    hos_agent_expected_actual_three.host_agent_ap_expected_actual.connect(arb_scb.scb_export_host[2]);
    hos_agent_expected_actual_four.host_agent_ap_expected_actual.connect(arb_scb.scb_export_host[3]);
  endfunction
endclass



