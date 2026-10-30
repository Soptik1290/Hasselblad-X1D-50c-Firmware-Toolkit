.pragma library

/*
  Put common helper functions in this js file to avoid code duplication with inline js in qml.
  It is a stateless library so it will be instantiated only once.
  As it is shared, it cannot access QML component instance objects or properties directly,
  although QML values can be passed as function parameters.
*/


// Calculate a string from given time expressed in seconds. The resulting string will be formatted
// as that of an exposure time length in seconds, minutes and hours.
function tdur(s1)
{
    var h1 = Math.floor(s1 / (60 * 60));
    s1 %= 60 * 60;
    var m1 = Math.floor(s1 / 60);
    s1 %= 60;
    var h2 = h1 ? h1+ ':' : ''
    var m2 = h1 && (m1 < 10) ? '0' + m1 : m1 ? m1 : ''
    var s2 = (h1 || m1) ? (':' + ((s1 < 10) ? '0' + s1 : s1)) : s1

    return h2 + m2 + s2;
}

var exposureButtonPos = Qt.point(-1, -1)
