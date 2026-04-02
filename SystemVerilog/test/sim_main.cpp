#include "Vtb.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtb* top = new Vtb;

    while (!Verilated::gotFinish()) {
        top->eval();   // 仿真一次
        break;         // 因为 initial 只跑一次
    }

    delete top;
    return 0;
}
