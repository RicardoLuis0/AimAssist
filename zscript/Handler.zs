class AimAssistHandler : DisdainStaticEventHandler {

	bool mark;//if to display markers or not

	AimAssistDebugMaker1 marker1;//target marker
	AimAssistDebugMaker2 marker2;//current aim marker
	AimAssistDebugMaker3 marker3;//obstruction marker
	AimAssistDebugMaker4 marker4;//obstruction marker

	AimAssistPlayerData playerData[MAXPLAYERS];

	override void OnRegister(){
		for(int i=0;i<MAXPLAYERS;i++){
			playerData[i]=new("AimAssistPlayerData");
		}
	}

	override void WorldLoaded(WorldEvent e){
		marker1=null;
		marker2=null;
		marker3=null;
		marker4=null;
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i]){
				UpdateCVARs(i);
			}
		}
	}
	
	override void PlayerEntered(PlayerEvent e){
		UpdateCVARs(e.playernumber);
	}
	
	override void WorldUnloaded(WorldEvent e){
		marker1=null;
		marker2=null;
		marker3=null;
		marker4=null;
	}
	
	override void PlayerDisconnected(PlayerEvent e){
		if(e.PlayerNumber==consoleplayer){
			if(mark){
				ClearMarkers();
			}
		}
	}

	//update cvar values
	void UpdateCVARs(int pnum){
		playerData[pnum].UpdateCVARs(pnum);
		if(pnum==consoleplayer){
			ClearMarkers();
			mark=CVAR.GetCVar("AIM_ASSIST_DEBUG_MARKER",players[consoleplayer]).getBool();
		}
	}

	void UpdateAllCVARs(){
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i]){
				UpdateCVARs(i);
			}
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
	bool doAim(int pnum){
		if(!playerData[pnum].aimEnabled()) return false;
		PlayerPawn pawn=players[pnum].mo;
		
		bool do_mark=pnum==consoleplayer&&mark;
		
		float closest_distance=playerData[pnum].max_distance+1;
		Actor closest=null;
		Actor hit=null;
		Vector3 hitloc=(0,0,0);
		
		//check straight ahead
		[closest,closest_distance,hitloc]=playerData[pnum].doTrace(pawn,0,0,closest,closest_distance);
		
		double precision=playerData[pnum].precision;
		double radial_precision=playerData[pnum].radial_precision;
		double max_angle=playerData[pnum].max_angle;
		int method=playerData[pnum].method;
		
		//check in a circle around the direction player's looking
		for(double i_a=precision;i_a<=max_angle;i_a+=precision){
			for(double i_r=0;i_r<=360&&!(closest&&method==1);i_r+=radial_precision){
				[closest,closest_distance,hitloc]=playerData[pnum].doTrace(pawn,i_a,i_r,closest,closest_distance);
			}
		}
		//if there was an enemy found
		if(closest){
			float pheight=pawn.viewheight*pawn.player.crouchfactor;
			Vector3 aimheight=(0,0,playerData[pnum].getAimHeight(closest.height,pheight,closest_distance));
			Vector3 delta;
			double target_angle,target_pitch;
			Vector3 view=pawn.pos+(0,0,pheight);
			//get target angle and pitch
			[delta,target_angle,target_pitch]=lookAt(view,closest.pos+aimheight);

			//show/move markers
			if(do_mark){
				if(!marker1){
					marker1=AimAssistDebugMaker1(pawn.Spawn("AimAssistDebugMaker1",pawn.pos,NO_REPLACE));
				}
				if(!marker2){
					marker2=AimAssistDebugMaker2(pawn.Spawn("AimAssistDebugMaker2",pawn.pos,NO_REPLACE));
				}
				marker1.setOrigin(hitloc,true);
				marker2.setOrigin(closest.pos+aimheight,true);
			}
			
			//check if view is obstructed
			if(playerData[pnum].check_obstacles){
				FLineTraceData t;
				double max_distance=playerData[pnum].max_distance;
				pawn.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pawn.viewheight*pawn.player.crouchfactor,data:t);
				if(t.hitType!=TRACE_HitActor||t.hitActor!=closest){
					if(do_mark){
						if(!marker3){
							marker3=AimAssistDebugMaker3(pawn.Spawn("AimAssistDebugMaker3",pawn.pos,NO_REPLACE));
						}
						marker3.setOrigin(t.hitLocation,false);
					}
					switch(playerData[pnum].on_obstruction){
					default:
					case 1://aim correction
						//try to aim at correct z
						[delta,target_angle,target_pitch]=lookAt(view,(hitloc.x,hitloc.y,closest.pos.z+aimheight.z));
						pawn.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pawn.viewheight*pawn.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(do_mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(pawn.Spawn("AimAssistDebugMaker4",pawn.pos,NO_REPLACE));
								}
								marker4.setOrigin((hitloc.x,hitloc.y,closest.pos.z+aimheight.z),false);
							}
							break;
						}
						//try to aim at correct xy
						[delta,target_angle,target_pitch]=lookAt(view,(closest.pos.x,closest.pos.y,hitloc.z));
						pawn.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pawn.viewheight*pawn.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(do_mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(pawn.Spawn("AimAssistDebugMaker4",pawn.pos,NO_REPLACE));
								}
								marker4.setOrigin((closest.pos.x,closest.pos.y,hitloc.z),false);
							}
							break;
						}
					case 2://target closest
						[delta,target_angle,target_pitch]=lookAt(view,hitloc);
						if(do_mark){
							if(!marker4){
								marker4=AimAssistDebugMaker4(pawn.Spawn("AimAssistDebugMaker4",pawn.pos,NO_REPLACE));
							}
							marker4.setOrigin(hitloc,false);
						}
						break;
					case 0://don't aim
						return false;
					}
				}else if(do_mark){
					ClearObstructionMarkers();
				}
			}

			//get angle difference
			double angle_diff=pawn.DeltaAngle(pawn.angle,target_angle);
			double pitch_diff=pawn.DeltaAngle(pawn.pitch,target_pitch);

			double rot_speed=playerData[pnum].rot_speed;
			//check rotation speed
			if(abs(angle_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				pawn.A_SetAngle(pawn.angle+(angle_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target angle
				pawn.A_SetAngle(target_angle,SPF_INTERPOLATE);
			}
			if(abs(pitch_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				pawn.A_SetPitch(pawn.pitch+(pitch_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target pitch
				pawn.A_SetPitch(target_pitch,SPF_INTERPOLATE);
			}
			return true;
		}else{
			if(do_mark){
				//if no target, remove markers
				ClearMarkers();
			}
			return false;
		}
	}

	override void WorldTick(){
		//if no keys are held and it's enabled, or keys are held and it's disabled, run the aim assist
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i] && (players[i].mo.FindInventory("DisdainCameraAnimation",true) == null)){
				if(!doAim(i)||playerData[i].always_recenter){
					playerData[i].doRecenter(players[i].mo);
				}
			}
		}
		if (gameaction == ga_savegame || gameaction == ga_autosave) {
			ClearMarkers();
		}
	}

	override void NetworkProcess(ConsoleEvent e){
		if(e.name=="AimAssistUpdateCVARs"){
			//player asked to update cvars
			UpdateCVARs(e.player);
			if(e.player==consoleplayer){
				console.printf("Aim Assist CVARs Updated");
			}
		}else if(e.name=="AimAssistToggle"){
			//toggle key pressed
			playerData[e.player].enabled=!playerData[e.player].enabled;
			if(e.player==consoleplayer){
				CVAR.getCVar("AIM_ASSIST_ENABLED",players[e.player]).setBool(playerData[e.player].enabled);
				console.printf("Aim Assist "..(playerData[e.player].enabled?"On":"Off"));
			}
		}else if(e.name=="AimAssistCenterView"){
			//center view
			if(players[e.player].mo)players[e.player].mo.A_SetPitch(0,SPF_INTERPOLATE);
		}else if(e.name=="AimAssistHoldKey1Down"){
			//toggle hold key1 pressed
			playerData[e.player].hold1=true;
		}else if(e.name=="AimAssistHoldKey2Down"){
			//toggle hold key2 pressed
			playerData[e.player].hold2=true;
		}else if(e.name=="AimAssistHoldKey1Up"){
			//toggle hold key1 released
			playerData[e.player].hold1=false;
		}else if(e.name=="AimAssistHoldKey2Up"){
			//toggle hold key2 released
			playerData[e.player].hold2=false;
		}
	}
	
	override bool InputProcess(InputEvent e){
		if(e.type==InputEvent.Type_KeyDown){
			if(e.keyScan==playerData[consoleplayer].key1){
				//key 1 was pressed, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey1Down");
			}else if(e.keyScan==playerData[consoleplayer].key2){
				//key 2 was pressed, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey2Down");
			}
		}else if(e.type==InputEvent.Type_KeyUp){
			if(e.keyScan==playerData[consoleplayer].key1){
				//key 1 was released, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey1Up");
			}else if(e.keyScan==playerData[consoleplayer].key2){
				//key 2 was released, send event
				EventHandler.SendNetworkEvent("AimAssistHoldKey2Up");
			}
		}
		return false;
	}
}
