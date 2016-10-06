package com.sinan.map;

public class Edge {
	int iEdgeID;
	int iStartNodeID;
	int iEndNodeID;
	double dDistance;
	public int getiEdgeID() {
		return iEdgeID;
	}
	public void setiEdgeID(int iEdgeID) {
		this.iEdgeID = iEdgeID;
	}
	public int getiStartNodeID() {
		return iStartNodeID;
	}
	public void setiStartNodeID(int iStartNodeID) {
		this.iStartNodeID = iStartNodeID;
	}
	public int getiEndNodeID() {
		return iEndNodeID;
	}
	public void setiEndNodeID(int iEndNodeID) {
		this.iEndNodeID = iEndNodeID;
	}
	public double getdDistance() {
		return dDistance;
	}
	public void setdDistance(double dDistance) {
		this.dDistance = dDistance;
	}

}
