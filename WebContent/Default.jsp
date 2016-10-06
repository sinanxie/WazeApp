<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>WazeApp</title>

<style>
	#map {
			display: block;
			left: 0;
			margin-left: 250px; 
			top: 0px;
	        width: calc(100% - 250px);
	        height: 100%;
	        position: absolute;   
	      }
</style>

<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="https://maps.googleapis.com/maps/api/js"></script>
<script>
	var mapCanvas = document.getElementById('map');
	var mapOptions = {
		center: new google.maps.LatLng(37.0000, -120.0000),
		zoom: 7,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	var map;
	var marker;
	var markers = [];
	var infoWindow;
	var Direction_infoWindows = [];
	
	var polyline_adj;
	var polyline_path1;
	var polyline_path2;
	var polyline_path3;

	var NodeID,Latitude,Longitude;		//	Info of selected node
	var flag_Direction = 0;				// --1: Direction mode
	var Direction_counter = 0;			//	Direction count nodes
	
	var Directions_Nodes = [];			//	Store the two nodes - zoom the map to fit both nodes into the map
	
	var CountClickPath1 = 0;			//	Flag: click on path table
	var CountClickPath2 = 0;
	var CountClickPath3 = 0;

	
	//------------------------------------------------------------------
	// 	Init when <body> is loaded
	// 	Add Row Handler to PathTable
	//	Send XMLHttpRequest() to get nodes and edges info in a XML form
	//------------------------------------------------------------------
	function initList(){				//	send XMLHttpRequest() to get nodes and edges info in a XML form
		addRowHandlers();				//	
		var xhr;
		if(window.XMLHttpRequest)
			xhr = new XMLHttpRequest();
		else if(window.ActiveObject)
			xhr = new ActiveObject("Microsoft.XMLHTTP");
		xhr.open("get","WazeAppServletPath?NodeID=&NodeID1=",true);
		xhr.onreadystatechange = function(){
			if(xhr.status==200 && xhr.readyState == 4){
				parseXML2Map(xhr.responseXML);				//	pass the XML to function parseXML2Map
			}
		}
		xhr.send(null);
	}
	
	//------------------------------------------------------------------
	// 	Analyse the XML form file
	//	Draw nodes(markers), add listeners to each marker
	//	Draw edges(polyline)
	//------------------------------------------------------------------
	function parseXML2Map(xml){
		// Draw Nodes
		var items = xml.getElementsByTagName("Nodes");			// Draw Nodes
		for (var i=0;i<items.length;i++){
			var NodeID = items[i].getElementsByTagName("NodeID")[0].childNodes[0].nodeValue;
			var dLatitude = items[i].getElementsByTagName("Latitude")[0].childNodes[0].nodeValue;
			var dLongitude = items[i].getElementsByTagName("Longitude")[0].childNodes[0].nodeValue;			    				
			var myLatLng = new google.maps.LatLng(dLatitude,dLongitude);		    				
			
        	marker = new google.maps.Marker({				// create a marker and set id
        		id: NodeID,
        	    position: myLatLng,
        	    map: map,
        	    title: "NodeID:"+NodeID+";\n"+"Latitude:"+dLatitude+";\n"+"Longitude:"+dLongitude+";",
        	    icon:'https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0',			    //	little red dot icon
        	  });
        	markers[NodeID] = marker;				// cache created marker to markers object with id as its key
        	
        	//-------------------------------------------------------------------------
        	//	Add listeners to each marker
        	//-------------------------------------------------------------------------
        	google.maps.event.addListener(marker, 'click', function(){
        		if(flag_Direction==0){									//	Remove the highlighted roads when click on another marker
    				if(polyline_adj!=null){
    					polyline_adj.setMap(null);						//	edges of the last selected node
    				}
    				var NodeID_temp = document.getElementById("NodeID").value;
    				var marker_temp = markers[NodeID_temp];					// Change back the color of marker
    				if(marker_temp!=null){
 						marker_temp.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
    				}
    			}
        		
        	    var str = this.getTitle();
        		console.log(str);
        		var split = str.split(';');						//	Show the info of selected node in the textfield
        		$('#NodeID').val(split[0].split(':')[1]);
        		$('#Latitude').val(split[1].split(':')[1]);
        		$('#Longitude').val(split[2].split(':')[1]);
        		
				 //	*** If not in Direction Mode ***
        		if (flag_Direction==0){		
        			map.setZoom(12);						//	Zoom after clicking
            	    map.setCenter(this.getPosition());
        			this.setIcon('https://www.google.com/mapfiles/marker_green.png');	//	Change selected node color to green
        			
        			if(infoWindow!=null)
        				infoWindow.close();
        			infoWindow = new google.maps.InfoWindow({
        			    content: '<table><tr><td align="left">Node ID:</td><td align="left">'+ split[0].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Latitude:</td><td align="left">'+ split[1].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Longitude:</td><td align="left">'+ split[2].split(':')[1]+'</td></tr></table>'
        			  });
        			infoWindow.open(map, this);
        			
        			HighlightRequest();							//	Send the request to Server
        		}
				
				//	*** If in Direction Mode ***
        		else{
        			var NodeID1 = document.getElementById("NodeID1").value;
        			var marker1 = markers[NodeID1];
        			var NodeID2 = document.getElementById("NodeID2").value;
        			var marker2 = markers[NodeID2];
        			if (this==marker1) {
        				Direction_infoWindows[0].open(map,this);
        			}
        			else if (this == marker2) {
        				Direction_infoWindows[1].open(map,this);
        			}
        			else{
/*         				map.setZoom(11);						//	Zoom after clicking
                	    map.setCenter(this.getPosition()); */
        			if (Direction_counter==0){							//	*** If it is the 1st node selected ***
        				var NodeID1 = document.getElementById("NodeID1").value;
        				if (polyline_path1!=null){							//	If highlighted the adjacent edges
        					ResetShortestPaths();
        				}
        				if (NodeID1!=""){								//	*** If there is data remaining from the last time running Direction ***
	        				var marker1 = markers[NodeID1];				//	Locate last two nodes and reset the color to yellow
	        				marker1.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
	        				var NodeID2 = document.getElementById("NodeID2").value;
	        				var marker2 = markers[NodeID2];
							marker2.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
	        				Directions_Nodes = [];						//	Reset the Directions_Nodes[]
	        				
	        				Direction_infoWindows[0].close();
	        				Direction_infoWindows[1].close();
	        				if (polyline_path1!=null){							//	If highlighted K shortest paths
	        					ResetShortestPaths();
	        				}
        				}
        				Directions_Nodes[0] = this;						//	Store selected marker (zoom out/in to fit both nodes into the map)
        				this.setIcon('https://www.google.com/mapfiles/marker_green.png');	// Set selected node color to green
        				ClearDirectionInfo();							//	Clear the TextField
        							
    					Direction_infoWindows[0] = new google.maps.InfoWindow({
//            			    content: this.getTitle()
							content: '<strong>Node 1 </strong><br>' +
								'<table><tr><td align="left">Node ID:</td><td align="left">'+ split[0].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Latitude:</td><td align="left">'+ split[1].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Longitude:</td><td align="left">'+ split[2].split(':')[1]+'</td></tr></table>'
            			  });
            			Direction_infoWindows[0].open(map, this);
            			
        				var str = this.getTitle();						//	Get the title of selected node
        				//var split = str.split(';');
        				$('#NodeID1').val(split[0].split(':')[1]);		//  Fill in the TextFields
                		$('#Latitude1').val(split[1].split(':')[1]);
                		$('#Longitude1').val(split[2].split(':')[1]);
        				Direction_counter++;							//	Direction_counter +1 = 1
        			} 
        			
        			else if (Direction_counter==1) {					//	*** If already selected a node ***
        				
        				this.setIcon('https://www.google.com/mapfiles/marker_green.png');	// Set selected node color to green
        				var str = this.getTitle();						//	Get the title of selected node	
        				var NodeID1 = document.getElementById("NodeID1").value;
        				var NodeID2 = document.getElementById("NodeID2").value;
        				if(NodeID1==""){
        					Directions_Nodes[0] = this;
        					Direction_infoWindows[0] = new google.maps.InfoWindow({
 //               			    content: this.getTitle()
 								content: '<strong>Node 1 </strong><br>'+
 									'<table><tr><td align="left">Node ID:</td><td align="left">'+ split[0].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Latitude:</td><td align="left">'+ split[1].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Longitude:</td><td align="left">'+ split[2].split(':')[1]+'</td></tr></table>'
                			  });
                			Direction_infoWindows[0].open(map, this);
        					//var split = str.split(';');
	        				$('#NodeID1').val(split[0].split(':')[1]);		//	Fill in the TextFields
	                		$('#Latitude1').val(split[1].split(':')[1]);
	                		$('#Longitude1').val(split[2].split(':')[1]);
        				}
        				else if(NodeID2==""){
        					Directions_Nodes[1] = this;
        					Direction_infoWindows[1] = new google.maps.InfoWindow({
//                			    content: this.getTitle()
								content: '<strong>Node 2 </strong><br>'+
									'<table><tr><td align="left">Node ID:</td><td align="left">'+ split[0].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Latitude:</td><td align="left">'+ split[1].split(':')[1] +'</td></tr>' +
            					 '<tr><td align="left">Longitude:</td><td align="left">'+ split[2].split(':')[1]+'</td></tr></table>'
                			  });
                			Direction_infoWindows[1].open(map, this);
        					//var split = str.split(';');
	        				$('#NodeID2').val(split[0].split(':')[1]);		//	Fill in the TextFields
	                		$('#Latitude2').val(split[1].split(':')[1]);
	                		$('#Longitude2').val(split[2].split(':')[1]);
        				}
        				
        				var bounds = new google.maps.LatLngBounds();
        				for (var i=0;i<Directions_Nodes.length;i++) {
        					bounds.extend(Directions_Nodes[i].position);
        				}
        				map.fitBounds(bounds);
                		Direction_counter = 0;							//	Reset Direction_counter to 0
        				ShortestRequest();								//	Call ShortestRequest() to find 3 shortest paths
        			} 
        		}
        		}
        			
        	}); 
		}
		//------------------------------------------------------------------
		// 	Draw Edges
		//------------------------------------------------------------------
		var items = xml.getElementsByTagName("Edges");			//	Draw Edges
		for (var i=0;i<items.length;i++){
			var EdgeID = items[i].getElementsByTagName("EdgeID")[0].childNodes[0].nodeValue;
			var StartID = items[i].getElementsByTagName("StartID")[0].childNodes[0].nodeValue;
			var StartLat = items[i].getElementsByTagName("StartLat")[0].childNodes[0].nodeValue;
			var StartLng = items[i].getElementsByTagName("StartLng")[0].childNodes[0].nodeValue;
			var EndID = items[i].getElementsByTagName("EndID")[0].childNodes[0].nodeValue;
			var EndLat = items[i].getElementsByTagName("EndLat")[0].childNodes[0].nodeValue;
			var EndLng = items[i].getElementsByTagName("EndLng")[0].childNodes[0].nodeValue;
			var Distance = items[i].getElementsByTagName("Distance")[0].childNodes[0].nodeValue;		    				
			
			var destinations = [];								// Push 2 nodes (a line) into one destinations[]
			destinations.push ( new google.maps.LatLng(StartLat,StartLng));
			destinations.push ( new google.maps.LatLng(EndLat,EndLng));
			
			var polylineOptions = {path:destinations,
					strokeColor:"#000000", strokeWeight:1};		// red:"#ff0000" black:"#000000"
			var polyline = new google.maps.Polyline( polylineOptions);
			polyline.setMap(map);			
		}
	}
	
	//------------------------------------------------------------------
	//	Send XMLHttpRequest() to get the info of adjacent edges
	//------------------------------------------------------------------
	function HighlightRequest(){					
		var xhr2;												
		if(window.XMLHttpRequest)
			xhr2 = new XMLHttpRequest();
		else if(window.ActiveObject)
			xhr2 = new ActiveObject("Microsoft.XMLHTTP"); 
		var NodeID = document.getElementById("NodeID").value;
		xhr2.open("get","WazeAppServletPath?NodeID="+NodeID+"&NodeID1=",true);	//	Pass the value of NodeID to Servlet
		xhr2.onreadystatechange = function(){
			if(xhr2.status==200 && xhr2.readyState == 4){
				HighlightEdges(xhr2.responseXML);
			}
		}
		xhr2.send(null);
	}
	
	//------------------------------------------------------------------
	//	Analyse the XML form file
	//	High light the adjacent edges
	//------------------------------------------------------------------
	function HighlightEdges(xml) {				//	High light the adjacent edges
		// Draw Edges	
		var destinations = [];					//	Push 2 nodes (a line) into one destinations[]
		var paths = [];							//	Push all lines into paths[]
		Latitude = document.getElementById("Latitude").value;			//	Latlng info of selected node
		Longitude = document.getElementById("Longitude").value;
		NodeID = document.getElementById("NodeID").value;
		
		var items = xml.getElementsByTagName("NextNodes");
		for (var i=0;i<items.length;i++){
			var NextNodeID = items[i].getElementsByTagName("NextNodeID")[0].childNodes[0].nodeValue;
			var NextNodeLat = items[i].getElementsByTagName("NextNodeLat")[0].childNodes[0].nodeValue;
			var NextNodeLng = items[i].getElementsByTagName("NextNodeLng")[0].childNodes[0].nodeValue;	    				

			destinations.push ( new google.maps.LatLng(Latitude,Longitude));
			destinations.push ( new google.maps.LatLng(NextNodeLat,NextNodeLng));				
		}
		for (var j=0;j<destinations.length;j++){
			paths.push(destinations[j]);				//	Push one line
		}
			
		var polylineOptions = {path:paths,				//	Draw all the adjacent edges together
				strokeColor:"#ff0000", strokeWeight:10}
		polyline_adj = new google.maps.Polyline( polylineOptions);
		polyline_adj.setMap(map);
	} 
	
	
	//------------------------------------------------------------------
	//	Click on Directions button
	//------------------------------------------------------------------
	function ClickOnDirections(){
		if (flag_Direction==0) {							//	If the button isn't pressed before
			document.getElementById("Directions").style.background='#ffff00';	//	Change button color to yellow
			flag_Direction = 1;								//	Set flag_Direction to 1
			if (polyline_adj!=null){							//	If highlighted the adjacent edges
				polyline_adj.setMap(null);						//	Set highlighted edges to null
			}
			if (polyline_path1!=null){							//	If highlighted K shortest paths
				ResetShortestPaths();
			}
			NodeID = document.getElementById("NodeID").value;
			var marker = markers[NodeID];					// 	Change back the color of selected marker
			if(marker!=null){								//	If there exists a selected marker
				marker.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
				infoWindow.close();
			}
			ClearSelectedInfo();							//	Clear selected node TextFields
			ClearDirectionInfo();							//	Clear direction TextFields
			document.getElementById("div_directions").style.display = "block";		//	Let div_Directions appear
			document.getElementById("div_selectedNode").style.display = "none";		//	Disappear div_selectedNode
		}
		else {												// If the button is pressed before
			document.getElementById("Directions").style.background='#ffffff';	//	Change button color to white
			if (polyline_path1!=null){							//	If highlighted K shortest paths
				ResetShortestPaths();							//	Reset highlighted edges to null
			}
			
			NodeID1 = document.getElementById("NodeID1").value;
			var marker1 = markers[NodeID1];					// Change back the color of marker
			if(marker1!=null){								//	If selected marker1 exists
				marker1.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
				Direction_infoWindows[0].close();
			}
			
			NodeID2 = document.getElementById("NodeID2").value;
			var marker2 = markers[NodeID2];					// Change back the color of marker
			if(marker2!=null){								//	If selected marker2 exists
				marker2.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
				Direction_infoWindows[1].close();
			}
			ClearSelectedInfo();							//	Clear selected node TextFields
			ClearDirectionInfo();							//	Clear direction TextFields
			flag_Direction = 0;								//	Set flag_Direction to 1
			Direction_counter = 0;							//	Set Direction_counter to 0
			document.getElementById("div_directions").style.display = "none";		//	Disappear div_Directions 
			document.getElementById("div_selectedNode").style.display = "block";	//	Let div_selectedNode appear
		}
	}
	
	//------------------------------------------------------------------
	//	Click on ClearNode1 button
	//------------------------------------------------------------------
	function ClickOnClearNode1(){
		var NodeID1 = document.getElementById("NodeID1").value;
		if (NodeID1!=""){								//	*** If there is data remaining from the last time running Direction ***
			var marker1 = markers[NodeID1];				//	Locate last two nodes and reset the color to yellow
			marker1.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
			ClearDirectionNode1Info();
			Direction_infoWindows[0].close();
			if(Direction_counter!=0)
				Direction_counter--;
			else if(Direction_counter==0){
				var NodeID2 = document.getElementById("NodeID2").value;
				Direction_counter = 1;
			}			
		}
		if (polyline_path1!=null){							//	If highlighted K shortest paths
			ResetShortestPaths();
		}
	}
	//------------------------------------------------------------------
	//	Clear Directions Node1 TextFields
	//------------------------------------------------------------------
	function ClearDirectionNode1Info(){
		$('#NodeID1').val("");
		$('#Latitude1').val("");
		$('#Longitude1').val("");
	}
	
	//------------------------------------------------------------------
	//	Click on ClearNode2 button
	//------------------------------------------------------------------
	function ClickOnClearNode2(){
		var NodeID2 = document.getElementById("NodeID2").value;
		if (NodeID2!=""){								//	*** If there is data remaining from the last time running Direction ***
			var marker2 = markers[NodeID2];				//	Locate last two nodes and reset the color to yellow
			marker2.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
			ClearDirectionNode2Info();	
			Direction_infoWindows[1].close();
			if(Direction_counter!=0)
				Direction_counter--;
			else if(Direction_counter==0){
				var NodeID2 = document.getElementById("NodeID2").value;
				Direction_counter = 1;
			}
		}
		if (polyline_path1!=null){							//	If highlighted K shortest paths
			ResetShortestPaths();
		}
	}
	//------------------------------------------------------------------
	//	Clear Directions Node2 TextFields
	//------------------------------------------------------------------
	function ClearDirectionNode2Info(){
		$('#NodeID2').val("");
		$('#Latitude2').val("");
		$('#Longitude2').val("");
	}
	
	//------------------------------------------------------------------
	//	Click on ClearAllNodes button
	//------------------------------------------------------------------
	function ClickOnClearAllNodes(){
		document.getElementById("Directions").style.background='#ffff00';	//	Change button color to yellow
		var NodeID1 = document.getElementById("NodeID1").value;
		var NodeID2 = document.getElementById("NodeID2").value;
		if (NodeID1!="" || NodeID2!=""){								//	*** If there is data remaining from the last time running Direction ***
			var marker1 = markers[NodeID1];				//	Locate last two nodes and reset the color to yellow
			if(marker1!=null){
				marker1.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
				Direction_infoWindows[0].close();
			}
			var marker2 = markers[NodeID2];
			if(marker2!=null){				
				marker2.setIcon('https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0');
				Direction_infoWindows[1].close();
			}
			Directions_Nodes = [];						//	Reset the Directions_Nodes[]
		}
		if (polyline_path1!=null){							//	If highlighted K shortest paths
			ResetShortestPaths();
		}
		ClearDirectionInfo();
		Direction_counter = 0;	
	}

	//------------------------------------------------------------------
	//	Reset polyline_path1 2 3
	//	Reset CountClickPath1 2 3
	//	Clear Directions ShortestPathsInfo TextFields
	//------------------------------------------------------------------
	function ResetShortestPaths(){
		$('#Distance1').val("");
		$('#Distance2').val("");
		$('#Distance3').val("");
		CountClickPath1 = 0;
		CountClickPath2 = 0;
		CountClickPath3 = 0;
		if (polyline_path1!=null) {
			polyline_path1.setMap(null);						//	Set highlighted edges to null
			polyline_path2.setMap(null);
			polyline_path3.setMap(null);
		};
	}
	
	//------------------------------------------------------------------
	//	Send XMLHttpRequest() to get the info of 3 shortest path
	//------------------------------------------------------------------
	function ShortestRequest(){
		ResetShortestPaths();
 		var xhr3;												
		if(window.XMLHttpRequest)
			xhr3 = new XMLHttpRequest();
		else if(window.ActiveObject)
			xhr3 = new ActiveObject("Microsoft.XMLHTTP"); 
		var NodeID1 = document.getElementById("NodeID1").value;
		var NodeID2 = document.getElementById("NodeID2").value;
		xhr3.open("get","WazeAppServletPath?NodeID=&NodeID1="+NodeID1+"&NodeID2="+NodeID2,true);	//	Pass the value of NodeID to Servlet
		xhr3.onreadystatechange = function(){
			if(xhr3.status==200 && xhr3.readyState == 4){
				DrawShortestPath(xhr3.responseXML);
			}
		}
		xhr3.send(null); 
	}
	

	//------------------------------------------------------------------
	//	Analyse the XML form file
	//	Draw Shortest Path
	//------------------------------------------------------------------
	function DrawShortestPath(xml) {				//	High light the adjacent edges
		// Draw Edges	
		var destinations = [];					//	Push 2 nodes (a line) into one destinations[]
		var destinations2 = [];
		var destinations3 = [];
		var paths = [];							//	Push all lines into paths[]
		var paths2 = [];
		var paths3 = [];
		var startMarker;
		var endMarker;
		var startLat,startLng;
		var endLat,endLng;

		var bounds = new google.maps.LatLngBounds();
		var point;

		var threePath = xml.getElementsByTagName("Paths");
		for (var p=0;p<threePath.length;p++) {
			
			var distance = threePath[p].getElementsByTagName("PathLength")[0].childNodes[0].nodeValue;
			var items = threePath[p].getElementsByTagName("NextNodeID");
			for (var i=0;i<items.length;i++){
				var NextNodeID = items[i].childNodes[0].nodeValue;
				endMarker = markers[NextNodeID];
				var str = endMarker.getTitle();						//	Get the title of selected node
				var split = str.split(';');
				var endLat = split[1].split(':')[1];
				var endLng = split[2].split(':')[1];
				point = new google.maps.LatLng(endLat,endLng);
				bounds.extend(point);
				if (i!=0 && p==0) {
					$('#Distance1').val(Math.round(distance*1000000)/1000000);
					destinations.push ( new google.maps.LatLng(startLat,startLng));
					destinations.push ( new google.maps.LatLng(endLat,endLng));
				}
				if (i!=0 && p==1) {
					$('#Distance2').val(Math.round(distance*1000000)/1000000);
					destinations2.push ( new google.maps.LatLng(startLat,startLng));
					destinations2.push ( new google.maps.LatLng(endLat,endLng));
				}
				if (i!=0 && p==2) {
					$('#Distance3').val(Math.round(distance*1000000)/1000000);
					destinations3.push ( new google.maps.LatLng(startLat,startLng));
					destinations3.push ( new google.maps.LatLng(endLat,endLng));
				}	
				startLat = endLat;
				startLng = endLng;
			}
		}
		for (var j=0;j<destinations.length;j++){
			paths.push(destinations[j]);				//	Push one line into path1
		}
		for (var j=0;j<destinations2.length;j++){
			paths2.push(destinations2[j]);				//	Push one line into path2
		}
		for (var j=0;j<destinations3.length;j++){
			paths3.push(destinations3[j]);				//	Push one line into path3
		}
			
		var polylineOptions = {path:paths,					//	Draw path_1
				strokeColor:"#ff0000", strokeWeight:14}
		polyline_path1 = new google.maps.Polyline( polylineOptions);
		polyline_path1.setMap(map);

		var polylineOptions2 = {path:paths2,				//	Draw path_2
				strokeColor:"#ffff00", strokeWeight:10}
		polyline_path2 = new google.maps.Polyline( polylineOptions2);
		polyline_path2.setMap(map);
		
		var polylineOptions3 = {path:paths3,				//	Draw path_3
				strokeColor:"#10DE25", strokeWeight:6}      //	Blue:07FFFF
		polyline_path3 = new google.maps.Polyline( polylineOptions3);
		polyline_path3.setMap(map);
		map.fitBounds(bounds);
	} 


	//------------------------------------------------------------------
	//	Add Row Listeners to PathTable
	//	Click on row in PathTable, only the selected path shows on the map
	//------------------------------------------------------------------
	function addRowHandlers() {
    	var table = document.getElementById("PathTable");
    	var rows = table.getElementsByTagName("tr");
    	for (i = 0; i < rows.length; i++) {
        	var currentRow = table.rows[i];
        	var createClickHandler = function(row) {
                return function() { 
                	var cell = this.getElementsByTagName("td")[0];
                    var content = cell.innerHTML;
                	if (content=="1st (Red):") {
                		if (CountClickPath1==0) {
                			polyline_path1.setMap(map);
                			polyline_path2.setMap(null);
							polyline_path3.setMap(null);
							CountClickPath1 = 1;
							CountClickPath2 = 0;
							CountClickPath3 = 0;
                		} else {
                			polyline_path2.setMap(map);
							polyline_path3.setMap(map);
							CountClickPath1 = 0;
                		}
                	}
                	if (content=="2nd (Yellow):") {
                		if (CountClickPath2==0) {
                			polyline_path2.setMap(map);
                			polyline_path1.setMap(null);
							polyline_path3.setMap(null);
							CountClickPath2 = 1;
							CountClickPath1 = 0;
							CountClickPath3 = 0;
                		} else {
                			polyline_path1.setMap(map);
							polyline_path3.setMap(map);
							CountClickPath2 = 0;
                		}
                	}
                	if (content=="3rd (Green):") {
                		if (CountClickPath3==0) {
                			polyline_path3.setMap(map);
                			polyline_path2.setMap(null);
							polyline_path1.setMap(null);
							CountClickPath3 = 1;
							CountClickPath2 = 0;
							CountClickPath1 = 0;
                		} else {
                			polyline_path2.setMap(map);
							polyline_path1.setMap(map);
							CountClickPath3 = 0;
                		}
                	}
                };
            };
        	currentRow.onclick = createClickHandler(currentRow);
    	}
    }

	//------------------------------------------------------------------
	//	Clear Selected Node TextFields
	//------------------------------------------------------------------
	function ClearSelectedInfo(){
		$('#NodeID').val("");
		$('#Latitude').val("");
		$('#Longitude').val("");
	}
	//------------------------------------------------------------------
	//	Clear Directions TextFields
	//------------------------------------------------------------------
	function ClearDirectionInfo(){
		$('#NodeID1').val("");
		$('#Latitude1').val("");
		$('#Longitude1').val("");
		$('#NodeID2').val("");
		$('#Latitude2').val("");
		$('#Longitude2').val("");
	}
		
	function initialize() {									//	Load the google map
		mapCanvas = document.getElementById('map');
		mapOptions = {
			center: new google.maps.LatLng(37.0000, -120.0000),
		    zoom: 7,
		    mapTypeId: google.maps.MapTypeId.ROADMAP
		}
		map = new google.maps.Map(mapCanvas, mapOptions);		        
	}
	google.maps.event.addDomListener(window, 'load', initialize);
</script>

</head>
<body onload="initList()">

	Directions <input type="button" id="Directions" name="Directions" value="Directions" onclick="ClickOnDirections()" />
	
	<div id="div_selectedNode" style="display: block">
	<p>Node ID of selected node:</p><input id="NodeID" name="NodeID" readonly/>
	<p>Latitude of selected node:</p><input id="Latitude" name="Latitude" readonly/>
	<p>Longitude of selected node:</p><input id="Longitude" name="Longitude" readonly/>
	</div>
	<br>
	
		
	<div id="div_directions" style="display: none">
	<p>Selected Node 1</p>
	<table>
    	<tr>
      		<td align="left">Node ID:</td>
      		<td align="left"><input id="NodeID1" name="NodeID1" readonly/></td>
    		</tr>
    	<tr>
      		<td align="left">Latitude:</td>
      		<td align="left"><input id="Latitude1" name="Latitude1" readonly/></td>
   		</tr>
    	<tr>
     		<td align="left">Longitude:</td>
      		<td align="left"><input id="Longitude1" name="Longitude1" readonly/></td>
    	</tr>
  	</table>
	<p><input type="button" id="ClearNode1" name="ClearNode1" value="Clear Node 1" onclick="ClickOnClearNode1()"/></p>
	
	<p>Selected Node 2</p>
	<table>
    	<tr>
      		<td align="left">Node ID:</td>
      		<td align="left"><input id="NodeID2" name="NodeID2" readonly/></td>
    		</tr>
    	<tr>
      		<td align="left">Latitude:</td>
      		<td align="left"><input id="Latitude2" name="Latitude2" readonly/></td>
   		</tr>
    	<tr>
     		<td align="left">Longitude:</td>
      		<td align="left"><input id="Longitude2" name="Longitude2" readonly/></td>
    	</tr>
  	</table>
	<p><input type="button" id="ClearNode2" name="ClearNode2" value="Clear Node 2" onclick="ClickOnClearNode2()"/></p>
	<br>
	<input type="button" style="width:120px; height:30px; border:2px solid black; border-radius: 15px; background-color: #C2F0FF; background-color: #ffffff;" id="ClearAllNodes" name="ClearAllNodes" value="Clear All Nodes" onclick="ClickOnClearAllNodes()"/>
	<br>
	
	<p>Shortest Path</p>
	<table id="PathTable">
		<tr>
      		<td align="left"></td>
      		<td align="left">Distance:</td>
    		</tr>
    	<tr>
      		<td align="left">1st (Red):</td>
      		<td align="left"><input id="Distance1" name="Distance1" readonly/></td>
    		</tr>
    	<tr>
      		<td align="left">2nd (Yellow):</td>
      		<td align="left"><input id="Distance2" name="Distance2" readonly/></td>
   		</tr>
    	<tr>
     		<td align="left">3rd (Green):</td>
      		<td align="left"><input id="Distance3" name="Distance3" readonly/></td>
    	</tr>
  	</table>
	
	</div>
	

	<div id="map"></div>
	
</body>
</html>