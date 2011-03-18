
    var directionsService = new google.maps.DirectionsService();
    var hospital_position;
    var actual_position;
    var request;
    var hospital_array = [];

    window.onload = function(){
      refreshPosition();
    }
    
    function refreshPosition() {
      $('span.loader p').text('Obteniendo tu posición...');
      $('div.box').fadeOut('fast');
      $('span.loader').fadeIn('slow',function(){
        if(navigator.geolocation){
          navigator.geolocation.getCurrentPosition(handleGetCurrentPosition, handleGetCurrentPositionError);
        }
      });
    }

    function handleGetCurrentPosition(location){
      actual_position = new google.maps.LatLng(location.coords.latitude, location.coords.longitude);
      var count = 0;

      $(document).bind('load',function(){
        count++;
        if (count == hospitals.length) {
          $('span.loader').fadeOut(function(){
            
            
            var sortedKeys = new Array();
            var sortedObj = {};
            for (var i in hospital_array){
              sortedKeys.push({v:i,c:hospital_array[i]});
            }
            sortedKeys.sort(function(x,y){return y.c - x.c});
            
            for (var i in sortedKeys) {
              var element = $('#hospital_'+sortedKeys[i].v).parent().parent();
              element.insertAfter('div#box');
            }
            
            $('div.box').fadeIn();
          });
        }
      });


      $.get('/', {'lat': location.coords.latitude, 'lon': location.coords.longitude}, function(hospitals_html){
        $('span.loader p').text('Obteniendo los mapas...');
        
        
        $('div.content').append(hospitals_html);

        $.each(hospitals, function(index, hospital){
          hospital_position = new google.maps.LatLng(hospital['latitude'], hospital['longitude']);
          request = {origin:actual_position, destination:hospital_position, travelMode: google.maps.DirectionsTravelMode.DRIVING};

          directionsService.route(request, function(response, status) {
            $(document).trigger('load');
            if (status == google.maps.DirectionsStatus.OK) {
              var steps = response.routes[0].legs[0].steps;
              var path = '';
              for (var i=0; i<steps.length; i++) {
                path += steps[i].path[0].lat().toFixed(4) + "," + steps[i].path[0].lng().toFixed(4) + '|';
              }
              path = path.substr(0,path.length-2);

              var start_address = response.routes[0].legs[0].start_address.replace( / /g,'+');
              var end_address = response.routes[0].legs[0].end_address.replace( / /g,'+');
              
              
              hospital_array[hospital['cartodb_id']] = response.routes[0].legs[0].distance.value;

              $('#hospital_'+hospital['cartodb_id']).parent().attr('href','http://maps.google.com/maps?saddr='+start_address+"&daddr="+end_address);
              $('#hospital_'+hospital['cartodb_id']).parent().parent().children('p.distance').text(response.routes[0].legs[0].duration.text + ' / ' + response.routes[0].legs[0].distance.text);
              $('#hospital_'+hospital['cartodb_id']).attr('src',"http://maps.google.com/maps/api/staticmap?path=color:0xff3300ff|weight:3|"+path+"&size=240x150"+
              "&markers=color:blue|"+actual_position.lat()+","+actual_position.lng()+"&markers=color:green|label:H|"+
              response.Gf.destination.lat()+","+response.Gf.destination.lng()+"&sensor=false");
            }
          });
        });
      });
    }

    function handleGetCurrentPositionError(location){
      $('span.loader').fadeOut(function(){
        $('span.error').fadeIn();
      });
      
    }