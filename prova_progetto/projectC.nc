
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
  //uint32_t rec_id;
  my_msg_t* mess;
  my_msg_t* route_mess;
  message_t packet;
  uint8_t n;
  tab_t tab_complete[8];
  uint8_t c=0; //counter per la route request
  uint8_t prova=0;
  

  task void sendRandmsg();
  //task void broadcast();
  



//*********************** Task Send Random Messages *********************************************************************//


  task void sendRandmsg() {  // task che manda i messaggi casuali (punto 1)
	
	//uint8_t num = (call Random.rand16() % 8) + 1;


//	SOLO campi che sono presenti in qualsiasi tipo di messaggio

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	//mess->msg_type = DATA;
	mess->msg_id = counter++;
	//mess->value = call Random.rand16();
	mess->dst_add = (call Random.rand16() % 8) + 1;
	mess->src_add = TOS_NODE_ID;
	//mess->crt_node = TOS_NODE_ID;


//TODO CREAZIONE DELLE TABELLE DI ROUTING (con l'array tab_complete[8])

// 1) per prima cosa, scorro la mia tabella per vedere se ho un match
	for (n=0; tab_complete[n].dst_add != mess->dst_add && n<(sizeof(tab_complete)/5); n++){ 
			//dbg("radio_pack","n = %d\n", n);	
		}
/* 2) ora ho un valore di "n" che può indicarmi: --> la posizione del match	
						     (tab_complete[n].dst_add == mess->dst_add) oppure (tab_complete[n].dst_add == mess->dst_add)
						 --> che non c'è stato match (quindi non vado nell' "else", dove userò la Task Broadcast)	
*/

//primo caso: trovo una corrispondenza nella Routing Table

	if (tab_complete[n].dst_add == mess->dst_add){
			dbg("radio_pack","Found a match in the Routing Table \n");

	// allora mando al Next-Hop
	// verifico se è effettivamente la destinazione e lo scrivo (serve solo per controllare) 
	//stampo comunque tutto per vedere come è stato creato il pacchetto
	//inoltre, aggiungo i dati (msg_value, msg_type = 1 (DATA))

		if (tab_complete[n].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination");	
		}else{
			dbg("radio_pack","Packet sent to next hop");
		}
		
		mess->msg_type = DATA;	//quindi deve essere 1
		mess->value = call Random.rand16();

	// mando effettivamente il pacchetto al (tab_complete[n].next_hop)
		if(call AMSend.send(tab_complete[n].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
		  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
		  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
		  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
		  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
		  dbg_clear("radio_pack","\t\t Payload \n" );
		  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
		  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		  dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
		  dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
		  dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
		  dbg_clear("radio_send", "\n");
		  dbg_clear("radio_pack", "\n");
		}

	}else{		//ATTENTO ALLE PARENTESI
	// graffa che chiude [[ if (tab_complete[n].dst_add == mess->dst_add) ]] 
	//(ovvero trova match nella tabella) e attiva l'else	
	// secondo caso: non trovo corrispondenza nella tabella ---> dovrò richiamare la task Broadcast
		//in realtà verrà chiamata solo la Broadcast, la Routing Table viene effettivamente aggiornata
		//solo dopo le ricezioni (!!!!!)
		//dato che non vogliamo passare i dati, serve solo specificare il tipo di msg che mandiamo in broadcast

		dbg("radio_pack","Match not found, sending in Broadcast in order to update the Routing Table \n");

			mess->msg_type = ROUTE_REQ;	//--> settiamo solo questo, il valore è 2
			//mess->crt_node = TOS_NODE_ID;  ---> non credo che servirà

			//post broadcast();

//prova: mando in broadcast scrivendo tutto
//fare una task potrebbe darmi errori, almeno qua in teoria so che manda i dati giusti che sono stati definiti in questa interfaccia
//sono sempre dentro l'else

  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			dbg("radio_pack","Pacchetti inviati in Broadcast come ROUTE REQ \n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", mess->src_add);
	           	dbg_clear("radio_pack","\t Destination: %hhu \n ", mess->dst_add);
			//dbg_clear("radio_pack","\t Current node: %hhu \n ", mess->crt_node);
			dbg_clear("radio_pack", "\t\t Msg_type: %hhu \n ", mess->msg_type);
			dbg_clear("radio_pack", "\t\t Route request id: %hhu \n", mess->msg_id);
		}

	}	//graffa che chiude l'else del Match non trovato


  } //graffa che chiude la Task di SEND RANDOM MSG 	






  //***************** Broadcast task ********************//

