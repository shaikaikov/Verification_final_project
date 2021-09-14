
/*
Author-Shai Kaikov.

Here the class of the host agent(host_agent_expected_actual).The class inherit from uvm_agent class.
This agent is inside the Env(arbiter_env).
Here I have four variables-hos_mon_expected_actual(in type of host_monitor_expected_actual-
the host monitor),driver_host(in type of arbiter_driver_host-the host driver),
arbiter_seqr(in the type of arbiter_sequencer-the host sequencer) and host_agent_ap_expected_actual
(in type of uvm_analysis_port-TLM).
In addition I have the constructor("new") of this class,build_phase function and connect_phase function.
*/
class host_agent_expected_actual extends uvm_agent;
  `uvm_component_utils(host_agent_expected_actual)

  uvm_analysis_port#(arbiter_transaction) host_agent_ap_expected_actual;
  host_monitor_expected_actual	hos_mon_expected_actual;
  arbiter_driver_host driver_host;
  arbiter_sequencer arbiter_seqr;

  /*
  The constructor of the host_agent_expected_actual-
  class that inherit from uvm_agent.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
	  super.new(name, parent);
  endfunction

  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function I create the host sequencer,the host driver and
  the host monitor with "create".
  In addition I create the TLM-uvm_analysis_port host_agent_ap_expected_actual
  with new.
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    host_agent_ap_expected_actual = new("host_agent_ap_expected_actual" , this);
    arbiter_seqr = arbiter_sequencer::type_id::create("arbiter_seqr" , this);
    driver_host = arbiter_driver_host::type_id::create("driver_host" , this);
    hos_mon_expected_actual = host_monitor_expected_actual::type_id::create("hos_mon_expected_actual" , this);
  endfunction
  
  /*
  Here the function connect_phase that get uvm_phase parameter.
  In this function I built the connection between the host driver 
  with the host sequencer and the connection between the host agent(this class)
  with the host monitor. 
  */
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver_host.seq_item_port.connect(arbiter_seqr.seq_item_export);
    hos_mon_expected_actual.mon_host_expected_actual.connect(host_agent_ap_expected_actual);
  endfunction
endclass


