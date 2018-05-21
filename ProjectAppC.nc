//WIRING CONFIGURATION
//Serve per connettere le interfaces with components



#include "Project.h"

configuration ProjectAppC {}

implementation {

  components MainC, ProjectC as App;
  components new SenderC(MY_MSG);		//Sender e Receiver attivi sul canale AM_MY_MSG
  components new ReceiverC(MY_MSG);		//AM_MY_MSG is the channel!!!
  components ActiveMessageC;
  components new TimerMilliC();
  components new FakeSensorC();

  //Boot interface
  App.Boot -> MainC.Boot;		//La Boot interface viene fatta sempre

  //*****************Add sendRandMess() interface ***********************//

  //Send and Receive interfaces
  App.Receive -> ReceiverC;
  App.Send -> SenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  //App.AMPacket -> AMSenderC;
  App.Packet -> SenderC;
  App.PacketAcknowledgements -> RandomMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;	// il componenente FakeSensorC l'ha scritto Redondi per SendACK

}

