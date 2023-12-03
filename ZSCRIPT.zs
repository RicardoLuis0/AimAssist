version "4.10.0"


class AimAssistPlayerData
{
// --------------------------- HARDCODED SETTINGS ---------------------------


	// radius steps to check
	const /*double*/ precision = 0.5;
	// angle increments to check
	const /*double*/ radial_precision = 30;

	// Aim Assist Method
	// 0 = Closest to Player
	// 1 = Closest to Crosshair
	const /*int*/ method = 1;

	// Check for obstacles between player and enemy
	const /*bool*/ check_obstacles = 1 /*true*/;
	
	// if there's an obstacle between the player and an enemy
	// 0 = Don't Aim
	// 1 = Aim Correction
	// 2 = Target Closest
	const /*int*/ on_obstruction = 1;
	
	// What to multiply the enemy height by to calculate aim height
	const /*double*/ enemy_heightmult = 1.0;
	// How many units to subtract from the enemy height to calculate aim height
	const /*double*/ enemy_heightoffset = -12.0;

	// What to multiply the player height by to calculate aim height
	const /*double*/ player_heightmult = 1.0;
	// How many units to subtract from the player height to calculate aim height
	const /*double*/ player_heightoffset = 0.0;

	// What to base the aim height on
	// 0 = Relative to Enemy Height
	// 1 = Relative to Player View Height
	// 2 = Relative to Both
	const /*int*/ aim_height_mode = 2;
	
	//Distance to start transition between monster and player view heights, used if aim height mode is 'both'
	const /*double*/ transition_start = 500;
	//Distance to end transition between monster and player view heights, used if aim height mode is 'both'
	const /*double*/ transition_end = 100;

// --------------------------- HARDCODED SETTINGS ---------------------------


// --------------------------- CVAR SETTINGS ---------------------------

	// if assist is enabled or not
	const enabled_cvar_name = "cl_aim_assist_enabled";
	CVar /*bool*/ enabled;
	
	// enable mode for aim assist
	// 0 = always
	// 1 = if the player's looking or moving
	// 2 = if the player's looking
	
	const enabled_mode_cvar_name = "cl_aim_assist_enable_mode";
	CVar /*int*/ enable_mode;

	//max assist angle
	const max_angle_cvar_name = "cl_aim_assist_angle_max";
	CVar /*double*/ max_angle;
	
	//max assist distance
	const max_distance_cvar_name = "cl_aim_assist_max_dist";
	CVar /*double*/ max_distance;
	
	//assist intensity
	const intensity_cvar_name = "cl_aim_assist_rot_speed";
	CVar /*double*/ intensity;
	
// --------------------------- CVAR SETTINGS ---------------------------













	int hold;
	
	void UpdateCVARs(int pnum)
	{
		PlayerInfo player = players[pnum];
		enabled = CVAR.GetCVar(enabled_cvar_name, player);
		enable_mode = CVAR.GetCVar(enabled_mode_cvar_name, player);
		max_angle = CVAR.GetCVar(max_angle_cvar_name, player);
		max_distance = CVAR.GetCVar(max_distance_cvar_name, player);
		intensity = CVAR.GetCVar(intensity_cvar_name, player);
	}
	
	float lerp(float v0, float v1, float t)
	{
		return v0 + t * (v1 - v0);
	}
	
	float getAimRatio(float distance)
	{
		if(distance >= transition_start)
		{
			return 1;
		}
		else if(distance < transition_end)
		{
			return 0;
		}
		else
		{
			return (distance - transition_end) / (transition_start - transition_end);
		}
	}
	
	float calculatePHeight(float pheight)
	{
		return player_heightoffset + (pheight * player_heightmult);
	}
	
	float calculateEHeight(float eheight)
	{
		return enemy_heightoffset + (eheight * enemy_heightmult);
	}
	
