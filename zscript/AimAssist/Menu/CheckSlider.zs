class OptionMenuCheckSliderBase : OptionMenuSliderBase
{
	
	double mMin, mMax, mStep;
	int mShowValue;
	int mDrawX;
	int mSliderShort;
	CVar mGrayCheck;
	
	OptionMenuCheckSliderBase Init (
		String label,
		double min,
		double max,
		double step,
		int showval,
		Name command = 'none',
		CVar graycheck = NULL
	) {
		Super.Init(label, min, max, step, showval, command, graycheck);
		mMin = min;
		mMax = max;
		mStep = step;
		mShowValue = showval;
		mDrawX = 0;
		mSliderShort = 0;
		mGrayCheck = graycheck;
		return self;
	}
	
	virtual double GetSliderTextValue() {
		return GetSliderValue();
	}

	override bool isGrayed(void) {
		return mGrayCheck && !mGrayCheck.GetInt();
	}
	
	override bool Selectable(void) {
		return !isGrayed();
	}
	
	private void DrawSliderElement (int color, int x, int y, String str, bool grayed = false) {
		int overlay = grayed? Color(96, 48, 0, 0) : 0;
		screen.DrawText (ConFont, color, x, y, str, DTA_CellX, 16 * CleanXfac_1, DTA_CellY, 16 * CleanYfac_1, DTA_ColorOverlay, overlay);
	}

	protected void DrawSlider (int x, int y, double min, double max, double cur, int fracdigits, int indent, bool grayed = false) {
		String formater = String.format("%%.%df", fracdigits);	// The format function cannot do the '%.*f' syntax.
		String textbuf;
		double range;
		int maxlen = 0;
		int right = x + (12 * 16 + 4) * CleanXfac_1;	// length of slider. This uses the old ConFont and 
		int cy = y + CleanYFac;

		range = max - min;
		double ccur = clamp(cur, min, max) - min;

		if (fracdigits >= 0) {
			textbuf = String.format(formater, max);
			maxlen = Menu.OptionWidth(textbuf) * CleanXfac_1;
		}

		mSliderShort = right + maxlen > screen.GetWidth();

		if (!mSliderShort) {
			DrawSliderElement(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x12", grayed);
			DrawSliderElement(Font.FindFontColor(gameinfo.mSliderColor), x + int((5 + ((ccur * 78) / range)) * 2 * CleanXfac_1), cy, "\x13", grayed);
		} else {
			// On 320x200 we need a shorter slider
			DrawSliderElement(Font.CR_WHITE, x, cy, "\x10\x11\x11\x11\x11\x11\x12", grayed);
			DrawSliderElement(Font.FindFontColor(gameinfo.mSliderColor), x + int((5 + ((ccur * 38) / range)) * 2 * CleanXfac_1), cy, "\x13", grayed);
			right -= 5*8*CleanXfac;
		}

		if (fracdigits >= 0 && right + maxlen <= screen.GetWidth()) {
			textbuf = String.format(formater, GetSliderTextValue());
			drawText(right, y, Font.CR_DARKGRAY, textbuf, grayed);
		}
	}
	
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected) {
		drawLabel(indent, y, selected ? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, isGrayed());
		mDrawX = indent + CursorSpace();
		DrawSlider (mDrawX, y, mMin, mMax, GetSliderValue(), mShowValue, indent, isGrayed());
		return indent;
	}

}

class OptionMenuItemCheckSlider : OptionMenuCheckSliderBase
{
	
	CVar mCVar;
	
	OptionMenuItemCheckSlider Init (
		String label,
		Name command,
		double min,
		double max,
		double step,
		int showval = 1,
		CVar graycheck = NULL
	) {
		Super.Init(label, min, max, step, showval, command, graycheck);
		mCVar = CVar.FindCVar(command);
		return self;
	}

	override double GetSliderValue()
	{
		if (mCVar != null)
		{
			return mCVar.GetFloat();
		}
		else
		{
			return 0;
		}
	}

	override void SetSliderValue(double val)
	{
		if (mCVar != null)
		{
			mCVar.SetFloat(val);
		}
	}
}
