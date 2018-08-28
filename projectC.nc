
#include "project.h"
#include "Timer.h"

module projectC {

  uses {
	interface Boot;
	interface Random;
    	interface AMPacket;	//to turning on the Radio and can modify the pkt I want to transmit
	interface Packet;
    	interface AMSend;			//interface to transmit the message
    	interface SplitControl;			//used basically to turning on the radio
    	interface Receive;
    	interface Timer<TMilli> as MilliTimer;
        interface Timer<TMilli> as Timer_rout_1;
	interface Timer<TMilli> as Timer_rout_2;
	interface Timer<TMilli> as Timer_rout_3;
	interface Timer<TMilli> as Timer_rout_4;
        interface Timer<TMilli> as Timer_rout_5;
	interface Timer<TMilli> as Timer_rout_6;
	interface Timer<TMilli> as Timer_rout_7;
	interface Timer<TMilli> as Timer_rout_8;
	interface Timer<TMilli> as Timer_rrep_1;
	interface Timer<TMilli> as Timer_rrep_2;
	interface Timer<TMilli> as Timer_rrep_3;
	interface Timer<TMilli> as Timer_rrep_4;
        interface Timer<TMilli> as Timer_rrep_5;
	interface Timer<TMilli> as Timer_rrep_6;
	interface Timer<TMilli> as Timer_rrep_7;
	interface Timer<TMilli> as Timer_rrep_8;
  }

} implementation {

//dichiarazioni variabili globali

  uint32_t counter = 0;
  my_msg_t* mess;
  my_msg_t* mess_out;
  message_t packet;
  uint8_t len_disc=0; //per tenere il conto dell'occupazione della tab discovery
  uint8_t temp;
  uint8_t n;
  uint8_t big_path;
  tab_d tab_discovery[100];
  tab_r tab_routing[9]; // deve essere 9 perchè altrimenti va da 0 a 7, noi vogliamo da 0 a 8 (e non usiamo la posizione 0)

  task void sendRandmsg();

//*********************** Task Send Random Messages *********************************************************************//


  task void sendRandmsg() {  // task che manda i messaggi

	mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter;
	counter = counter + 1;
	mess->dst_add = (call Random.rand16() % 8) + 1;
	if (mess->dst_add == TOS_NODE_ID){
		dbg("radio_pack","Invio il pacchetto a me stesso quindi non serve AODV\n\n");
		return;
	}
	mess->src_add = TOS_NODE_ID;
	mess->crt_add = TOS_NODE_ID;

	dbg_clear("radio_send", "\n");
	dbg("radio_pack", "Sono il nodo --> %hhu e invio un messaggio con i seguenti parametri: \n\t\t Source Address:%hhu \n\t\t Destination Address: %hhu \n\t\t Message ID:%hhu \n\n ", TOS_NODE_ID, mess->src_add, mess->dst_add, mess->msg_id);


	//primo caso: trovo una corrispondenza nella Routing Table
	if (tab_routing[mess->dst_add].dst_add == mess->dst_add && tab_routing[mess->dst_add].status == 1){
			dbg("radio_pack","Found a match in the Routing Table \n");

		// allora mando al Next-Hop
		// verifico se è effettivamente la destinazione e lo scrivo (serve solo per controllare) 
		// stampo comunque tutto per vedere come è stato creato il pacchetto
		// inoltre, aggiungo i dati (msg_value, msg_type = 1 (DATA))

		if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination\n");	
		}else{
			dbg("radio_pack","Packet sent to next hop");
			dbg_clear("radio_pack", "\t Next-Hop address: %hhu \n", tab_routing[mess->dst_add].next_hop);
		}
		
		mess->msg_type = DATA;	
		mess->value = call Random.rand16();

		// mando effettivamente il pacchetto al (tab_routing[mess->des.add].next_hop)
		if(call AMSend.send(tab_routing[mess->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}

	}else{			
	// secondo caso: non trovo corrispondenza nella tabella ---> dovrò mandare il messaggio in broadcast

		dbg("radio_pack","Match not found, sending a ROUTE_REQ in Broadcast in order to update the Routing Table, e per inviare il pacchetto alla destinazione %hhu \n\n", mess->dst_add);

		mess->msg_type = ROUTE_REQ;
		
		if (mess->dst_add == 1){ //timer che servono per la route reply che deve arrivare prima di un secondo (punto di inizio del timer)
			call Timer_rrep_1.startOneShot (1000);								
		}else if (mess->dst_add == 2){
			call Timer_rrep_2.startOneShot (1000);								
		}else if (mess->dst_add == 3){
			call Timer_rrep_3.startOneShot (1000);								
		}else if (mess->dst_add == 4){
			call Timer_rrep_4.startOneShot (1000);								
		}else if (mess->dst_add == 5){
			call Timer_rrep_5.startOneShot (1000);								
		}else if (mess->dst_add == 6){
			call Timer_rrep_6.startOneShot (1000);								
		}else if (mess->dst_add == 7){
			call Timer_rrep_7.startOneShot (1000);								
		}else if (mess->dst_add == 8){
			call Timer_rrep_8.startOneShot (1000);								
		}
		
		tab_discovery[len_disc].msg_id = mess->msg_id;	
		//mi salvo il msg_id di questa ROUTE_REQ per fare un confronto successivo ed eliminare i doppioni	
		tab_discovery[len_disc].src_add = mess->src_add;
		tab_discovery[len_disc].path = 100;
		tab_discovery[len_disc].dst_add = mess->dst_add;
		tab_discovery[len_disc].prec_node = mess->crt_add;
		tab_discovery[len_disc].status = 1;

		dbg("radio_pack","Ho aggiornato la Tab_Discovery del nodo %hhu in posizione %hhu coi seguenti paramentri:\n\t Message ID: %hhu \n\t Source Address: %hhu \n\t Lunghezza del Path: %hhu \n\t Destination Address: %hhu \n\t Prec Node: %hhu \n\n", TOS_NODE_ID, len_disc, tab_discovery[len_disc].msg_id, tab_discovery[len_disc].src_add,tab_discovery[len_disc].path, tab_discovery[len_disc].dst_add, tab_discovery[len_disc].prec_node);

		len_disc += 1;

		//prova: mando in broadcast scrivendo tutto
		//fare una task potrebbe darmi errori, almeno qua in teoria so che manda i dati giusti che sono stati definiti in questa interfaccia

  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}
		
	}	//graffa che chiude l'else del Match non trovato


  } //graffa che chiude la Task di SEND RANDOM MSG 	


  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	for(n=0;n<9;n++){
		tab_routing[n].status = 0;
	}
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
	
	//dbg("radio_send", "Packet sent...\n\n");
					
    }else{
	  dbg_clear("radio_pack", "but ack was not received\n"); 		
    }

    //dbg_clear("radio_send", " at time %s \n", sim_time_string());
  }



  //***************************** Receive interface ********************************//

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	
	temp=0;
	big_path=100; //contatore che serve più avanti (per trovare il più piccolo path di routing che serve per eliminare gli altri)
	mess=(my_msg_t*)payload;

