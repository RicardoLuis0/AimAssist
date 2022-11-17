class AimAssist_JsonElementOrError {
}

class AimAssist_JsonElement : AimAssist_JsonElementOrError abstract {
	abstract string serialize();
}

class AimAssist_JsonNumber : AimAssist_JsonElement abstract {
	abstract AimAssist_JsonNumber negate();
	abstract double  getDouble();
	abstract int getInt();
}

class AimAssist_JsonInt : AimAssist_JsonNumber {
	int i;
	
	static AimAssist_JsonInt make(int i=0){
		AimAssist_JsonInt ii=new("AimAssist_JsonInt");
		ii.i=i;
		return ii;
	}
	
	override AimAssist_JsonNumber negate(){
		i=-i;
		return self;
	}
	
	override string serialize(){
		return ""..i;
	}
	
	override double getDouble() {
		return double(i);
	}
	
	override int getInt() {
		return i;
	}
}

class AimAssist_JsonDouble : AimAssist_JsonNumber {
	double d;
	static AimAssist_JsonDouble make(double d=0){
		AimAssist_JsonDouble dd=new("AimAssist_JsonDouble");
		dd.d=d;
		return dd;
	}
	override AimAssist_JsonNumber negate(){
		d=-d;
		return self;
	}
	override string serialize(){
		return ""..d;
	}
	
	override double getDouble() {
		return d;
	}
	
	override int getInt() {
		return int(d);
	}
}

class AimAssist_JsonBool : AimAssist_JsonElement {
	bool b;
	static AimAssist_JsonBool make(bool b=false){
		AimAssist_JsonBool bb=new("AimAssist_JsonBool");
		bb.b=b;
		return bb;
	}
	override string serialize(){
		return b?"true":"false";
	}
}

class AimAssist_JsonString : AimAssist_JsonElement {
	string s;
	static AimAssist_JsonString make(string s=""){
		AimAssist_JsonString ss=new("AimAssist_JsonString");
		ss.s=s;
		return ss;
	}
	override string serialize(){
		return AimAssist_JSON.serialize_string(s);
	}
}

class AimAssist_JsonNull : AimAssist_JsonElement {
	static AimAssist_JsonNull make(){
		return new("AimAssist_JsonNull");
	}
	override string serialize(){
		return "null";
	}
}

class AimAssist_JsonError : AimAssist_JsonElementOrError {
	String what;
	static AimAssist_JsonError make(string s){
		AimAssist_JsonError e=new("AimAssist_JsonError");
		e.what=s;
		return e;
	}
}