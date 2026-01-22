#include <stdio.h>
#include "xil_io.h"
#include "xparameters.h"
#include "xil_types.h"
#include "xil_cache.h"
#include "sleep.h"

#define VDMA_BASEADDR               XPAR_AXI_VDMA_0_BASEADDR
#define VDMA_FRAME0_START_ADDRES    0x01000000
#define STRIDE                      640*2
#define HSIZE                       640*2
#define VSIZE                       480

#define AXI_LITE_BASEADDR           0x43C00000

int main() 
{
    // VDMA 写通道设置
    Xil_Out32(VDMA_BASEADDR+0x30, 0x1);
    Xil_Out32(VDMA_BASEADDR+0xAC, VDMA_FRAME0_START_ADDRES);
    Xil_Out32(VDMA_BASEADDR+0xA8, STRIDE);
    Xil_Out32(VDMA_BASEADDR+0xA4, HSIZE);
    Xil_Out32(VDMA_BASEADDR+0xA0, VSIZE);

    // VDMA 读通道设置
    Xil_Out32(VDMA_BASEADDR, 0x1);
    Xil_Out32(VDMA_BASEADDR+0x5c, VDMA_FRAME0_START_ADDRES);
    Xil_Out32(VDMA_BASEADDR+0x58, STRIDE);
    Xil_Out32(VDMA_BASEADDR+0x54, HSIZE);
    Xil_Out32(VDMA_BASEADDR+0x50, VSIZE);

    Xil_Out32(AXI_LITE_BASEADDR, 0x2);

    // int i;
    // for (i = 0; i < 100; i++) {
    //     Xil_Out32(AXI_LITE_BASEADDR, i%10);
    //     sleep(3);        
    // }


    return 0;
}