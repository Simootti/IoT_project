
#include "project.h"
#include "Timer.h"

module projectC {

  uses {
	interface Boot;
	interface Random;
    	interface AMPacket;	//to turning on the Radio and can modify the pkt I want to transmit
	interface Packet;			
	//interface PacketAcknowledgements;
    	interface AMSend;			//interface to transmit the message
    	interface SplitControl;			//used basically to turning on the radio
    	//interface Receive;
    	interface Timer<TMilli> as MilliTimer;
	//interface Read<uint16_t>;		//used to read Data from a sensor
  }

} implementation {

  uint32_t counter=0;
  uint8_t rec_id;
  my_msg_t* mess;
  message_t packet;
  uint8_t num=0;
  uint8_t n;
  tab_t tab_complete[8];
  

  task void sendRandmsg();
  //task void creationRoutTab();

  
  //******************************Point 1 of project*********************************//
  

 task void sendRandmsg() {
	
	num = (call Random.rand16() % 8) + 1;

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = REQ;
	mess->msg_id = counter++;
	mess->value = call Random.rand16();
	mess->dst_add = num;
	
	for (n=0; tab_complete[n].dst_add != mess->dst_add && n<9; n++){ //TODO pensare al valore 9 (lunghezza dell'array)
	}
	if (tab_complete[n].dst_add == mess->dst_add){
		printf ("Find a match with destination \n");
		printf ("Send to next-hop \n");
	}else{
		printf ("Do not find a match, updating a routing table \n");
		//TODO aggiornamento tabella , broadcast req
	}
	
 	if(call AMSend.send(num,&packet,sizeof(my_msg_t)) == SUCCESS){	
	  dbg("radio_send", "SendRandmsg successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
	  dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      
      }
  }

  //******************************Point 2 of project*********************************//	
/*
  task void creationRoutTab() {
  	
	for (n=0; mess->dst_add == tab_t[n].dst_add; n++){
			
	}
	
	
	
	//mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = ROUTE_REQ;
	dbg_clear("Verify the type of message....", "msg_type: %hhu", mess->msg_type);

	if(call AMSend.send(BROADCAST,&packet,sizeof(my_msg_t)) == SUCCESS){
		dgb_clear("Pacchetto inviato in Broadcast come ROUTE REQ");	
	}
  
  }
*/


  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();	
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){

    if(err == SUCCESS) {
		dbg("radio","Radio %d on!\n", TOS_NODE_ID);
		if ( TOS_NODE_ID ) {
		dbg("role","I'm node %d: start sending periodical request\n" , TOS_NODE_ID );
		call MilliTimer.startPeriodic( 30000 );
		}
    }
    else{
	call SplitControl.start();
    }
  
  

  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {		
	post sendRandmsg();				
  }

  //********************* AMSend interface *********************//

  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	
	dbg("radio_send", "Packet sent...");
					
	} else {
	  dbg_clear("radio_ack", "but ack was not received"); 		
	}
	
	dbg_clear("radio_send", " at time %s \n", sim_time_string());

    }

  }	

  //***************************** Receive interface ********************************//
/*
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	my_msg_t* mess=(my_msg_t*)payload;
	rec_id = mess->msg_id;

	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );

	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );

	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);

	dbg_clear("radio_rec", "\n ");
	dbg_clear("radio_pack","\n");
	

	if ( mess->msg_type == REQ ) {
		post sendResp();
	}


    return buf;

  }

  */
  
		
  

  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//
  //*******************************************************************************************//

  // Tasks sono come le funzioni, MA eseguite in modo ASINCRONO
  // Le Task non vengono eseguite quando chiamate, ma vengono messe in queue 
  // e lo scheduler di TinyOS decide quand'è il miglior momento per eseguirle 
  // Diventa molto più efficiente nel gestire gli eventi (dobbiamo usare le Tasks)

/*

  ***************** Task send request ********************

  task void sendReq() {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
//il type my_msg_t è stato definito nell'header file
//assegno il contenuto
	mess->msg_type = REQ;
	mess->msg_id = counter++;
//counter verrà incrementato ogni volta che viene richiamata la task
	    
	dbg("radio_send", "Try to send a request to node 2 at time %s \n", sim_time_string());
    
	call PacketAcknowledgements.requestAck( &packet );
//it will trigger an event to be fired if the ACK is received
//ci permette di capire se il nostro pkt è stato ricevuto o no dal ricevitore

	if(call AMSend.send(2,&packet,sizeof(my_msg_t)) == SUCCESS){
//2 --> indica l'address della destinazione
//&packet --> what pkt you have to transmit
		
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      
      }

 }        

  ****************** Task send response *****************
  task void sendResp() {
	call Read.read();	//legge dal sensore
  }				//il valore letto verrà poi messo come "data" nella .readDone
				//nella "Receive interface"

***************** Boot interface ********************
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();		//in this way SplitControl starts the radio in the Boot
  }

***************** SplitControl interface ********************

//evento che si verifica appena finito SplitControl(.startDone)

 event void SplitControl.startDone(error_t err){	
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");	//video (April 22,IoT) min:35
	if ( TOS_NODE_ID == 1 ) {
	  dbg("role","I'm node 1: start sending periodical request\n");
	  call MilliTimer.startPeriodic( 800 );				//800 ms
	}
    }
    else{
	call SplitControl.start();	//se la Radio non è stata accesa bene, riprova
    }

  }
  
  event void SplitControl.stopDone(error_t err){}

  ***************** MilliTimer interface ********************
  event void MilliTimer.fired() {		//when the Timer fires, I will "post" una sendReq()
	post sendReq();				//eseguirà il codice all'interno di quella funzione
  }						//sendReq viene definita prima
  

  ********************* AMSend interface ****************
//when you call the send command, you have to wait for the .sendDone event

  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	dbg("radio_send", "Packet sent...");

	if ( call PacketAcknowledgements.wasAcked( buf ) ) {	//se riceviamo l'ACK
	  dbg_clear("radio_ack", "and ack received");		//allora
	  call MilliTimer.stop();				//possiamo fermare il timer
	} else {
	  dbg_clear("radio_ack", "but ack was not received");	//altrimenti possiamo mandare
	  post sendReq();					//un'altra richiesta
	}
	dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }

  }

  ***************************** Receive interface *****************
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	my_msg_t* mess=(my_msg_t*)payload;
	rec_id = mess->msg_id;
	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	dbg_clear("radio_rec", "\n ");
	dbg_clear("radio_pack","\n");
	
	if ( mess->msg_type == REQ ) {
		post sendResp();		//chiama sendResp (send response) --> definita sopra
	}

    return buf;

  }
  
  ************************* Read interface **********************
  event void Read.readDone(error_t result, uint16_t data) {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = RESP;
	mess->msg_id = rec_id;
	mess->value = data;
	  
	dbg("radio_send", "Try to send a response to node 1 at time %s \n", sim_time_string());
	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(1,&packet,sizeof(my_msg_t)) == SUCCESS){
		
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");

        }

  }

}
 */

