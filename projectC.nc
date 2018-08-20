
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
  message_t packet;
  uint8_t n;
  tab_t tab_discovery[8];
  tab_t tab_routing[10];
  uint8_t c=0; //counter per la route request
  uint8_t prova=0;

  task void sendRandmsg();


//*********************** Task Send Random Messages *********************************************************************//


  task void sendRandmsg() {  // task che manda i messaggi casuali (punto 1)
	
	//uint8_t num = (call Random.rand16() % 8) + 1; //lo lascio solo per poter settare il destination address del broadcast


//	SOLO campi che sono presenti in qualsiasi tipo di messaggio

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter++;
	mess->dst_add = (call Random.rand16() % 8) + 1;
	mess->src_add = TOS_NODE_ID;
	mess->crt_node = TOS_NODE_ID;
	mess->prec_node = TOS_NODE_ID;

	dbg_clear("radio_send", "\n");
	dbg_clear("radio_pack", "\n");
	dbg_clear("radio_pack", "\t\t Stampo la Destinazione del nodo %hhu : %hhu \n",TOS_NODE_ID, mess->dst_add);
	dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);


//TODO CREAZIONE DELLE TABELLE DI ROUTING (con l'array tab_routing[8])

// 1) per prima cosa, scorro la mia tabella per vedere se ho un match
	for (n=0; tab_routing[n].dst_add != mess->dst_add && n<(sizeof(tab_routing)/sizeof(tab_t)); n++){ 	
	}
/* 2) ora ho un valore di "n" che può indicarmi: --> la posizione del match	
						     (tab_routing[n].dst_add == mess->dst_add) oppure (tab_routing[n].dst_add == mess->dst_add)
						 --> che non c'è stato match (quindi non vado nell' "else", dove userò la Task Broadcast)	
*/

//primo caso: trovo una corrispondenza nella Routing Table

	if (tab_routing[n].dst_add == mess->dst_add){
			dbg("radio_pack","Found a match in the Routing Table \n");

	// allora mando al Next-Hop
	// verifico se è effettivamente la destinazione e lo scrivo (serve solo per controllare) 
	//stampo comunque tutto per vedere come è stato creato il pacchetto
	//inoltre, aggiungo i dati (msg_value, msg_type = 1 (DATA))

		if (tab_routing[n].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination");	
		}else{
			dbg("radio_pack","Packet sent to next hop");
		}
		
		mess->msg_type = DATA;	//quindi deve essere 1, devo stare attento a non mandare un msg data prima che sia fatta tutta la route reply
		mess->value = call Random.rand16();

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
		if(call AMSend.send(tab_routing[n].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
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
			  dbg_clear("radio_pack", "\t\t Next-Hop: %hhu \n", tab_routing[n].next_hop);
			  dbg_clear("radio_send", "\n");
			  dbg_clear("radio_pack", "\n");
		}

	}else{		//ATTENTO ALLE PARENTESI
	// graffa che chiude [[ if (tab_routing[n].dst_add == mess->dst_add) ]] 
	//(ovvero trova match nella tabella) e attiva l'else	
	// secondo caso: non trovo corrispondenza nella tabella ---> dovrò richiamare la task Broadcast
		//in realtà verrà chiamata solo la Broadcast, la Routing Table viene effettivamente aggiornata
		//solo dopo le ricezioni (!!!!!)
		//dato che non vogliamo passare i dati, serve solo specificare il tipo di msg che mandiamo in broadcast

		dbg("radio_pack","Match not found, sending in Broadcast in order to update the Routing Table \n");

			mess->msg_type = ROUTE_REQ;	//--> settiamo solo questo, il valore è 2
			dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);

//prova: mando in broadcast scrivendo tutto
//fare una task potrebbe darmi errori, almeno qua in teoria so che manda i dati giusti che sono stati definiti in questa interfaccia
//sono sempre dentro l'else

  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			/*dbg("radio_pack","Pacchetti inviati in Broadcast come ROUTE REQ \n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
			dbg_clear("radio_pack","\t Source: %hhu \n ", mess->src_add);
	           	dbg_clear("radio_pack","\t Original Destination: %hhu \n ", mess->dst_add);
			//dbg_clear("radio_pack","\t Current node: %hhu \n ", mess->crt_node);
			dbg_clear("radio_pack", "\t\t Msg_type: %hhu \n ", mess->msg_type);
			dbg_clear("radio_pack", "\t\t Route request id: %hhu \n", mess->msg_id);*/
		}

