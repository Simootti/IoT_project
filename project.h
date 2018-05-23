
#ifndef PROJECT_H
#define PROJECT_H

typedef nx_struct my_msg {	//defines the payload of the msg
	nx_uint8_t msg_type;	//8 bits unsigned variable
				//metti nx per variabili che verranno trasmesse nel network
	nx_uint16_t msg_id;	//16 bits unsigned variable
	nx_uint16_t value;	//data
	nx_uint8_t dst_add;	//destination address
	nx_uint8_t src_add;
} my_msg_t;

#define REQ 1
#define ROUTE_REQ 2
#define ROUTE_RESP 3

enum{
AM_MY_MSG = 6,		//questo è l'active message ID (we will communicate over AM channel 6)
};

//**********************************************************************//

typedef nx_struct route_message {
	nx_uint8_t msg_type;		//deve dirci se è ROUTE_REQ o ROUTE_RESP
	nx_uint16_t route_id;
	nx_uint8_t src_add;
	nx_uint8_t dst_add;
	nx_uint8_t crt_node;
} route_msg_t;

//**********************************************************************//

typedef nx_struct tab {
	nx_uint8_t src_add;		
	nx_uint16_t dst_add;	
	nx_uint16_t next_hop;	
	nx_uint8_t path;	//numero di nodi attraversati
} tab_t;

#endif
