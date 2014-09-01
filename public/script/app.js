
/* Application javascript */
$(document).ready( function(){
    if ($('.datepicker_form').length>0) {
        $(function() {
            $( "#from" ).datepicker({
                changeMonth: true,
                dateFormat: "yy-mm-dd",
                onClose: function( selectedDate ) {
                    $( "#to" ).datepicker( "option", "minDate", selectedDate );
                }
            });
            $( "#to" ).datepicker({
                changeMonth: true,
                dateFormat: "yy-mm-dd",
                onClose: function( selectedDate ) {
                    $( "#from" ).datepicker( "option", "maxDate", selectedDate );
                }
            });
        });
    }
    if($("#orders_table").length != 0){
        $(function(){
            $("#orders_table").tablesorter();
        });
    }
    if($("#client_list").length != 0){
        $(function(){
            $("#client_list").tablesorter();
        });
    }
    $('#live_search').on("keyup", function() {
        var value = $(this).val().toLowerCase();
        $("table tr").each(function(index) {
            if (index != 0) {

                $row = $(this);

                var id = $row.text().toLowerCase();
                if (id.search(value) > 0) {
                    $(this).show();
                }
                else {
                    $(this).hide();
                }
            }
        });
    });    
    $(".hide_section").click(function(){
        $('#add_new_client').hide();
    });
    $(".show_section").click(function(){
        $('#add_new_client').show();
    });
});