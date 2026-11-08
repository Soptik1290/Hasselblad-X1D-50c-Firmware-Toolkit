Qt.include(guiconfig.keyMapsName)

// Helper functions for key mappings from key to camera function specific to model.

// Given the pressed event.key keycode, the key's (if found) possible camera key map functions are logged to the display.
function log(key)
{
    for(var i in CAMKEYS) {
        var v = CAMKEYS[i]
        var arr = v.key
        if(arr.indexOf(key) !== -1)
            console.log("key pressed:", v.name, v.key)
    }
}


// Given the pressed event.key keycode, the key function (if found) is returned as an object.
function camFnFromKey(key)
{
    for(var i in CAMKEYS) {
        var v = CAMKEYS[i]
        if(v.key === key)
            return v
    }
    return null
}


// Given the pressed event.key keycode and expected function's name, this function returns true if the given key was pressed.
function pressedFn(name, key)
{
    var v = CAMKEYS[name]
    if(undefined === v)
        return false
    var arr = v.key
    return undefined !== arr && (arr.indexOf(key) !== -1)
}


// Given the pressed event and expected function's name, this function returns true if the given key was pressed.
// AND if matched, it automatically accepts the event so it's not sent for further processing on lower focus levels.
function pressedFnAcc(name, event)
{
    if(pressedFn(name, event.key)) {
        event.accepted = true
        return true
    }
    return false
}


// Given the pressed event.key keycode and expected key functions label, the function returns true if the given key was pressed.
function pressedLabel(label, key)
{
    for(var i in CAMKEYS) {
        var v = CAMKEYS[i]
        if(undefined === v)
            return false
        var arr = v.key
        if(undefined !== arr && label === v.name)
            return arr.indexOf(key) !== -1;
    }
    return false
}
