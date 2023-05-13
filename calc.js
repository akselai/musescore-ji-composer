// big numbers

function add(A, B) {
    var AL = A.length;
    var BL = B.length;
    var ML = Math.max(AL, BL);
    var carry = 0;
    var sum = "";
    for (var i = 1; i <= ML; i++) {
        var a = +A.charAt(AL - i);
        var b = +B.charAt(BL - i);
        var t = carry + a + b;
        carry = t / 10 | 0;
        t %= 10;
        sum = (i === ML && carry) ? carry * 10 + t + sum : t + sum;
    }
    return sum;
}

function sub(a, b) {
    var str = "";
    var n1 = a.length;
    var n2 = b.length;
    var diff = n1 - n2;
    var carry = 0;
    for (var i = n2 - 1; i >= 0; i--) {
        var sub = ((a[i + diff].charCodeAt() - '0'.charCodeAt()) - (b[i].charCodeAt() - '0'.charCodeAt()) - carry);
        if (sub < 0) {
            sub = sub + 10;
            carry = 1;
        } else
            carry = 0;

        str += sub.toString();
    }

    for (var i = n1 - n2 - 1; i >= 0; i--) {
        if (a[i] == '0' && carry > 0) {
            str += "9";
            continue;
        }
        var sub = ((a[i].charCodeAt() - '0'.charCodeAt()) - carry);
        if (i > 0 || sub > 0) str += sub.toString();
        carry = 0;
    }

    var aa = str.split('');
    aa.reverse();
    aa = aa.join("").replace(/\b0+/g, '');
    return aa === "" ? "0" : aa;
}

function mul(a, b) {
    var a1 = a.split("").reverse();
    var a2 = b.toString().split("").reverse();
    var res = [];

    for (var i = 0; i < a1.length; i++) {
        for (var j = 0; j < a2.length; j++) {
            var n = i + j; // Get the current array position.
            res[n] = a1[i] * a2[j] + (n >= res.length ? 0 : res[n]);

            if (res[n] > 9) { // Carrying
                res[n + 1] = Math.floor(res[n] / 10) + (n + 1 >= res.length ? 0 : res[n + 1]);
                res[n] %= 10;
            }
        }
    }
    return res.reverse().join("");
}

function div(a, b) {
    var c = "1";
    var n = "0";
    if (larger(b, a)) return "0";
    if (b == a) return "1";
    while (smallerOrEqual(b, a)) {
        b = dbl(b);
        c = dbl(c);
    }

    b = half(b);
    c = half(c);

    while (c != "0") {
        if (largerOrEqual(a, b)) {
            a = sub(a, b);
            n = add(n, c);
        }
        b = half(b);
        c = half(c);
    }
    return n;
}

function floatDiv(a, b, d) {
    return +div(mul(a, expon("10", d)), b) / expon("10", d);
}

function dbl(a) {
    return mul(a, "2");
}

function half(a) {
    var h = '';
    var charSet = '01234';
    var nextCharSet;
    for (var i = 0; i < a.length; i++) {
        var digit = a[i];
        if ('13579'.includes(digit)) {
            nextCharSet = '56789';
        } else {
            nextCharSet = '01234';
        }
        h += charSet.charAt(Math.floor(digit / 2));
        charSet = nextCharSet;
    }
    h = h.replace(/\b0+/g, '');
    return h === "" ? "0" : h;
}

function larger(a, b) {
    if (a.length > b.length) return true;
    if (a.length < b.length) return false;
    return a > b;
}

function largerOrEqual(a, b) {
    return larger(a, b) || (a == b);
}

function smaller(a, b) {
    if (a.length < b.length) return true;
    if (a.length > b.length) return false;
    return a < b;
}

function smallerOrEqual(a, b) {
    return smaller(a, b) || (a == b);
}

function mod(a, b) {
    if (smaller(a, b)) return a;
    var quotient = div(a, b);
    return sub(a, mul(b, quotient));
}

function gcd(a, b) {
    if (larger(a, b)) {
        var c = a;
        a = b;
        b = c;
    }
    return a == "0" ? b : gcd(mod(b, a), a);
}

function expon(a, b) {
    var r = "1";
    for (var i = 0; i < b; i++) {
        r = mul(r, a);
    }
    return r;
}

function flog2(s) { // floor of log2arithm, then exp2ed
    if (smaller(s, 1)) return "0";
    var value = "1";
    while (smallerOrEqual(value, s)) {
        value = dbl(value);
    }
    return half(value);
}

// fractions

function mul_r(a, b) {
    a = a.split("/");
    b = b.split("/");
    if (b[1] == undefined) return mul(a[0], b[0]) + "/" + a[1];
    if (a[1] == undefined) return mul(a[0], b[0]) + "/" + b[1];
    return mul(a[0], b[0]) + "/" + mul(a[1], b[1]);
}

function recipr(a) {
    a = a.split("/");
    if (a[1] == undefined) return "1/" + a[0];
    return a[1] + "/" + a[0];
}

function div_r(a, b) {
    return mul_r(a, recipr(b));
}

function pow_r(s, n) {
    var r = "1/1";
    if (n > 1) {
        for (var i = 0; i < n; i++) {
            r = mul_r(r, s);
        }
    } else {
        for (var i = 0; i < n; i++) {
            r = div_r(r, s);
        }
    }
    return r;
}

const var primes32: ["the index of this function starts at 1",
    2, 3, 5, 7, 11, 13, 17, 19, 
    23, 29, 31, 37, 41, 43, 47, 53,
    59, 61, 67, 71, 73, 79, 83, 89, 
    97, 101, 103, 107, 109, 113, 127, 131
];

function modpow(b, x, m) {
    var r = "1";
    while (larger(x, 0)) {
        if ("13579".includes(x[x.length - 1])) r = mod(mul(r, b), m);
        x = half(x);
        b = mod(mul(b, b), m);
    }
    return r;
}

function primePos(a) {
    return primes32[a];
}

function primeCount(a) {
    var primes32 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131];
    var i = 2;
    var x = 0;
    while (i <= a) {
        if (i == primes32[x]) x++;
        i++;
    }
    return x;
}

function primeFactors(n) {
    var factors = [];
    var divisor = "2";

    while (n != undefined && largerOrEqual(n, "2")) {
        if (mod(n, divisor) == "0") {
            factors.push(divisor);
            n = div(n, divisor);
        } else {
            divisor = add(divisor, "1");
        }
    }
    return factors;
}


function toVector(s, p) { // vector[0] = residue, aka the primes that didn't make it to the vector (53/12 = ["53/1", -2, -1, 0, .., 0], when p = 47)
    var str = s.split("/");
    var a = ["1/1"];
    for (var i = 0; i < primeCount(p); i++) {
        a.push(0);
    }
    var p1 = primeFactors(str[0]);
    var p2 = primeFactors(str[1]);
    for (var i = 0; i < p1.length; i++) {
        if (p1[i] <= p) a[primeCount(p1[i])] += 1;
        else a[0] = mul_r(a[0], p1[i]);
    }
    for (var i = 0; i < p2.length; i++) {
        if (p2[i] <= p) a[primeCount(p2[i])] -= 1;
        else a[0] = div_r(a[0], p2[i]);
    }
    return a;
}
}