class AimAssistPlayerData {
	CVar /*bool*/ enabled;//if assist is enabled or not

	CVar /*double*/ max_angle;//max assist angle
	CVar /*double*/ precision;//assist angle precision
	CVar /*double*/ radial_precision;//assist radial precision
	CVar /*double*/ max_distance;//max assist precision
	CVar /*double*/ rot_speed;//assist intensity

	CVar /*int*/ method;//assist method

	CVar /*bool*/ check_obstacles;//if to check for obstacles before rotating

	int hold;
	
	CVar /*double*/ enemy_heightadd;
	CVar /*double*/ enemy_heightsub;
	CVar /*double*/ enemy_heightmult;

	CVar /*double*/ player_heightadd;
	CVar /*double*/ player_heightsub;
	CVar /*double*/ player_heightmult;

	CVar /*double*/ transition_start;
	CVar /*double*/ transition_end;

	CVar /*int*/ aim_height_mode;

	CVar /*int*/ on_obstruction;
	CVar /*bool*/ mIsEnabled;
	CVar /*double*/ mStep;
	
	CVar /*bool*/ always_recenter;
	
	CVar /*int*/ enable_mode;
	
	CVar /*bool*/ debug_traces;
	
	void UpdateCVARs(int pnum){
		PlayerInfo player=players[pnum];
		enabled=CVAR.GetCVar("cl_aim_assist_enabled",player);
		max_angle=CVAR.GetCVar("cl_aim_assist_angle_max",player);
		precision=CVAR.GetCVar("cl_aim_assist_precision",player);
		radial_precision=CVAR.GetCVar("cl_aim_assist_radial_precision",player);
		max_distance=CVAR.GetCVar("cl_aim_assist_max_dist",player);
		rot_speed=CVAR.GetCVar("cl_aim_assist_rot_speed",player);
		method=CVAR.GetCVar("cl_aim_assist_method",player);
		check_obstacles=CVAR.GetCVar("cl_aim_assist_check_for_obstacles",player);
		enemy_heightadd=CVAR.GetCVar("cl_aim_assist_vertical_plus_offset_enemy",player);
		enemy_heightsub=CVAR.GetCVar("cl_aim_assist_vertical_minus_offset_enemy",player);
		enemy_heightmult=CVAR.GetCVar("cl_aim_assist_enemy_height_mult",player);
		player_heightadd=CVAR.GetCVar("cl_aim_assist_vertical_plus_offset_player",player);
		player_heightsub=CVAR.GetCVar("cl_aim_assist_vertical_minus_offset_player",player);
		player_heightmult=CVAR.GetCVar("cl_aim_assist_player_height_mult",player);
		transition_start=CVAR.GetCVar("cl_aim_assist_height_mode_transition_distance_start",player);
		transition_end=CVAR.GetCVar("cl_aim_assist_height_mode_transition_distance_end",player);
		aim_height_mode=CVAR.GetCVar("cl_aim_assist_height_mode",player);
		on_obstruction=CVAR.GetCVar("cl_aim_assist_on_obstruction",player);
		mIsEnabled=CVAR.GetCVar("cl_recenter_enabled",player);
		mStep=CVAR.GetCVar("cl_recenter_step",player);
		always_recenter=CVAR.GetCVar("cl_recenter_always_enabled",player);
		enable_mode=CVAR.GetCVar("cl_aim_assist_enable_mode",player);
		debug_traces=CVAR.GetCVar("cl_aim_assist_trace_debug",player);
	}
	
	float lerp(float v0,float v1,float t){
		return v0 + t * (v1 - v0);
	}
	
	float getAimRatio(float distance){
		if(distance>=transition_start.getFloat()){
			return 1;
		}else if(distance<transition_end.getFloat()){
			return 0;
		}else{
			return (distance-transition_end.getFloat())/(transition_start.getFloat()-transition_end.getFloat());
		}
	}
	
	float calculatePHeight(float pheight){
		return player_heightadd.getFloat() + (pheight * player_heightmult.getFloat()) - player_heightsub.getFloat();
	}
	
	float calculateEHeight(float eheight){
		return enemy_heightadd.getFloat() + (eheight * enemy_heightmult.getFloat()) - enemy_heightsub.getFloat();
	}
	
	float getAimHeight(float enemyheight,float playerheight,float distance){
		switch(aim_height_mode.getInt()){
			default:
			case 0://aim at enemy
				return calculateEHeight(enemyheight);
			case 1://aim at player view
				return calculatePHeight(playerheight);
			case 2://mix based on distance
				return lerp(calculatePHeight(playerheight),calculateEHeight(enemyheight),getAimRatio(distance));
		}
	}
	//do linetrace and get results
	play Actor,double,Vector3 doTrace(PlayerPawn a,double i_angle,double i_rotation,Actor closest,double closest_distance){
		FLineTraceData t;
		Vector3 hitloc=(0,0,0);
		//do a linetrace around i_a and i_r in a circle
		if(a.LineTrace(a.angle+(sin(i_rotation)*i_angle),			//trace angle
							max_distance.getFloat(),				//trace max distance
							a.pitch+(cos(i_rotation)*i_angle),		//trace pitch
							TRF_NOSKY,								//trace flags
							a.viewheight*a.player.crouchfactor,		//trace height
							data:t									//output struct
		)){
			if(t.hitType==TRACE_HitActor){//if hit is an actor
				
				if(t.hitActor.bISMONSTER&&!t.hitActor.bFRIENDLY&&!t.hitActor.bCORPSE){//if hit is a monster and not friendly
					if(!closest||a.Distance3D(t.HitActor)>closest_distance){//if it's closer than last hit
						//change this as new closest
						closest=t.HitActor;
						closest_distance=a.Distance3D(t.HitActor);
						hitloc=t.HitLocation;
					}
					if(debug_traces.getBool()){
						let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
						a.A_SpawnParticle("#FF0000",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
					}
				} else if (debug_traces.getBool()) {
					let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
					a.A_SpawnParticle("#FFFF00",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
				}
			} else if (debug_traces.getBool()) {
				
				let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
				a.A_SpawnParticle("#00FF00",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
			}
		}
		return closest,closest_distance,hitloc;
	}
	
	bool aimEnabled(PlayerInfo player){
		bool base = (enabled.getBool() == !hold);
		
		switch(enable_mode.getInt()){
		default:
		case 0://always
			return base;
		case 1:// look or move
			return base && ((abs(player.cmd.yaw) + abs(player.cmd.pitch) + abs(player.cmd.roll) + abs(player.cmd.forwardmove) + abs(player.cmd.sidemove) + abs(player.cmd.upmove)) > 0);
		case 2:// look
			return base && ((abs(player.cmd.yaw) + abs(player.cmd.pitch) + abs(player.cmd.roll)) > 0);
		}
	}
	
	/* Copyright Alexander Kromm (mmaulwurff@gmail.com) 2020-2021 */
	static double makeNewPitch(double pitch, double step){
		if(abs(pitch) <= step){
			return 0;
		} else if (pitch > 0){
			return pitch - step;
		} else {
			return pitch + step;
		}
	}
	
	play void doRecenter(PlayerPawn pawn){
		if(!mIsEnabled.getBool())return;
		pawn.A_SetPitch(makeNewPitch(pawn.pitch, mStep.getFloat()), SPF_Interpolate);
	}
	
}