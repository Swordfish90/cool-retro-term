import QtQuick 2.0
import QtTest 1.0
import "../../app/qml/utils.js" as Utils

TestCase {
    name: "UtilsTests"

    // ==================== clamp() tests ====================

    function test_clamp_within_range() {
        compare(Utils.clamp(5, 0, 10), 5)
    }

    function test_clamp_at_min() {
        compare(Utils.clamp(0, 0, 10), 0)
    }

    function test_clamp_at_max() {
        compare(Utils.clamp(10, 0, 10), 10)
    }

    function test_clamp_below_min() {
        compare(Utils.clamp(-5, 0, 10), 0)
    }

    function test_clamp_above_max() {
        compare(Utils.clamp(15, 0, 10), 10)
    }

    function test_clamp_negative_range() {
        compare(Utils.clamp(0, -10, -5), -5)
    }

    function test_clamp_float() {
        compare(Utils.clamp(0.5, 0.0, 1.0), 0.5)
    }

    // ==================== lint() tests ====================

    function test_lint_at_zero() {
        compare(Utils.lint(0, 10, 0), 0)
    }

    function test_lint_at_one() {
        compare(Utils.lint(0, 10, 1), 10)
    }

    function test_lint_at_half() {
        compare(Utils.lint(0, 10, 0.5), 5)
    }

    function test_lint_negative() {
        compare(Utils.lint(-10, 10, 0.5), 0)
    }

    // ==================== smoothstep() tests ====================

    function test_smoothstep_below_min() {
        compare(Utils.smoothstep(0, 1, -1), 0)
    }

    function test_smoothstep_above_max() {
        compare(Utils.smoothstep(0, 1, 2), 1)
    }

    function test_smoothstep_at_min() {
        compare(Utils.smoothstep(0, 1, 0), 0)
    }

    function test_smoothstep_at_max() {
        compare(Utils.smoothstep(0, 1, 1), 1)
    }

    function test_smoothstep_at_half() {
        compare(Utils.smoothstep(0, 1, 0.5), 0.5)
    }

    // ==================== strToColor() tests ====================

    function test_strToColor_black() {
        var c = Utils.strToColor("#000000")
        compare(c.r, 0)
        compare(c.g, 0)
        compare(c.b, 0)
    }

    function test_strToColor_white() {
        var c = Utils.strToColor("#ffffff")
        // 255/256 = 0.99609375
        verify(c.r > 0.99)
        verify(c.g > 0.99)
        verify(c.b > 0.99)
    }

    function test_strToColor_red() {
        var c = Utils.strToColor("#ff0000")
        verify(c.r > 0.99)
        compare(c.g, 0)
        compare(c.b, 0)
    }

    // ==================== tokenizeCommandLine() tests ====================

    function test_tokenize_empty() {
        var result = Utils.tokenizeCommandLine("")
        compare(result.length, 0)
    }

    function test_tokenize_simple() {
        var result = Utils.tokenizeCommandLine("echo hello")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello")
    }

    function test_tokenize_multiple_args() {
        var result = Utils.tokenizeCommandLine("ls -la /tmp")
        compare(result.length, 3)
        compare(result[0], "ls")
        compare(result[1], "-la")
        compare(result[2], "/tmp")
    }

    function test_tokenize_double_quotes() {
        var result = Utils.tokenizeCommandLine('echo "hello world"')
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello world")
    }

    function test_tokenize_single_quotes() {
        var result = Utils.tokenizeCommandLine("echo 'hello world'")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello world")
    }

    function test_tokenize_escaped_space() {
        var result = Utils.tokenizeCommandLine("echo hello\\ world")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello world")
    }

    function test_tokenize_multiple_spaces() {
        var result = Utils.tokenizeCommandLine("echo    hello")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello")
    }

    function test_tokenize_tabs() {
        var result = Utils.tokenizeCommandLine("echo\thello")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello")
    }

    function test_tokenize_mixed_quotes() {
        var result = Utils.tokenizeCommandLine("echo \"it's\" 'a \"test\"'")
        compare(result.length, 3)
        compare(result[0], "echo")
        compare(result[1], "it's")
        compare(result[2], "a \"test\"")
    }

    function test_tokenize_escaped_quote_in_double() {
        var result = Utils.tokenizeCommandLine('echo "hello\\"world"')
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], 'hello"world')
    }

    function test_tokenize_newline_delimits() {
        var result = Utils.tokenizeCommandLine("echo\nhello")
        compare(result.length, 2)
        compare(result[0], "echo")
        compare(result[1], "hello")
    }

    function test_tokenize_complex_command() {
        var result = Utils.tokenizeCommandLine('bash -c "echo hello && ls -la"')
        compare(result.length, 3)
        compare(result[0], "bash")
        compare(result[1], "-c")
        compare(result[2], "echo hello && ls -la")
    }

    function test_tokenize_trailing_backslash_ignored() {
        // Trailing backslash means incomplete escape - token should be ignored
        var result = Utils.tokenizeCommandLine("echo hello\\")
        compare(result.length, 1)
        compare(result[0], "echo")
    }

    function test_tokenize_unclosed_quote_ignored() {
        // Unclosed quote means incomplete token - should be ignored
        var result = Utils.tokenizeCommandLine('echo "hello')
        compare(result.length, 1)
        compare(result[0], "echo")
    }
}
