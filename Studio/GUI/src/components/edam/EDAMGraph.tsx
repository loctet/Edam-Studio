
import React, { useState, useCallback, useRef, useEffect } from 'react';
import { useTheme } from './ThemeProvider';
import { Card } from '@/components/ui/card';
import type {EDAMModel, EDAMTransition} from "@edams-models/edam/types";
import { ZoomIn, ZoomOut, Maximize, MoveHorizontal, Download } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { formatTransitionLabel } from './utils';

interface Node {
  id: string;
  position: { x: number; y: number };
  data: { label: string; isInitial?: boolean; isFinal?: boolean };
}

interface Edge {
  id: string;
  source: string;
  target: string;
  data: EDAMTransition;
}

interface EDAMGraphProps {
  model: EDAMModel | null;
  onNodeClick: (node: any) => void;
  onEdgeClick: (edge: any) => void;
  svgRef?: (node: SVGElement | null) => void;
}

export const EDAMGraph: React.FC<EDAMGraphProps> = ({ 
  model, 
  onNodeClick, 
  onEdgeClick,
  svgRef
}) => {
  const { theme } = useTheme();
  const [zoom, setZoom] = useState(1);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [selectedEdge, setSelectedEdge] = useState<string | null>(null);
  const [nodes, setNodes] = useState<Node[]>([]);
  const [edges, setEdges] = useState<Edge[]>([]);
  const [draggingNode, setDraggingNode] = useState<string | null>(null);
  const [nodeDragStart, setNodeDragStart] = useState({ x: 0, y: 0 });
  const svgElement = useRef<SVGSVGElement>(null);
  
  useEffect(() => {
    if (svgRef && svgElement.current) {
      svgRef(svgElement.current);
    }
  }, [svgRef, svgElement.current]);
  
  useEffect(() => {
    if (!model) {
      setNodes([]);
      setEdges([]);
      return;
    }
    
    const nodeCount = model.states.length + 1;
    const radius = Math.max(150, nodeCount * 30);
    const newNodes: Node[] = model.states.map((state, index) => {
      const angle = (index / nodeCount) * 2 * Math.PI;
      return {
        id: state,
        position: {
          x: 300 + radius * Math.cos(angle),
          y: 200 + radius * Math.sin(angle),
        },
        data: {
          label: state,
          isInitial: state === model.initialState,
          isFinal: model.finalStates?.includes(state) || false,
        },
      };
    });
    const angle = ((nodeCount -1) / nodeCount) * 2 * Math.PI;
    newNodes.push({
      id: "_",
      position: {
        x: 300 + radius * Math.cos(angle),
        y: 200 + radius * Math.sin(angle),
      },
      data: {
        label: "_",
        isInitial: true,
        isFinal: false,
      },
    })
    
    const newEdges: Edge[] = model.transitions.map((transition, index) => ({
      id: `edge-${index}`,
      source: transition.from,
      target: transition.to,
      data: transition,
    }));
    
    setNodes(newNodes);
    setEdges(newEdges);
    
    setZoom(1);
    setPosition({ x: 0, y: 0 });
    setSelectedNode(null);
    setSelectedEdge(null);
  }, [model]);
  
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button === 0) { // Left click
      setIsDragging(true);
      setDragStart({ x: e.clientX, y: e.clientY });
      e.preventDefault();
    }
  }, []);
  
  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (isDragging) {
      const dx = (e.clientX - dragStart.x) / zoom;
      const dy = (e.clientY - dragStart.y) / zoom;
      setPosition(prev => ({ x: prev.x + dx, y: prev.y + dy }));
      setDragStart({ x: e.clientX, y: e.clientY });
    } else if (draggingNode) {
      const svgRect = svgElement.current?.getBoundingClientRect();
      if (!svgRect) return;
      
      const dx = (e.clientX - nodeDragStart.x) / zoom;
      const dy = (e.clientY - nodeDragStart.y) / zoom;
      
      setNodes(prev => prev.map(node => 
        node.id === draggingNode 
          ? { 
              ...node, 
              position: { 
                x: node.position.x + dx, 
                y: node.position.y + dy 
              } 
            } 
          : node
      ));
      
      setNodeDragStart({ x: e.clientX, y: e.clientY });
    }
  }, [isDragging, dragStart, zoom, draggingNode, nodeDragStart]);
  
  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
    setDraggingNode(null);
  }, []);
  
  const handleZoomIn = useCallback(() => {
    setZoom(prev => Math.min(prev + 0.1, 3));
  }, []);
  
  const handleZoomOut = useCallback(() => {
    setZoom(prev => Math.max(prev - 0.1, 0.3));
  }, []);
  
  const handleReset = useCallback(() => {
    setZoom(1);
    setPosition({ x: 0, y: 0 });
  }, []);
  
  const handleNodeClick = useCallback((e: React.MouseEvent, nodeId: string) => {
    e.stopPropagation();
    setSelectedNode(nodeId === selectedNode ? null : nodeId);
    setSelectedEdge(null);
    
    const node = nodes.find(n => n.id === nodeId);
    if (node) {
      onNodeClick(node);
    }
  }, [nodes, selectedNode, onNodeClick]);
  
  const handleNodeMouseDown = useCallback((e: React.MouseEvent, nodeId: string) => {
    if (e.button === 0 && !e.altKey) {
      e.stopPropagation();
      setDraggingNode(nodeId);
      setNodeDragStart({ x: e.clientX, y: e.clientY });
    }
  }, []);
  
  const handleEdgeClick = useCallback((e: React.MouseEvent, edgeId: string) => {
    e.stopPropagation();
    setSelectedEdge(edgeId === selectedEdge ? null : edgeId);
    setSelectedNode(null);
    
    const edge = edges.find(e => e.id === edgeId);
    if (edge) {
      onEdgeClick(edge);
    }
  }, [edges, selectedEdge, onEdgeClick]);
  
  const getEdgePath = useCallback(
    (sourceNode: Node, targetNode: Node, loopIndex: number = 0) => {
      const sourceX = sourceNode.position.x;
      const sourceY = sourceNode.position.y;
      const targetX = targetNode.position.x;
      const targetY = targetNode.position.y;
  
      const dx = targetX - sourceX;
      const dy = targetY - sourceY;
      const distance = Math.sqrt(dx * dx + dy * dy);
  
      const nodeRadius = 40;
      const ratio = nodeRadius / distance;
  
      const startX = sourceX + dx * ratio;
      const startY = sourceY + dy * ratio;
      const endX = targetX - dx * ratio;
      const endY = targetY - dy * ratio;
  
      if (sourceNode.id === targetNode.id) {
        const loopSpacing = 20; // distance between loops
        const offset = loopIndex * loopSpacing;
  
        const controlOffsetX = 60 + offset;
        const controlOffsetY = 80 + offset;
  
        return `M ${sourceX} ${sourceY - nodeRadius}
                C ${sourceX - controlOffsetX} ${sourceY - controlOffsetY}, 
                  ${sourceX + controlOffsetX} ${sourceY - controlOffsetY}, 
                  ${sourceX} ${sourceY - nodeRadius}`;
      }
  
      return `M ${startX} ${startY} L ${endX} ${endY}`;
    },
    []
  );
  
  
  const getEdgeLabelPosition = useCallback((sourceNode: Node, targetNode: Node) => {
    if (sourceNode.id === targetNode.id) {
      return {
        x: sourceNode.position.x,
        y: sourceNode.position.y - 80,
      };
    }
    
    const midX = (sourceNode.position.x + targetNode.position.x) / 2;
    const midY = (sourceNode.position.y + targetNode.position.y) / 2;
    
    return { x: midX, y: midY };
  }, []);
  
  const getTransitionsBetweenNodes = useCallback((sourceId: string, targetId: string) => {
    if (!model) return [];
    
    return model.transitions.filter(t => t.from === sourceId && t.to === targetId);
  }, [model]);
  
  const handleBackgroundClick = useCallback(() => {
    setSelectedNode(null);
    setSelectedEdge(null);
  }, []);
  
  const handleExportGraph = useCallback(() => {
    if (!model || !svgElement.current) return;
    
    try {
      const serializer = new XMLSerializer();
      const svgString = serializer.serializeToString(svgElement.current);
      
      const blob = new Blob([svgString], { type: 'image/svg+xml' });
      const url = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `${model.name.replace(/\s+/g, '_')}.svg`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting graph:', error);
    }
  }, [model, svgElement]);
  
  return (
    <Card className={`h-full border rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-gray-800 text-white' : 'bg-white'}`}>
      <div className="p-2 border-b flex justify-between items-center">
        <h3 className="text-sm font-medium">Graph Visualization</h3>
        <div className="flex space-x-1">
          <Button
            size="sm"
            variant="ghost"
            onClick={handleZoomIn}
            title="Zoom in"
            className="h-7 w-7 p-0"
          >
            <ZoomIn className="h-4 w-4" />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={handleZoomOut}
            title="Zoom out"
            className="h-7 w-7 p-0"
          >
            <ZoomOut className="h-4 w-4" />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={handleReset}
            title="Reset view"
            className="h-7 w-7 p-0"
          >
            <Maximize className="h-4 w-4" />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={handleExportGraph}
            title="Export as SVG"
            className="h-7 w-7 p-0"
            disabled={!model}
          >
            <Download className="h-4 w-4" />
          </Button>
        </div>
      </div>
      
      <div 
        className="relative w-full overflow-hidden cursor-grab active:cursor-grabbing"
        style={{ height: 'calc(100% - 40px)' }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onClick={handleBackgroundClick}
      >
        {model ? (
          <svg 
            ref={svgElement}
            className="w-full h-[800px]"
            style={{ 
              cursor: isDragging 
                ? 'grabbing' 
                : draggingNode 
                ? 'grabbing' 
                : 'grab',
            }}
          >
            <g 
              transform={`translate(${position.x}, ${position.y}) scale(${zoom})`}
            >
              {
                (() => {
                  const edgeGroups: Record<string, any[]> = {};
                
                  // Group edges between node pairs (including direction)
                  edges.forEach(edge => {
                    const key = [edge.source, edge.target].sort().join('_');
                    if (!edgeGroups[key]) edgeGroups[key] = [];
                    edgeGroups[key].push(edge);
                  });
                
                  return edges.map(edge => {
                    const sourceNode = nodes.find(n => n.id === edge.source);
                    const targetNode = nodes.find(n => n.id === edge.target);
                
                    if (!sourceNode || !targetNode) return null;
                
                    let loopIndex = 0;
                
                    // Handle self-loop curvature index
                    if (sourceNode.id === targetNode.id) {
                      loopIndex = 1; // Add slight curve for self-loop
                    } else {
                      // Determine curve direction and magnitude for bidirectional/multi-edges
                      const key = [edge.source, edge.target].sort().join('_');
                      const allEdges = edgeGroups[key];
                      const sameDirectionEdges = allEdges.filter(e => e.source === edge.source && e.target === edge.target);
                      const reverseDirectionEdges = allEdges.filter(e => e.source === edge.target && e.target === edge.source);
                
                      const indexInSameDir = sameDirectionEdges.findIndex(e => e.id === edge.id);
                      const totalEdges = allEdges.length;
                
                      // Assign offset index based on direction
                      const sameDirIndex = sameDirectionEdges.length > 1 ? indexInSameDir : 0;
                      const dir = edge.source < edge.target ? 1 : -1; // determine curve side
                
                      loopIndex = dir * ((sameDirIndex - (sameDirectionEdges.length - 1) / 2));
                    }
                
                    const path = getEdgePath(sourceNode, targetNode, loopIndex);
                    const labelPos = getEdgeLabelPosition(sourceNode, targetNode);
                
                    const transitions = getTransitionsBetweenNodes(edge.source, edge.target);
                    const isMultiEdge = transitions.length > 1;
                
                    const transitionIndex = transitions.findIndex(
                      t => t.operation === edge.data.operation
                    );
                
                    let adjustedLabelPos = { ...labelPos };
                    if (isMultiEdge && sourceNode.id !== targetNode.id) {
                      const offset = (transitionIndex - (transitions.length - 1) / 2) * 20;
                      const dx = targetNode.position.x - sourceNode.position.x;
                      const dy = targetNode.position.y - sourceNode.position.y;
                      const length = Math.sqrt(dx * dx + dy * dy);
                      const perpX = -dy / length;
                      const perpY = dx / length;
                
                      adjustedLabelPos.x += perpX * offset;
                      adjustedLabelPos.y += perpY * offset;
                    }
                
                    return (
                      <g
                        key={edge.id}
                        onClick={(e) => handleEdgeClick(e, edge.id)}
                        className="cursor-pointer transition-colors"
                      >
                        <path
                          d={path}
                          stroke={
                            selectedEdge === edge.id
                              ? theme === 'dark'
                                ? '#f59e0b' // amber-500
                                : '#2563eb' // blue-600
                              : theme === 'dark'
                                ? '#4fd1c5' // teal-400
                                : '#3b82f6' // blue-500
                          }
                          strokeWidth={selectedEdge === edge.id ? 3 : 2}
                          fill="none"
                          markerEnd={`url(#arrowhead${selectedEdge === edge.id ? '-selected' : ''})`}
                          className="transition-all duration-200"
                        />
                        <text
                          x={adjustedLabelPos.x}
                          y={adjustedLabelPos.y}
                          textAnchor="middle"
                          dy="-5"
                          fontSize="12"
                          fill={
                            selectedEdge === edge.id
                              ? theme === 'dark'
                                ? '#fcd34d' // amber-300
                                : '#1d4ed8' // blue-700
                              : theme === 'dark'
                                ? '#e2e8f0' // slate-200
                                : '#1e40af' // blue-800
                          }
                          className="pointer-events-none"
                        >
                          {formatTransitionLabel(edge.data)}
                        </text>
                      </g>
                    );
                  });
                })()
              
              }

              
              {nodes.map(node => (
                <g 
                  key={node.id}
                  transform={`translate(${node.position.x}, ${node.position.y})`}
                  onClick={(e) => handleNodeClick(e, node.id)}
                  onMouseDown={(e) => handleNodeMouseDown(e, node.id)}
                  className={`cursor-${draggingNode === node.id ? 'grabbing' : 'pointer'} transition-colors`}
                >
                  <circle
                    r={40}
                    fill={
                      selectedNode === node.id
                        ? theme === 'dark' 
                          ? '#374151' // gray-700
                          : '#f3f4f6' // gray-100
                        : theme === 'dark' 
                          ? '#1f2937' // gray-800
                          : '#ffffff' // white
                    }
                    stroke={
                      selectedNode === node.id
                        ? (theme === 'dark' ? '#f59e0b' : '#2563eb') // amber-500 or blue-600
                        : node.data.isInitial
                        ? '#22c55e' // green-500
                        : (theme === 'dark' ? '#6b7280' : '#9ca3af') // gray-500 or gray-400
                    }
                    strokeWidth={node.data.isFinal ? 4 : 2}
                    className="transition-all duration-200"
                  />
                  
                  {node.data.isFinal && (
                    <circle
                      r={34}
                      fill="none"
                      stroke={
                        selectedNode === node.id
                          ? (theme === 'dark' ? '#f59e0b' : '#2563eb') // amber-500 or blue-600
                          : (theme === 'dark' ? '#6b7280' : '#9ca3af') // gray-500 or gray-400
                      }
                      strokeWidth={2}
                      className="transition-colors duration-200"
                    />
                  )}
                  
                  <text
                    textAnchor="middle"
                    dy="5"
                    fontSize="14"
                    fontWeight={node.data.isInitial ? "bold" : "normal"}
                    fill={theme === 'dark' ? '#e2e8f0' : '#1e293b'} // slate-200 or slate-800
                    className="pointer-events-none"
                  >
                    {node.data.label}
                  </text>
                </g>
              ))}
              
              <defs>
                <marker
                  id="arrowhead"
                  viewBox="0 0 10 10"
                  refX="8"
                  refY="5"
                  markerWidth="6"
                  markerHeight="6"
                  orient="auto"
                >
                  <path
                    d="M 0 0 L 10 5 L 0 10 z"
                    fill={theme === 'dark' ? '#4fd1c5' : '#3b82f6'} // teal-400 or blue-500
                  />
                </marker>
                <marker
                  id="arrowhead-selected"
                  viewBox="0 0 10 10"
                  refX="8"
                  refY="5"
                  markerWidth="6"
                  markerHeight="6"
                  orient="auto"
                >
                  <path
                    d="M 0 0 L 10 5 L 0 10 z"
                    fill={theme === 'dark' ? '#f59e0b' : '#2563eb'} // amber-500 or blue-600
                  />
                </marker>
              </defs>
            </g>
          </svg>
        ) : (
          <div className="flex items-center justify-center h-full text-gray-500">
            <p>Select a model to visualize or create a new one</p>
          </div>
        )}
      </div>
      
      {model && nodes.length > 0 && (
        <div className={`absolute bottom-4 right-4 w-48 h-48 border rounded overflow-hidden ${
          theme === 'dark' ? 'bg-gray-900 border-gray-700' : 'bg-gray-100 border-gray-300'
        }`}>
          <svg className="w-full h-full">
            {edges.map((edge, index) => {
              const sourceNode = nodes.find(n => n.id === edge.source);
              const targetNode = nodes.find(n => n.id === edge.target);
              
              if (!sourceNode || !targetNode) return null;
              
              const sourceX = (sourceNode.position.x / 1000) * 144 + 24;
              const sourceY = (sourceNode.position.y / 800) * 144 + 24;
              const targetX = (targetNode.position.x / 1000) * 144 + 24;
              const targetY = (targetNode.position.y / 800) * 144 + 24;
              
              return (
                <line
                  key={`minimap-edge-${index}`}
                  x1={sourceX}
                  y1={sourceY}
                  x2={targetX}
                  y2={targetY}
                  stroke={theme === 'dark' ? '#4fd1c5' : '#3b82f6'} // teal-400 or blue-500
                  strokeWidth="1"
                />
              );
            })}
            
            {nodes.map(node => (
              <circle
                key={`minimap-${node.id}`}
                cx={(node.position.x / 1000) * 144 + 24}
                cy={(node.position.y / 800) * 144 + 24}
                r={node.data.isInitial || node.data.isFinal ? 4 : 3}
                fill={
                  node.data.isInitial
                    ? '#22c55e' // green-500
                    : selectedNode === node.id
                    ? (theme === 'dark' ? '#f59e0b' : '#2563eb') // amber-500 or blue-600
                    : (theme === 'dark' ? '#4fd1c5' : '#3b82f6') // teal-400 or blue-500
                }
                stroke={
                  node.data.isFinal
                    ? (theme === 'dark' ? '#e2e8f0' : '#1e293b') // slate-200 or slate-800
                    : 'none'
                }
                strokeWidth="1"
              />
            ))}
            
            <rect
              x={((-position.x / zoom) / 1000) * 144 + 24}
              y={((-position.y / zoom) / 800) * 144 + 24}
              width={(144 / zoom)}
              height={(144 / zoom)}
              fill="none"
              stroke={theme === 'dark' ? 'white' : 'black'}
              strokeWidth="1"
              strokeDasharray="2,2"
              opacity="0.5"
            />
          </svg>
        </div>
      )}
    </Card>
  );
};
