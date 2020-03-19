// i2c_bypass:
// 区分主从端,1主，2从，从FPGA透传
// 必须设置上拉或外置上拉电阻
// inout port must be pulled up!!

module i2c_bypass(
    reset_n,
    clk,
	scl1,
	sda1,
	scl2,
	sda2
);

input wire  clk;
input wire	scl1;
inout wire	sda1;
output	scl2;
inout wire	sda2;

reg scl2;

always @(posedge clk or negedge reset_n)
begin
    if (reset_n == 1'b0) 
    begin
        scl2 <= 1'b1;
    end
    else
    begin
        if (scl1)
        begin
            scl2 <= 1'b1;
        end
        else
        begin
            scl2 <= 1'b0;
        end
    end
end

wire SDA_I1;
wire SDA_I2;
reg SDA_T1;
reg SDA_T2;
//reg SDA_O1;
//reg SDA_O2;

reg [2:0]    ST_SDA_STATE;
parameter    ST_SDA_IDLE =3'b001;
parameter    ST_SDA_12   =3'b011;
parameter    ST_SDA_21   =3'b100;

//assign sda1 = (SDA_T1)? 1'bz: SDA_O1;
//assign sda2 = (SDA_T2)? 1'bz: SDA_O2;
assign sda1 = (SDA_T1)? 1'bz: 1'b0;
assign sda2 = (SDA_T2)? 1'bz: 1'b0;
assign SDA_I1 = (SDA_T1)? sda1:1'bz;
assign SDA_I2 = (SDA_T2)? sda2:1'bz;

always @(posedge clk or negedge reset_n)
begin
    if (reset_n == 1'b0) 
    begin
        SDA_T1 <= 1'b1;
        SDA_T2 <= 1'b1;
        //SDA_O1 <= 1'b1;
        //SDA_O2 <= 1'b1;
        ST_SDA_STATE <= ST_SDA_IDLE;
    end
    else
    begin
        case(ST_SDA_STATE)
        ST_SDA_IDLE: // wait for SDA_I1 or SDA_I2 to be pulled low
        begin
            SDA_T1 <= 1'b1; // both OBUFT in high-impedance state
            SDA_T2 <= 1'b1;
            if (SDA_I1 == 1'b0)
            begin
                SDA_T2 <= 1'b0; // sda driven by SDA_O2 is now low
                //SDA_O2 <= 1'b0;
                ST_SDA_STATE <= ST_SDA_12;
            end
            else if (SDA_I2 == 1'b0)
            begin
                SDA_T1 <= 1'b0; // sda driven by SDA_O1 is now low 
                //SDA_O1 <= 1'b0;
                ST_SDA_STATE <= ST_SDA_21;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_IDLE;
            end
        end
        
        ST_SDA_12:  // wait for SDA_I1 to go high
        begin
            if (SDA_I1 == 1'b1)
            begin
                //SDA_T1 <= 1'b1;
                //SDA_T2 <= 1'b1;
                ST_SDA_STATE <= ST_SDA_IDLE;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_12;
            end
        end

        ST_SDA_21:  // wait for SDA_I2 to go high
        begin
            if (SDA_I2 == 1'b1)
            begin
                //SDA_T1 <= 1'b1;
                //SDA_T2 <= 1'b1;
                ST_SDA_STATE <= ST_SDA_IDLE;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_21;
            end
        end

        default:
        begin
            ST_SDA_STATE    <= ST_SDA_IDLE;
        end
    end
end

endmodule

/*
always @(posedge CLOCK or posedge RESET)
begin
    if (RESET == 1'b1) 
    begin
        
    end
    else
    begin
        if ()
        begin
            
        end
        else
        begin
            
        end
    end
end



for VHDL

CTRL_LOGIC: process(clk100)
begin
    if rising_edge(clk100) then
        if(rst100 = '1') then  
            SDA_O1 <= '0';
            SDA_O2 <= '0';
            i2c_state <= s0;                         
        else  
            case i2c_state is
                when s0 =>          --s0: wait for SDA_I1 or SDA_I2 to be pulled low
                    SDA_T1 <= '1';          --both OBUFT in high-impedance state
                    SDA_T2 <= '1';
                    if(SDA_I1 = '0') then 
                        SDA_T2 <= '0';      --sda driven by SDA_O2 is now low                 
                        i2c_state <= s1; 
                    elsif(SDA_I2 = '0') then
                        SDA_T1 <= '0';      --sda driven by SDA_O1 is now low                  
                        i2c_state <= s2;                     
                    else
                        i2c_state <= s0;
                    end if;
                                  
                when s1 =>          --s1: wait for SDA_I1 to go high
                    if(SDA_I1 = '1') then
                        i2c_state <= s0;
                    else
                        i2c_state <= s1;           
                    end if;
                    
                when s2 =>          --s2: wait for SDA_I2 to go high
                    if(SDA_I2 = '1') then
                        i2c_state <= s0;
                    else
                        i2c_state <= s2;           
                    end if;

                when others =>      --others: bad state
                    i2c_state <= s0;    
            end case; 
        end if;  
    end if;
end process CTRL_LOGIC;

*/