//dubbio: prende davvero i valori che vengono definiti in Send e Receive prima di chiamarlo?
/*
  task void broadcast(){
  	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			dbg("radio_pack","Pacchetti inviati in Broadcast come ROUTE REQ \n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", mess->src_add);
	           	dbg_clear("radio_pack","\t Destination: %hhu \n ", mess->dst_add);
			//dbg_clear("radio_pack","\t Current node: %hhu \n ", route_mess->crt_node);
			dbg_clear("radio_pack", "\t\t Msg_type: %hhu \n ", mess->msg_type);
			dbg_clear("radio_pack", "\t\t Route request id: %hhu \n", mess->msg_id);
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

	mess=(my_msg_t*)payload;
	//rec_id = mess->msg_id;


//non è detto che abbia tutti i dati, dipende dalla tipologia di messaggio

//TODO differenziare i 3 casi di arrivo (3 tipologie di messaggio) e agire di conseguenza
//	quindi controllo il msg_type

//***********************************DA FARE PER POTER CREARE LA ROUTING TABLE***********************************************************//

//TODO RICORDA CHE DEVI PRIMA SALVARE IL percorso NELLA tab_complete[n] CON TUTTE LE SUE CARATTERISTICHE (NEXT_HOP, SRC, DST E PATH +1 OGNI
//     VOLTA CHE PASSA IN UN NODO LA STESSA BROADCAST CON SRC,DST E ROUTE_ID UGUALI) COSÌ POI PUOI RIUSCIRE A FARE IL BROADCAST NEL
//     NEXT_HOP FINO ALLA DESTINAZIONE, SE NO E' IMPOSSIBILE

//***************************************************************************************************************************************//


// 1) IF msg_type is DATA
	if(mess->msg_type == DATA){
		
		//controllo: sono io il nodo di destinazione?
		//se lo sono, allora stampo tutto perchè avrò tutti i dati
		if(mess->dst_add == TOS_NODE_ID){
		dbg("radio_pack","ORIGINAL DESTINATION REACHED \n");

		dbg("radio_rec","Message received at time %s \n", sim_time_string());
		dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
		dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
		dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
		dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
		dbg_clear("radio_pack","\t\t Payload \n" );
		dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
		dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
		dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
		dbg_clear("radio_pack","\n");
		}
		else{
		//SE NON SONO IO IL NODO DI DESTINAZIONE, ALLORA dovrò fare forward
		//controllo la tabella di routing

		// scorro la mia tabella per vedere se ho un match
			for (n=0; tab_complete[n].dst_add != mess->dst_add && n<(sizeof(tab_complete)/5); n++){ 
				//dbg("radio_pack","n = %d\n", n);	
			}
			if (tab_complete[n].dst_add == mess->dst_add){
				dbg("radio_pack","Found a match in the Routing Table \n");
			// a differenza della Task SendRandom Message, qua NON devo creare un nuovo pacchetto, nel caso lo devo SOLO inoltrare
			//rimetto gli stessi messaggi
				if (tab_complete[n].next_hop == mess->dst_add){
					dbg("radio_pack","Packet sent to destination");	
				}else{
					dbg("radio_pack","Packet sent to next hop");
				}
			//faccio la call di invio pacchetto al next-hop
			//si verifica se ho trovato un match (quindi ho next_hop nella tabella)

				call AMSend.send(tab_complete[n].next_hop,&packet,sizeof(my_msg_t));

			}	//graffa che chiude [[if (tab_complete[n].dst_add == mess->dst_add)]]
			else{
			dbg("radio_pack","Match not found, sending in Broadcast in order to update the Routing Table \n");
			//NON DEVO MANDARE UN MESSAGGIO DEL TUTTO NUOVO, RIUTILIZZO L'ID DEL MESSAGGIO CHE HO RICEVUTO
			//PER POTER RICONOSCERE CHE STO ANCORA PARLANDO DI QUELL'INVIO DA UNA SRC CHE NON SONO IO
			
			}

		}	//graffa che chiude l'else


	} // graffa che chiude if(msg_type == 1) ---> DATA type 














/*
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
	dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
	//dbg_clear("radio_pack", "\t\t current node: %hhu \n", mess->crt_node);
	dbg_clear("radio_pack","\n");

*/











//TODO ELIMINARE I DUPLICATI MA PRIMA BISOGNA SALVARE LE ENTRY

	return buf;

 }



}  //parentesi graffa di chiususra implementation



