
/*
Author-Shai Kaikov.

Here the class of the slave agent(slave_agent_expected_actual).The class inherit from uvm_agent class.
This agent is inside the Env(arbiter_env).
Here I have four variables-slav_mon_expected_actual(in type of slave_monitor_expected_actual-
the slave monitor),driver_slave(in type of arbiter_driver_slave-the slave driver) and slave_agent_ap_expected_actual
(in type of uvm_analysis_port-TLM).
In addition I have the constructor("new") of this class,build_phase function and connect_phase function.
*/
class slave_agent_expected_actual extends uvm_agent;
  `uvm_component_utils(slave_agent_expected_actual)

  uvm_analysis_port#(arbiter_transaction) slave_agent_ap_expected_actual;
  slave_monitor_expected_actual	slav_mon_expected_actual;
  arbiter_driver_slave driver_slave;
  
  /*
  The constructor of the slave_agent_expected_actual-
  class that inherit from uvm_agent.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
	  super.new(name, parent);
  endfunction
  
  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function I create the slave driver
  and the slave monitor with "create".
  In addition I create the TLM-uvm_analysis_port slave_agent_ap_expected_actual
  with new.
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    slave_agent_ap_expected_actual = new("slave_agent_ap_expected_actual" , this);
    slav_mon_expected_actual = slave_monitor_expected_actual::type_id::create("slav_mon_expected_actual" , this);
    driver_slave=arbiter_driver_slave::type_id::create("driver_slave",this);
  endfunction

  /*
  Here the function connect_phase that get uvm_phase parameter.
  In this function I built the connection between the slave agent(this class)
  with the slave monitor.  
  */
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    slav_mon_expected_actual.mon_slave_expected_actual.connect(slave_agent_ap_expected_actual);
  endfunction
endclass


