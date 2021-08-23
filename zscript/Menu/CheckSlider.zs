class OptionMenuItemCheckSlider : OptionMenuItemSlider{
	protected CVar check;

	OptionMenuItemSlider Init(String label, Name command, double min, double max, double step, int showval = 1,CVar check_var=null) {
		Super.Init(label, command, min, max, step, showval);
		check=check_var;
		return self;
	}

	protected void DrawSlider (int x, int y, double min, double max, double cur, int fracdigits, int indent)
	{
		bool grayed=isGrayed();
		Color slidercolor=grayed?Font.FindFontColor("DarkGray"):Font.FindFontColor(gameinfo.mSliderColor);
		String formater = String.format("%%.%df", fracdigits);	// The format function cannot do the '%.*f' syntax.
		String textbuf;
		double range;
		int maxlen = 0;
		int right = x + (12*8 + 4) * CleanXfac_1;
		int cy = y + (OptionMenuSettings.mLinespacing-8)*CleanYfac_1;

		range = max - min;
		double ccur = clamp(cur, min, max) - min;

		if (fracdigits >= 0)
		{
			textbuf = String.format(formater, max);
			maxlen = SmallFont.StringWidth(textbuf) * CleanXfac_1;
		}

		mSliderShort = right + maxlen > screen.GetWidth();

		if (!mSliderShort)
		{
			Menu.DrawConText(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x12");
			Menu.DrawConText(slidercolor, x + int((5 + ((ccur * 78) / range)) * CleanXfac_1), cy, "\x13");
		}
		else
		{
			// On 320x200 we need a shorter slider
			Menu.DrawConText(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x12");
			Menu.DrawConText(slidercolor, x + int((5 + ((ccur * 38) / range)) * CleanXfac_1), cy, "\x13");
			right -= 5*8*CleanXfac_1;
		}

		if (fracdigits >= 0 && right + maxlen <= screen.GetWidth())
		{
			textbuf = String.format(formater, cur);
			screen.DrawText(SmallFont, Font.CR_DARKGRAY, right, y, textbuf, DTA_CleanNoMove_1, true);
		}
	}


	//=============================================================================
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor);
		mDrawX = indent + CursorSpace();
		DrawSlider (mDrawX, y, mMin, mMax, GetSliderValue(), mShowValue, indent);
		return indent;
	}

	virtual bool isGrayed() {
		return check != null && !check.GetInt();
	}
	
	override bool Selectable() {
		return !isGrayed();
	}
}