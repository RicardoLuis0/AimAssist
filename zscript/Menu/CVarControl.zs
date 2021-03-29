class OptionMenuItemCVARControl : OptionMenuItemControlBase {

	CVAR CV_key1,CV_key2;

	OptionMenuItemCVARControl Init(String label, CVar CVAR_key1,CVar CVAR_key2) {
		Super.init(label,"",null);
		CV_key1=CVAR_key1;
		CV_key2=CVAR_key2;
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) {
		drawLabel(indent, y, (mWaiting? OptionMenuSettings.mFontColorHighlight: 
			(selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor)));

		String description;
		int Key1=CV_key1.getInt(), Key2=CV_key2.getInt();
		description = KeyBindings.NameKeys (Key1, Key2);
		if (description.Length() > 0) {
			Menu.DrawConText(Font.CR_WHITE, indent + CursorSpace(), y + (OptionMenuSettings.mLinespacing-8)*CleanYfac_1, description);
		} else {
			screen.DrawText(SmallFont, Font.CR_BLACK, indent + CursorSpace(), y + (OptionMenuSettings.mLinespacing-8)*CleanYfac_1, "---", DTA_CleanNoMove_1, true);
		}
		return indent;
	}

	override bool MenuEvent(int mkey, bool fromcontroller) {
		if (mkey == Menu.MKEY_Input) {
			mWaiting = false;
			if(CV_key1.getInt()==mInput) {
				return true;
			}else if(CV_key2.getInt()==mInput) {
				return true;
			}else if(CV_key1.getInt()==0) {
				CV_key1.setInt(mInput);
			}else{
				CV_key2.setInt(mInput);
			}
			return true;
		} else if (mkey == Menu.MKEY_Clear) {
			CV_key1.setInt(0);
			CV_key2.setInt(0);
			return true;
		} else if (mkey == Menu.MKEY_Abort) {
			mWaiting = false;
			return true;
		}
		return false;
	}
}
