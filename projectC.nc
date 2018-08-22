
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
  my_msg_t* mess;
  message_t packet;
  uint8_t len_disc=0; //per tenere il conto dell'occupazione della tab discovery
  uint8_t n;
  uint8_t m;
  uint8_t big_path;
  tab_d tab_discovery[100];
  tab_r tab_routing[8];

  task void sendRandmsg();

//TODO IMPORTANTISSIMO : VEDERE COME SISTEMARE I VARI PACCHETTI IN MODO DA MANDARE I PACCHEETI GIUSTI E FARE GLI IF GIUSTI NELL'INTERFACCIA DI RICEZIONE
//STO PROVANDO SE FUNZIONA CON UN SINGOLO MESSAGGIO MESS AL POSTO CHE 3 TIPI DI MESSAGGIO DIFFERENTI (CON LA DIFFERENZIAZIONE TRA I 3 MEDIANTE MSG TYPE)

//IMPORTANTISSIMO (l'assunzione sopra)!!!!!

//*********************** Task Send Random Messages *********************************************************************//


  task void sendRandmsg() {  // task che manda i messaggi casuali
	
	//uint8_t num = (call Random.rand16() % 8) + 1; //lo lascio solo per poter settare il destination address del broadcast

	//SOLO campi che sono presenti in qualsiasi tipo di messaggio

	mess = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter++;
	mess->dst_add = (call Random.rand16() % 8) + 1;
	mess->src_add = TOS_NODE_ID;
	mess->crt_add = TOS_NODE_ID;

	dbg_clear("radio_send", "\n");
	dbg_clear("radio_pack", "\n");
	dbg_clear("radio_pack", "\t\t Stampo la Destinazione del nodo %hhu : %hhu \n",TOS_NODE_ID, mess->dst_add);
	dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);

	//primo caso: trovo una corrispondenza nella Routing Table
	if (tab_routing[mess->dst_add].dst_add == mess->dst_add){
			dbg("radio_pack","Found a match in the Routing Table \n");

		// allora mando al Next-Hop
		// verifico se è effettivamente la destinazione e lo scrivo (serve solo per controllare) 
		// stampo comunque tutto per vedere come è stato creato il pacchetto
		// inoltre, aggiungo i dati (msg_value, msg_type = 1 (DATA))

		if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination");	
		}else{
			dbg("radio_pack","Packet sent to next hop");
		}
		
		mess->msg_type = DATA;	
		mess->value = call Random.rand16();

		// mando effettivamente il pacchetto al (tab_routing[mess->des.add].next_hop)
		if(call AMSend.send(tab_routing[mess->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}

	}else{			
	// secondo caso: non trovo corrispondenza nella tabella ---> dovrò mandare il messaggio in broadcast
		dbg("radio_pack","Match not found, sending in Broadcast in order to update the Routing Table \n");

		mess->msg_type = ROUTE_REQ;
		dbg_clear("radio_pack", "\t\t destination address: %hhu \n", mess->dst_add);

		//prova: mando in broadcast scrivendo tutto
		//fare una task potrebbe darmi errori, almeno qua in teoria so che manda i dati giusti che sono stati definiti in questa interfaccia

  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}
		
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
	
	m=0; //contatore che serve più avanti (tener tracce del precedente path in modo da aumentarlo)
	big_path=100; //contatore che serve più avanti (per trovare il più piccolo path di routing che serve per eliminare gli altri)
	mess=(my_msg_t*)payload;

// 1) IF msg_type is DATA
	if(mess->msg_type == DATA){
		
		//CONTROLLO: sono io il nodo di destinazione?
		//se lo sono, allora stampo tutto perchè avrò tutti i dati
		if(mess->dst_add == TOS_NODE_ID){
			dbg("radio_pack","DATA packet reached the ORIGINAL DESTINATION correctly!\n");
		}
		else{
		//se non sono io la destinazione allora dovrò fare forward
		//controllo la tabella di routing
		//TODO controllare se valido il valore nella tabella di routing?? Vedere se funziona anche senza controllo

			if (tab_routing[mess->dst_add].dst_add == mess->dst_add){
				dbg("radio_pack","Found a match in the Routing Table \n");
				
				if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
					dbg("radio_pack","Packet sent to destination");	
				}else{
					dbg("radio_pack","Packet sent to next hop");
					dbg_clear("radio_pack", "\t\t Next-Hop address: %hhu \n", tab_routing[mess->dst_add].next_hop);
				}
				/*
				mess_tipo1 = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t))); //Creo pacchetto da inoltrare
				mess_tipo1->value = mess->value;
				mess_tipo1->type = DATA;
				mess_tipo1->dst_add = mess->dst_add;
				mess_tipo1->src_add = mess->src_add;
				mess_tipo1->crt_add = TOS_NODE_ID; 

				provando con messaggio unico 
				*/
				
				mess->crt_add = TOS_NODE_ID;
				
				if(call AMSend.send(tab_routing[mess->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){
				}

			}	//graffa che chiude [[if (tab_routing[mess->dst_add].dst_add == mess->dst_add)]]
			else{

			// Se siamo qui è perché c'è un errore nelle tabelle di routing

				dbg("radio_pack","ERRORE : NON DOVRESTI ESSERE QUI, DOVRESTI ESSERE STATO INOLTRATO IN TABELLA");

			}

		}	//graffa che chiude l'else (TOS_NODE_ID)

	} // graffa che chiude if(msg_type == 1) ---> DATA type 
//********************************************************************************************************************************************//

// 2) caso due : IF msg_type == ROUTE_REQ

	if(mess->msg_type == ROUTE_REQ){

	
	// PRIMO CONTROLLO: HO GIÀ RICEVUTO QUESTA ROUTE_REQ? (eliminazione duplicati)
	// SE msg_id e src_add e msg_id corrispondono a qualcosa che ho già in memoria, allora scarto la seconda

		for (n=0; n<len_disc; n++){ 	
			
			if(tab_discovery[n].src_add == mess->src_add && tab_discovery[n].msg_id == mess->msg_id && tab_discovery[n].dst_add == mess->dst_add){
			
				return buf;
			}

		} //elimina il pacchetto duplicato, se duplicato faccio return buf dentro al for così interrompo l'interfaccia receive
		
		// a) controllo se sono io il nodo destinazione
		if(mess->dst_add == TOS_NODE_ID){
			dbg("radio_pack","I am the Destination of the Route_Req %hhu sent originally by Node %hhu \n",mess->msg_id, mess->src_add );
			// dovrebbe stamparmi sia l'id della route_req sia la VERA sorgente
			dbg("radio_pack","I send a ROUTE_REPLY to  %hhu  \n",mess->crt_add );
			/*
			deve stamparmi il nodo che mi ha "consegnato" la ROUTE_REQ (crt_add indica ancora l'ultimo hop che ha fatto forward)
			se src e dst sono collegati, allora in questo caso src_add == crt_add )
	
			nella richiesta non mi è richiesto di aggiornare la tabella della destinazione, quindi mi limito a mandare una ROUTE_REPLY
			che riattraverserà tutti i nodi
			-->la gestione del riattraversare tutti gli hop è affidata al ricevimento di una ROUTE_REPLY (definiamo più avanti) 
			*/

			tab_discovery[len_disc].msg_id = mess->msg_id;	//mi salvo il msg_id di questa ROUTE_REQ per fare un confronto successivo ed eliminare i doppioni	
			tab_discovery[len_disc].src_add = mess->src_add;
			tab_discovery[len_disc].dst_add = mess->dst_add;
			tab_discovery[len_disc].prec_node = mess->crt_add;
			
			for (n=0; n<len_disc; n++){ //per aggiungere al msg_id il path precedente
				if (tab_discovery[n].msg_id == tab_discovery[len_disc].msg_id){
					if (tab_discovery[n].path >= m){
						m = tab_discovery[n].path;
					}
				}
			}
			
			tab_discovery[len_disc].path = m + 1;
			len_disc += 1;
			/*
			mess_tipo3 = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_tipo3->dst_add = mess->src_add;
			mess_tipo3->src_add = mess->dst_add;
			mess_tipo3->msg_type = ROUTE_REPLY;
			mess_tipo3->msg_id = mess->msg_id;
			mess_tipo3->crt_add = TOS_NODE_ID;
			call AMSend.send(mess_tipo3->dst_node,&packet,sizeof(my_msg_t));
			*/
			mess->msg_type = ROUTE_REPLY;
			mess->dst_add = mess->src_add;
			mess->src_add = mess->dst_add;
			mess->crt_add = TOS_NODE_ID;
			if(call AMSend.send(mess->dst_add,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		} 	// graffa che chiude [[if(mess->dst_add == TOS_NODE_ID)]] --> se esco da questo if, vuol dire che non sono io la DST
		 else{
		 //se sono qui, vuol dire che non sono la destinazione

			tab_discovery[len_disc].msg_id = mess->msg_id;	//mi salvo il msg_id di questa ROUTE_REQ per fare un confronto successivo ed eliminare i doppioni	
			tab_discovery[len_disc].src_add = mess->src_add;
			tab_discovery[len_disc].dst_add = mess->dst_add;
			tab_discovery[len_disc].prec_node = mess->crt_add;
			
			for (n=0; n<len_disc; n++){ //per aggiungere al msg_id il path precedente
				if (tab_discovery[n].msg_id == tab_discovery[len_disc].msg_id && tab_discovery[n].prec_node == tab_discovery[len_disc].prec_node){
					if (m >= tab_discovery[n].path){
						m = tab_discovery[n].path;
					}
				}
			}
			
			tab_discovery[len_disc].path = m + 1;
			len_disc += 1;

			mess->crt_add = TOS_NODE_ID;

	  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		} //graffa che chiude l'else
 
	}	//graffa che chiude if(mess->msg_type == ROUTE_REQ)

//********************************************************************************************************************************************************//

// 2) caso due : If msg_type == ROUTE_REPLY

	if(mess->msg_type == ROUTE_REPLY){

		if(mess->src_add == TOS_NODE_ID){	//se sono io la sorgente
			
			//Qui non faccio il controllo del path perché c'è bisogno di farlo solo quando fa il primo RREP dove no
			//Metto i dati in tabella
			tab_routing[mess->dst_add].dst_add = mess->src_add;
			tab_routing[mess->dst_add].next_hop = mess->crt_add;
			
			//stampo cosa ho aggiornato nella mia tabella
			dbg("radio_rec","ROUTE_REPLY received at time %s \n", sim_time_string());
			dbg_clear("radio_pack","\t\t Routing Table of the node %hhu in position %hhu \n", TOS_NODE_ID, mess->dst_add);
			dbg_clear("radio_pack", "\t\t Table --> Destination address: %hhu \n", tab_routing[mess->dst_add].dst_add);
			dbg_clear("radio_pack", "\t\t Table --> Next-Hop: %hhu \n", tab_routing[mess->dst_add].next_hop);		

			//setto il pacchetto come DATA da inviare --> reimposto coi dati che ho ora della RoutingTable
			mess->msg_type = DATA;
			mess->value = call Random.rand16();
			mess->dst_add = tab_routing[mess->dst_add].dst_add;
			mess->src_add = TOS_NODE_ID;
			mess->crt_add = TOS_NODE_ID;
			//mess->next_hop = tab_routing[mess->dst_add].next_hop;

			// mando effettivamente il pacchetto al (tab_routing[n].next_hop)
			if(call AMSend.send(tab_routing[mess->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
			}

		} //graffa che chiude il "se sono io la sorgente"
		else{ 
			//se non sono io la sorgente --> sono un nodo che diventerà un next-hop di quello prima di me
			//Controllo dei path
				
			for (n=0; n<len_disc; n++){ //per controllare la lunghezza del path, che se maggiore rispetto a una con uguale id la elimino
				if (tab_discovery[n].dst_add == mess->src_add && tab_discovery[n].msg_id == mess->msg_id){
					if (tab_discovery[n].path <= big_path){
						big_path = tab_discovery[n].path;
					}
					if (tab_discovery[n].path > big_path){
						return buf;
					}
				}
			}

			//salvare valori nella tabella di routing
			tab_routing[mess->dst_add].dst_add = mess->src_add;
			tab_routing[mess->dst_add].next_hop = mess->crt_add; //nodo corrente della richiesta che ricevo quindi di fatto quello sucessivo nella tab routing
			
			//Fare la ricerca della tab discovery correlata per la RRES verso il percorso giusto
			for (n=0; tab_discovery[n].dst_add != mess->src_add && tab_discovery[n].msg_id != mess->msg_id && n<len_disc && tab_discovery[n].next_hop != TOS_NODE_ID; n++){
			}
			//Invio del pacchetto RRES
			/*
			mess_tipo3 = (my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_tipo3->dst_add = tab_discovery[n].src_add;
			mess_tipo3->src_add = tab_discovery[n].dst_add;
			mess_tipo3->msg_type = ROUTE_REPLY;
			mess_tipo3->msg_id = mess->msg_id;
			mess_tipo3->crt_add = TOS_NODE_ID;
			mess_tipo3->next_hop = tab_discovery[n].crt_add;
			if(call AMSend.send(mess_tipo3->next_hop,&packet,sizeof(my_msg_t))){
			}
			*/

			mess->dst_add = tab_discovery[n].src_add;
			mess->src_add = tab_discovery[n].dst_add;
			mess->msg_type = ROUTE_REPLY; //non serve però io lo ribadisco
			mess->msg_id = tab_discovery[n].msg_id;
			mess->crt_add = TOS_NODE_ID;
			//mess->next_hop = tab_discovery[n].prec_node;	
			if(call AMSend.send(tab_discovery[n].prec_node,&packet,sizeof(my_msg_t))){
			}

		} //graffa che chiude else che diceva che non sono io la sorgente

	} // chiude if (msq_type = ROUTE_REPLY)

	return buf;
  }

}  //parentesi graffa di chiusura implementation
