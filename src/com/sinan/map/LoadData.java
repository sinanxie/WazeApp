package com.sinan.map;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

import javax.servlet.ServletContext;


public class LoadData {
	public void LoadNodes(){
		try {
			WazeAppServlet.EdgesMap.clear();
			WazeAppServlet.NodeEdgesMap.clear();
			WazeAppServlet.NodesMap.clear();
			Scanner input = new Scanner(new File("/Users/sinanxie1/Documents/Eclipse_workspace/WazeAppTest/Nodes.txt"));
			while (input.hasNextLine()) {
	            String str = input.nextLine();
	            String[] strArray = str.split(" ");
	            Node tempNode = new Node();
	            int iNodeId = Integer.parseInt(strArray[0].trim());
	            tempNode.setiNodeID(iNodeId); 
	            tempNode.setdLongitude(Double.parseDouble(strArray[1].trim()));
	            tempNode.setdLatitude(Double.parseDouble(strArray[2].trim()));
	            WazeAppServlet.NodesMap.put(iNodeId, tempNode);
	            Map<Integer, Double> map = new HashMap<>();
	            WazeAppServlet.NodeEdgesMap.put(iNodeId,map);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
	}
	
	public void LoadEdges(){
		try {
			Scanner input = new Scanner(new File("/Users/sinanxie1/Documents/Eclipse_workspace/WazeAppTest/Edges.txt"));
			while (input.hasNextLine()) {
	            String str = input.nextLine();
	            String[] strArray = str.split(" ");
	            Edge tempEdge = new Edge();
	            int iEdgeId = Integer.parseInt(strArray[0].trim());
	            int iStartNodeID = Integer.parseInt(strArray[1].trim());
	            int iEndNodeID = Integer.parseInt(strArray[2].trim());
	            double dDistance = Double.parseDouble(strArray[3].trim());
	            tempEdge.setiEdgeID(iEdgeId);
	            tempEdge.setiStartNodeID(iStartNodeID);
	            tempEdge.setiEndNodeID(iEndNodeID);
	            tempEdge.setdDistance(dDistance);
	            WazeAppServlet.EdgesMap.put(iEdgeId, tempEdge);
	            
	            Map<Integer, Double> map = new HashMap<>();
	            map = WazeAppServlet.NodeEdgesMap.get(iStartNodeID);
	            map.put(iEndNodeID, dDistance);
	            WazeAppServlet.NodeEdgesMap.put(iStartNodeID, map);		    //	Put end node into list(adjacent nodes) of startnode
	            map = WazeAppServlet.NodeEdgesMap.get(iEndNodeID);
	            map.put(iStartNodeID, dDistance);
	            WazeAppServlet.NodeEdgesMap.put(iEndNodeID, map);			//	Put start node into list(adjacent nodes) of endnode
	            
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		} catch (NullPointerException e) {
			
		}
	}

}
