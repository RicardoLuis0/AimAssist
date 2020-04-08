class AimAssistHandler:StaticEventHandler{
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

	bool mark;//if to display markers or not

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

	AimAssistDebugMaker1 marker1;//target marker
	AimAssistDebugMaker2 marker2;//current aim marker
	AimAssistDebugMaker3 marker3;//obstruction marker
	AimAssistDebugMaker4 marker4;//obstruction marker

	override void OnRegister(){
		mark=CVAR.findCVar("AIM_ASSIST_DEBUG_MARKER").getBool();
		UpdateCVARs();
	}

	override void WorldLoaded(WorldEvent e){
		marker1=null;
		marker2=null;
		marker3=null;
		marker4=null;
		UpdateCVARs();
	}

	//update cvar values
	void UpdateCVARs(){
		enabled=CVAR.findCVar("AIM_ASSIST_ENABLED").getBool();
		max_angle=CVAR.findCVar("AIM_ASSIST_ANGLE_MAX").getFloat();
		precision=CVAR.findCVar("AIM_ASSIST_PRECISION").getFloat();
		radial_precision=CVAR.findCVar("AIM_ASSIST_RADIAL_PRECISION").getFloat();
		max_distance=CVAR.findCVar("AIM_ASSIST_MAX_DIST").getFloat();
		rot_speed=CVAR.findCVar("AIM_ASSIST_ROT_SPEED").getFloat();
		method=CVAR.findCVar("AIM_ASSIST_METHOD").getInt();
		check_obstacles=CVAR.findCVar("AIM_ASSIST_CHECK_FOR_OBSTACLES").getBool();
		key1=CVAR.findCVar("AIM_ASSIST_HOLD_KEY_1").getInt();
		key2=CVAR.findCVar("AIM_ASSIST_HOLD_KEY_2").getInt();
		enemy_heightadd=CVAR.findCVar("AIM_ASSIST_VERTICAL_PLUS_OFFSET_ENEMY").getFloat();
		enemy_heightsub=CVAR.findCVar("AIM_ASSIST_VERTICAL_MINUS_OFFSET_ENEMY").getFloat();
		enemy_heightmult=CVAR.findCVar("AIM_ASSIST_ENEMY_HEIGHT_MULT").getFloat();
		player_heightadd=CVAR.findCVar("AIM_ASSIST_VERTICAL_PLUS_OFFSET_PLAYER").getFloat();
		player_heightsub=CVAR.findCVar("AIM_ASSIST_VERTICAL_MINUS_OFFSET_PLAYER").getFloat();;
		player_heightmult=CVAR.findCVar("AIM_ASSIST_PLAYER_HEIGHT_MULT").getFloat();
		aim_height_mode=CVAR.findCVar("AIM_ASSIST_HEIGHT_MODE").getInt();
		transition_start=CVAR.findCVar("AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_START").getFloat();
		transition_end=CVAR.findCVar("AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_END").getFloat();
		on_obstruction=CVAR.findCVar("AIM_ASSIST_ON_OBSTRUCTION").getInt();
		hold1=false;
		hold2=false;
		if(CVAR.findCVar("AIM_ASSIST_DEBUG_MARKER").getBool()){
			mark=true;
		}else{
			if(mark){
				ClearMarkers();
				mark=false;
			}
		}
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
	//get rid of markers in world
	void ClearMarkers(){
		if(marker1){
			marker1.destroy();
			marker1=null;
		}
		if(marker2){
			marker2.destroy();
			marker2=null;
		}
		if(marker3){
			marker3.destroy();
			marker3=null;
		}
		if(marker4){
			marker4.destroy();
			marker4=null;
		}
	}
	void ClearObstructionMarkers(){
		if(marker3){
			marker3.destroy();
			marker3=null;
		}
		if(marker4){
			marker4.destroy();
			marker4=null;
		}
	}
	//do linetrace and get results
	Actor,double,Vector3 doTrace(PlayerPawn a,double i_angle,double i_rotation,Actor closest,double closest_distance){
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

	//get angle and delta from two positions
	static vector3,double,double lookAt(Vector3 pos1,Vector3 pos2){
			//calculate difference between pos1 and pos2 (level.Vec3Diff takes portals into account)
			
			Vector3 delta=level.Vec3Diff(pos1,pos2);
			
			//calculate angle and pitch to other actor
			double target_angle=atan2(delta.y,delta.x);
			double target_pitch=-asin(delta.z/delta.length());

			return delta,target_angle,target_pitch;
	}

	//main method, does all work
	void doAim(PlayerPawn a){
		float closest_distance=max_distance+1;
		Actor closest=null,hit=null;
		Vector3 hitloc=(0,0,0);
		//check straight ahead
		[closest,closest_distance,hitloc]=doTrace(a,0,0,closest,closest_distance);
		
		//check in a circle around the direction player's looking
		for(double i_a=precision;i_a<=max_angle;i_a+=precision){
			for(double i_r=0;i_r<=360&&!(closest&&method==1);i_r+=radial_precision){
				[closest,closest_distance,hitloc]=doTrace(a,i_a,i_r,closest,closest_distance);
			}
		}
		//if there was an enemy found
		if(closest){
			float pheight=a.viewheight*a.player.crouchfactor;
			Vector3 aimheight=(0,0,getAimHeight(closest.height,pheight,closest_distance));
			Vector3 delta;
			double target_angle,target_pitch;
			Vector3 view=a.pos+(0,0,pheight);
			//get target angle and pitch
			[delta,target_angle,target_pitch]=lookAt(view,closest.pos+aimheight);

			//show/move markers
			if(mark){
				if(!marker1){
					marker1=AimAssistDebugMaker1(a.Spawn("AimAssistDebugMaker1",a.pos,NO_REPLACE));
				}
				if(!marker2){
					marker2=AimAssistDebugMaker2(a.Spawn("AimAssistDebugMaker2",a.pos,NO_REPLACE));
				}
				marker1.setOrigin(hitloc,true);
				marker2.setOrigin(closest.pos+aimheight,true);
			}
			
			//check if view is obstructed
			if(check_obstacles){
				FLineTraceData t;
				a.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,a.viewheight*a.player.crouchfactor,data:t);
				if(t.hitType!=TRACE_HitActor||t.hitActor!=closest){
					if(mark){
						if(!marker3){
							marker3=AimAssistDebugMaker3(a.Spawn("AimAssistDebugMaker3",a.pos,NO_REPLACE));
						}
						marker3.setOrigin(t.hitLocation,false);
					}else{
						ClearObstructionMarkers();
					}
					switch(on_obstruction){
					default:
					case 1://aim correction
						//try to aim at correct z
						[delta,target_angle,target_pitch]=lookAt(view,(hitloc.x,hitloc.y,closest.pos.z+aimheight.z));
						a.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,a.viewheight*a.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(a.Spawn("AimAssistDebugMaker4",a.pos,NO_REPLACE));
								}
								marker4.setOrigin((hitloc.x,hitloc.y,closest.pos.z+aimheight.z),false);
							}
							break;
						}
						//try to aim at correct xy
						[delta,target_angle,target_pitch]=lookAt(view,(closest.pos.x,closest.pos.y,hitloc.z));
						a.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,a.viewheight*a.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(a.Spawn("AimAssistDebugMaker4",a.pos,NO_REPLACE));
								}
								marker4.setOrigin((closest.pos.x,closest.pos.y,hitloc.z),false);
							}
							break;
						}
					case 2://target closest
						[delta,target_angle,target_pitch]=lookAt(view,hitloc);
						if(mark){
							if(!marker4){
								marker4=AimAssistDebugMaker4(a.Spawn("AimAssistDebugMaker4",a.pos,NO_REPLACE));
							}
							marker4.setOrigin(hitloc,false);
						}
						break;
					case 0://don't aim
						return;
					}
				}else{
					ClearObstructionMarkers();
				}
			}else{
				ClearObstructionMarkers();
			}

			//get angle difference
			double angle_diff=a.DeltaAngle(a.angle,target_angle);
			double pitch_diff=a.DeltaAngle(a.pitch,target_pitch);

			//check rotation speed
			if(abs(angle_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				a.A_SetAngle(a.angle+(angle_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target angle
				a.A_SetAngle(target_angle,SPF_INTERPOLATE);
			}
			if(abs(pitch_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				a.A_SetPitch(a.pitch+(pitch_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target pitch
				a.A_SetPitch(target_pitch,SPF_INTERPOLATE);
			}
		}else{
			//if no target, remove markers
			ClearMarkers();
		}
	}

	override void WorldTick(){
		//if no keys are held and it's enabled, or keys are held and it's disabled, run the aim assist
		if(((enabled&&!(hold1||hold2))||(!enabled&&(hold1||hold2)))&&playeringame[consoleplayer]){
			doAim(players[consoleplayer].mo);
		}
	}

	override void NetworkProcess(ConsoleEvent e){
		if(e.player==consoleplayer){
			if(e.name=="AimAssistUpdateCVARs"){
				//player asked to update cvars
				UpdateCVARs();
				console.printf("Aim Assist CVARs Updated");
			}else if(e.name=="AimAssistToggle"){
				//toggle key pressed
				enabled=!enabled;
				CVAR.findCVar("AIM_ASSIST_ENABLED").setBool(enabled);
				console.printf("Aim Assist "..(enabled?"On":"Off"));
			}else if(e.name=="AimAssistHoldKey1Down"){
				//toggle hold key1 pressed
				hold1=true;
			}else if(e.name=="AimAssistHoldKey2Down"){
				//toggle hold key2 pressed
				hold2=true;
			}else if(e.name=="AimAssistHoldKey1Up"){
				//toggle hold key1 released
				hold1=false;
			}else if(e.name=="AimAssistHoldKey2Up"){
				//toggle hold key2 released
				hold2=false;
			}

		}
	}
	override bool InputProcess(InputEvent e){
		if(e.type==InputEvent.Type_KeyDown){
			if(e.keyScan==key1){
				//key 1 was pressed, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey1Down");
			}else if(e.keyScan==key2){
				//key 2 was pressed, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey2Down");
			}
		}else if(e.type==InputEvent.Type_KeyUp){
			if(e.keyScan==key1){
				//key 1 was released, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey1Up");
			}else if(e.keyScan==key2){
				//key 2 was released, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey2Up");
			}
		}
		return false;
	}
}
