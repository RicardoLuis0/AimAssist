class OptionMenuItemCheckValSlider : OptionMenuItemCheckSlider
{
	int mVal;
	bool mNot;
	
	OptionMenuItemCheckValSlider Init(
		String label,
		Name command,
		double min,
		double max,
		double step,
		int showval = 1,
		CVar check_var = null,
		int check_val = 0,
		bool check_not = true
	) {
		Super.Init(label, command, min, max, step, showval,check_var);
		mVal = check_val;
		mNot = check_not;
		return self;
	}
	
	override bool isGrayed() {
		return mGrayCheck && ((mGrayCheck.GetInt() == mVal) != mNot);
	}
}

class  OptionMenuItemCheckValOption : OptionMenuItemOption
{
	protected CVar mGrayCheck;
	int mVal;
	bool mNot;
	
	OptionMenuItemCheckValOption Init(
		String label,
		Name command,
		Name values,
		int center = 0,
		CVar check_var = null,
		int check_val = 0,
		bool check_not = true
	) {
		Super.Init(label, command, values, null, center);
		mGrayCheck = check_var;
		mVal = check_val;
		mNot = check_not;
		return self;
	}
	
	override bool isGrayed() {
		return mGrayCheck && ((mGrayCheck.GetInt() == mVal) != mNot);
	}
}
