
#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct my_msg {	//defines the payload of the msg
	nx_uint8_t msg_type;	//8 bits unsigned variable
				//metti nx per variabili che verranno trasmesse nel network
	nx_uint16_t msg_id;	//16 bits unsigned variable
	nx_uint16_t value;
	nx_uint32_t dst_add;	//destination address
	nx_uint16_t data1;	//Send a data 1 to a random destination
	nx_uint16_t data2;	//Send a data 2 to a random destination
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
//AM_MY_MSG = 6,		questo è l'active message ID (we will communicate over AM channel 6)
MY_MSG = 7,
};

#endif
