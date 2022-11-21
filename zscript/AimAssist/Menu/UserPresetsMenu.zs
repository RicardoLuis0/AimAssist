
class AimAssistPresetMessageBox : CustomMessageBoxMenuBase {
	
	string mPreset;
	
	static const string options[] = {
		"Load",
		"Overwrite",
		"Delete",
		"Cancel"
	};
	
	static const string cmds[] = {
		"LoadUserPreset",
		"SaveUserPreset",
		"DeleteUserPreset"
	};
	
	int confirm_index;
	
	override uint optionCount(){
		return options.Size();
	}
	
	override string optionName(uint i){
		return options[i];
	}
	
	override int OptionXOffset(uint index) {
		return -30;
	}
	
	// -1 = no shortcut
	override int OptionForShortcut(int char_key, out bool activate) {
		if(char_key == 110) {
			activate = false;
			return 3;
		}
		return -1;
	}
	
	// -1 = escape
	override void HandleResult(int i) {
		if(i == -1 || i == 3) {
			CloseSound();
			Close();
		} else {
			MenuSound("menu/activate");
			confirm_index = i;
			Menu.StartMessage(TEXTCOLOR_NORMAL.."Are you sure you want to "..options[i].." preset '"..mPreset.."'?", 0);
		}
	}
	
	int toClose;
	
	override void OnReturn() {
		if(toClose) {
			AimAssistUserPresetsMenu(mParentMenu).toClose = toClose - 1;
			Close();
		}
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			AimAssistHandler(StaticEventHandler.Find("AimAssistHandler")).ExecuteCommand(cmds[confirm_index],mPreset);
			toClose = confirm_index == 0 ? 3 : confirm_index == 1 ? 1 : 2;
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
}

class AimAssistUserPreset : OptionMenuItemSubmenu
{
	String mPreset;


	AimAssistUserPreset Init(String preset)
	{
		Super.Init(preset, "");
		mPreset = preset;
		return self;
	}

	override bool Activate()
	{
		let mBox = new("AimAssistPresetMessageBox");
		mBox.mPreset = mPreset;
		mBox.Init(Menu.GetCurrentMenu(),mPreset,true);
		mBox.ActivateMenu();
		return true;
	}
}

class AimAssistSavePresetMenu : OptionMenu {
	bool toClose;
	
	override void OnReturn() {
		if(toClose) {
			Close();
		}
	}
}

class OptionMenuItemAimAssistSaveUserPreset : OptionMenuItemSubmenu
{
	OptionMenuItemAimAssistSaveUserPreset Init()
	{
		Super.Init("Confirm", "", 0, true);
		return self;
	}
	
	AimAssistSavePresetMenu parentMenu;

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			AimAssistHandler(StaticEventHandler.Find("AimAssistHandler")).ExecuteCommand("SaveUserPreset",__aim_assist_save_preset_name);
			CVar.GetCVar("__aim_assist_save_preset_name").SetString("");
			parentMenu.toClose = true;
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
	override bool Activate()
	{
		let handler = AimAssistHandler(StaticEventHandler.Find("AimAssistHandler"));
		parentMenu = AimAssistSavePresetMenu(Menu.GetCurrentMenu());
		handler.presets;
		if(__aim_assist_save_preset_name.RightIndexOf(" ") != -1){
			Menu.StartMessage(TEXTCOLOR_NORMAL.."Preset Name Cannot Contain Whitespace", 1);
		} else if(handler.presets.Get(__aim_assist_save_preset_name) != null) {
			Menu.StartMessage(TEXTCOLOR_NORMAL.."Overwrite existing preset '"..__aim_assist_save_preset_name.."'?", 0);
		} else if(__aim_assist_save_preset_name.Length() == 0){
			Menu.StartMessage(TEXTCOLOR_NORMAL.."Cannot Create Preset with Empty Name", 1);
		} else {
			handler.ExecuteCommand("SaveUserPreset",__aim_assist_save_preset_name);
			parentMenu.Close();
		}
		return true;
	}
}


class OptionMenuItemAimAssistConfirmCommand : OptionMenuItemSubmenu
{
	String mPrompt;
	
	Name mCommand;
	String mData;


	OptionMenuItemAimAssistConfirmCommand Init(String label,Name command,String data, String prompt = "")
	{
		Super.Init(label, "");
		mPrompt = prompt;
		mCommand = command;
		mData = data;
		return self;
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			AimAssistHandler(StaticEventHandler.Find("AimAssistHandler")).ExecuteCommand(mCommand,mData);
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
	override bool Activate()
	{
		Menu.StartMessage(TEXTCOLOR_NORMAL..mPrompt, 0);
		return true;
	}
}


class AimAssistUserPresetsMenu : OptionMenu {
	
	void RebuildList(OptionMenuDescriptor desc) {
		let handler = AimAssistHandler(StaticEventHandler.Find("AimAssistHandler"));
		desc.mItems.Clear();
		Array<String> keys;
		handler.presets.getKeys(keys);
		let n = keys.Size();
		for(uint i = 0; i < n; i++) {
			desc.mItems.Push(new("AimAssistUserPreset").Init(keys[i]));
		}
	}
	
	
	override void Init(Menu parent, OptionMenuDescriptor desc) {
		
		RebuildList(desc);
		
		Super.Init(parent,desc);
	}
	
	int toClose;
	
	override void OnReturn() {
		if(toClose) {
			AimAssistPresetsMenu(mParentMenu).toClose = toClose - 1;
			mDesc.mSelectedItem = 0;
			Close();
		}
	}
}

class OptionMenuItemUserPresetsSubmenu : OptionMenuItemSubmenu {
	AimAssistHandler handler;
	OptionMenuItemUserPresetsSubmenu Init(String label, Name command, int param = 0, bool centered = false) {
		Super.Init(label,command,param,centered);
		handler = AimAssistHandler(StaticEventHandler.Find("AimAssistHandler"));
		return self;
	}
	override bool Selectable() {
		return handler.presets.size() != 0;
	}
	
	override bool Activate() {
		if(Selectable()) return Super.Activate();
		return false;
	}
}

class AimAssistPresetsMenu : OptionMenu {
	bool toClose;
	
	override void OnReturn() {
		CVar.GetCVar("__aim_assist_save_preset_name").SetString("");
		if(toClose) {
			Close();
		}
	}
}