// 1) IF msg_type is DATA
	if(mess->msg_type == DATA){
		
		//CONTROLLO: sono io il nodo di destinazione?
		//se lo sono, allora stampo tutto perchè avrò tutti i dati
		if(mess->dst_add == TOS_NODE_ID){
			dbg("radio_pack","Il pacchetto DATA inviato da %hhu a %hhu è arrivato a destinazione\n", mess->src_add , mess->dst_add);
			dbg("radio_pack","DATA packet reached the ORIGINAL DESTINATION correctly!\n");
		}else{
			//se NON sono io la destinazione allora dovrò fare forward
			dbg("radio_pack","Sono il nodo %hhu e ho ricevuto un pkt da %hhu verso %hhu \n", TOS_NODE_ID , mess->src_add, mess->dst_add);

			//controllo la tabella di routing

			if (tab_routing[mess->dst_add].dst_add == mess->dst_add && tab_routing[mess->dst_add].status == 1){

				dbg("radio_pack","Found a match in the Routing Table \n");
				//dbg("radio_pack","In questo nodo (numero %hhu) ho una corrispondenza nella routing table\n", TOS_NODE_ID);
				//dbg("radio_pack","nella posizione %hhu, infatti\n", mess->dst_add);
				//dbg("radio_pack","Destination: %hhu == %hhu \n",tab_routing[mess->dst_add].dst_add , mess->dst_add);

			
				if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
					dbg("radio_pack","Packet sent to destination\n");	
				}else{
					dbg("radio_pack","Packet sent to next hop");
					dbg_clear("radio_pack", "\t Next-Hop address: %hhu \n", tab_routing[mess->dst_add].next_hop);
				}
				
				mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
				mess_out->msg_id = mess->msg_id;
				mess_out->msg_type = DATA;
				mess_out->value = mess->value;
				mess_out->dst_add = mess->dst_add;
				mess_out->src_add = mess->src_add;
				mess_out->crt_add = TOS_NODE_ID;
				
				if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){
				}

			}else{ //graffa che chiude [[if (tab_routing[mess->dst_add].dst_add == mess->dst_add)]]

				// Se siamo qui è perché c'è un errore nelle tabelle di routing
				dbg("radio_pack","La tabella di routing è scaduta, quindi è impossibile inoltrare il pacchetto! \n\n");

			}

		}	//graffa che chiude l'else (TOS_NODE_ID)

	} // graffa che chiude if(msg_type == 1) ---> DATA type 
