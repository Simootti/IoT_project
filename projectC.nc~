
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
    	interface Receive;
    	interface Timer<TMilli> as MilliTimer;
	//interface Read<uint16_t>;		//used to read Data from a sensor
  }

} implementation {

//dichiarazioni variabili globali

  uint32_t counter=0;
  uint8_t rec_id;
  my_msg_t* mess;
  route_msg_t* route_mess;
  message_t packet;
  uint8_t n;
  tab_t tab_complete[8];
  route_msg_t route_save[8]; //array per salvare la route request per poter eliminare i duplicati
  uint8_t c=0; //counter per la route request	
  

  task void sendRandmsg();
  task void broadcast();
  
//**************************************************************************************************************************************//


  task void sendRandmsg() {  // task che manda i messaggi casuali (punto 1) e controlla la tabella di routing (parte del punto 2)
	
	uint8_t num = (call Random.rand16() % 8) + 1;

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = REQ;
	mess->msg_id = counter++;
	mess->value = call Random.rand16();
	mess->dst_add = num;
	mess->src_add = TOS_NODE_ID;
	/*
	route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
	route_mess->msg_type = ROUTE_REQ;
	route_mess->route_id = c++;
	route_mess->dst_add = mess->dst_add;
	route_mess->src_add = mess->src_add;
	route_mess->crt_node = TOS_NODE_ID;
	*/
	for (n=0; tab_complete[n].dst_add != mess->dst_add && n<(sizeof(tab_complete)/5); n++){
		//dbg("radio_pack","n = %d\n", n);	
	}
	if (tab_complete[n].dst_add == mess->dst_add){
		dbg("radio_pack","Found a match with destination \n");
		dbg("radio_pack","Send to next-hop \n");
		
		if (tab_complete[n].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination");		
		}else{
			dbg("radio_pack","Packet sent to next hop");
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
				  dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
				  dbg_clear("radio_send", "\n");
				  dbg_clear("radio_pack", "\n");	
			}
		}

	}else{
		dbg("radio_pack","Do not find a match,then update a routing table \n");
		
		route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
		route_mess->msg_type = ROUTE_REQ;
		route_mess->route_id = c++;
		route_mess->dst_add = mess->dst_add;
		route_mess->src_add = mess->src_add;
		route_mess->crt_node = TOS_NODE_ID; 
		
		post broadcast();
	}
		
		
		//TODO CREAZIONE DELLE TABELLE DI ROUTING (con l'array tab_complete[8])
		
		
 	//if(call AMSend.send(num,&packet,sizeof(my_msg_t)) == SUCCESS){}   pacchetto casuale
  }  	


  //***************** Broadcast task ********************//
  task void broadcast(){
  	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(route_msg_t)) == SUCCESS){
			dbg("radio_pack","Pacchetti inviati in Broadcast come ROUTE REQ \n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", route_mess->src_add);
	           	dbg_clear("radio_pack","\t Destination: %hhu \n ", route_mess->dst_add);
			dbg_clear("radio_pack","\t Current node: %hhu \n ", route_mess->crt_node);
			dbg_clear("radio_pack", "\t\t Msg_type: %hhu \n ", route_mess->msg_type);
			dbg_clear("radio_pack", "\t\t Route request id: %hhu \n", route_mess->route_id);
	}
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
    	}else{
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
					
    }else{
	  dbg_clear("radio_ack", "but ack was not received"); 		
    }

    dbg_clear("radio_send", " at time %s \n", sim_time_string());
  }
	

  //***************************** Receive interface ********************************//

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	route_mess=(route_msg_t*)payload;
	
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
	dbg_clear("radio_pack", "\t\t current node: %hhu \n", route_mess->crt_node);
	dbg_clear("radio_pack","\n");

	// IL BROADCAST È FATTO SOLO DAL NODO MADRE E NON DA QUELLI INTERMEDI PER RAGGIUNGERE LA DESTINAZIONE

	if(route_mess->dst_add != route_mess->crt_node){
		for (n=0; tab_complete[n].dst_add != mess->dst_add && n<(sizeof(tab_complete)/5); n++){
			//dbg("radio_pack","n = %d\n", n);	
		}
		if (tab_complete[n].dst_add == mess->dst_add){
			dbg("radio_pack","Find a match with destination \n");
			dbg("radio_pack","Send to next-hop \n");
		
			if (tab_complete[n].next_hop == mess->dst_add){
				dbg("radio_pack","Packet sent to destination");		
			}else{
				dbg("radio_pack","Packet sent to next hop");
				if(call AMSend.send(tab_complete[n].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
					 	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
						  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
						  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
						  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
						  dbg_clear("radio_pack","\t\t Payload \n" );
						  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
						  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
						  dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
						  dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
						  dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
						  dbg_clear("radio_send", "\n");
						  dbg_clear("radio_pack", "\n");	
				}
			}
		}else{
			dbg("radio_pack","Do not find a match,then update a routing table \n");
				route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
				route_mess->msg_type = ROUTE_REQ;
				route_mess->route_id = c++;
				route_mess->dst_add = mess->dst_add;
				route_mess->src_add = mess->src_add;
				route_mess->crt_node = TOS_NODE_ID;  

				post broadcast();	
		}
	}

/*
	if (route_mess->msg_type == ROUTE_REQ && route_mess->msg_id != route_save[].msg_id) {
		//TODO ELIMINARE I DUPLICATI MA PRIMA BISOGNA SALVARE LE ENTRY
		route_mess = (route_msg_t*)(call Packet.getPayload(&packet,sizeof(route_msg_t)));
		route_save[].msg_type = route_mess->msg_type;
		route_save[].msg_id = route_mess->msg_id;
		route_save[].dst_add = route_mess->dst_add;
		route_save[].src_add = route_mess->src_add;   
	}

	if ( mess->msg_type == REQ ) {
			//post sendResp();
	}
*/


	return buf;

  }



}  //parentesi graffa di chiususra implementation



