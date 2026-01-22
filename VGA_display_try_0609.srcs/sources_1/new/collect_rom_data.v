module collect_rom_data(
    input digit_0_rom_data,
    input digit_1_rom_data,
    input digit_2_rom_data,
    input digit_3_rom_data,
    input digit_4_rom_data,
    input digit_5_rom_data,
    input digit_6_rom_data,
    input digit_7_rom_data,
    input digit_8_rom_data,
    input digit_9_rom_data,
    
    output [9:0] rom_data_collect
    );
    
    assign rom_data_collect = {digit_9_rom_data, 
                               digit_8_rom_data, 
                               digit_7_rom_data,
                               digit_6_rom_data,
                               digit_5_rom_data,
                               digit_4_rom_data,
                               digit_3_rom_data,
                               digit_2_rom_data,
                               digit_1_rom_data,
                               digit_0_rom_data};
endmodule
