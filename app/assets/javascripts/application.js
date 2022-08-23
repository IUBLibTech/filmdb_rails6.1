// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/widgets/autocomplete
//= require turbolinks
//= require jquery-ui
//= require jquery_nested_form
//= require sweet_alerts/dist/sweetalert.min
//= require_self
//= require_tree .


//Override the default confirm dialog by rails
$.rails.allowAction = function(link){
    if (link.data("confirm") == undefined){
        return true;
    }
    $.rails.showConfirmationDialog(link);
    return false;
}
//User click confirm button
$.rails.confirmed = function(link){
    link.data("confirm", null);
    link.trigger("click.rails");
}
//Display the confirmation dialog
$.rails.showConfirmationDialog = function(link){
    var message = link.data("confirm");
    swal({
        title: message,
        type: 'warning',
        confirmButtonText: 'Sure',
        confirmButtonColor: '#2acbb3',
        showCancelButton: true
    },
    function(isConfirm){
        if (isConfirm) {
            $.rails.confirmed(link);
        } else  {
            swal.close();
        }
    });
}

function showLoad(jqSelector, scale) {
	jqSelector.after("<div class='loader right' style='zoom: %{scale}; -moz-transform: scale(%{scale})'></div>");
}
function hideLoader(jqSelector) {
	jqSelector.find('.loader').remove();
}

function hookBarcodeValidators() {
    // validator for the IU barcode field
    if (typeof medium === 'undefined') {
        $("#iu_barcode").bind("input", function () {
            validateIUBarcode($(this));
        });
        $("#mdpi_barcode").bind("input", function () {
            validateMdpiBarcode($(this));
        });
    } else {
        $("#" + medium + "_iu_barcode").bind("input", function () {
            validateIUBarcode($(this));
        });
        // validator for MDPI barcode field
        $("#" + medium + "_mdpi_barcode").bind("input", function () {
            validateMdpiBarcode($(this));
        });
    }
}