	float getAimHeight(float enemyheight, float playerheight, float distance)
	{
		if(aim_height_mode == 1)
		{
			return calculatePHeight(playerheight);
		}
		else if(aim_height_mode == 2)
		{
			return lerp(calculatePHeight(playerheight), calculateEHeight(enemyheight), getAimRatio(distance));
		}
		else
		{
			return calculateEHeight(enemyheight);
		}
	}
	
	
	play Actor,double,Vector3 doTrace(PlayerPawn a, double i_angle, double i_rotation, Actor closest, double closest_distance)
	{ 	//do linetrace and get results
		FLineTraceData t;
		Vector3 hitloc;
		//do a linetrace around i_a and i_r in a circle
		if(a.LineTrace(
			a.angle + (sin(i_rotation) * i_angle),	//trace angle
			max_distance.getFloat(),				//trace max distance
			a.pitch + (cos(i_rotation) * i_angle),	//trace pitch
			TRF_NOSKY,								//trace flags
			a.viewheight * a.player.crouchfactor,	//trace height
			data:t									//output struct
		)){
			if(t.hitType==TRACE_HitActor)
			{	//if hit is an actor
				if(t.hitActor.bISMONSTER&&!t.hitActor.bFRIENDLY&&!t.hitActor.bCORPSE)
				{	//if hit is a monster and not friendly
					if(!closest || a.Distance3D(t.HitActor) > closest_distance)
					{ 	//if it's closer than last hit
						//choose this as new closest
						closest = t.HitActor;
						closest_distance = a.Distance3D(t.HitActor);
						hitloc = t.HitLocation;
					}
				}
			}
		}
		return closest,closest_distance,hitloc;
	}
	
	bool aimEnabled(PlayerInfo player)
	{
		switch(enable_mode.getInt())
		{
		default:
		case 0://always
			return enabled.getBool() == !hold;
		case 1:// look or move
			return (enabled.getBool() == !hold) && ((abs(player.cmd.yaw) + abs(player.cmd.pitch) + abs(player.cmd.roll) + abs(player.cmd.forwardmove) + abs(player.cmd.sidemove) + abs(player.cmd.upmove)) > 0);
		case 2:// look
			return (enabled.getBool() == !hold) && ((abs(player.cmd.yaw) + abs(player.cmd.pitch) + abs(player.cmd.roll)) > 0);
		}
	}
	
}


class AimAssistHandler : StaticEventHandler
{
	AimAssistPlayerData playerData[MAXPLAYERS];
	
	override void OnRegister()
	{
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			playerData[i] = new("AimAssistPlayerData");
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		for(int i=0;i<MAXPLAYERS;i++)
		{
			if(playeringame[i])
			{
				UpdateCVARs(i);
			}
		}
	}
	
	override void PlayerEntered(PlayerEvent e)
	{
		UpdateCVARs(e.playernumber);
	}

	//update cvar values
	void UpdateCVARs(int pnum)
	{
		playerData[pnum].UpdateCVARs(pnum);
	}

	void UpdateAllCVARs()
	{
		for(int i=0;i<MAXPLAYERS;i++)
		{
			if(playeringame[i])
			{
				UpdateCVARs(i);
			}
		}
	}

	//get angle and delta from two positions
	static vector3,double,double lookAt(Vector3 pos1,Vector3 pos2)
	{
		//calculate difference between pos1 and pos2 (level.Vec3Diff takes portals into account)
		Vector3 delta = level.Vec3Diff(pos1, pos2);
		
		//calculate angle and pitch to other actor
		double target_angle = atan2(delta.y, delta.x);
		double target_pitch = -asin(delta.z/delta.length());

		return delta, target_angle, target_pitch;
	}

