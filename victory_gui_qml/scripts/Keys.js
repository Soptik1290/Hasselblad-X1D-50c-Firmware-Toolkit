Qt.include("KeyMapsWedge.js")
function log(key)
{
    for(var i in CAMKEYS) {
        var v = CAMKEYS[i]
        var arr = v.key
        if(arr.indexOf(key) !== -1)
            console.log("key pressed:", v.name, v.key)
    }
}
function camFnFromKey(key)
{
    for(var i in CAMKEYS) {
        var v = CAMKEYS[i]
        if(v.key === key)
            return v
    }
    return null
}
function pressedFn(name, key)
{
    var v = CAMKEYS[name]
    if(undefined === v)
        return false
    var arr = v.key
    return undefined !== arr && (arr.indexOf(key) !== -1)
}
function pressedFnAcc(name, event)
{
    if(pressedFn(name, event.key)) {
        event.accepted = true
        return true
    }
    return false
}
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
