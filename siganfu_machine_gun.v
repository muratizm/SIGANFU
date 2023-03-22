`timescale 1ms / 100ns

module siganfu_machine_gun (
	input sysclk,
	input reboot,
	input target_locked,
	input is_enemy,
	input fire_command,
	input firing_mode, 
	input overheat_sensor,
	output reg[2:0] current_state,
	output reg criticality_alert,
	output reg fire_trigger
);
    
    integer bullet_counter = 25;
    integer  magazine_counter = 3;
    reg control_single;
    
    
	always @(posedge sysclk or posedge reboot) begin

	   if (reboot) begin 

	       // If reboot occurs (current_state, criticality_alert, fire_trigger) it is reset to its initial values and the program is reset.
	       assign current_state = 3'b000;
	       assign criticality_alert = 0;
	       assign fire_trigger = 0;
	       
	       control_single = 0;
	   end

	   else begin

	       if(target_locked && is_enemy && fire_command) begin

		   // If all the required inputs reach the desired values, the shot mode is started. 
	           if (overheat_sensor) begin
		       // When the machine gun overheats from shooting, it has to be cooled down,  process takes 100 ms.  
	               assign current_state = 3'b100;
	               assign fire_trigger = 0;
		       #100;
                       assign current_state = 3'b000;
	           end

	           else begin
			// if the program is not switched to overheat mode 
			// checks the number of bullets. if there are no bullets left, it goes to the reload stage. 
	               if (bullet_counter > 0) begin

	                   if (firing_mode) begin
				// While in this state, the machine gun is in the automatic firing mode.
	                       assign fire_trigger = 1;
	                       assign current_state = 3'b010;
	                       bullet_counter = bullet_counter - 1;
	                       #5;
	                       assign fire_trigger = 0;
	                   end

	                   else begin
                           if (!control_single) begin
                               assign fire_trigger = 1;
                               assign current_state = 3'b001;
                               bullet_counter = bullet_counter - 1;
                               #5;
                               assign fire_trigger = 0;
                               #5;
                               control_single = 1;
                           end

	                   end

	               end

	               else begin
			    // If there is no lead left in the magazine we have 
	                   assign fire_trigger = 0;
	                   control_single = 0;

	                   if (magazine_counter > 1)begin
				// If we still have a spare magazines, it enters this state in which it loads a new magazine. Reloading takes 50 ms.
	                       bullet_counter = 25;
	                       magazine_counter = magazine_counter - 1;
	                       assign current_state = 3'b011;
	                       #50;
	                   end

	                   else if (magazine_counter == 1) begin
				// If we have the last spare clip left, we'll take it now and we won't have any spare clips
				// So the criticality_alert will be high and the reload will be done. Reloading takes 50 ms.
	                       bullet_counter = 25;
	                       magazine_counter = magazine_counter- 1;
	                       assign current_state = 3'b011;
	                       #50;
	                       assign criticality_alert = 1;
	                   end

	                   else begin
				// When all of the magazines and ammo have been exhausted, the machine gun goes into downfall state.
	                       assign current_state = 3'b101;
	                   end

	               end
	           end
	       end

	       else if (control_single && !fire_command) begin
	       		// In this state, the machine gun is at rest. No shots are being fired.
               		assign current_state = 3'b000;
               		control_single = 0;
               end

	   end

	end
	
endmodule