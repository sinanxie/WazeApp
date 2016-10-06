package com.sinan.map;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Map;
import java.util.PriorityQueue;
import java.util.Set;

import jdk.nashorn.internal.objects.annotations.SpecializedFunction.LinkLogic;
import sun.awt.image.ImageWatched.Link;

public class ShortestPaths {
		
	//---------------------------------------------------------------------------------------
	// Data Structure
	//---------------------------------------------------------------------------------------
	//
	//--Dijkstra's Algorithm
	//
	//		Map <Integer,DijkstraVertex> 		oDijkVertexMap 		-- Key:nodeID	- Store each node info: iParentID, dDist
	//		PriorityQueue<DijkstraVertex> 		DistMinHeap  		-- To pop out the next Unknown node with min dDist
	//  	Set <Integer> 						KnownSet			-- Store known node, to make sure loopless
	// 
	//--Yen's Algorithm
	//
	//		Map<Integer, LinkedList<Integer>> 	RootPathMap 		-- Key:index	- Value:rootPath
	// 		Map<Integer, LinkedList<Integer>> 	FirstNodeOfSpurPathMap	-- Key:rootPathIndex	- Value:node list that should be set to infinity when finding Kth shortest path
	//  	Map <Integer, LinkedList<Integer>> 	PathMap				-- Key:index	- Value:path	-Store paths found so far
	//		PriorityQueue<PathLength> 			PathDistMinHeap  	-- Store all the potential Kth shortest path
	//  	ArrayList<PathLength>				PathDistKthMinHeap 	-- Store k-shortest paths
	//	
	//---------------------------------------------------------------------------------------
	
	static Map <Integer,DijkstraVertex> oDijkVertexMap = new HashMap<>();
	static Set <Integer> KnownSet = new HashSet<>();				//	Nodes Set - Each time run AStarAlgorithm()
	static PriorityQueue<DijkstraVertex> DistMinHeap = new PriorityQueue<>(new Comparator<DijkstraVertex>() {
		public int compare(DijkstraVertex n1, DijkstraVertex n2) {
			if (n1.dDist > n2.dDist) 
				return +1;
	        if (n1.dDist == n2.dDist) 
	        	return 0;
	        return -1;
	    }
	});
	
	static Map<Integer, LinkedList<Integer>>RootPathMap = new HashMap<>();
	static Map<Integer, LinkedList<Integer>> FirstNodeOfSpurPathMap = new HashMap<>();
	static Map <Integer, LinkedList<Integer>> PathMap = new HashMap<>();			//	Path Index -> Nodes list	
	static PriorityQueue<PathLength> PathDistMinHeap = new PriorityQueue<>(new Comparator<PathLength>() {
		public int compare(PathLength p1, PathLength p2){
			if (p1.dLength > p2.dLength)
				return 1;
			if (p1.dLength == p2.dLength)
				return 0;
			return -1;
		}
	});	
	static ArrayList<PathLength> PathDistKthList = new ArrayList<>();
	
