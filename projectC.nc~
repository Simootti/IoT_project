
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
  route_msg_t* route_mess;
  message_t packet;
  uint8_t num=0;
  uint8_t n;
  tab_t tab_complete[8];
  route_msg_t route_save[8]; //array per salvare la route request per poter eliminare i duplicati
  uint8_t c=0; //counter per la route request	
  

  task void sendRandmsg();
  

  task void sendRandmsg() {  // task che manda i messaggi casuali (punto 1) e controlla la tabella di routing (parte del punto 2)
	
	num = (call Random.rand16() % 8) + 1;

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = REQ;
	mess->msg_id = counter++;
	mess->value = call Random.rand16();
	mess->dst_add = num;
	mess->src_add = TOS_NODE_ID;
	
	for (n=0; tab_complete[n].dst_add != mess->dst_add && n<(sizeof(tab_complete)/5); n++){
		//printf("n = %d\n", n);	
	}
	if (tab_complete[n].dst_add == mess->dst_add){
		printf ("Find a match with destination \n");
		printf ("Send to next-hop \n");
		
		if (tab_complete[n].next_hop == mess->dst_add){
			printf("Packet sent to destination");		
		}else{
			printf("Packet sent to next hop");
			//DA VERIFICARE!!!
			//il pacchetto viene mandato al next-hop SE c'e' un match nella tabella
			// ATTENZIONE: nel payload del pkt NON viene cambiata la dst, che verrà usata per
			// 	       fare confronto nel nodo successivo
			if(call AMSend.send(tab_complete[n].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
				  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
				  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
				  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
				  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
				  dbg_clear("radio_pack","\t\t Payload \n" );
				  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
				  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
				  dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
				  dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
				  dbg_clear("radio_send", "\n");
				  dbg_clear("radio_pack", "\n");	
		}
	}else{
		printf ("Do not find a match,then update a routing table \n");
		
		route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
		route_mess->msg_type = ROUTE_REQ;
		route_mess->msg_id = c++;
		route_mess->dst_add = mess->dst_add;
		route_mess->src_add = mess->src_add;
		route_mess->crt_node = TOS_NODE_ID;  

		// FARE UNA TASK PER LA FUNZIONE BROADCAST
	//task void broadcast
		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(route_msg_t)) == SUCCESS){
			printf("Pacchetti inviati in Broadcast come ROUTE REQ \n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", route_mess->src_add);
	           	dbg_clear("radio_pack","\t Destination: %hhu \n ", route_mess->dst_add);
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", route_mess->msg_type);
			dbg_clear("radio_pack", "\t\t destination address: %hhu \n", route_mess->route_id);
		}
		
		//TODO CREAZIONE DELLE TABELLE DI ROUTING (con l'array tab_complete[8])
		
		
	}
	/*
 	if(call AMSend.send(num,&packet,sizeof(my_msg_t)) == SUCCESS){    pacchetto casuale
		dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
		dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
		dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
		dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
		dbg_clear("radio_pack","\t\t Payload \n" );
		dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
		dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
		dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
		dbg_clear("radio_send", "\n");
		dbg_clear("radio_pack", "\n");
	}*/
  }



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
	call SplitControl.start();,
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

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	route_msg_t* route_mess=(route_msg_t*)payload;
	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", route_mess->msg_type);
	dbg_clear("radio_pack", "\t\t route request id: %hhu \n", route_mess->route_id);
	dbg_clear("radio_pack", "\t\t destination address: %hhu \n", route_mess->dst_add);
	dbg_clear("radio_pack", "\t\t source address: %hhu \n", route_mess->src_add);
	dbg_clear("radio_pack","\n");
/*
	// IL BROADCAST È FATTO SOLO DAL NODO MADRE E NON DA QUELLI INTERMEDI PER RAGGIUNGERE LA DESTINAZIONE ???
		if(route_mess->dst_add != route_mess->crt_node){
		  	call task void broadcast;
		  }

	if (route_mess->msg_type == ROUTE_REQ && route_mess->msg_id != route_save[].msg_id) {
		//TODO ELIMINARE I DUPLICATI MA PRIMA BISOGNA SALVARE LE ENTRY
		route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
		route_save[].msg_type = route_mess->msg_type;
		route_save[].msg_id = route_mess->msg_id;
		route_save[].dst_add = route_mess->dst_add;
		route_save[].src_add = route_mess->src_add;   
	}

	if ( mess->msg_type == REQ ) {
			post sendResp();
	}
*/


    return buf;

  }
  
		
  

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

