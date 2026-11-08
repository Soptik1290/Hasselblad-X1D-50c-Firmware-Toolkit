.pragma library
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
