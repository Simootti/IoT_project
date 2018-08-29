
#ifndef PROJECT_H
#define PROJECT_H

typedef nx_struct my_msg {	//defines the payload of the msg
	nx_uint8_t msg_type;	//8 bits unsigned variable
	nx_uint16_t msg_id;	//16 bits unsigned variable
	nx_uint16_t value;	//data
	nx_uint8_t dst_add;	//destination address
	nx_uint8_t src_add;	//source address
	nx_uint8_t crt_add;	//current node --> serve a identificare un next-hop a cui nel caso dobbiamo rispondere
	nx_uint8_t path;	//In order to chose the best path in the ROUTE_REPLY

} my_msg_t;

#define DATA 1
#define ROUTE_REQ 2
#define ROUTE_REPLY 3

enum{
AM_MY_MSG = 6,		//this is the active message ID
};

//**********************************************************************//

typedef nx_struct tab {
	
	nx_uint16_t dst_add;	//destinatiobn of the packet
	nx_uint16_t next_hop;	//next_hop associated with the destination
	nx_uint16_t status;	//if = 1 the table is valid and we can use it, if = 0 it has expired
} tab_r;

//**********************************************************************//

typedef nx_struct tab2 {
	nx_uint8_t src_add;	//saving inside the table the source of the request (needed to update)
	nx_uint16_t dst_add;	//destination of the packet
	nx_uint8_t status;	//if = 1 the table is valid and we can use it, if = 0 it has expired
	nx_uint8_t path;	//number of nodes we have crossed, needed to retrieve the best path
	nx_uint8_t msg_id;	//to verify the duplicates of a ROUTE_REQ
	nx_uint8_t prec_node;	//to save the previous node
} tab_d;

#endif
