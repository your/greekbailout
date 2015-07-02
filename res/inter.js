/*
{
  "speed": "15.000 EUR/h",
  "left":"20 days",
  "date":"07/02/2015 17:31 UTC"
}
*/
function inter() {
  $( "#loading" ).addClass( "fa-spin" );
  $( "#speed" ).fadeOut( "fast" ).html( "(updating)" ).fadeIn( "fast" );
  $( "#left" ).fadeOut( "fast" ).html( "(updating)" ).fadeIn( "fast" );
  $( "#date" ).fadeOut( "fast" ).html( "(updating)" ).fadeIn( "fast" );

  $.getJSON( "res/data.json", function( data ) {
    var items = [];
    $.each( data, function( key, val ) {
      $( '#' + key ).fadeOut( "fast" ).delay( 1000 ).html( val ).fadeIn( "fast" );
      $( "#loading" ).removeClass( "fa-spin" );
    });
  });
};



