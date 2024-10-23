class AimAssistHandler : StaticEventHandler{

	bool mark;//if to display markers or not

	AimAssistDebugMaker1 marker1;//target marker
	AimAssistDebugMaker2 marker2;//current aim marker
	AimAssistDebugMaker3 marker3;//obstruction marker
	AimAssistDebugMaker4 marker4;//obstruction marker

	AimAssistPlayerData playerData[MAXPLAYERS];
	
	AimAssist_JsonObject presets;
	
	static const Name preset_cvars[] = {
		// -----------
		//  base
		// -----------
			"cl_aim_assist_enabled",
			"cl_aim_assist_angle_max",
			"cl_aim_assist_max_dist",
			"cl_aim_assist_rot_speed",
			"cl_aim_assist_method",
		// -----------
		//  aim height
		// -----------
			"cl_aim_assist_height_mode",
			
			"cl_aim_assist_vertical_plus_offset_enemy",
			"cl_aim_assist_vertical_minus_offset_enemy",
			"cl_aim_assist_enemy_height_mult",
			
			"cl_aim_assist_vertical_plus_offset_player",
			"cl_aim_assist_vertical_minus_offset_player",
			"cl_aim_assist_player_height_mult",
			
			"cl_aim_assist_height_mode_transition_distance_start",
			"cl_aim_assist_height_mode_transition_distance_end",
		// -----------
		//  performance
		// -----------
			"cl_aim_assist_precision",
			"cl_aim_assist_radial_precision",
			
			"cl_aim_assist_check_for_obstacles",
			"cl_aim_assist_on_obstruction",
		// -----------
		//  recenter
		// -----------
			"cl_recenter_enabled",
			"cl_recenter_step",
			"cl_recenter_always_enabled",
		// -----------
		//  new
		// -----------
			"cl_aim_assist_enable_mode"
	};
	
	const NEW_CVAR_COUNT = 1; // new cvars are allowed to be missing when loading presets
	
	static const int new_cvar_defaults_int[] = {
		0 // cl_aim_assist_enable_mode
	};
	static const int new_cvar_defaults_double[] = {
		-1 // invalid
	};

	
	static const Name old_cvars[] = {
		"AIM_ASSIST_ENABLED",
		"AIM_ASSIST_ANGLE_MAX",
		"AIM_ASSIST_MAX_DIST",
		"AIM_ASSIST_ROT_SPEED",
		"AIM_ASSIST_METHOD",
		"AIM_ASSIST_HEIGHT_MODE",
		"AIM_ASSIST_VERTICAL_PLUS_OFFSET_ENEMY",
		"AIM_ASSIST_VERTICAL_MINUS_OFFSET_ENEMY",
		"AIM_ASSIST_ENEMY_HEIGHT_MULT",
		"AIM_ASSIST_VERTICAL_PLUS_OFFSET_PLAYER",
		"AIM_ASSIST_VERTICAL_MINUS_OFFSET_PLAYER",
		"AIM_ASSIST_PLAYER_HEIGHT_MULT",
		"AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_START",
		"AIM_ASSIST_HEIGHT_MODE_TRANSITION_DISTANCE_END",
		"AIM_ASSIST_PRECISION",
		"AIM_ASSIST_RADIAL_PRECISION",
		"AIM_ASSIST_CHECK_FOR_OBSTACLES",
		"AIM_ASSIST_ON_OBSTRUCTION",
		"rc_enabled",
		"rc_step",
		"rc_always_enabled"
	};
	
	static const Class<AimAssist_JsonElement> preset_cvar_json_types[] = {
		// -----------
		//  base
		// -----------
			"AimAssist_JsonBool",	// cl_aim_assist_enabled
			"AimAssist_JsonNumber",	// cl_aim_assist_angle_max
			"AimAssist_JsonNumber",	// cl_aim_assist_max_dist
			"AimAssist_JsonNumber",	// cl_aim_assist_rot_speed
			"AimAssist_JsonNumber",	// cl_aim_assist_method
		// -----------
		//  aim height
		// -----------
			"AimAssist_JsonNumber",	// cl_aim_assist_height_mode
			
			"AimAssist_JsonNumber",	// cl_aim_assist_vertical_plus_offset_enemy
			"AimAssist_JsonNumber",	// cl_aim_assist_vertical_minus_offset_enemy
			"AimAssist_JsonNumber",	// cl_aim_assist_enemy_height_mult
			
			"AimAssist_JsonNumber",	// cl_aim_assist_vertical_plus_offset_player
			"AimAssist_JsonNumber",	// cl_aim_assist_vertical_minus_offset_player
			"AimAssist_JsonNumber",	// cl_aim_assist_player_height_mult
			
			"AimAssist_JsonNumber",	// cl_aim_assist_height_mode_transition_distance_start
			"AimAssist_JsonNumber",	// cl_aim_assist_height_mode_transition_distance_end
		// -----------
		//  performance
		// -----------
			"AimAssist_JsonNumber",	// cl_aim_assist_precision
			"AimAssist_JsonNumber",	// cl_aim_assist_radial_precision
			
			"AimAssist_JsonBool",	// cl_aim_assist_check_for_obstacles
			"AimAssist_JsonNumber",	// cl_aim_assist_on_obstruction
		// -----------
		//  recenter
		// -----------
			"AimAssist_JsonBool",	// cl_recenter_enabled
			"AimAssist_JsonNumber",	// cl_recenter_step
			"AimAssist_JsonBool",	// cl_recenter_always_enabled
		// -----------
		//  new
		// -----------
			"AimAssist_JsonNumber"	// cl_aim_assist_enable_mode
	};
	
	
	static const String preset_pretty_types[] = {
		// -----------
		//  base
		// -----------
			"Bool",		// cl_aim_assist_enabled
			"Number",	// cl_aim_assist_angle_max
			"Number",	// cl_aim_assist_max_dist
			"Number",	// cl_aim_assist_rot_speed
			"Number",	// cl_aim_assist_method
		// -----------
		//  aim height
		// -----------
			"Number",	// cl_aim_assist_height_mode
			
			"Number",	// cl_aim_assist_vertical_plus_offset_enemy
			"Number",	// cl_aim_assist_vertical_minus_offset_enemy
			"Number",	// cl_aim_assist_enemy_height_mult
			
			"Number",	// cl_aim_assist_vertical_plus_offset_player
			"Number",	// cl_aim_assist_vertical_minus_offset_player
			"Number",	// cl_aim_assist_player_height_mult
			
			"Number",	// cl_aim_assist_height_mode_transition_distance_start
			"Number",	// cl_aim_assist_height_mode_transition_distance_end
		// -----------
		//  performance
		// -----------
			"Number",	// cl_aim_assist_precision
			"Number",	// cl_aim_assist_radial_precision
			
			"Bool",		// cl_aim_assist_check_for_obstacles
			"Number",	// cl_aim_assist_on_obstruction
		// -----------
		//  recenter
		// -----------
			"Bool",		// cl_recenter_enabled
			"Number",	// cl_recenter_step
			"Bool"		// cl_recenter_always_enabled
		// -----------
		//  new
		// -----------
			"Number"	// cl_aim_assist_enable_mode
	};
	
	
	int FindPresetCVarName(Name cvar_name){
		let n = preset_cvars.Size();
		for(uint i = 0; i < n; i++){
			if(cvar_name == preset_cvars[i]){
				return i;
			}
		}
		return n;
	}
	
	override void OnRegister(){
		for(int i=0;i<MAXPLAYERS;i++){
			playerData[i]=new("AimAssistPlayerData");
		}
		let presetsOrError = AimAssist_JSON.parse(__aim_assist_user_presets_json);
		if(!(presetsOrError is "AimAssist_JsonObject")){
			if(presetsOrError is "AimAssist_JsonError"){
				console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Presets CVar has invalid JSON data ("..(AimAssist_JsonError(presetsOrError).what).."), ignoring it");
			} else {
				console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Presets CVar is not a JSON Object, ignoring it");
			}
			presets = AimAssist_JsonObject.make();
		} else {
			Array<String> invalidKeys;
			
			presets = AimAssist_JsonObject(presetsOrError);
			Array<String> keys;
			presets.GetKeys(keys);
			let n = keys.Size();
			
			let PRESET_COUNT = preset_cvars.Size();
			
			for(int i = 0; i < n; i++) {
				bool invalid = false;
				let key = keys[i];
				let value = presets.Get(key);
				if(!(value is "AimAssist_JsonObject")) {
					console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Preset '"..key.."' is not a JSON Object");
				} else {
					let obj = AimAssist_JsonObject(value);
					Array<String> obj_keys;
					obj.GetKeys(obj_keys);
					let n = obj_keys.Size();
					Array<int> cvar_key_count;
					cvar_key_count.Resize(PRESET_COUNT);
					for(int i = 0; i < n; i++) {
						let cvar_name = obj_keys[i];
						int j = FindPresetCVarName(cvar_name);
						if(j == PRESET_COUNT) {
							invalid = true;
							console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Preset '"..key.."' has an invalid CVar '"..cvar_name.."'");
						} else {
							let cvar_data = obj.Get(cvar_name);
							if(!(cvar_data is preset_cvar_json_types[j])){
								invalid = true;
								console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Preset '"..key.."' CVar '"..cvar_name.."' has type '"..cvar_data.GetPrettyName().."', expected '"..preset_pretty_types[j].."'");
							} else {
								cvar_key_count[j]++;
							}
						}
					}
					
					for(uint i = 0; i < PRESET_COUNT; i++) {
						if(cvar_key_count[i] == 0) {
							if( i < (PRESET_COUNT - NEW_CVAR_COUNT))
							{
								invalid = true;
								console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Preset '"..key.."' is missing CVar '"..preset_cvars[i].."'");
							}
							else
							{
								console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_ORANGE.."Aim Assist Preset '"..key.."' is missing CVar '"..preset_cvars[i].."', loading defaults");
								let c = CVar.FindCVar(preset_cvars[i]);
								let ii = i - (PRESET_COUNT - NEW_CVAR_COUNT);
								switch(c.GetRealType()){
								case CVar.CVAR_Int:
									obj.Set(preset_cvars[i],AimAssist_JsonInt.make(new_cvar_defaults_int[ii]));
									break;
								case CVar.CVAR_Float:
									obj.Set(preset_cvars[i],AimAssist_JsonDouble.make(new_cvar_defaults_double[ii]));
									break;
								case CVar.CVAR_Bool:
									obj.Set(preset_cvars[i],AimAssist_JsonBool.make(new_cvar_defaults_int[ii]));
									break;
								}
								
							}
						}
					}
				}
				
				if(invalid) {
					console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Aim Assist Preset '"..key.."' has errors, ignoring it");
					invalidKeys.Push(key);
				}
			}
			n = invalidKeys.Size();
			for(int i = 0; i < n; i++) {
				presets.delete(invalidKeys[i]);
			}
		}
	}
	
	clearscope void SavePresets(){
		CVar.FindCVar("__aim_assist_user_presets_json").SetString(presets.serialize());
	}
	
	clearscope AimAssist_JsonObject CurrentToJson() {
		let obj = AimAssist_JsonObject.make();
		let n = preset_cvars.Size();
		for(uint i = 0; i < n; i++){
			AimAssist_JsonElement e;
			CVar c = CVar.GetCVar(preset_cvars[i],players[consoleplayer]);
			switch(c.GetRealType()){
			case CVar.CVAR_Int:
				e = AimAssist_JsonInt.make(c.GetInt());
				break;
			case CVar.CVAR_Float:
				e = AimAssist_JsonDouble.make(c.GetFloat());
				break;
			case CVar.CVAR_Bool:
				e = AimAssist_JsonBool.make(c.GetBool());
				break;
			}
			obj.Set(preset_cvars[i],e);
		}
		return obj;
	}
	
	clearscope void LoadPreset(string preset_name) {
		ResetToDefault();
		let obj_e = presets.Get(preset_name);
		if(obj_e && obj_e is "AimAssist_JsonObject") {
			let obj = AimAssist_JsonObject(obj_e);
			let n = preset_cvars.Size();
			for(uint i = 0; i < n; i++) {
				CVar c = CVar.FindCVar(preset_cvars[i]);
				let e = obj.Get(preset_cvars[i]);
				
				switch(c.GetRealType()){
				case CVar.CVAR_Int:
					c.SetInt(AimAssist_JsonNumber(e).GetInt());
					break;
				case CVar.CVAR_Float:
					c.SetFloat(AimAssist_JsonNumber(e).GetDouble());
					break;
				case CVar.CVAR_Bool:
					c.SetBool(AimAssist_JsonBool(e).b);
					break;
				}
			}
		}
	}
	
	clearscope void LoadOldCVars() {
		ResetToDefault();
		let n = old_cvars.Size();
		for(uint i = 0; i < n; i++) {
			CVar c = CVar.FindCVar(preset_cvars[i]);
			switch(c.GetRealType()) {
			case CVar.CVAR_Int:
				c.SetInt(CVar.FindCVar(old_cvars[i]).GetInt());
				break;
			case CVar.CVAR_Float:
				c.SetFloat(CVar.FindCVar(old_cvars[i]).GetFloat());
				break;
			case CVar.CVAR_Bool:
				c.SetBool(CVar.FindCVar(old_cvars[i]).GetBool());
				break;
			}
		}
	}
	
	clearscope void ResetToDefault(bool performance = false) {
		let n = preset_cvars.Size();
		for(uint i = 0; i < n; i++){
			CVar.FindCVar(preset_cvars[i]).ResetToDefault();
		}
		if(performance) {
			CVar.FindCVar("cl_aim_assist_precision").SetFloat(2.0);
			CVar.FindCVar("cl_aim_assist_radial_precision").SetInt(45);
		}
	}
	
	clearscope void ExecuteCommand(name cmd,string data) {
		switch(cmd) {
		case Name("SaveUserPreset"):
			presets.Set(data,CurrentToJson());
			SavePresets();
			break;
		case Name("DeleteUserPreset"):
			presets.Delete(data);
			SavePresets();
			break;
		case Name("LoadUserPreset"):
			LoadPreset(data);
			break;
		case Name("ResetToDefault"):
		case Name("LoadDefaultPreset"):
			ResetToDefault();
			break;
		case Name("LoadPerformancePreset"):
			ResetToDefault(true);
			break;
		case Name("LoadOldCVars"):
			LoadOldCVars();
			break;
		default:
			console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."unkonwn confirm command "..cmd.." , ignoring it");
		}
	}

	override void WorldLoaded(WorldEvent e){
		marker1=null;
		marker2=null;
		marker3=null;
		marker4=null;
		for(int i=0;i<MAXPLAYERS;i++) {
			if(playeringame[i]) {
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
			mark=CVAR.GetCVar("cl_aim_assist_debug_marker",players[consoleplayer]).getBool();
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
		let pdata = playerData[pnum];
		let pi = players[pnum];
		let pp = players[pnum].mo;
		if(!pdata.aimEnabled(players[pnum])){
			ClearMarkers();
			return false;
		}
		PlayerPawn pawn=players[pnum].mo;
		
		bool do_mark=pnum==consoleplayer&&mark;
		
		double precision=pdata.precision.getFloat();
		double radial_precision=pdata.radial_precision.getFloat();
		double max_angle=pdata.max_angle.getFloat();
		double max_distance=pdata.max_distance.getFloat();
		int method=pdata.method.getInt();
		
		
		
		
		float closest_distance=max_distance+1;
		Actor closest=null;
		Actor hit=null;
		Vector3 hitloc=(0,0,0);
		
		//check straight ahead
		[closest,closest_distance,hitloc]=pdata.doTrace(pp,0,0,closest,closest_distance);
		
		
		//check in a circle around the direction player's looking
		for(double i_a=precision;i_a<=max_angle;i_a+=precision){
			for(double i_r=0;i_r<=360&&!(closest&&method==1);i_r+=radial_precision){
				[closest,closest_distance,hitloc]=pdata.doTrace(pp,i_a,i_r,closest,closest_distance);
			}
		}
		//if there was an enemy found
		if(closest){
			float pheight=pp.viewheight*pp.player.crouchfactor;
			Vector3 aimheight=(0,0,pdata.getAimHeight(closest.height,pheight,closest_distance));
			Vector3 delta;
			double target_angle,target_pitch;
			Vector3 view=pp.pos+(0,0,pheight);
			//get target angle and pitch
			[delta,target_angle,target_pitch]=lookAt(view,closest.pos+aimheight);

			//show/move markers
			if(do_mark){
				if(!marker1){
					marker1=AimAssistDebugMaker1(pp.Spawn("AimAssistDebugMaker1",pp.pos,NO_REPLACE));
				}
				if(!marker2){
					marker2=AimAssistDebugMaker2(pp.Spawn("AimAssistDebugMaker2",pp.pos,NO_REPLACE));
				}
				marker1.setOrigin(hitloc,true);
				marker2.setOrigin(closest.pos+aimheight,true);
			}
			
			//check if view is obstructed
			if(pdata.check_obstacles.getBool()){
				FLineTraceData t;
				pp.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pp.viewheight*pp.player.crouchfactor,data:t);
				if(t.hitType!=TRACE_HitActor||t.hitActor!=closest){
					if(do_mark){
						if(!marker3){
							marker3=AimAssistDebugMaker3(pp.Spawn("AimAssistDebugMaker3",pp.pos,NO_REPLACE));
						}
						marker3.setOrigin(t.hitLocation,false);
					}
					switch(pdata.on_obstruction.getInt()){
					default:
					case 1://aim correction
						//try to aim at correct z
						[delta,target_angle,target_pitch]=lookAt(view,(hitloc.x,hitloc.y,closest.pos.z+aimheight.z));
						pp.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pp.viewheight*pp.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(do_mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(pp.Spawn("AimAssistDebugMaker4",pp.pos,NO_REPLACE));
								}
								marker4.setOrigin((hitloc.x,hitloc.y,closest.pos.z+aimheight.z),false);
							}
							break;
						}
						//try to aim at correct xy
						[delta,target_angle,target_pitch]=lookAt(view,(closest.pos.x,closest.pos.y,hitloc.z));
						pp.LineTrace(target_angle,max_distance,target_pitch,TRF_NOSKY,pp.viewheight*pp.player.crouchfactor,data:t);
						if(t.hitType==TRACE_HitActor&&t.hitActor==closest){
							if(do_mark){
								if(!marker4){
									marker4=AimAssistDebugMaker4(pp.Spawn("AimAssistDebugMaker4",pp.pos,NO_REPLACE));
								}
								marker4.setOrigin((closest.pos.x,closest.pos.y,hitloc.z),false);
							}
							break;
						}
					case 2://target closest
						[delta,target_angle,target_pitch]=lookAt(view,hitloc);
						if(do_mark){
							if(!marker4){
								marker4=AimAssistDebugMaker4(pp.Spawn("AimAssistDebugMaker4",pp.pos,NO_REPLACE));
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
			double angle_diff=pp.DeltaAngle(pp.angle,target_angle);
			double pitch_diff=pp.DeltaAngle(pp.pitch,target_pitch);

			double rot_speed=pdata.rot_speed.getFloat();
			//check rotation speed
			if(abs(angle_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				pp.A_SetAngle(pp.angle+(angle_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target angle
				pp.A_SetAngle(target_angle,SPF_INTERPOLATE);
			}
			if(abs(pitch_diff)>rot_speed){
				//if rotation speed is lower than difference, add/subtract rotation speed
				pp.A_SetPitch(pp.pitch+(pitch_diff>0?rot_speed:-rot_speed),SPF_INTERPOLATE);
			}else{
				//if rotation speed is higher than differece, set to target pitch
				pp.A_SetPitch(target_pitch,SPF_INTERPOLATE);
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
			if(playeringame[i]){
				if(!doAim(i)||playerData[i].always_recenter.getBool()){
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
			if(e.player==consoleplayer){
				CVar enabled = CVAR.GetCVar("cl_aim_assist_enabled",players[e.player]);
				console.printf("Aim Assist "..((!enabled.GetBool())?"On":"Off"));
				enabled.SetBool(!enabled.GetBool());
			}
		}else if(e.name=="AimAssistCenterView"){
			//center view
			if(players[e.player].mo)players[e.player].mo.A_SetPitch(0,SPF_INTERPOLATE);
		}else if(e.name=="AimAssistToggleHoldDown"){
			//key held
			playerData[e.player].hold++;
		}else if(e.name=="AimAssistToggleHoldUp"){
			//key released
			playerData[e.player].hold--;
		}
	}
}
