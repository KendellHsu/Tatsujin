module shift_load (
	input            clk,
	input            rst,  
	input      [1:0] song,      // song selection
	input            delete,
	output reg [9:0] note_R,
	//output reg [9:0] note_G,
	output reg [9:0] note_B,
	output reg [2:0] offset,    // pixel counter
	output  		 note_R_judge,
	output           note_B_judge,
	output reg       finish 	// the idication of song end
);

	localparam Rick_Roll = 40'b0000000110011000100110000010100110000110;
	localparam yare_yare = 40'd0;
	localparam madeo     = 40'd0;
	localparam Rick_Roll_length = 10'd40;
	localparam yare_yare_length = 10'd40;
	localparam madeo_length     = 10'd40;
	localparam speed            = 17'49999;
	integer i;

	localparam IDLE = 3'd0, NOTE_GET = 3'd1, OFFSET = 3'd2, FINISH = 3'd3;

	reg [9:0]   index;           // offset counter
	reg [1:0]   CS, NS;  
	reg [100:0] song_bits ;      // storage the selection song bits
	reg [9:0]  song_length;
	reg [16:0]   cnt_time;        // time counter
	reg [19:0]  note_range;      


	always @(posedge clk or posedge rst) begin
		if(rst) CS <= IDLE;
		else    CS <= NS;
	end

	always @(*) begin
		if(rst) begin 
			song_bits = 101'd0;
			song_length = 10'd0;
		end
		
		case(song)

		2'd1: begin
			song_bits[100 -: Rick_Roll_length] = Rick_Roll;
			song_length = Rick_Roll_length;
		end

		2'd2: begin
			song_bits[100 -: yare_yare_length] = yare_yare;
		 	song_length = yare_yare_length;
		 end

	 	 2'd3: begin
		 	song_bits[100 -: madeo_length] = madeo;
		 	song_length = madeo_length;
		 end

		endcase

	end

	always @(*) begin
		case(CS)

		IDLE:	  NS = (song != 2'd0) 		  ? NOTE_GET : IDLE;

		NOTE_GET: NS = (cnt_time == speed)	  ? OFFSET   : NOTE_GET;

		OFFSET:   NS = (index == song_length >> 1) ? FINISH   : NOTE_GET;

		FINISH:   NS = IDLE;

		default:  NS = IDLE;

		endcase
	end


// cnt_time
	always @(posedge clk or posedge rst) begin
		if(rst) cnt_time <= 17'd0; 
		else if(CS == NOTE_GET)       cnt_time <= cnt_time + 17'd1;
		else if(cnt_time > speed)     cnt_time <= 17'd0;
		else                          cnt_time <= cnt_time;
	end

// offset & index
	always @(posedge clk or posedge rst) begin
		if(rst) begin 
			offset <= 3'd0;
			index  <= 10'd0;
		end
		else if(NS == OFFSET && offset == 3'd6) begin
			offset <= 3'd0;
			index <= index + 10'd1;
		end

		else if(NS == OFFSET) begin
			offset <= offset + 3'd1;
		end

		else begin
			offset <= offset;
			index <= index;
		end
	end

// note range
	always @(posedge clk or posedge rst posedge delete) begin
		if(rst) 				note_range <= 20'd0;
		else if(delete)         note_range <= {note_range[19:18],2'd0,note_range[15:0]};
		else if(NS == NOTE_GET) note_range = {note_range[17:0], song_bits[100-2*index-:2]};
		else 					note_range = note_range;
		
	end

	always @(*) begin
		if(rst) begin
			note_R = 10'd0;
		  //note_G = 10'd0;
			note_B = 10'd0;
		end  
		else begin
			
				
			for ( i=0 ; i<10;i=i+1 ) begin
				if(note_range[19-i*2-:2] == 2'd1) begin
					note_R[i] = 1'd1;
					//note_G[i] = 1'd0;
					note_B[i] = 1'd0;
				end	
				else if(note_range[19-i*2-:2] == 2'd2) begin
					note_R[i] = 1'd0;
					//note_G[i] = 1'd1;
					note_B[i] = 1'd1;
				end	 
				else if(note_range[19-i*2-:2] == 2'd0)begin
						note_R[i] = 1'd0;
						//note_G[i] = 1'd1;
						note_B[i] = 1'd0;
				end					
			end
		end
	end

	assign note_R_judge = note_R[1];
	assign note_B_judge = note_B[1];

//finish
	always @(posedge clk or posedge rst) begin
		if(rst) 			  finish <= 1'd0;
		else if(NS == FINISH) finish <= 1'd1;
		else                  finish <= 1'd0;
	end

endmodule