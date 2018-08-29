
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

//global variables declaration

  uint32_t counter = 0;
  my_msg_t* mess;
  my_msg_t* mess_out;
  message_t packet;
  uint8_t len_disc=0; //in order to count the occupancy of the tab discovery
  uint8_t temp;
  uint8_t n;
  uint8_t big_path;
  tab_d tab_discovery[100];
  tab_r tab_routing[9]; // it must be 9 because we need (for our idea) the positions from 1 to 8 (we won't use position 0)

  task void sendRandmsg();

//*********************** Task Send Random Messages *********************************************************************//


  task void sendRandmsg() {  // task which send messages

	mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter;
	counter = counter + 1;
	mess->dst_add = (call Random.rand16() % 8) + 1;
	if (mess->dst_add == TOS_NODE_ID){
		dbg("radio_pack","I sent a packet to myself, so AODV it's not necessary\n\n");
		return;
	}
	mess->src_add = TOS_NODE_ID;
	mess->crt_add = TOS_NODE_ID;

	dbg_clear("radio_send", "\n");
	dbg("radio_pack", "I am the Node --> %hhu sending a message with the following parameters: \n\t\t Source Address:%hhu \n\t\t Destination Address: %hhu \n\t\t Message ID:%hhu \n\n ", TOS_NODE_ID, mess->src_add, mess->dst_add, mess->msg_id);


	//First case: found a match inside the Routing Table
	if (tab_routing[mess->dst_add].dst_add == mess->dst_add && tab_routing[mess->dst_add].status == 1){
			dbg("radio_pack","Found a match in the Routing Table \n");

		// then I send to Next-Hop
		// verify if it's the true destination, then write it (just checking)
		// print everythingh to see the packet
		// add the data (msg_value, msg_type = 1 (DATA))

		if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
			dbg("radio_pack","Packet sent to destination\n");
			dbg_clear("radio_pack", "\t Next-Hop address: %hhu \n\n", tab_routing[mess->dst_add].next_hop);	
		}else{
			dbg("radio_pack","Packet sent to next hop");
			dbg_clear("radio_pack", "\t Next-Hop address: %hhu \n\n", tab_routing[mess->dst_add].next_hop);
		}
		
		mess->msg_type = DATA;	
		mess->value = call Random.rand16();

		// I actually send the message to (tab_routing[mess->des.add].next_hop)
		if(call AMSend.send(tab_routing[mess->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}

	}else{			
	// Second case: Match in the Routing Table not found---> message sent in Broadcast

		dbg("radio_pack","Match not found, sending a ROUTE_REQ in Broadcast in order to update the Routing Table, and to send the packet towards the destination %hhu \n\n", mess->dst_add);

		mess->msg_type = ROUTE_REQ;

		if (mess->dst_add == 1){ 	// Timers nedded for the Route_Reply, that must arrives before 1 second (Timer's starting point)
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
		//saving the msg_id of this ROUTE_REQ for a following comparison and to remove the duplicates	
		tab_discovery[len_disc].src_add = mess->src_add;
		tab_discovery[len_disc].path = 100;
		tab_discovery[len_disc].dst_add = mess->dst_add;
		tab_discovery[len_disc].prec_node = mess->crt_add;
		tab_discovery[len_disc].status = 1;

		dbg("radio_pack","Tab_Discovery of the Node %hhu UPDATED in position %hhu with the following parameters:\n\t Message ID: %hhu \n\t Source Address: %hhu \n\t Path length: %hhu \n\t Destination Address: %hhu \n\t Prec Node: %hhu \n\n", TOS_NODE_ID, len_disc, tab_discovery[len_disc].msg_id, tab_discovery[len_disc].src_add,tab_discovery[len_disc].path, tab_discovery[len_disc].dst_add, tab_discovery[len_disc].prec_node);

		len_disc += 1;

		//prova: Sending in Broadcast the Route_Req
		//I'm sending data which has been defined in this Interface

  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){	
		}
		
	}	//closing the "else" of the Match NOT found


  } //closing "SEND RANDOM MSG" Task  	


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
	big_path=100; //counter needed to find the shortest routing path
	mess=(my_msg_t*)payload;

// 1) IF msg_type is DATA
	if(mess->msg_type == DATA){
		
		//CHECK: Am I the Destination Node?
		if(mess->dst_add == TOS_NODE_ID){
			dbg("radio_pack","DATA packet send originally from %hhu to %hhu reached its Destination\n", mess->src_add , mess->dst_add);
			dbg("radio_pack","DATA packet reached the ORIGINAL DESTINATION correctly!\n\n");
		}else{
			//If I'm NOT the destination, then I must forward
			dbg("radio_pack","I am the Node %hhu, received a pkt from Source %hhu directed to Destination %hhu \n", TOS_NODE_ID , mess->src_add, mess->dst_add);

			//controllo la tabella di routing

			if (tab_routing[mess->dst_add].dst_add == mess->dst_add && tab_routing[mess->dst_add].status == 1){

				dbg("radio_pack","Found a match in the Routing Table \n");
				//dbg("radio_pack","In questo nodo (numero %hhu) ho una corrispondenza nella routing table\n", TOS_NODE_ID);
				//dbg("radio_pack","nella posizione %hhu, infatti\n", mess->dst_add);
				//dbg("radio_pack","Destination: %hhu == %hhu \n",tab_routing[mess->dst_add].dst_add , mess->dst_add);

			
				if (tab_routing[mess->dst_add].next_hop == mess->dst_add){
					dbg("radio_pack","Packet sent to destination");
					dbg_clear("radio_pack", "\t Next-Hop address: %hhu \n\n", tab_routing[mess->dst_add].next_hop);		
				}else{
					dbg("radio_pack","Packet sent to next hop");
					dbg_clear("radio_pack", "\t Next-Hop address: %hhu\n\n", tab_routing[mess->dst_add].next_hop);
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

			}else{ //closing [[if (tab_routing[mess->dst_add].dst_add == mess->dst_add)]]

				// If we're here, there is an error ---> Routing Table has expired
				dbg("radio_pack","Routing Table has expired, so it's impossible to forward the packet! \n\n");

			}

		}	//closing "else (TOS_NODE_ID)"

	} // closing [if(msg_type == 1) ---> DATA type] 
//********************************************************************************************************************************************//

// 2) Second Case : IF msg_type == ROUTE_REQ

	if(mess->msg_type == ROUTE_REQ){

	// Elimination of Duplicates
	// If msg_id and src_add and dst_add are equal to somethingh already in memory, duplicate Route_Req are discarded

		for (n=0; n<len_disc; n++){ 	
			
			if(tab_discovery[n].src_add == mess->src_add && tab_discovery[n].msg_id == mess->msg_id && tab_discovery[n].dst_add == mess->dst_add){
				dbg("radio_pack", "Discarding a duplicate of the REQ with ID: %hhu originated by %hhu and sent towards %hhu \n\n", mess->msg_id ,mess->src_add, mess->crt_add);

				return buf;
			}

		} //Discarding the duplicate, doing a "return buf" inside the "for cycle" so I stop the "receive interface"
		
		// a) Checking if I am the Destination Node
		if(mess->dst_add == TOS_NODE_ID){

			dbg("radio_pack","I am Node %hhu, the Destination of the Route_Req sent originally by Node %hhu of the message with ID: %hhu \n",TOS_NODE_ID, mess->src_add , mess->msg_id );
			// it should print the id of the route_req and the REAL source
			dbg("radio_pack","I send a ROUTE_REPLY to %hhu with source %hhu \n\n",mess->src_add, mess->dst_add );
			/*
			sending a ROUTE_REPLY which crosses all the nodes backwards
			-->the management of coming back to the source depends by the arrival of a ROUTE_REPLY (defined later in the program) 
			*/

			temp = mess->crt_add;			

			mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			mess_out->msg_id = mess->msg_id;
			mess_out->msg_type = ROUTE_REPLY;
			mess_out->dst_add = mess->src_add;
			mess_out->src_add = mess->dst_add;
			mess_out->crt_add = TOS_NODE_ID;
			mess_out->path = 1;		//here we start to calculate the path, and will find a way thanks to the tab_discovery

			if(call AMSend.send(temp,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		}else{ // closing [[if(mess->dst_add == TOS_NODE_ID)]] --> if I exit from this "if", it means I'm NOT the DST
		
			//If I'm here, I am NOT the Destination

			tab_discovery[len_disc].msg_id = mess->msg_id;	
			//saving the msg_id of this ROUTE_REQ to compare later and discard the duplicates	
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

			dbg("radio_pack","I am the Node %hhu, sending a ROUTE_REQ in BROADCAST because I am NOT the DST \n", TOS_NODE_ID );
			dbg("radio_pack","Sending a ROUTE_REQ to find a path from Source %hhu to Destination %hhu with ID %hhu \n \n", mess_out->src_add, mess_out->dst_add, mess_out->msg_id );

	  		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
			}

		} //closing the "else"
 
	}	//closing --> if(mess->msg_type == ROUTE_REQ)

//********************************************************************************************************************************************************//

// 3) Third Case : If msg_type == ROUTE_REPLY

	if(mess->msg_type == ROUTE_REPLY){

		if(mess->dst_add == TOS_NODE_ID){	//IF I'm the Source
			
			for (n=0; (tab_discovery[n].dst_add != mess->src_add || tab_discovery[n].msg_id != mess->msg_id || tab_discovery[n].src_add != mess->dst_add) && n<len_disc; n++){
			}
			if (n == len_disc){
				dbg("radio_pack","Didn't find the corrispondent tab_discovery of the Route_Req \n");
				return buf;
			}

			if (tab_discovery[n].status != 1){
				dbg("radio_pack","The ROUTE_REPLY of this tab_discovery has expired! \n");
				return buf;
			}

			if (tab_discovery[n].path > mess->path){
				tab_discovery[n].path = mess->path;
				//saving data inside the routing table
				tab_routing[mess->src_add].dst_add = mess->src_add;
				tab_routing[mess->src_add].next_hop = mess->crt_add; //current node of the request that I receive, so the next one in the tab_routing
				tab_routing[mess->src_add].status = 1;
				dbg("radio_pack","Updating the path inside the tab_discovery: %hhu, from node %hhu to node %hhu \n", tab_discovery[n].path,tab_discovery[n].src_add,tab_discovery[n].dst_add);

				//timer for the routing table that after 90 seconds it's eliminated (in the interface of --> timer.fire)
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
			
			//print what has been updated
			dbg("radio_rec","I am the Destination of the ROUTE_REPLY\n");
			dbg("radio_rec","ROUTE_REPLY received at time %s \n", sim_time_string());
			dbg_clear("radio_pack","\t Routing Table of the node %hhu in position %hhu \n", TOS_NODE_ID, mess->src_add);
			dbg_clear("radio_pack","\t Table --> Destination address: %hhu \n", tab_routing[mess->src_add].dst_add);
			dbg_clear("radio_pack","\t Table --> Next-Hop: %hhu \n", tab_routing[mess->src_add].next_hop);

		}else{ //closing the "if I'm the Original Source"
			
			for (n=0; (tab_discovery[n].dst_add != mess->src_add || tab_discovery[n].msg_id != mess->msg_id || tab_discovery[n].src_add != mess->dst_add) && n<len_disc; n++){
			}
			if (n == len_disc){
				dbg("radio_pack","Didn't find the corrispondent tab_discovery of the Route_Req");
				return buf;
			}
			if (tab_discovery[n].path > mess->path){
				tab_discovery[n].path = mess->path;
				//saving data inside the routing table
				tab_routing[mess->src_add].dst_add = mess->src_add;
				tab_routing[mess->src_add].next_hop = mess->crt_add; //current node of the request that I receive, so the next one in the tab_routing
				tab_routing[mess->src_add].status = 1;
				dbg("radio_pack","Updating the path inside the tab_discovery: %hhu, from node %hhu to node %hhu \n", tab_discovery[n].path,tab_discovery[n].src_add,tab_discovery[n].dst_add);
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

			dbg("radio_pack","FORWARDING a ROUTE_REPLY from Source %hhu to Destination %hhu \n \n", mess_out->src_add, mess_out->dst_add );

			if(call AMSend.send(tab_discovery[n].prec_node,&packet,sizeof(my_msg_t))){
			}

		} //closing the "else" that said "I'm not the Source"

	} // closing --> if (msq_type = ROUTE_REPLY)

	return buf;

  } // closing the Receive Interface

  //***************** Timer Routing Stop ********************// 

//we need this inteface when the Timer of the tab_routing expires, putting the "status" equal to 0 in order to invalidate the Table

  event void Timer_rout_1.fired() {					
	tab_routing[1].status = 0;
	dbg("radio_pack","Routing Table 1 has expired\n");				
  }
  event void Timer_rout_2.fired() {		
	tab_routing[2].status = 0;
	dbg("radio_pack","Routing Table 2 has expired\n");				
  }
  event void Timer_rout_3.fired() {		
	tab_routing[3].status = 0;
	dbg("radio_pack","Routing Table 3 has expired\n");				
  }
  event void Timer_rout_4.fired() {		
	tab_routing[4].status = 0;
	dbg("radio_pack","Routing Table 4 has expired\n");				
  }
  event void Timer_rout_5.fired() {		
	tab_routing[5].status = 0;
	dbg("radio_pack","Routing Table 5 has expired\n");				
  }
  event void Timer_rout_6.fired() {		
	tab_routing[6].status = 0;
	dbg("radio_pack","Routing Table 6 has expired\n");				
  }
  event void Timer_rout_7.fired() {		
	tab_routing[7].status = 0;
	dbg("radio_pack","Routing Table 7 has expired\n");				
  }
  event void Timer_rout_8.fired() {		
	tab_routing[8].status = 0;
	dbg("radio_pack","Routing Table 8 has expired\n");				
  }

  //***************** Timer RREP Stop ********************//

//we need this interface when the timer of the Route_Reply expires, putting the status equal to 0, so invalidates every tab_discovery with same src e dst

  event void Timer_rrep_1.fired() {	
			
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 1 has expired\n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 1 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 1;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_2.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 2 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 2 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 2;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_3.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 3 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 3 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 3;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_4.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 4 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 4 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 4;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_5.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 5 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 5 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 5;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_6.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 6 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 6 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 6;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_7.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 7 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 7 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 7;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

  event void Timer_rrep_8.fired() {
	dbg("radio_pack","ROUTE_REPLY from Source %hhu and Destination 8 has expired \n", TOS_NODE_ID);
	for (n=0;n<len_disc; n++){	
		if(tab_discovery[n].dst_add == 8 && tab_discovery[n].src_add == TOS_NODE_ID){
			tab_discovery[n].status = 0;
		}		
	}

	//setting the packet as DATA to send --> using the data that I have now in the RoutingTable
	mess_out=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess_out->msg_id = 0; //in order to don't let this "empty"
	mess_out->msg_type = DATA;
	mess_out->value = call Random.rand16();
	mess_out->dst_add = 8;
	mess_out->src_add = TOS_NODE_ID;
	mess_out->crt_add = TOS_NODE_ID;

	// actually sending the packet to (tab_routing[n].next_hop)
	if(call AMSend.send(tab_routing[mess_out->dst_add].next_hop,&packet,sizeof(my_msg_t)) == SUCCESS){	
	}					
  }

}  //closing the Implementation
