function validCheckDigit(barcode) {
    if ((/^\d+$/.test(barcode))) {
        check = barcode.slice(-1);
        sum = 0;
        var pairs = barcode.split("").reverse().join('').match(/.{1,2}/g);
        for (i in pairs) {
            o = parseInt(pairs[i][1] * 2);
            sum += parseInt(o > 9 ? Math.floor(o / 10) + (o % 10) : o);
            sum += parseInt(pairs[i][0]);
        }
        sum -= check;
        return (sum * 9) % 10 == check;
    } else {
        return false;
    }
}

function markInvalid(barcodeEl) {
    barcodeEl.addClass("bad_barcode");
}

function markValid(barcodeEl) {
    barcodeEl.removeClass("bad_barcode");
}
function isValidBarcode(barcode) {
	isValidBarcode(barcode, false);
}
function isValidBarcode(barcode, mdpi) {
    sd = mdpi == true ? 4 : 3
    return barcode.length == 14 && barcode.charAt(0) == sd && validCheckDigit(barcode);
}

function validateIUBarcode(barcodeEl) {
    if (isValidBarcode(barcodeEl.val(), false)) {
        markValid(barcodeEl);
	      return true;
    } else {
        markInvalid(barcodeEl);
	      return false;
    }
}

function validateMdpiBarcode(barcodeEl) {
    if (isValidBarcode(barcodeEl.val(), true)) {
        markValid(barcodeEl);
    } else {
        markInvalid(barcodeEl);
    }
}

