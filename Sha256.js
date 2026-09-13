.pragma library

function randomSalt() {
  var chars = "0123456789abcdef";
  var res = "";
  for (var i = 0; i < 32; i++) {
    res += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return res;
}

function utf8Encode(str) {
  return unescape(encodeURIComponent(str));
}

function sha256Raw(str) {
  function rightRotate(value, amount) {
    return (value >>> amount) | (value << (32 - amount));
  }

  var mathPow = Math.pow;
  var maxWord = mathPow(2, 32);
  var i, j;
  var words = [];
  var asciiBitLength = str.length * 8;

  var hash = [];
  var k = [];
  var primeCounter = 0;

  var isComposite = {};
  for (var candidate = 2; primeCounter < 64; candidate++) {
    if (!isComposite[candidate]) {
      for (i = candidate * candidate; i < 312; i += candidate) {
        isComposite[i] = true;
      }
      if (primeCounter < 8) {
        hash[primeCounter] = (mathPow(candidate, 0.5) * maxWord) | 0;
      }
      k[primeCounter] = (mathPow(candidate, 1 / 3) * maxWord) | 0;
      primeCounter++;
    }
  }

  str += "\x80";
  while ((str.length % 64) - 56) str += "\x00";
  for (i = 0; i < str.length; i++) {
    j = str.charCodeAt(i);
    words[i >> 2] |= j << (((3 - i) % 4) * 8);
  }
  words[words.length] = (asciiBitLength / maxWord) | 0;
  words[words.length] = asciiBitLength;

  for (j = 0; j < words.length; ) {
    var w = words.slice(j, (j += 16));
    var oldHash = hash.slice(0);

    for (i = 0; i < 64; i++) {
      var w15 = w[i - 15], w2 = w[i - 2];
      var s0 = rightRotate(w15, 7) ^ rightRotate(w15, 18) ^ (w15 >>> 3);
      var s1 = rightRotate(w2, 17) ^ rightRotate(w2, 19) ^ (w2 >>> 10);
      w[i] = (i < 16) ? w[i] : (w[i - 16] + s0 + w[i - 7] + s1) | 0;

      var s1_h = rightRotate(hash[4], 6) ^ rightRotate(hash[4], 11) ^ rightRotate(hash[4], 25);
      var ch = (hash[4] & hash[5]) ^ (~hash[4] & hash[6]);
      var temp1 = (hash[7] + s1_h + ch + k[i] + w[i]) | 0;
      var s0_h = rightRotate(hash[0], 2) ^ rightRotate(hash[0], 13) ^ rightRotate(hash[0], 22);
      var maj = (hash[0] & hash[1]) ^ (hash[0] & hash[2]) ^ (hash[1] & hash[2]);
      var temp2 = (s0_h + maj) | 0;

      hash[7] = hash[6];
      hash[6] = hash[5];
      hash[5] = hash[4];
      hash[4] = (hash[3] + temp1) | 0;
      hash[3] = hash[2];
      hash[2] = hash[1];
      hash[1] = hash[0];
      hash[0] = (temp1 + temp2) | 0;
    }

    for (i = 0; i < 8; i++) {
      hash[i] = (hash[i] + oldHash[i]) | 0;
    }
  }

  var raw = "";
  for (i = 0; i < 8; i++) {
    for (j = 3; j >= 0; j--) {
      raw += String.fromCharCode((hash[i] >> (8 * j)) & 255);
    }
  }
  return raw;
}

function hexFromRaw(raw) {
  var result = "";
  for (var i = 0; i < raw.length; i++) {
    var b = raw.charCodeAt(i) & 255;
    result += (b < 16 ? "0" : "") + b.toString(16);
  }
  return result;
}

function sha256(str) {
  return hexFromRaw(sha256Raw(utf8Encode(str)));
}

function hmacSha256(key, message) {
  var k = utf8Encode(key);
  var m = utf8Encode(message);
  if (k.length > 64) {
    k = sha256Raw(k);
  }
  while (k.length < 64) {
    k += "\x00";
  }
  var oKeyPad = "";
  var iKeyPad = "";
  for (var i = 0; i < 64; i++) {
    var c = k.charCodeAt(i);
    oKeyPad += String.fromCharCode(c ^ 0x5c);
    iKeyPad += String.fromCharCode(c ^ 0x36);
  }
  var innerHash = sha256Raw(iKeyPad + m);
  var outerHash = sha256Raw(oKeyPad + innerHash);
  return hexFromRaw(outerHash);
}
