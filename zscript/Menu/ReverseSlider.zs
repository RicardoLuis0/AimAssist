class OptionMenuItemReverseSlider : OptionMenuItemSlider{

	OptionMenuItemSlider Init(String label, Name command, double min, double max, double step, int showval = 1) {
		Super.Init(label, command, min, max, step, showval);
		return self;
	}

	protected void DrawReverseSlider (int x, int y, double min, double max, double cur, int fracdigits, int indent) {
		String formater = String.format("%%.%df", fracdigits);	// The format function cannot do the '%.*f' syntax.
		String textbuf;
		double range;
		int maxlen = 0;
		int right = x + (12*8 + 4) * CleanXfac_1;
		int cy = y + (OptionMenuSettings.mLinespacing-8)*CleanYfac_1;

		range = max - min;
		double ccur = (max-min)-(clamp(cur, min, max) - min);
		if (fracdigits >= 0) {
			textbuf = String.format(formater, max);
			maxlen = SmallFont.StringWidth(textbuf) * CleanXfac_1;
		}

		mSliderShort = right + maxlen > screen.GetWidth();

		if (!mSliderShort) {
			Menu.DrawConText(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x12");
			Menu.DrawConText(Font.FindFontColor(gameinfo.mSliderColor), x + int((5 + ((ccur * 78) / range)) * CleanXfac_1), cy, "\x13");
		}else{
			Menu.DrawConText(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x12");
			Menu.DrawConText(Font.FindFontColor(gameinfo.mSliderColor), x + int((5 + ((ccur * 38) / range)) * CleanXfac_1), cy, "\x13");
			right -= 5*8*CleanXfac_1;
		}

		if (fracdigits >= 0 && right + maxlen <= screen.GetWidth()) {
			textbuf = String.format(formater, cur);
			screen.DrawText(SmallFont, Font.CR_DARKGRAY, right, y, textbuf, DTA_CleanNoMove_1, true);
		}
	}


	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) {
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor);
		mDrawX = indent + CursorSpace();
		DrawReverseSlider(mDrawX, y, mMin, mMax, GetSliderValue(), mShowValue, indent);
		return indent;
	}

	override bool MenuEvent (int mkey, bool fromcontroller) {
		double value = GetSliderValue();
		if (mkey == Menu.MKEY_Right) {
			value -= mStep;
		}else if (mkey == Menu.MKEY_Left) {
			value += mStep;
		}else{
			return OptionMenuItem.MenuEvent(mkey, fromcontroller);
		}
		if (value ~== 0) value = 0;	// This is to prevent formatting anomalies with very small values
		SetSliderValue(clamp(value, mMin, mMax));
		Menu.MenuSound("menu/change");
		return true;
	}

	override bool MouseEvent(int type, int x, int y) {
		let lm = OptionMenu(Menu.GetCurrentMenu());
		if (type != Menu.MOUSE_Click) {
			if (!lm.CheckFocus(self)) return false;
		}
		if (type == Menu.MOUSE_Release) {
			lm.ReleaseFocus();
		}

		int slide_left = mDrawX+8*CleanXfac_1;
		int slide_right = slide_left + (10*8*CleanXfac_1 >> mSliderShort);	// 12 char cells with 8 pixels each.

		if (type == Menu.MOUSE_Click) {
			if (x < slide_left || x >= slide_right) return true;
		}

		x = clamp(x, slide_left, slide_right);
		double v = mMax - ((x - slide_left) * (mMax - mMin)) / (slide_right - slide_left);
		if (v != GetSliderValue()) {
			SetSliderValue(v);
			//Menu.MenuSound("menu/change");
		}
		if (type == Menu.MOUSE_Click) {
			lm.SetFocus(self);
		}
		return true;
	}
}
