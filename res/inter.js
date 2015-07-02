/*
{
  "speed": "15.000 EUR/h",
  "left":"20 days",
  "date":"07/02/2015 17:31 UTC"
}
*/
function inter() {
  $( "#loading" ).addClass( "fa-spin" );
  $.getJSON( "res/data.json", function( data ) {
    var items = [];
    $.each( data, function( key, val ) {
      $( '#' + key ).fadeOut( 1000 );
      $( '#' + key ).html( val );
      $( '#' + key ).fadeIn( 1000 );
      $( "#loading" ).removeClass( "fa-spin" );
    });
  });
};



