package com.sinan.map;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.PriorityQueue;
import java.util.Set;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(description = "WazeApp Servlet", urlPatterns = { "/WazeAppServletPath" })
public class WazeAppServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	
	static Map <Integer,Node> NodesMap = new HashMap <Integer,Node>();	
	static Map <Integer,Edge> EdgesMap = new HashMap <Integer,Edge>();
	//	Store edges of each node in a form of storing the adjacent node (draw adjacent edge on map)
	static Map <Integer, Map<Integer, Double>>  NodeEdgesMap =new HashMap <>();	//	Store edges of each node
	
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		response.setContentType("text/xml;charset=UTF-8");
		PrintWriter out = response.getWriter();
		StringBuilder xml = new StringBuilder();
		String str1 = request.getParameter("NodeID").toString();
		String str2 = request.getParameter("NodeID1").toString();
		if (str1!=""){												//	Find Adjacent Nodes. Only have ID of Node
			FindAdjacentNodes find = new FindAdjacentNodes();		//	实例化 FindAdjacentNodes Class
			find.FindAdjacentEdges(Integer.parseInt(str1),xml);		//	Call FindAdjacentNodes() method
			out.print(xml.toString());
			out.flush();
			out.close();
			return;
		}
		else if (str2!=""){									//	Calculate Shortest Path. Get ID of both Node1 & Node2
			int iNodeID1 = Integer.parseInt(request.getParameter("NodeID1"));
			int iNodeID2 = Integer.parseInt(request.getParameter("NodeID2"));
			ShortestPaths calculate = new ShortestPaths();
			calculate.ShortestPaths(iNodeID1, iNodeID2, xml);
			out.print(xml.toString());
			out.flush();
			out.close();
			return;			
		}
		
		LoadData load = new LoadData();							//	init 实例化 LoadData Class
		load.LoadNodes();										// 	Call LoadNodes() method (in LoadData Class)
		load.LoadEdges();										//	Call LoadEdges() method (in LoadData Class)
		xml.append("<items>");
		Iterator iter = NodesMap.keySet().iterator();			//	遍历 NodesMap  Change data into XML format
		while(iter.hasNext())
		{
			String sIndex = iter.next().toString();
			int iIndex = Integer.parseInt(sIndex);
			Node node = NodesMap.get(iIndex);					//	实例化 Node to store info retrieved from NodesMap
			double dLongitude = node.getdLongitude();
			double dLatitude = node.getdLatitude();
			xml.append("<Nodes>");
			xml.append("<NodeID>").append(iIndex).append("</NodeID>");
			xml.append("<Longitude>").append(dLongitude).append("</Longitude>");
			xml.append("<Latitude>").append(dLatitude).append("</Latitude>");
			xml.append("</Nodes>");			
		}
		Iterator iter2 = EdgesMap.keySet().iterator();		//	遍历 EdgesMap Change data into XML format
		while(iter2.hasNext())
		{
			String sIndex = iter2.next().toString();
			int iIndex = Integer.parseInt(sIndex);			//	Edge ID
			Edge edge = EdgesMap.get(iIndex);				//	Get edge info
			int StartID = edge.getiStartNodeID();			//	Start Node
			Node StartNode = NodesMap.get(StartID);			//	Get start node latlng info (to draw road)
			double StartLat = StartNode.getdLatitude();
			double StartLng = StartNode.getdLongitude();
			int EndID = edge.getiEndNodeID();				//	End Node
			Node EndNode = NodesMap.get(EndID);				//	Get end node latlng info (to draw road)
			double EndLat = EndNode.getdLatitude();
			double EndLng = EndNode.getdLongitude();
			double dDistance = edge.getdDistance();
			xml.append("<Edges>");
			xml.append("<EdgeID>").append(iIndex).append("</EdgeID>");
			xml.append("<StartID>").append(StartID).append("</StartID>");
			xml.append("<StartLat>").append(StartLat).append("</StartLat>");
			xml.append("<StartLng>").append(StartLng).append("</StartLng>");
			xml.append("<EndID>").append(EndID).append("</EndID>");
			xml.append("<EndLat>").append(EndLat).append("</EndLat>");
			xml.append("<EndLng>").append(EndLng).append("</EndLng>");
			xml.append("<Distance>").append(dDistance).append("</Distance>");
			xml.append("</Edges>");			
		}		
		xml.append("</items>");
		out.print(xml.toString());
		out.flush();
		out.close();
	}

	
	
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doGet(request, response);
	}

}