	// Global variables
	int iGlobalPathIndex = 0;				//	Path Index
	int iGlobalRootPathIndex = 0;
	int iKth = 3;							//	Kth Shortest Paths	
	int iNextNodeID = -1;	
	PathLength globalPath = new PathLength();
	
	
	//	-------------------------------------------------
	//	Function:	Find shortest path
	//	Input: @iNodeID1	@iNodeID2	@path
	//	Output: @path - shortest path 
	//	-------------------------------------------------
	public void DijkstraAlgorithm(int iNodeID1, int iNodeID2, LinkedList<Integer> path){
		DistMinHeap.clear();
		oDijkVertexMap.clear();
		DijkstraVertex vNode1 = new DijkstraVertex();
		vNode1.iNodeID = iNodeID1;
		vNode1.dDist = (double) 0;
		vNode1.iParentID = -1;
		oDijkVertexMap.put(vNode1.iNodeID, vNode1);
		DistMinHeap.add(vNode1);
		while(!DistMinHeap.isEmpty()){
			DijkstraVertex vNodeTemp = new DijkstraVertex();
			vNodeTemp = DistMinHeap.poll();				//	Parent node of nodes in NodeIDMap	【vNodeTemp-parent node】
			KnownSet.add(vNodeTemp.iNodeID);			//	Add pop node into KnownSet
			
			if (vNodeTemp.iNodeID==iNodeID2) {			//	Stop Alg if meet the End Node

				FormPathToList(iNodeID2, path);			

				PathLength tempPath = new PathLength();
				tempPath.iPathID = iGlobalPathIndex;
				tempPath.dLength = vNodeTemp.dDist;
				
				globalPath = tempPath;
				
				break;
			}
			Map<Integer, Double> NodeIDMap = WazeAppServlet.NodeEdgesMap.get(vNodeTemp.iNodeID);
			for (Integer ii : NodeIDMap.keySet()){					//	ii - NodeID; Add adjacent nodes into DistMinHeap
				if (!KnownSet.contains(ii)) {
					DijkstraVertex n2;
					if (oDijkVertexMap.containsKey(ii)) {
						n2 = oDijkVertexMap.get(ii);
					} else {
						n2 = new DijkstraVertex();
						n2.dDist = Double.POSITIVE_INFINITY;
					}
					n2.iNodeID = ii;
					Double dTemp = vNodeTemp.dDist + NodeIDMap.get(ii);		//	Dist !! Change to A* Algorithm
					if (dTemp < n2.dDist) {
						n2.dDist = dTemp;
						n2.iParentID = vNodeTemp.iNodeID;
						oDijkVertexMap.put(n2.iNodeID, n2);
					}
					if (DistMinHeap.contains(n2)) {			//	If n2 is ready in the DistMinHeap, remove it
						DistMinHeap.remove(n2);
					}
					DistMinHeap.add(n2);					//	Add adjacent nodes into DistMinHeap
				}
			}
		}
	}
	
	//	-------------------------------------------------
	//	Function:	Find k-shortest paths
	//	Input: @iNodeID1	@iNodeID2	@k
	//	Output: @PathDistKthList - a list of k-shortest paths
	//	-------------------------------------------------
	public void KthShortestPath(int iNodeID1, int iNodeID2, int k){
		LinkedList<Integer> pathList = new LinkedList<>();
		DijkstraAlgorithm(iNodeID1, iNodeID2, pathList);
		
		PathMap.put(iGlobalPathIndex, pathList);
		PathDistMinHeap.add(globalPath);					//	Add path to PathDistMinHeap
		iGlobalPathIndex++;
		
		PathLength tempPath = new PathLength();				
		tempPath = PathDistMinHeap.remove();				
		PathDistKthList.add(tempPath);

		while (PathDistKthList.size()<k) {
			int iPathIndex = tempPath.iPathID;
			LinkedList<Integer> tempPathList = PathMap.get(iPathIndex);		//	Get the last shortest path (list of NodeID)

			Map <Integer,DijkstraVertex> newDijkVertexMap = new HashMap<>();
			FormDijkVerMap(newDijkVertexMap, tempPathList);					//	Form a DijkVerMap for last shortest path
			
			for (int ii : tempPathList) {
				if (ii==iNodeID2) {
					break;
				}
				KnownSet.clear();
				iNextNodeID = -1;
				LinkedList<Integer> tempRootPath = FormRootPath(ii, tempPathList);
				int iRootPathIndex = FindRootPath(tempRootPath);
				if (iRootPathIndex == -1) {
					RootPathMap.put(iGlobalRootPathIndex, tempRootPath);
					LinkedList<Integer> list = new LinkedList<>();
					FirstNodeOfSpurPathMap.put(iGlobalRootPathIndex, list);
					iRootPathIndex = iGlobalRootPathIndex;
					iGlobalRootPathIndex++;
				}
				
				AddNextNodeList(iRootPathIndex, iNextNodeID);
				
				if (CheckNodes(iRootPathIndex, ii)) {
					continue;
				}			

				Map<Integer, Double> NodeIDMap = WazeAppServlet.NodeEdgesMap.get(ii);				
				Map<Integer, Double> tempMap = new HashMap<>();					//	Store info of edges that set to infinity
				
				LinkedList<Integer> nodeList1 = FirstNodeOfSpurPathMap.get(iRootPathIndex);
				if (nodeList1!=null) {
					for(int mm : nodeList1){
						Double tempDist = NodeIDMap.get(mm);
						tempMap.put(mm, tempDist);
						NodeIDMap.remove(mm);
					}
				}
				WazeAppServlet.NodeEdgesMap.put(ii, NodeIDMap);			//	Update data structure
								
				Double dRootDist = newDijkVertexMap.get(ii).dDist;
				
				LinkedList<Integer> SpurPath = new LinkedList<>();
				DijkstraAlgorithm(ii, iNodeID2, SpurPath);				//	Implement Dijkstra's Algorithm to find the shortest path
				
				if (SpurPath!=null && SpurPath.size()!=0) {
					pathList = UnionTwoPath(tempRootPath,SpurPath);
					PathMap.put(iGlobalPathIndex, pathList);
					
					int iTempNextNodeId = SpurPath.getFirst();
					AddNextNodeList(iRootPathIndex, iTempNextNodeId);
					
					globalPath.dLength += dRootDist;
					PathLength temp = new PathLength();
					temp = globalPath;
					PathDistMinHeap.add(temp);					//	Add path to PathDistMinHeap
					iGlobalPathIndex++;
				}

				Map<Integer, Double> NodeIDMap2 = WazeAppServlet.NodeEdgesMap.get(ii);
				for (int nn : tempMap.keySet()){
					Double tempDist = tempMap.get(nn);
					NodeIDMap2.put(nn, tempDist);
				}
				WazeAppServlet.NodeEdgesMap.put(ii, NodeIDMap2);		//	Change back data in data structure
			}
			tempPath = PathDistMinHeap.remove();
			PathDistKthList.add(tempPath);

		}
	}
	//	-------------------------------------------------
	//	Function:	Form path into a list
	//	Input: @iEndNodeID	@pathList
	//	Output: Direct change pathList
	//	-------------------------------------------------
	public void FormPathToList(int iEndNodeID,LinkedList<Integer> pathList){
		pathList.addFirst(iEndNodeID);
		if (oDijkVertexMap.get(iEndNodeID).iParentID!=-1) {
			DijkstraVertex vTemp = oDijkVertexMap.get(iEndNodeID);
			FormPathToList(vTemp.iParentID, pathList);
		}
	}
	
