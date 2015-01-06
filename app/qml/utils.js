.pragma library

function lint(a, b, t) {
    return (1 - t) * a + (t) * b;
}
function mix(c1, c2, alpha){
    return Qt.rgba(c1.r * alpha + c2.r * (1-alpha),
                   c1.g * alpha + c2.g * (1-alpha),
                   c1.b * alpha + c2.b * (1-alpha),
                   c1.a * alpha + c2.a * (1-alpha))
}
function strToColor(s){
    var r = parseInt(s.substring(1,3), 16) / 256;
    var g = parseInt(s.substring(3,5), 16) / 256;
    var b = parseInt(s.substring(5,7), 16) / 256;
    return Qt.rgba(r, g, b, 1.0);
}
