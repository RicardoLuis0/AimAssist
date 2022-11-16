
class OptionMenuItemCheckValSlider : OptionMenuItemCheckSlider {
	int val;
	bool not;

	OptionMenuItemCheckValSlider Init(String label, Name command, double min, double max, double step, int showval = 1,CVar check_var=null,int check_val=0,bool check_not=true) {
		Super.Init(label, command, min, max, step, showval,check_var);
		val=check_val;
		not=check_not;
		return self;
	}

	override bool isGrayed() {
		return mGrayCheck != null && not?!(mGrayCheck.GetInt()==val):((mGrayCheck.GetInt()==val));
	}
}