// TODO IMPLEMENTARE CHE LA SORGENTE ASPETTA 1 SECONDO PER LA ROUTE_REPLY
		
	}	//graffa che chiude l'else del Match non trovato


  } //graffa che chiude la Task di SEND RANDOM MSG 	


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
	
	//dbg("radio_send", "Packet sent...");
					
    }else{
	  //dbg_clear("radio_pack", "but ack was not received"); 		
    }

    //dbg_clear("radio_send", " at time %s \n", sim_time_string());
  }



  //***************************** Receive interface ********************************//

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	//TODO inizializzare qua i pacchetti (data,rreq,rrep)
	my_msg_t* mess_tipo2;
	mess=(my_msg_t*)payload;
	
	//rec_id = mess->msg_id;


//non è detto che abbia tutti i dati, dipende dalla tipologia di messaggio

//TODO differenziare i 3 casi di arrivo (3 tipologie di messaggio) e agire di conseguenza
//	quindi controllo il msg_type

//TODO fare un controllo per i path

//***************************************************************************************************************************************//


// 1) IF msg_type is DATA
	if(mess->msg_type == DATA){
		
		//controllo: sono io il nodo di destinazione?
		//se lo sono, allora stampo tutto perchè avrò tutti i dati
		if(mess->dst_add == TOS_NODE_ID){
			dbg("radio_pack","DATA packet reached the ORIGINAL DESTINATION correctly!\n");
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
			dbg_clear("radio_pack","\n");*/
		}
		else{
		//SE NON SONO IO IL NODO DI DESTINAZIONE, ALLORA dovrò fare forward
		//controllo la tabella di routing
		//TODO non fare confusione con routing table e tab complete (qui ci va tab complete secondo me)
		// scorro la mia tabella per vedere se ho un match
			for (n=0; tab_routing[n].dst_add != mess->dst_add && n<(sizeof(tab_routing)/5); n++){ //TODO DA CAMBIARE
				//dbg("radio_pack","n = %d\n", n);	
			}
			if (tab_routing[n].dst_add == mess->dst_add){
				dbg("radio_pack","Found a match in the Routing Table \n");
			// a differenza della Task SendRandom Message, qua NON devo creare un nuovo pacchetto, nel caso lo devo SOLO inoltrare
			//rimetto gli stessi messaggi
				if (tab_routing[n].next_hop == mess->dst_add){
					dbg("radio_pack","Packet sent to destination");	
				}else{
					dbg("radio_pack","Packet sent to next hop");
					dbg_clear("radio_pack", "\t\t Next-Hop address: %hhu \n", tab_routing[n].next_hop);
				}
			//faccio la call di invio pacchetto al next-hop
			//si verifica se ho trovato un match (quindi ho next_hop nella tabella)

				call AMSend.send(tab_routing[n].next_hop,&packet,sizeof(my_msg_t));
				/*
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
				*/




			}	//graffa che chiude [[if (tab_routing[n].dst_add == mess->dst_add)]]
			else{

			//NON DEVO MANDARE UN MESSAGGIO DEL TUTTO NUOVO, RIUTILIZZO L'ID DEL MESSAGGIO CHE HO RICEVUTO
			//PER POTER RICONOSCERE CHE STO ANCORA PARLANDO DI QUELL'INVIO DA UNA SRC CHE NON SONO IO

			// IN REALTÀ QUA NON CI FINIRÀ MAI ---> IN TEORIA I PACCHETTI DI TIPO DATA VENGONO INVIATI SOLO SE LA SORGENTE CONOSCE UN PATH
				dbg("radio_pack","ERRORE : NON DOVRESTI ESSERE QUI");

				}
			

		}	//graffa che chiude l'else


	} // graffa che chiude if(msg_type == 1) ---> DATA type 
//********************************************************************************************************************************************//

