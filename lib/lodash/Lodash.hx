package lib.lodash;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;

class Lodash
{
    macro public static function build():Array<Field> 
	{
		var printer = new haxe.macro.Printer();
		var pos = haxe.macro.Context.currentPos();
		var classFields = haxe.macro.Context.getBuildFields();
		var localClass = Context.getLocalClass().get();
		
		var lodashFields = [];
		for( field in classFields )
		{
			if( field.meta == null ) continue;
			for( meta in field.meta )
			{
				if( meta.name == ":throttle" )
				{
					lodashFields.push( {isThrottle:true, field:field, meta:meta, access:field.access} );
				}
				else if( meta.name == ":debounce" )
				{
					lodashFields.push( {isThrottle:false, field:field, meta:meta, access:field.access} );
				}
			}
		}

		//On supprime le champ d'origine de la definition de la classe, on va surcharger tout ceci
		for( field in lodashFields )
			classFields.remove(field.field);
		

//CLEANING METHODS ANS PROPERTIES
		var lodashClean = "__cleanLodashList";
		var propertyCleanListField:Field = {
			name: lodashClean,
			access: [Access.APrivate],
			kind: FieldType.FVar(macro: List<Void->Void>),//can't initialize here due to hxgenjs unsupported feature , macro new List()
			pos: Context.currentPos(),
		};
		var lodashStaticClean = "__cleanLodashStaticList";
		var propertyCleanStaticListField:Field = {
			name: lodashStaticClean,
			access: [Access.APrivate, Access.AStatic],
			kind: FieldType.FVar(macro: List<Void->Void>),
			pos: Context.currentPos(),
		};
		var myCleanFunc:Function = {
			expr: macro {
				#if debug trace("clean lodash methods"); #end
				if( $i{lodashClean} == null ) return;
				for(f in $i{lodashClean})
					if( f != null ) f();
				$i{lodashClean} = new List();
			},
			ret: macro: Void,
			args: [],
		}
		var cleanField:Field = {
			name: 'lodashDispose',
			access: [Access.APrivate],
			kind: FieldType.FFun(myCleanFunc),
			pos: Context.currentPos(),
		};
		var myCleanStaticFunc:Function = {
			expr: macro {
				#if debug trace("clean lodash static methods"); #end
				if( $i{lodashStaticClean} == null ) return;
				for(f in $i{lodashStaticClean})
					if( f != null ) f();
				$i{lodashStaticClean} = new List();
			},
			ret: macro: Void,
			args: [],
		}
		var cleanStaticField:Field = {
			name: 'lodashDisposeStatic',
			access: [Access.AStatic],
			kind: FieldType.FFun(myCleanStaticFunc),
			pos: Context.currentPos(),
		};

		#if (debug && macro_debug) 
		trace(printer.printField(propertyCleanListField)); 
		trace(printer.printField(propertyCleanStaticListField)); 
		trace(printer.printField(cleanField)); 
		trace(printer.printField(cleanStaticField)); 
		#end

		classFields.push(propertyCleanListField);
		classFields.push(propertyCleanStaticListField);
		classFields.push(cleanField);
		classFields.push(cleanStaticField);

//PARSING FIELDS

		for( field in lodashFields )
		{
			var meta = field.meta;
			var fieldName = field.field.name;
			
			var tvoid = macro : Void;
			switch( field.field.kind )
			{
				case FFun( f ):
				
					var arguments = f.args.map(function(a) return macro $i{a.name});
					var argumentsType = f.args.map(function(a) return a.type);
					var returnType = f.ret != null ? f.ret : macro :Void;
					
					var prefixName = field.isThrottle ? 'throttled' : 'debounced';

					var throttleArguments:Array<haxe.macro.Expr> = [macro $i{'__un${prefixName}_${fieldName}'}];
					if(meta.params[0] != null) throttleArguments.push(meta.params[0]);
					if(meta.params[1] != null) throttleArguments.push(meta.params[1]);
					
					var exprCall = 	if( field.isThrottle ) macro lib.lodash.Lodash.Throttle.throttle($a{throttleArguments} );
									else macro lib.lodash.Lodash.Debounce.debounce($a{throttleArguments} );
					var propName = '${prefixName}_${fieldName}';

					var cleanIdentifier;				
					if( field.field.access != null && Lambda.has(field.field.access, Access.AStatic) ) {
						cleanIdentifier = lodashStaticClean;
					} else {
						cleanIdentifier = lodashClean;
					}

					var myFunc:Function = {
						expr: macro {
							if( $i{propName} == null ) {
								var tmp = $exprCall;
								$i{propName} = cast tmp;
								if( $i{cleanIdentifier} == null ) $i{cleanIdentifier} = new List();
								$i{cleanIdentifier}.add(tmp.cancel);
							}
							return $i{propName}($a{arguments});
						},
						ret: f.ret,
						args: f.args,
					}

					var newFieldsAccess = field.field.access.copy();
					// on nettoie un peu ce qui pourrait gener
					newFieldsAccess.remove(Access.APublic);
					newFieldsAccess.remove(Access.AInline);
					// On recréé le champ d'origine mais renommé et on l'appelera depuis la nouvelle définition de la méthode
                    var untrotthedDef = { 
						meta: [], 
						access: newFieldsAccess,
						kind: field.field.kind, 
						name: '__un'+propName,
						pos: Context.currentPos(),
						doc:null,
					};

					var propertyField:Field = {
						name: propName,
						access: newFieldsAccess,
						kind: FieldType.FVar(ComplexType.TFunction(argumentsType, returnType)),
						pos: Context.currentPos(),
					};

					var getterField:Field = {
						name: fieldName,
						access: field.field.access,
						kind: FieldType.FFun(myFunc),
						pos: Context.currentPos(),
					};

					#if (debug && macro_debug)
					trace(printer.printField(propertyField));
					trace(printer.printField(untrotthedDef));
					trace(printer.printField(getterField));
					#end

					classFields.push(untrotthedDef);
					classFields.push(propertyField);
					classFields.push(getterField);
					
				default: 
					Context.fatalError( "Invalid @:throttle or @:debounce position " + field.field.kind, Context.currentPos() );
			}
		}
		
        return classFields;
    }
}
#else
import haxe.Constraints.Function;

typedef ThrottleOptions = {
    ? leading : Bool,
    ? trailing : Bool
}

@:jsRequire('lodash.throttle')
extern class Throttle {
    @:selfCall
    static public function throttle<T:haxe.Constraints.Function>(f:T, ? wait:Int = 0, ? options:ThrottleOptions):CancellableFunction<T>;
}

typedef DebounceOptions = {
    ? leading : Bool,
    ? trailing : Bool,
	? maxWait : Int,
}

@:jsRequire('lodash.debounce')
extern class Debounce {
    @:selfCall
    static public function debounce<T:haxe.Constraints.Function>(f:T, ? wait:Int = 0, ? options:DebounceOptions):CancellableFunction<T>;
}

@:callable
abstract CancellableFunction<T>(T) from T to T {
    public function cancel() untyped (this.cancel)();
}
#end
