
#include "project.h"

configuration ProjectAppC {}

implementation {

  components MainC, RandomC, projectC as App;
  components new AMSenderC(AM_MY_MSG);		//Sender e Receiver attivi sul canale AM_MY_MSG
  components new AMReceiverC(AM_MY_MSG);	//AM_MY_MSG is the channel!!!
  components ActiveMessageC;
  components new TimerMilliC();

  components new TimerMilliC() as Timer_rout_1C;
  components new TimerMilliC() as Timer_rout_2C;
  components new TimerMilliC() as Timer_rout_3C;
  components new TimerMilliC() as Timer_rout_4C;
  components new TimerMilliC() as Timer_rout_5C;
  components new TimerMilliC() as Timer_rout_6C;
  components new TimerMilliC() as Timer_rout_7C;
  components new TimerMilliC() as Timer_rout_8C;

  

  
  

  //Boot interface
  App.Boot -> MainC.Boot;		//la Boot interface viene fatta sempre


  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  	//App.PacketAcknowledgements -> ActiveMessageC;

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

  //Random interface and its initialization
  App.Random -> RandomC;	
  RandomC <- MainC.SoftwareInit;

}

