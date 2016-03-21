.pragma library
function clamp(x, min, max) {
    if (x <= min)
        return min;
    if (x >= max)
        return max;
    return x;
}
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

/* Tokenizes a command into program and arguments, taking into account quoted
 * strings and backslashes.
 * Based on GLib's tokenizer, used by Gnome Terminal
 */
function tokenizeCommandLine(s){
    var args = [];
    var currentToken = "";
    var quoteChar = "";
    var escaped = false;
    var nextToken = function() {
        args.push(currentToken);
        currentToken = "";
    }
    var appendToCurrentToken = function(c) {
        currentToken += c;
    }

    for (var i = 0; i < s.length; i++) {

        // char followed by backslash, append literally
        if (escaped) {
            escaped = false;
            appendToCurrentToken(s[i]);

        // char inside quotes, either close or append
        } else if (quoteChar) {
            escaped = s[i] === '\\';
            if (quoteChar === s[i]) {
                quoteChar = "";
                nextToken();
            } else if (!escaped) {
                appendToCurrentToken(s[i]);
            }

        // regular char
        } else {
            escaped = s[i] === '\\';
            switch (s[i]) {
            case '\\':
                // begin escape
                break;
            case '\n':
                // newlines always delimits
                nextToken();
                break;
            case ' ':
            case '\t':
                // delimit on new whitespace
                if (currentToken) {
                    nextToken();
                }
                break;
            case '\'':
            case '"':
                // begin quoted section
                quoteChar = s[i];
                break;
            default:
                appendToCurrentToken(s[i]);
            }
        }
    }

    // ignore last token if broken quotes/backslash
    if (currentToken && !escaped && !quoteChar) {
        nextToken();
    }

    return args;
}
