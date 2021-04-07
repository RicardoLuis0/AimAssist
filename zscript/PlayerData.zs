class AimAssistPlayerData {
	bool enabled;//if assist is enabled or not

	double max_angle;//max assist angle
	double precision;//assist angle precision
	double radial_precision;//assist radial precision
	double max_distance;//max assist precision
	double rot_speed;//assist intensity

	int method;//assist method

	bool check_obstacles;//if to check for obstacles before rotating

	int key1;//toggle hold key 1
	int key2;//toggle hold key 2

	bool hold1;//if key 1 is being held
	bool hold2;//if key 2 is being held

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
	
	void UpdateCVARs(int pnum){
		PlayerInfo player=players[pnum];
		enabled=CVAR.GetCVar("AIM_ASSIST_ENABLED",player).getBool();
		max_angle=CVAR.GetCVar("AIM_ASSIST_ANGLE_MAX",player).getFloat();
		precision=CVAR.GetCVar("AIM_ASSIST_PRECISION",player).getFloat();
		radial_precision=CVAR.GetCVar("AIM_ASSIST_RADIAL_PRECISION",player).getFloat();
		max_distance=CVAR.GetCVar("AIM_ASSIST_MAX_DIST",player).getFloat();
		rot_speed=CVAR.GetCVar("AIM_ASSIST_ROT_SPEED",player).getFloat();
		method=CVAR.GetCVar("AIM_ASSIST_METHOD",player).getInt();
		check_obstacles=CVAR.GetCVar("AIM_ASSIST_CHECK_FOR_OBSTACLES",player).getBool();
		int key1_old=key1;
		int key2_old=key2;
		int hold1_old=hold1;
		int hold2_old=hold2;
		key1=CVAR.GetCVar("AIM_ASSIST_HOLD_KEY_1",player).getInt();
		key2=CVAR.GetCVar("AIM_ASSIST_HOLD_KEY_2",player).getInt();
		if(key1!=key1_old)hold1=(key1==key2_old?hold2_old:false);
		if(key2!=key2_old)hold2=(key2==key1_old?hold1_old:false);
		enemy_heightadd=CVAR.GetCVar("AIM_ASSIST_VERTICAL_PLUS_OFFSET_ENEMY",player).getFloat();
		enemy_heightsub=CVAR.GetCVar("AIM_ASSIST_VERTICAL_MINUS_OFFSET_ENEMY",player).getFloat();
		enemy_heightmult=CVAR.GetCVar("AIM_ASSIST_ENEMY_HEIGHT_MULT",player).getFloat();
		player_heightadd=CVAR.GetCVar("AIM_ASSIST_VERTICAL_PLUS_OFFSET_PLAYER",player).getFloat();
		player_heightsub=CVAR.GetCVar("AIM_ASSIST_VERTICAL_MINUS_OFFSET_PLAYER",player).getFloat();
		player_heightmult=CVAR.GetCVar("AIM_ASSIST_PLAYER_HEIGHT_MULT",player).getFloat();
		aim_height_mode=CVAR.GetCVar("AIM_ASSIST_HEIGHT_MODE",player).getInt();
		transition_start=CVAR.GetCVar("AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_START",player).getFloat();
		transition_end=CVAR.GetCVar("AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_END",player).getFloat();
		on_obstruction=CVAR.GetCVar("AIM_ASSIST_ON_OBSTRUCTION",player).getInt();
		mIsEnabled=CVAR.GetCVar("rc_enabled",player).getBool();
		mStep=CVAR.GetCVar("rc_step",player).getFloat();
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
				if(t.hitActor.bISMONSTER&&!t.hitActor.bFRIENDLY){//if hit is a monster and not friendly
					if(!closest||a.Distance3D(t.HitActor)>closest_distance){//if it's closer than last hit
						//change this as new closest
						closest=t.HitActor;
						closest_distance=a.Distance3D(t.HitActor);
						hitloc=t.HitLocation;
					}
				}
			}
		}
		return closest,closest_distance,hitloc;
	}
	
	bool aimEnabled(){
		return (enabled&&!(hold1||hold2))||(!enabled&&(hold1||hold2));
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