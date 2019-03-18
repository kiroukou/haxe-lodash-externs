# haxe-lodash-externs
Haxe externs for some functionnalities of the lodash Js library


# Supported features
At the moment, only debounce and throttle feature are supported

# How to use it
On the class you expect to use throttled and debounced methods, place the following metadata over your class 
```
@:build(lib.lodash.Lodash.build())
```

That will allow you to access to the ```@:throttle``` and ```@:debounce``` metadatas.
Those metas are to place on your methods you want to alterate the behaviour.

# Options
```haxe
@:throttle
@:throttle(500)
@:throttle(500, {leading:true})
@:throttle(500, {trailing:true})

@:debounce
@:debounce(500)
@:debounce(500, {leading:true})
@:debounce(500, {trailing:true})
@:debounce(500, {maxWait:1000, trailing:true})

```

# Cleaning

The library gives you some entry points to clean the potential debouncing/throttling callbacks. In environements like react, that could lead to some undesired behaviours when component is unmounted for example.

So here are the methods you can call to clean the remaining functions : 
```
myInstance.lodashDispose();
MyClass.lodashDisposeStatic();
```


# Npm/Yarn configuration

You have to load the lodash js file dependencies to make it work properly.
Edit your package.json file and place the following at the end of your dependencies node : 
```js
"dependencies": {
    ...
    "lodash.throttle": "^4.1.1",
    "lodash.debounce": "^4.0.8"

  },
```

And then, don't forget to run the dependencies update with npm install or yarn install.

# Demo
The current code sample if for react-native target, but it is quite self explanatory

```haxe
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.native.api.StyleSheet;

import react.native.component.View;
import react.native.component.Button;

@:build(lib.lodash.Lodash.build())
@:expose('Demo')
class Demo extends ReactComponent
{
    public static var styles = StyleSheet.create({
		container: {
			flex: 1,
			justifyContent: 'center',
			alignItems: 'stretch',
			backgroundColor: '#CCCCCC',
		},
		text: {
			fontSize: 20,
			textAlign: 'center',
			margin: 10,
		},
	});

    @:throttle(1000)
    public function onClickThrottled()
    {
        trace("click throttled");
    }

    @:debounce(1000, {trailing:true })
    public function onClickDebounced()
    {
        trace("click debounced");
    }

    override public function render() 
    {
        var styles = Demo.styles;
        return jsx('
            <View style=${styles.container}>
                <Button 
                    color="red"
                    key="0"
                    title="Click Me Throttled"
                    onPress=${onClickThrottled}
                />

                 <Button 
                    key="1"
                    color="blue"
                    title="Click Me Debounced"
                    onPress=${onClickDebounced}
                />
            </View>
        ');
    }
}
```
