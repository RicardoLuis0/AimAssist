class OptionMenuItemReverseSlider : OptionMenuCheckSliderBase
{
	
	CVar mCVar;
	double mInterval;
	
	OptionMenuItemReverseSlider Init(
		String label,
		Name command,
		double min,
		double max,
		double step,
		int showval = 1,
		CVar graycheck = NULL
	) {
		mInterval = max - min;
		Super.Init(label, 0, mInterval, step, showval, command, graycheck);
		mCVar = CVar.FindCVar(command);
		return self;
	}
	
	override double GetSliderValue() {
		if (mCVar != null) {
			return 0 - (mCVar.GetFloat() - mInterval);
		} else {
			return 0;
		}
	}
	
	override void SetSliderValue(double val) {
		if (mCVar != null) {
			mCVar.SetFloat(mMin + (mInterval - val));
		}
	}
	
	override double GetSliderTextValue() {
		if (mCVar != null) {
			return mCVar.GetFloat();
		} else {
			return 0;
		}
	}
}

class OptionMenuItemReverseCheckValSlider : OptionMenuItemReverseSlider
{
	int val;
	bool not;

	OptionMenuItemReverseCheckValSlider Init(
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
		val=check_val;
		not=check_not;
		return self;
	}

	override bool isGrayed() {
		return mGrayCheck && ((mGrayCheck.GetInt() == val) != not);
	}
}