//********************************************************************************************************************************************//

// 2) caso due : IF msg_type == ROUTE_REQ

	if(mess->msg_type == ROUTE_REQ){

	// Eliminazione duplicati
	// Se msg_id e src_add e msg_id corrispondono a qualcosa che ho già in memoria, allora scarto la seconda

		for (n=0; n<len_disc; n++){ 	
			
			if(tab_discovery[n].src_add == mess->src_add && tab_discovery[n].msg_id == mess->msg_id && tab_discovery[n].dst_add == mess->dst_add){
				dbg("radio_pack", "Elimino un duplicato della richiesta con id: %hhu originata da %hhu e mandata da %hhu \n\n", mess->msg_id ,mess->src_add, mess->crt_add);

				return buf;
			}

		} //elimina il pacchetto duplicato, se duplicato faccio return buf dentro al for così interrompo l'interfaccia receive
		
		// a) controllo se sono io il nodo destinazione
		if(mess->dst_add == TOS_NODE_ID){

			dbg("radio_pack","I am Node %hhu, the Destination of the Route_Req sent originally by Node %hhu of the message with ID: %hhu \n",TOS_NODE_ID, mess->src_add , mess->msg_id );
			// dovrebbe stamparmi sia l'id della route_req sia la VERA sorgente
			dbg("radio_pack","I send a ROUTE_REPLY to %hhu with source %hhu \n\n",mess->src_add, mess->dst_add );
			/*
			deve stamparmi il nodo che mi ha "consegnato" la ROUTE_REQ (crt_add indica ancora l'ultimo hop che ha fatto forward)
			se src e dst sono collegati, allora in questo caso src_add == crt_add )
	
			nella richiesta non mi è richiesto di aggiornare la tabella della destinazione, quindi mi limito a mandare una ROUTE_REPLY
			che riattraverserà tutti i nodi
			-->la gestione del riattraversare tutti gli hop è affidata al ricevimento di una ROUTE_REPLY (definiamo più avanti) 
			*/

			temp = mess->crt_add;			

			mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_out->msg_id = mess->msg_id;
			mess_out->msg_type = ROUTE_REPLY;
			mess_out->dst_add = mess->src_add;
			mess_out->src_add = mess->dst_add;
			mess_out->crt_add = TOS_NODE_ID;
			mess_out->path = 1;		//inizia il calcolo del path da qua, e troverà un percorso grazie alle tab_discovery

			if(call AMSend.send(temp,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		}else{ // graffa che chiude [[if(mess->dst_add == TOS_NODE_ID)]] --> se esco da questo if, vuol dire che non sono io la DST
		
			//se sono qui, vuol dire che non sono la destinazione

			tab_discovery[len_disc].msg_id = mess->msg_id;	
			//mi salvo il msg_id di questa ROUTE_REQ per fare un confronto successivo ed eliminare i doppioni	
			tab_discovery[len_disc].src_add = mess->src_add;
			tab_discovery[len_disc].path = big_path;
			tab_discovery[len_disc].dst_add = mess->dst_add;
			tab_discovery[len_disc].prec_node = mess->crt_add;
			tab_discovery[len_disc].status = 1;

			len_disc += 1;
			
			mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_out->msg_id = mess->msg_id;
			mess_out->msg_type = ROUTE_REQ;
			mess_out->dst_add = mess->dst_add;
			mess_out->src_add = mess->src_add;
			mess_out->crt_add = TOS_NODE_ID;

			dbg("radio_pack","Sono il nodo %hhu, Invio una ROUTE_REQ in BROADCAST perchè NON sono io la dst \n", TOS_NODE_ID );
			dbg("radio_pack","Invio una ROUTE_REQ per trovare un percorso da sorgente %hhu a destinazione %hhu con ID %hhu \n \n", mess_out->src_add, mess_out->dst_add, mess_out->msg_id );

	  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		} //graffa che chiude l'else
 
	}	//graffa che chiude if(mess->msg_type == ROUTE_REQ)

//********************************************************************************************************************************************************//

// 2) caso due : If msg_type == ROUTE_REPLY

	if(mess->msg_type == ROUTE_REPLY){

		if(mess->dst_add == TOS_NODE_ID){	//se sono io la sorgente
			
			for (n=0; (tab_discovery[n].dst_add != mess->src_add || tab_discovery[n].msg_id != mess->msg_id || tab_discovery[n].src_add != mess->dst_add) && n<len_disc; n++){
			}
			if (n == len_disc){
				dbg("radio_pack","Non ho trovato la corrispondente tab discovery della Route_Req \n");
				return buf;
			}

			if (tab_discovery[n].status != 1){
				dbg("radio_pack","La RREP di questa tab_discovery è scaduta! \n");
				return buf;
			}

			if (tab_discovery[n].path > mess->path){
				tab_discovery[n].path = mess->path;
				//salvare valori nella tabella di routing
				tab_routing[mess->src_add].dst_add = mess->src_add;
				tab_routing[mess->src_add].next_hop = mess->crt_add; //nodo corrente della richiesta che ricevo quindi di fatto quello sucessivo nella tab routing
				tab_routing[mess->src_add].status = 1;
				dbg("radio_pack","Aggiorno path nella tabella di discovery: %hhu dal nodo %hhu al nodo %hhu \n", tab_discovery[n].path,tab_discovery[n].src_add,tab_discovery[n].dst_add);
				
				if (tab_routing[mess->src_add].dst_add == 1){ //timer per la tabella di routing che dopo 90 secondi si elimina (nell'interfaccia del timer.fire)
					call Timer_rout_1.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 2){
					call Timer_rout_2.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 3){
					call Timer_rout_3.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 4){
					call Timer_rout_4.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 5){
					call Timer_rout_5.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 6){
					call Timer_rout_6.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 7){
					call Timer_rout_7.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 8){
					call Timer_rout_8.startOneShot (90000);									
				}
			}
			
			//stampo cosa ho aggiornato nella mia tabella
			dbg("radio_rec","Sono la destinazione della ROUTE_REPLY\n");
			dbg("radio_rec","ROUTE_REPLY received at time %s \n", sim_time_string());
			dbg_clear("radio_pack","\t Routing Table of the node %hhu in position %hhu \n", TOS_NODE_ID, mess->src_add);
			dbg_clear("radio_pack","\t Table --> Destination address: %hhu \n", tab_routing[mess->src_add].dst_add);
			dbg_clear("radio_pack","\t Table --> Next-Hop: %hhu \n", tab_routing[mess->src_add].next_hop);

		}else{ //graffa che chiude il "se non sono io la sorgente"
			
			for (n=0; (tab_discovery[n].dst_add != mess->src_add || tab_discovery[n].msg_id != mess->msg_id || tab_discovery[n].src_add != mess->dst_add) && n<len_disc; n++){
			}
			if (n == len_disc){
				dbg("radio_pack","Non ho trovato la corrispondente tab discovery della route req");
				return buf;
			}
			if (tab_discovery[n].path > mess->path){
				tab_discovery[n].path = mess->path;
				//salvare valori nella tabella di routing
				tab_routing[mess->src_add].dst_add = mess->src_add;
				tab_routing[mess->src_add].next_hop = mess->crt_add; //nodo corrente della richiesta che ricevo quindi di fatto quello sucessivo nella tab routing
				tab_routing[mess->src_add].status = 1;
				dbg("radio_pack","Aggiorno path nella tabella di discovery: %hhu dal nodo %hhu al nodo %hhu \n", tab_discovery[n].path,tab_discovery[n].src_add,tab_discovery[n].dst_add);
				if (tab_routing[mess->src_add].dst_add == 1){
					call Timer_rout_1.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 2){
					call Timer_rout_2.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 3){
					call Timer_rout_3.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 4){
					call Timer_rout_4.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 5){
					call Timer_rout_5.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 6){
					call Timer_rout_6.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 7){
					call Timer_rout_7.startOneShot (90000);									
				}else if (tab_routing[mess->src_add].dst_add == 8){
					call Timer_rout_8.startOneShot (90000);									
				}
			}

			mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_out->dst_add = mess->dst_add;
			mess_out->src_add = mess->src_add;
			mess_out->msg_type = ROUTE_REPLY;
			mess_out->msg_id = mess->msg_id;
			mess_out->crt_add = TOS_NODE_ID;
			mess_out->path = mess->path + 1;

			dbg("radio_pack","INOLTRO UNA ROUTE_REPLY da sorgente %hhu a destinazione %hhu \n \n", mess_out->src_add, mess_out->dst_add );

			if(call AMSend.send(tab_discovery[n].prec_node,&packet,sizeof(my_msg_t))){
			}

		} //graffa che chiude else che diceva che non sono io la sorgente

	} // chiude if (msq_type = ROUTE_REPLY)

	return buf;

  } //interfaccia receive

  //***************** Timer Routing Stop ********************// 
  event void Timer_rout_1.fired() {					//questa interfaccia serve quando il timer della tab_routing scade, metto lo status a zero così invalido la tabella
	tab_routing[1].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 1\n");				
  }
  event void Timer_rout_2.fired() {		
	tab_routing[2].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 2\n");				
  }
  event void Timer_rout_3.fired() {		
	tab_routing[3].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 3\n");				
  }
  event void Timer_rout_4.fired() {		
	tab_routing[4].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 4\n");				
  }
  event void Timer_rout_5.fired() {		
	tab_routing[5].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 5\n");				
  }
  event void Timer_rout_6.fired() {		
	tab_routing[6].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 6\n");				
  }
  event void Timer_rout_7.fired() {		
	tab_routing[7].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 7\n");				
  }
  event void Timer_rout_8.fired() {		
	tab_routing[8].status = 0;
	dbg("radio_pack","E' scaduta la tabella di routing 8\n");				
  }

  //***************** Timer RREP Stop ********************//
  event void Timer_rrep_1.fired() {	//questa interfaccia serve quando il timer della RREP scade, metto lo status a zero così invalido tutte le tab_discovery con quella src e dst
			
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 1 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 1 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 1;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_2.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 2 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 2 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 2;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_3.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 3 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 3 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 3;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_4.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 4 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 4 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 4;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_5.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 5 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 5 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 5;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_6.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 6 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 6 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 6;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_7.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 7 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 7 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 7;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_8.fired() {
	dbg("radio_pack","E' scaduta la RREP da sorgente %hhu e destinazione 8 \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 8 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //per non lasciarlo "vuoto"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 8;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

}  //parentesi graffa di chiusura implementation
