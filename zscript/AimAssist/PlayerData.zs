class AimAssistPlayerData {
	bool enabled;//if assist is enabled or not

	double max_angle;//max assist angle
	double precision;//assist angle precision
	double radial_precision;//assist radial precision
	double max_distance;//max assist precision
	double rot_speed;//assist intensity

	int method;//assist method

	bool check_obstacles;//if to check for obstacles before rotating

	int hold;
	
	float enemy_heightadd;
	float enemy_heightsub;
	float enemy_heightmult;

	float player_heightadd;
	float player_heightsub;
	float player_heightmult;

	float transition_start;
	float transition_end;

	int aim_height_mode;

	int on_obstruction;
	bool mIsEnabled;
	double mStep;
	
	bool always_recenter;
	
	bool debug_traces;
	
	void UpdateCVARs(int pnum){
		PlayerInfo player=players[pnum];
		enabled=CVAR.GetCVar("cl_aim_assist_enabled",player).getBool();
		max_angle=CVAR.GetCVar("cl_aim_assist_angle_max",player).getFloat();
		precision=CVAR.GetCVar("cl_aim_assist_precision",player).getFloat();
		radial_precision=CVAR.GetCVar("cl_aim_assist_radial_precision",player).getFloat();
		max_distance=CVAR.GetCVar("cl_aim_assist_max_dist",player).getFloat();
		rot_speed=CVAR.GetCVar("cl_aim_assist_rot_speed",player).getFloat();
		method=CVAR.GetCVar("cl_aim_assist_method",player).getInt();
		check_obstacles=CVAR.GetCVar("cl_aim_assist_check_for_obstacles",player).getBool();
		enemy_heightadd=CVAR.GetCVar("cl_aim_assist_vertical_plus_offset_enemy",player).getFloat();
		enemy_heightsub=CVAR.GetCVar("cl_aim_assist_vertical_minus_offset_enemy",player).getFloat();
		enemy_heightmult=CVAR.GetCVar("cl_aim_assist_enemy_height_mult",player).getFloat();
		player_heightadd=CVAR.GetCVar("cl_aim_assist_vertical_plus_offset_player",player).getFloat();
		player_heightsub=CVAR.GetCVar("cl_aim_assist_vertical_minus_offset_player",player).getFloat();
		player_heightmult=CVAR.GetCVar("cl_aim_assist_player_height_mult",player).getFloat();
		aim_height_mode=CVAR.GetCVar("cl_aim_assist_height_mode",player).getInt();
		transition_start=CVAR.GetCVar("cl_aim_assist_height_mode_transition_distance_start",player).getFloat();
		transition_end=CVAR.GetCVar("cl_aim_assist_height_mode_transition_distance_end",player).getFloat();
		on_obstruction=CVAR.GetCVar("cl_aim_assist_on_obstruction",player).getInt();
		debug_traces=CVAR.GetCVar("cl_aim_assist_trace_debug",player).getBool();
		mIsEnabled=CVAR.GetCVar("cl_recenter_enabled",player).getBool();
		mStep=CVAR.GetCVar("cl_recenter_step",player).getFloat();
		always_recenter=CVAR.GetCVar("cl_recenter_always_enabled",player).getBool();
	}
	
	float lerp(float v0,float v1,float t){
		return v0 + t * (v1 - v0);
	}
	
	float getAimRatio(float distance){
		if(distance>=transition_start){
			return 1;
		}else if(distance<transition_end){
			return 0;
		}else{
			return (distance-transition_end)/(transition_start-transition_end);
		}
	}
	
	float calculatePHeight(float pheight){
		return player_heightadd + (pheight * player_heightmult) - player_heightsub;
	}
	
	float calculateEHeight(float eheight){
		return enemy_heightadd + (eheight * enemy_heightmult) - enemy_heightsub;
	}
	
	float getAimHeight(float enemyheight,float playerheight,float distance){
		switch(aim_height_mode){
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
							max_distance,							//trace max distance
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
					if(debug_traces){
						let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
						a.A_SpawnParticle("#FF0000",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
					}
				} else if (debug_traces) {
					let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
					a.A_SpawnParticle("#FFFF00",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
				}
			} else if (debug_traces) {
				
				let hitDist = level.Vec3Diff(a.pos,t.hitLocation).length();
				a.A_SpawnParticle("#00FF00",SPF_FULLBRIGHT,1,clamp(hitDist/100,2.5,75),xoff:t.hitLocation.x - a.pos.x,t.hitLocation.y - a.pos.y,t.hitLocation.z - a.pos.z);
			}
		}
		return closest,closest_distance,hitloc;
	}
	
	bool aimEnabled(){
		return enabled == !hold;
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
		if(!mIsEnabled)return;
		pawn.A_SetPitch(makeNewPitch(pawn.pitch, mStep), SPF_Interpolate);
	}
	
}