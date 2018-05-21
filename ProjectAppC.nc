//WIRING CONFIGURATION
//Serve per connettere le interfaces with components



#include "Project.h"

configuration ProjectAppC {}

implementation {

  components MainC, ProjectC as App;
  components new AMSenderC(AM_MY_MSG);		//Sender e Receiver attivi sul canale AM_MY_MSG
  components new AMReceiverC(AM_MY_MSG);		//AM_MY_MSG is the channel!!!
  components ActiveMessageC;
  components new TimerMilliC();
  components new FakeSensorC();

  //Boot interface
  App.Boot -> MainC.Boot;		//La Boot interface viene fatta sempre


  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> ActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;	// il componenente FakeSensorC l'ha scritto Redondi per SendACK

}