// 2) caso due : IF msg_type == ROUTE_REQ

	if(mess->msg_type == ROUTE_REQ){

	
	//TODO PRIMO CONTROLLO: HO GIÀ RICEVUTO QUESTA ROUTE_REQ?
	// SE msg_id e src_add e msg_id corrispondono a qualcosa che ho già in memoria, allora scarto la seconda
	//--> ATTENTO 

		//TODO trovare la n corrispondente- cambiare la tabella in modo intelligente (in modo che scorra la tabella)
		if(tab_discovery[n].src_add == mess->src_add && tab_discovery[n].msg_id == mess->msg_id && tab_discovery[n].dst_add == mess->dst_add){

			return buf;	//elimina il pacchetto duplicato

		}else{	//ovvero se non è un duplicato
		
		// a) controllo se sono io il nodo destinazione
			if(mess->dst_add == TOS_NODE_ID){
				dbg("radio_pack","I am the Destination of the Route_Req %hhu sent originally by Node %hhu \n",mess->msg_id, mess->src_add );
				// dovrebbe stamparmi sia l'id della route_req sia la VERA sorgente
				dbg("radio_pack","I send a ROUTE_REPLY to  %hhu  \n",mess->crt_node );
				/*
				deve stamparmi il nodo che mi ha "consegnato" la ROUTE_REQ (crt_node indica ancora l'ultimo hop che ha fatto forward)
				se src e dst sono collegati, allora in questo caso src_add == crt_node
		
				nella richiesta non mi è richiesto di aggiornare la tabella della destinazione, quindi mi limito a mandare una ROUTE_REPLY
				che riattraverserà tutti i nodi
				-->la gestione del riattraversare tutti gli hop è affidata al ricevimento di una ROUTE_REPLY (definiamo più avanti) 
				*/
		
				mess->msg_type = ROUTE_REPLY; //TODO creare il pacchetto da inviare
				//mess->path non viene messo qui: infatti è un contatore incrementato ogni volte che
				//ricevo una ROUTE_REQ e devo fare forward (definisco più avanti). 
				//non c'è bisogno di definirlo qua
				
				mess_tipo2 = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
				mess_tipo2->dst_add = mess->dst_add; //TODO DA COPIARE QUEL CHE VOGLIO
				call AMSend.send(mess->prec_node,&packet,sizeof(my_msg_t));


			} 	// graffa che chiude [[if(mess->dst_add == TOS_NODE_ID)]] --> se esco da questo if, vuol dire che non sono io la DST
			else{
			//se sono qui, vuol dire che non sono la destinazione --> ho altri due casi possibili
			//Ma prima devo scorrere la tabella, DA NON FARE QUESTO CASO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				
				//TODO caso b) non ho la destinazione nella mia tabella --> devo fare una REQ in BROADCAST pure io 
				//MA SENZA CREARE UN ALTRO PACCHETTO, "RICICLANDO LO STESSO"
				//Attenzione all'uso della n, bisogna selezionare il giusto posto dove metterla 

				//TODO segnarsi la lunghezza della tabella utilizzata fino ad ora, mi raccomando attenzione!!!!!

				tab_discovery[len_tab_discovery].msg_id = mess->msg_id;	//mi salvo il msg_id di questa ROUTE_REQ per fare un confronto successivo ed eliminare i doppioni	
				tab_discovery[len_tab_discovery].src_add = mess->src_add;
				tab_discovery[n].dst_add = mess->dst_add;
				tab_discovery[n].prec_node = "......"; //qui devo salvare il nodo da cui il messaggio l'ho ricevuto
				tab_discovery[n].path += 1;
				len_tab_discovery += 1;

				mess->msg_type = ROUTE_REQ; //TODO CREARE L'ALTRO PACCHETTO DA INVIARE

				dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);

		  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
				}

			}


			} 
		}	//graffa che chiude la verifica dei duplicati
	}	//graffa che chiude if(mess->msg_type == ROUTE_REQ)

//********************************************************************************************************************************************************//

