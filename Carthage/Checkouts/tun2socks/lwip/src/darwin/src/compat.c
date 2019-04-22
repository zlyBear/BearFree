#include "compat.h"

void tcp_accepted_c(struct tcp_pcb *pcb) {
    tcp_accepted(pcb);
}