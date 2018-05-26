
#ifndef PROJECT_H
#define PROJECT_H

typedef nx_struct my_msg {	//defines the payload of the msg
	nx_uint8_t msg_type;	//8 bits unsigned variable
	nx_uint16_t msg_id;	//16 bits unsigned variable
	nx_uint16_t value;	//data
	nx_uint8_t dst_add;	//destination address
	nx_uint8_t src_add;	//source address
	//nx_uint8_t crt_node;	//current node
} my_msg_t;

#define REQ 1
#define ROUTE_REQ 2
#define ROUTE_RESP 3

enum{
AM_MY_MSG = 6,		//questo è l'active message ID (we will communicate over AM channel 6)
};

//**********************************************************************//

typedef nx_struct tab {
	nx_uint8_t src_add;		
	nx_uint16_t dst_add;	
	nx_uint16_t next_hop;
	nx_uint16_t distance_from_dst;	//indicherà qual è la distanza che ci separa dalla destinazione 
					// --->(valore che serve mettere nella Routing Table per verificare dopo il percorso migliore)
	nx_uint8_t path;	//numero di nodi attraversati
} tab_t;

#endif
