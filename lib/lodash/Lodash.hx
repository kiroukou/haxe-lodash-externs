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
					var myFunc:Function = {
						expr: macro {
							if( $i{propName} == null ) {
								$i{propName} = cast $exprCall;
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
						name: '__un${prefixName}_${fieldName}',
						pos: Context.currentPos(),
						doc:null,
					};

					var propertyField:Field = {
						name: '${prefixName}_${fieldName}',
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
    static public function throttle<T:haxe.Constraints.Function>(f:T, ? wait : Int = 0, ? options : ThrottleOptions) : T;
}

typedef DebounceOptions = {
    ? leading : Bool,
    ? trailing : Bool,
	? maxWait : Int,
}

@:jsRequire('lodash.debounce')
extern class Debounce {
    @:selfCall
    static public function debounce<T:haxe.Constraints.Function>(f:T, ? wait : Int = 0, ? options : DebounceOptions) : T;
}
#end
