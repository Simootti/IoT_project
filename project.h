
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

#define DATA 1
#define ROUTE_REQ 2
#define ROUTE_RESP 3

enum{
AM_MY_MSG = 6,		//questo è l'active message ID (we will communicate over AM channel 6)
};

//**********************************************************************//

typedef nx_struct tab {
	nx_uint8_t src_add;	//salvo nella tabella la sorgente della richiesta (serve per aggiornare)
				//---> serve forse alla ROUTE_RESP
	nx_uint16_t dst_add;	//destinazione del pacchetto
	nx_uint16_t next_hop;	//next_hop associato alla destinazione (segue il percorso, non importa che sia
				//direttamente la destinazione)
	nx_uint8_t path;	//numero di nodi attraversati, serve per trovare il path migliore
} tab_t;

#endif
