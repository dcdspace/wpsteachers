//FOR SOMEONE GRADING WHO DOES NOT KNOW JAVASCRIPT, THIS IS IT...

$(function() {
    $('#search_input').fastLiveFilter('#teacherList');
    $('.error').hide();
    $(".submitReview").click(function(event) {
        // validate and process form here
        // alert(event.target.id);
        $('.error').hide();
        var teacherID = event.target.id;
        var body = $("#reviewBody" + teacherID).val();
        var formID = "#reviewForm" + teacherID;
        var rating = $('input[name=rating]:checked', formID).val();
        console.log("Teacher ID:" + teacherID);
        console.log("Rating:" + rating);
        if (rating == undefined) {
            $("label#reviewRatingError" + teacherID).fadeIn();
            //alert("label#body_error" + entryID);
            //alert(body);
            $("#reviewInputBox" + teacherID).addClass("has-error");
            return false;
        }
        if (body == "") {
            $("label#reviewBodyError" + teacherID).fadeIn();
            //alert("label#body_error" + entryID);
            //alert(body);
            $("#reviewInputBox" + teacherID).addClass("has-error");
            $("#reviewBody" + teacherID).focus();
            return false;
        }

        $("#reviewInputBox").removeClass("has-error");

        $("#loading" + teacherID).html("<img src='/pics/loading.gif'>");
        var dataString = 'body='+ body + '&rating=' + rating + '&teacherID=' + teacherID;
//alert (dataString);return false;
        $.ajax({
            type: "POST",
            url: "/post/create",
            data: dataString,
            success: function(html) {
                html = $(html);
                console.log(html);
                setTimeout(function (){
                    $("#loading" + teacherID).empty();
                    $("#reviewBody" + teacherID).val("");
                    $('input[name=rating]:checked', formID).removeAttr('checked');
                    //$('#commentForm').before(html).fadeIn('slow');
                    (html).hide().prependTo('#teacherRatings' + teacherID).slideDown("slow");
                }, 1000);
                console.log(html);


            }
        });
        return false;

    });

});