	//	-------------------------------------------------
	//	Function:	Form a rootpath
	//	Input: @iNodeID - spur node id	@pathList - k-1 shortest path
	//	Output: @rooPath
	//	-------------------------------------------------
	public LinkedList<Integer> FormRootPath(int iNodeID, LinkedList<Integer> pathList) {
		int flag = 0;
		LinkedList<Integer> rootPath = new LinkedList<>();
		for(int ii:pathList){
			if (flag == 1) {
				iNextNodeID = ii;
				break;
			}
			if (ii!=iNodeID) {
				rootPath.add(ii);
				KnownSet.add(ii);
				continue;
			} else if (ii == iNodeID) {
				rootPath.add(ii);
//				KnownSet.add(ii);
				flag = 1;
				continue;
			} 
		}
		return rootPath;
	}
	
	//	-------------------------------------------------
	//	Function:	Check if there exist a same rooPath in RootPathMap
	//	Input: @rootPath
	//	Output: @rootPathIndex - if exists, return rootPathIndex; if not, return -1
	//	-------------------------------------------------	
	public int FindRootPath(LinkedList<Integer> rootPath){
		if (RootPathMap.size()==0) {
			return -1;
		}
		boolean flag = false;
		LinkedList<Integer> path = new LinkedList<>();
		for(int ii:RootPathMap.keySet()){
			path = RootPathMap.get(ii);
			if (rootPath.size()!=path.size()) {
				continue;
			}
			for(int jj:path){
				if (!rootPath.contains(jj)) {
					break;
				}
				flag = true;
			}
			if (flag) {
				return ii;
			}
		}
		return -1;	
	}
	
	//	-------------------------------------------------
	//	Function:	Add node to list, according to the index of rootpath
	//	Input: @index - RootPathIndex	@nodeID - Next node after spur node in path
	//	Output: Directly change the data in FirstNodeOfSpurPathMap
	//	-------------------------------------------------
	public void AddNextNodeList(int index, int nodeID) {
		LinkedList<Integer> list = FirstNodeOfSpurPathMap.get(index);
		if (!list.contains(nodeID)) {
			list.add(nodeID);
			FirstNodeOfSpurPathMap.put(index, list);
		}
	}
	
