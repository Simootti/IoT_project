
#include "project.h"

configuration ProjectAppC {}

implementation {

  components MainC, RandomC, projectC as App;
  components new AMSenderC(AM_MY_MSG);		//Sender e Receiver attivi sul canale AM_MY_MSG
  components new AMReceiverC(AM_MY_MSG);	//AM_MY_MSG is the channel!!!
  components ActiveMessageC;
  components new TimerMilliC();

  //Boot interface
  App.Boot -> MainC.Boot;		//la Boot interface viene fatta sempre


  //Send and Receive interfaces
  	//App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  	//App.PacketAcknowledgements -> ActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Random interface and its initialization
  App.Random -> RandomC;	
  RandomC <- MainC.SoftwareInit;

}

