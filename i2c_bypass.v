// i2c_bypass:
// 不区分主从端，从FPGA透传
// 必须设置上拉或外置上拉电阻
// inout port must be pulled up!!

module i2c_bypass(
    input reset_n,
    input clk,
	inout scl1,
	inout sda1,
	inout scl2,
	inout sda2
);

wire    clk;
wire	scl1;
wire	sda1;
wire	scl2;
wire	sda2;

reg SDA_T1;
reg SDA_T2;
reg [10:0]   sda_delay_cnt;
reg [2:0]    ST_SDA_STATE;
parameter    ST_SDA_IDLE =3'b001;
parameter    ST_SDA_12   =3'b010;
parameter    ST_SDA_21   =3'b100;
parameter    ST_SDA_DELAY   =3'b000;

assign sda1 = (SDA_T1)? 1'b0:1'bz;
assign sda2 = (SDA_T2)? 1'b0:1'bz;


always @(posedge clk or negedge reset_n)
begin
    if (reset_n == 1'b0) 
    begin
        SDA_T1 <= 1'b0;
        SDA_T2 <= 1'b0;
        ST_SDA_STATE <= ST_SDA_IDLE;
        sda_delay_cnt <= 11'b0;
    end
    else
    begin
        case(ST_SDA_STATE)
        ST_SDA_IDLE: // wait for SDA_I1 or SDA_I2 to be pulled low
        begin
            SDA_T1 <= 1'b0; // both OBUFT in high-impedance state
            SDA_T2 <= 1'b0;
            if (sda1 == 1'b0)
            begin
                SDA_T1 <= 1'b0;
                SDA_T2 <= 1'b1; // sda driven by SDA_O2 is now low
                ST_SDA_STATE <= ST_SDA_12;
            end
            else if (sda2 == 1'b0)
            begin
                SDA_T1 <= 1'b1; // sda driven by SDA_O1 is now low 
                SDA_T2 <= 1'b0;
                ST_SDA_STATE <= ST_SDA_21;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_IDLE;
            end
        end
        
        ST_SDA_12:  // wait for SDA_I1 to go high
        begin
            if (sda1 == 1'b1)
            begin
                SDA_T1 <= 1'b0;
                SDA_T2 <= 1'b0;
                ST_SDA_STATE <= ST_SDA_DELAY;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_12;
            end
        end

        ST_SDA_21:  // wait for SDA_I2 to go high
        begin
            if (sda2 == 1'b1)
            begin
                SDA_T1 <= 1'b0;
                SDA_T2 <= 1'b0;
                ST_SDA_STATE <= ST_SDA_DELAY;
            end
            else
            begin
                ST_SDA_STATE <= ST_SDA_21;
            end
        end
		
		// 10k pull-up 1.8v rising time 400ns, 3.3V rising time 800ns, base on 64M clk, Tclk=16ns, 800/16=50
        ST_SDA_DELAY:
        begin
            if(sda_delay_cnt<50)
            begin
                sda_delay_cnt <= sda_delay_cnt + 1'b1;
                ST_SDA_STATE <= ST_SDA_DELAY;
            end
            else
            begin
				sda_delay_cnt <= 11'b0;
                ST_SDA_STATE <= ST_SDA_IDLE;
            end
        end

        default:
        begin
            SDA_T1 <= 1'b0;
            SDA_T2 <= 1'b0;
			sda_delay_cnt <= 11'b0;
            ST_SDA_STATE    <= ST_SDA_IDLE;
        end
        endcase
    end
end


reg SCL_T1;
reg SCL_T2;

reg [10:0]   scl_delay_cnt;
reg [2:0]    ST_SCL_STATE;
parameter    ST_SCL_IDLE =3'b001;
parameter    ST_SCL_12   =3'b010;
parameter    ST_SCL_21   =3'b100;
parameter    ST_SCL_DELAY   =3'b000;

assign scl1 = (SCL_T1)? 1'b0:1'bz;
assign scl2 = (SCL_T2)? 1'b0:1'bz;


always @(posedge clk or negedge reset_n)
begin
    if (reset_n == 1'b0) 
    begin
        SCL_T1 <= 1'b0;
        SCL_T2 <= 1'b0;
        ST_SCL_STATE <= ST_SCL_IDLE;
        scl_delay_cnt <= 11'b0;
    end
    else
    begin
        case(ST_SCL_STATE)
        ST_SCL_IDLE: // wait for SCL_I1 or SCL_I2 to be pulled low
        begin
            SCL_T1 <= 1'b0; // both OBUFT in high-impedance state
            SCL_T2 <= 1'b0;
            if (scl1 == 1'b0)
            begin
                SCL_T1 <= 1'b0;
                SCL_T2 <= 1'b1; // scl driven by SCL_O2 is now low
                ST_SCL_STATE <= ST_SCL_12;
            end
            else if (scl2 == 1'b0)
            begin
                SCL_T1 <= 1'b1; // scl driven by SCL_O1 is now low 
                SCL_T2 <= 1'b0;
                ST_SCL_STATE <= ST_SCL_21;
            end
            else
            begin
                ST_SCL_STATE <= ST_SCL_IDLE;
            end
        end
        
        ST_SCL_12:  // wait for SCL_I1 to go high
        begin
            if (scl1 == 1'b1)
            begin
                SCL_T1 <= 1'b0; // both OBUFT in high-impedance state
                SCL_T2 <= 1'b0;
                ST_SCL_STATE <= ST_SCL_DELAY;
            end
            else
            begin
                ST_SCL_STATE <= ST_SCL_12;
            end
        end

        ST_SCL_21:  // wait for SCL_I2 to go high
        begin
            if (scl2 == 1'b1)
            begin
                SCL_T1 <= 1'b0; // both OBUFT in high-impedance state
                SCL_T2 <= 1'b0;
                ST_SCL_STATE <= ST_SCL_DELAY;
            end
            else
            begin
                ST_SCL_STATE <= ST_SCL_21;
            end
        end
		
		// 10k pull-up 1.8v rising time 400ns, 3.3V rising time 800ns, base on 64M clk, Tclk=16ns, 800/16=50
        ST_SCL_DELAY:
        begin
            if(scl_delay_cnt<50)
            begin
                scl_delay_cnt <= scl_delay_cnt + 1'b1;
                ST_SCL_STATE <= ST_SCL_DELAY;
            end
            else
            begin
				scl_delay_cnt <= 11'b0;
                ST_SCL_STATE <= ST_SCL_IDLE;
            end
        end

        default:
        begin
            SCL_T1 <= 1'b0; // both OBUFT in high-impedance state
            SCL_T2 <= 1'b0;
			scl_delay_cnt <= 11'b0;
            ST_SCL_STATE    <= ST_SCL_IDLE;
        end
        endcase
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
