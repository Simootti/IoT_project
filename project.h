
#ifndef PROJECT_H
#define PROJECT_H

typedef nx_struct my_msg {	//defines the payload of the msg
	nx_uint8_t msg_type;	//8 bits unsigned variable
				//metti nx per variabili che verranno trasmesse nel network
	nx_uint16_t msg_id;	//16 bits unsigned variable
	nx_uint16_t value;	//data
	nx_uint8_t dst_add;	//destination address
} my_msg_t;

#define REQ 1

enum{
AM_MY_MSG = 6,		//questo è l'active message ID (we will communicate over AM channel 6)
};

#endif