	//	-------------------------------------------------
	//	Function:	Check if all the adjacent nodes are usable to find shortest path
	//	Input: @ iRootPathIndex	@iNodeID - spur node
	//	Output:  True - No node available to calculate shortest path 
	//	-------------------------------------------------	
	public boolean CheckNodes(int iRootPathIndex, int iNodeID){				
		LinkedList<Integer> nodeList = FirstNodeOfSpurPathMap.get(iRootPathIndex);
		Map<Integer, Double> NodeIDMap = WazeAppServlet.NodeEdgesMap.get(iNodeID);
		for(Integer ii:NodeIDMap.keySet()){
			boolean temp = nodeList.contains(ii);
			boolean temp2 = KnownSet.contains(ii);
			if ((!temp) && (!temp2)) {
				return false;								
			}
		}		
		return true;
	}
	
	//	-------------------------------------------------
	//	Function:	Union rooPath and spurPath together
	//	Input: @rootPath 	@spurPath
	//	Output: @resultPath = rootPath+spurPath
	//	-------------------------------------------------
	public LinkedList<Integer> UnionTwoPath(LinkedList<Integer> rootPath, LinkedList<Integer> spurPath){
		LinkedList<Integer> resultPath = new LinkedList<>();
		for (int ii: rootPath){
			resultPath.add(ii);
		}
		if (spurPath.size()!=0) {
			spurPath.removeFirst();
		}
//		spurPath.removeFirst();
		for (int ii:spurPath){
			resultPath.addLast(ii);
		}
		return resultPath;
	}
	
	//	-------------------------------------------------
	//	Function:	Construct a new DijkstraVertex Map for k-1 shortest path
	//	Input: @newDijkVertexMap	@tempPathList
	//	Output: Directly change the data in newDijkVertexMap
	//	-------------------------------------------------
	public void FormDijkVerMap(Map <Integer,DijkstraVertex> newDijkVertexMap, LinkedList<Integer> tempPathList){
		int iParent = -1;
		Double dDist = 0.0;	
		for (Integer ii:tempPathList) {
			if (iParent!=-1) {
				dDist += WazeAppServlet.NodeEdgesMap.get(iParent).get(ii);
			}
			DijkstraVertex tempVertex = new DijkstraVertex();
			tempVertex.iNodeID = ii;
			tempVertex.iParentID = iParent;
			tempVertex.dDist = dDist;
			newDijkVertexMap.put(ii, tempVertex);
			iParent = ii;
		}	
	}
	
	//	-------------------------------------------------
	//	Function:	Initialize data structure used in Yen's algorithm
	//	-------------------------------------------------
	public  void initDataStructure() {
		oDijkVertexMap.clear();
		DistMinHeap.clear();
		KnownSet.clear();
		PathDistMinHeap.clear();
		PathDistKthList.clear();
		PathMap.clear();
		iGlobalPathIndex = 0;
		iGlobalRootPathIndex= 0;
		RootPathMap.clear();
		FirstNodeOfSpurPathMap.clear();
		globalPath = null;
		LoadData load = new LoadData();						
		load.LoadNodes();										
		load.LoadEdges();
	}
	
	public StringBuilder ShortestPaths(Integer iNodeID1,Integer iNodeID2,StringBuilder xml){
		
		long startTime = System.currentTimeMillis();
		
		initDataStructure();				
		KthShortestPath(iNodeID1,iNodeID2, iKth);
				
		xml.append("<items>");
		for (int iK = 0; iK<iKth ;iK++){
			xml.append("<Paths>");
			PathLength tempPath = new PathLength();
			if (PathDistKthList.size()>0) {
				tempPath = PathDistKthList.remove(0);
			} else {
				tempPath = PathDistMinHeap.remove();
			}
			int iPathIndex = tempPath.iPathID;
			LinkedList<Integer> tempPathList = PathMap.get(iPathIndex);		//	Get the shortest path (list of NodeID)
			for (Integer ii:tempPathList){
				xml.append("<NextNodeID>").append(ii).append("</NextNodeID>");
			}
			xml.append("<PathLength>").append(tempPath.dLength).append("</PathLength>");
			xml.append("</Paths>");
		}
		xml.append("</items>");
		
		long endTime   = System.currentTimeMillis();
		long totalTime = endTime - startTime;
		
		System.out.println(totalTime);
		
		return xml;			
	}
}
