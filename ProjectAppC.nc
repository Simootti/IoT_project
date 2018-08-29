
#include "project.h"

configuration ProjectAppC {}

implementation {

  components MainC, RandomC, projectC as App;
  components new AMSenderC(AM_MY_MSG);	
  components new AMReceiverC(AM_MY_MSG);	
  components ActiveMessageC;
  components new TimerMilliC();

  components new TimerMilliC() as Timer_rout_1C; //Timer for each value of the valid tab_routing (i.e. every position except 0)
  components new TimerMilliC() as Timer_rout_2C;
  components new TimerMilliC() as Timer_rout_3C;
  components new TimerMilliC() as Timer_rout_4C;
  components new TimerMilliC() as Timer_rout_5C;
  components new TimerMilliC() as Timer_rout_6C;
  components new TimerMilliC() as Timer_rout_7C;
  components new TimerMilliC() as Timer_rout_8C;

  components new TimerMilliC() as Timer_rrep_1C; //Timer (for each source) to invalid everything has been sent from this node till the specific destination if RREP doesn't arrive in time
  components new TimerMilliC() as Timer_rrep_2C;
  components new TimerMilliC() as Timer_rrep_3C;
  components new TimerMilliC() as Timer_rrep_4C;
  components new TimerMilliC() as Timer_rrep_5C;
  components new TimerMilliC() as Timer_rrep_6C;
  components new TimerMilliC() as Timer_rrep_7C;
  components new TimerMilliC() as Timer_rrep_8C;

  //Boot interface
  App.Boot -> MainC.Boot;		//the Boot interface must be done always

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  App.Timer_rout_1 -> Timer_rout_1C;
  App.Timer_rout_2 -> Timer_rout_2C;
  App.Timer_rout_3 -> Timer_rout_3C;
  App.Timer_rout_4 -> Timer_rout_4C;
  App.Timer_rout_5 -> Timer_rout_5C;
  App.Timer_rout_6 -> Timer_rout_6C;
  App.Timer_rout_7 -> Timer_rout_7C;
  App.Timer_rout_8 -> Timer_rout_8C;

  App.Timer_rrep_1 -> Timer_rrep_1C;
  App.Timer_rrep_2 -> Timer_rrep_2C;
  App.Timer_rrep_3 -> Timer_rrep_3C;
  App.Timer_rrep_4 -> Timer_rrep_4C;
  App.Timer_rrep_5 -> Timer_rrep_5C;
  App.Timer_rrep_6 -> Timer_rrep_6C;
  App.Timer_rrep_7 -> Timer_rrep_7C;
  App.Timer_rrep_8 -> Timer_rrep_8C;

  //Random interface and its initialization
  App.Random -> RandomC;	
  RandomC <- MainC.SoftwareInit;

}
