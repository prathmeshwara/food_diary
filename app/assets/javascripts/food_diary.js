// Below used statement is the shortcut for jQuery(document).ready(function() {});
$(function() {

   // For previewing image before upload.
   $('#diet_photo').change(function() {
      readURL($(this)[0]);
   });

});

function readURL(input) {
  if (input.files && input.files[0]) {
      var reader = new FileReader();

      reader.onload = function (e) {
          $('#preview_diet_photo')
              .attr('src', e.target.result)
              .width(250)
              .height(150);
      };

      reader.readAsDataURL(input.files[0]);
  }
}