// 2) caso due : If msg_type == ROUTE_REPLY

	if(mess->msg_type == ROUTE_REPLY){

		if(mess->src_add == TOS_NODE_ID){	//se sono io la sorgente
		
			//aggiorno la tabella e mando alla dst i dati
			//TODO CONTROLLO LUNGHEZZA PATH
			//TODO METTERE LA DST_ADD COME INDICATORE DELLA ROUTING TABLE
			
			//una volta trovato, riempio i campi (stampo per verifica)
			tab_routing[n].dst_add = mess->dst_add;
			tab_routing[mess->dst_add].next_hop = mess->crt_node; //crt mi dice l'ultimo nodo che mi ha passato la reply
			tab_routing[n].path = mess->path;
			//stampo cosa ho aggiornato nella mia tabella
			dbg("radio_rec","ROUTE_REPLY received at time %s \n", sim_time_string());
			dbg_clear("radio_pack","\t\t Routing Table of the node %hhu in position %hhu \n", TOS_NODE_ID, n );
			dbg_clear("radio_pack", "\t\t Table --> Destination address: %hhu \n", tab_routing[n].dst_add);
			dbg_clear("radio_pack", "\t\t Table --> Next-Hop: %hhu \n", tab_routing[n].next_hop);		

			//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
			mess->msg_type = DATA;
			mess->value = call Random.rand16();
			mess->dst_add = tab_routing[n].dst_add;
			mess->src_add = TOS_NODE_ID;

			// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
			if(call AMSend.send(tab_routing[n].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
				  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
				  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
				  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
				  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
				  dbg_clear("radio_pack","\t\t Payload \n" );
				  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
				  //dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);	--> non serve col pkt DARA
				  dbg_clear("radio_pack", "\t\t DATA: %hhu \n", mess->value);
				  dbg_clear("radio_pack", "\t\t source address: %hhu \n", mess->src_add);
				  dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);
				  dbg_clear("radio_pack", "\t\t Next-Hop: %hhu \n", tab_routing[n].next_hop);
				  dbg_clear("radio_send", "\n");
				  dbg_clear("radio_pack", "\n");
				}

		} //graffa che chiude il "se sono io la sorgente"
		else{
			// se sono qui, vuol dire che non sono io la sorgente --> sono un nodo che diventerà un next-hop di quello prima di me
			// aggiorno la mia tabella di discovery e mando un messaggio a quello prima
			//TODO : CONTROLLO SULLA LUNGHEZZA DEL PATH

			//prima di tutto aggiorno la mia tabella (infatti le REPLY vengono inviate solo dopo aver trovato una dst )
			//prima scorro finchè non trovo un posto libero (con valori nulli)
			//una volta trovato, riempio i campi (stampo per verifica)
			
			tab_discovery[n].dst_add = mess->dst_add;
			tab_discovery[n].src_add = mess->src_add; // qua la sorgente è quella originaria, serve per il confronto sui duplicati
			tab_discovery[n].next_hop = mess->crt_node; //crt mi dice l'ultimo nodo che mi ha passato la reply
			tab_discovery[n].path = mess->path;
			//stampo cosa ho aggiornato nella mia tabella
			dbg("radio_rec","ROUTE_REPLY received at time %s \n", sim_time_string());
			dbg_clear("radio_pack","\t\t Routing Table of the node %hhu in position %hhu \n", TOS_NODE_ID, n );
			dbg_clear("radio_pack", "\t\t Table --> Destination address: %hhu \n", tab_discovery[n].dst_add);
			dbg_clear("radio_pack", "\t\t Table --> source address: %hhu \n", tab_discovery[n].src_add);
			dbg_clear("radio_pack", "\t\t Table --> Next-Hop: %hhu \n", tab_discovery[n].next_hop);	
			
			mess->msg_type = ROUTE_REPLY; //TODO replicare il messaggio di route reply, COME FARE?

			dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);

			if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){	

			} //graffa che chiude else che diceva che non sono io la sorgente

	} // chiude if (msq_type = ROUTE_REPLY)

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
	dbg_clear("radio_pack", "\t\t current node: %hhu \n", mess->crt_node);
	dbg_clear("radio_pack","\n");

*/

	return buf;
 }


}  //parentesi graffa di chiusura implementation
