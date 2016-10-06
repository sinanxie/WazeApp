package com.sinan.map;

import java.util.List;
import java.util.Map;

public class FindAdjacentNodes {
	public StringBuilder FindAdjacentEdges(Integer iNodeID,StringBuilder xml){
		xml.append("<items>");
		Map<Integer, Double> map = WazeAppServlet.NodeEdgesMap.get(iNodeID);
		for (Integer ii : map.keySet()) {
			Node NextNode = WazeAppServlet.NodesMap.get(ii);
			double dNextNodeLat = NextNode.getdLatitude();
			double dNextNodeLng = NextNode.getdLongitude();
			xml.append("<NextNodes>");
			xml.append("<NextNodeID>").append(ii).append("</NextNodeID>");
			xml.append("<NextNodeLat>").append(dNextNodeLat).append("</NextNodeLat>");
			xml.append("<NextNodeLng>").append(dNextNodeLng).append("</NextNodeLng>");
			xml.append("</NextNodes>");
		}
		xml.append("</items>");
		return xml;		
	}
}
