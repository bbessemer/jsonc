/*
 * Public domain.
 */

/**
 * @file utf8.js
 * @author Brent Bessemer
 * created July 2017
 */

(function () {

function utf8encode (string) {
    var byte_array = new Uint8Array(string.length * 4);
    var i = 0, j = 0;
    while (i < string.length) {
        var codepoint = string.codePointAt(i++);
        if (codepoint > 0xffff) /* 4 bytes */ {
            i++;    // Due to weirdness with UTF-16.
            byte_array[j++] = 0xf0 | ((codepoint >>> 18) & 7);
            byte_array[j++] = 0x80 | ((codepoint >>> 12) & 63);
            byte_array[j++] = 0x80 | ((codepoint >>>  6) & 63);
            byte_array[j++] = 0x80 | (codepoint & 63);
        } else if (codepoint > 0x7ff) /* 3 bytes */ {
            byte_array[j++] = 0xe0 | ((codepoint >>> 12) & 15);
            byte_array[j++] = 0x80 | ((codepoint >>>  6) & 63);
            byte_array[j++] = 0x80 | (codepoint & 63);
        } else if (codepoint > 0x7f) /* 2 bytes */ {
            byte_array[j++] = 0xc0 | ((codepoint >>> 6) & 31);
            byte_array[j++] = 0x80 | (codepoint & 63);
        } else /* 1 byte (ASCII) */ {
            byte_array[j++] = codepoint;
        }
    }
    return byte_array.slice(0, j);
}

function utf8decode (byte_array) {
    var chars = new Uint32Array(byte_array.length);
    var i = 0, j = 0;
    while (i < byte_array.length) {
        var firstbyte = byte_array[i++];
        var codepoint = 0xfffd | 0; // Unicode 'replacement' character (�)
        if ((firstbyte & 0xf0) === 0xf0) /* 4 bytes */ {
            codepoint = (firstbyte & 7) << 18;
            codepoint |= (byte_array[i++] & 0x3f) << 12;
            codepoint |= (byte_array[i++] & 0x3f) << 6;
            codepoint |= (byte_array[i++] & 0x3f);
        } else if ((firstbyte & 0xe0) === 0xe0) /* 3 bytes */ {
            codepoint = (firstbyte & 0xf) << 12;
            codepoint |= (byte_array[i++] & 0x3f) << 6;
            codepoint |= (byte_array[i++] & 0x3f);
        } else if ((firstbyte & 0xc0) === 0xc0) /* 2 bytes */ {
            codepoint = (firstbyte & 0x1f) << 6;
            codepoint |= (byte_array[i++] & 0x3f);
        } else if ((firstbyte & 0x80) === 0) /* 1 byte (ASCII) */ {
            codepoint = firstbyte;
        }
        chars[j++] = codepoint;
    }
    return String.fromCodePoint.apply(String, chars.slice(0, j));
}

module.exports = {
    encode: utf8encode,
    decode: utf8decode
};

})();
