$( document ).ready(function() {
	$( "#notice" ).hide();
	$( "#notice" ).show("slide", { direction: "up" }, "slow")
	$.ajaxSetup({ cache: false });
	inter();
});

var data = []

function inter() {
  $( "#loading" ).addClass( "fa-spin" );
  $.getJSON( "res/data.json", function( data ) {
    var items = [];
    $.each( data, function( key, val ) {
      $( '#' + key ).fadeOut( "fast" ).html( val ).fadeIn( "fast" );
      $( "#loading" ).removeClass( "fa-spin" );
    });
  });
  $.getJSON( "res/graph.json", function( data ) {
	  console.log(data);
	  graph( d3, data );
  });
};

function graph( d3, data ) {
  function visualizeTimeline( selector, data ) {
    var d3container = d3.select( selector ),
        width       = d3container.attr( 'width' ),
        height      = d3container.attr( 'height' ),
        margin      = { top : 5, right : 0, bottom : 30, left : 0 },
        svg         = d3container.append( 'svg' )
                                  .attr( 'height', height )
                                  .attr( 'width', width ),
    
        x     = d3.scale.ordinal()
                        .rangeRoundBands( [ 0, width ] )
                        .domain(
                          data.map( function( d ) { return d.date; } )
                        ),
        xAxis = d3.svg.axis().scale( x ).orient( 'bottom' ),
        
        y     = d3.scale.linear()
                        .range( [ height - margin.bottom * 1.5, margin.top ] )
                        .domain(
                          [ 0, d3.max( data, function( d ) { return d.value; } ) ]
                        ),
        yAxis = d3.svg.axis().scale( y ).orient( 'left' ),
        
        xAxisGroup,
        yAxisGroup,
        
        // animation stuff,
        duration = 3000;
    
    xAxisGroup = svg.append( 'g' )
                    .attr( 'class', 'x axis' )
                    .attr( 'transform', 'translate( 0,' + ( height - margin.bottom ) + ')' )
                    .transition()
                    .call( xAxis );
    
    /* For the drop shadow filter... */
    var defs = svg.append( 'defs' );

    var filter = defs.append( 'filter' )
                      .attr( 'id', 'dropshadowArea' )

    filter.append( 'feGaussianBlur' )
          .attr( 'in', 'SourceAlpha' )
          .attr( 'stdDeviation', 3 )
          .attr( 'result', 'blur' );
    filter.append( 'feOffset' )
          .attr( 'in', 'blur' )
          .attr( 'dx', 2 )
          .attr( 'dy', 2 )
          .attr( 'result', 'offsetBlur' );

    var feMerge = filter.append( 'feMerge' );

    feMerge.append( 'feMergeNode' )
            .attr( 'in", "offsetBlur' )
    feMerge.append( 'feMergeNode' )
            .attr( 'in', 'SourceGraphic' );
    // end filter stuff
    
    drawArea(
      svg,
      data.filter(
        function( datum ) { return datum.type === 'wt'; }
      ),
      'cyan',
      0
    );
    
    function drawArea( svg, data, className, index ) {
      var area = d3.svg.area()
                        .x( function( d ) { return x( d.date ) + x.rangeBand() / 2 ; } )
                        .y0( height - margin.bottom * 1.5 )
                        .y1( function( d ) { return y( d.value ); } )
                        .interpolate( 'cardinal' ),
          startData = [];
      
      data.forEach( function( datum ) {
        startData.push( { date : datum.date, value : 0 } );
      } );
      
      svg.append( 'path' )
          .datum( startData )
          .attr( 'class', 'timeline_area ' + className )
          .attr( 'd', area )
          .attr( 'filter', 'url(#dropshadowArea)' )
          .transition()
          .delay( 1000 * index )   
          .duration( duration )
          .attrTween( 'd', tweenArea( data ) );
      
      function tweenArea( b ) {
        return function( a ) {
          var i = d3.interpolateArray( a, b );          
          a.forEach( function( datum, index ) {
            a[ index ] = b[ index ]
          } );

          return function( t ) {
            return area( i ( t ) );
          };
        };
      }
    }
  }
  visualizeTimeline( '.timeline', data );
}