	//main method, does all work
	bool doAim(int pnum)
	{
		let pdata = playerData[pnum];
		//let pi = players[pnum];
		let pp = players[pnum].mo;
		
		if(!pdata.aimEnabled(players[pnum]))
		{
			return false;
		}
		
		double max_distance = pdata.max_distance.getFloat();
		double rot_speed = pdata.intensity.getFloat();
		
		//check straight ahead
		let [closest, closest_distance, hitloc] = pdata.doTrace(pp, 0, 0, null, max_distance + 1);
		
		double precision=pdata.precision;
		double radial_precision=pdata.radial_precision;
		double max_angle=pdata.max_angle.getFloat();
		int method=pdata.method;
		
		//check in a circle around the direction player's looking
		for(double i_a = precision; i_a <= max_angle; i_a += precision)
		{
			for(double i_r = 0; i_r <= 360 && !(closest && method == 1); i_r += radial_precision)
			{
				[closest, closest_distance, hitloc] = pdata.doTrace(pp, i_a, i_r, closest, closest_distance);
			}
		}
		//if there was an enemy found
		if(closest){
			float pheight = pp.viewheight * pp.player.crouchfactor;
			
			Vector3 aimheight = (0, 0, pdata.getAimHeight(closest.height, pheight, closest_distance));
			
			Vector3 view = pp.pos + (0, 0, pheight);
			//get target angle and pitch
			let [delta, target_angle, target_pitch] = lookAt(view, closest.pos + aimheight);
			
			//check if view is obstructed
			if(pdata.check_obstacles)
			{
				FLineTraceData t;
				
				pp.LineTrace(
					target_angle,
					max_distance,
					target_pitch,
					TRF_NOSKY,
					pp.viewheight * pp.player.crouchfactor,
					data:t
				);
				
				if(t.hitType != TRACE_HitActor || t.hitActor != closest)
				{
					if(pdata.on_obstruction == 1)
					{	//aim correction
						//try to aim at correct z
						[delta, target_angle, target_pitch] = lookAt(view, (hitloc.x, hitloc.y, closest.pos.z + aimheight.z));
						
						pp.LineTrace(
							target_angle,
							max_distance,
							target_pitch,
							TRF_NOSKY,
							pp.viewheight * pp.player.crouchfactor,
							data:t
						);
						if(t.hitType != TRACE_HitActor || t.hitActor != closest)
						{	//try to aim at correct xy
							[delta, target_angle, target_pitch] = lookAt(view, (closest.pos.x, closest.pos.y, hitloc.z));
							pp.LineTrace(
								target_angle,
								max_distance,
								target_pitch,
								TRF_NOSKY,
								pp.viewheight * pp.player.crouchfactor,
								data:t
							);
							if(t.hitType != TRACE_HitActor || t.hitActor != closest)
							{
								[delta, target_angle, target_pitch] = lookAt(view, hitloc);
							}
						}
					}
					else if(pdata.on_obstruction == 2)
					{	// target closest
						[delta, target_angle, target_pitch] = lookAt(view, hitloc);
					}
					else
					{
						return false;
					}
				}
			}

			//get angle difference
			double angle_diff = Actor.DeltaAngle(pp.angle, target_angle);
			double pitch_diff = Actor.DeltaAngle(pp.pitch, target_pitch);
			
			//check rotation speed
			if(abs(angle_diff) > rot_speed)
			{	//if rotation speed is lower than difference, add/subtract rotation speed
				pp.A_SetAngle(pp.angle+(angle_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}
			else
			{	//if rotation speed is higher than differece, set to target angle
				pp.A_SetAngle(target_angle, SPF_INTERPOLATE);
			}
			
			if(abs(pitch_diff) > rot_speed)
			{	//if rotation speed is lower than difference, add/subtract rotation speed
				pp.A_SetPitch(pp.pitch + (pitch_diff > 0 ? rot_speed : -rot_speed), SPF_INTERPOLATE);
			}
			else
			{	//if rotation speed is higher than differece, set to target pitch
				pp.A_SetPitch(target_pitch,SPF_INTERPOLATE);
			}
			return true;
		}else{
			return false;
		}
	}

	override void WorldTick(){
		//if no keys are held and it's enabled, or keys are held and it's disabled, run the aim assist
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			if(playeringame[i])
			{
				doAim(i);
			}
		}
	}
	
	override void InterfaceProcess(ConsoleEvent e)
	{
		if(e.name == "AimAssistToggle")
		{	//toggle key pressed
			if(e.player == consoleplayer)
			{
				playerData[e.player].enabled.setBool(!playerData[e.player].enabled.getBool());
				console.printf("Aim Assist "..(playerData[e.player].enabled?"On":"Off"));
			}
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if(e.name == "AimAssistToggleHoldDown")
		{	//key held
			playerData[e.player].hold++;
		}
		else if(e.name == "AimAssistToggleHoldUp")
		{	//key released
			playerData[e.player].hold--;
		}
	}
}
