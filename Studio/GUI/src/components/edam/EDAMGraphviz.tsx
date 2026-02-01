import React from 'react';
import { Graphviz } from 'graphviz-react';
import type {EDAMModel} from "@edams-models/edam/types";
import { Card } from '@/components/ui/card';
import { useTheme } from './ThemeProvider';
import { formatTransitionLabel } from './utils';

interface EDAMGraphvizProps {
  model: EDAMModel | null;
  onNodeClick?: (nodeName: string) => void;
  onEdgeClick?: (source: string, target: string, operation: string) => void;
}

export const EDAMGraphviz: React.FC<EDAMGraphvizProps> = ({ 
  model, 
  onNodeClick,
  onEdgeClick
}) => {
  const { theme } = useTheme();

  const generateDotGraph = () => {
    if (!model) return '';

    const nodeColor = theme === 'dark' ? '#4fd1c5' : '#3b82f6';
    const edgeColor = theme === 'dark' ? '#4fd1c5' : '#3b82f6';
    const initialColor = '#22c55e';
    const finalColor = theme === 'dark' ? '#f59e0b' : '#ea580c';
    const bgColor = theme === 'dark' ? '#1f2937' : '#ffffff';
    const textColor = theme === 'dark' ? '#e2e8f0' : '#1e293b';

    let dot = `digraph G {
      bgcolor="${bgColor}";
      node [style="filled", fillcolor="${bgColor}", color="${nodeColor}", fontcolor="${textColor}", shape=circle, fontname="Arial", height=0.7, width=0.7];
      edge [color="${edgeColor}", fontcolor="${textColor}", fontname="Arial", fontsize=10];
      rankdir=LR;
    `;

    // Add nodes
    for (const state of model.states) {
      const isInitial = state === model.initialState;
      const isFinal = model.finalStates?.includes(state) || false;
      
      let nodeAttributes = [];
      
      if (isInitial) {
        nodeAttributes.push(`color="${initialColor}"`);
        nodeAttributes.push('penwidth=2');
      }
      
      if (isFinal) {
        nodeAttributes.push(`color="${finalColor}"`);
        nodeAttributes.push('peripheries=2');
        nodeAttributes.push('penwidth=2');
      }
      
      dot += `  "${state}" [${nodeAttributes.join(', ')}];\n`;
    }

    // Group transitions between same nodes for better labeling
    const transitionGroups: Record<string, Array<{ operation: string, guard?: any }>> = {};
    
    for (const transition of model.transitions) {
      const key = `${transition.from}|${transition.to}`;
      if (!transitionGroups[key]) {
        transitionGroups[key] = [];
      }
      
      transitionGroups[key].push({
        operation: transition.operation,
        guard: transition.guard
      });
    }

    // Add edges with labels
    for (const [key, transitions] of Object.entries(transitionGroups)) {
      const [source, target] = key.split('|');
      const operations = transitions.map(t => t.operation).join('\\n');
      
      if (source === target) {
        // Self-loop needs special handling
        dot += `  "${source}" -> "${target}" [label="${operations}", constraint=false, minlen=2];\n`;
      } else {
        dot += `  "${source}" -> "${target}" [label="${operations}"];\n`;
      }
    }

    dot += '}';
    return dot;
  };

  const handleNodeClick = (event: React.MouseEvent<HTMLDivElement>) => {
    // Extract node id from event by traversing the DOM
    const target = event.target as HTMLElement;
    
    // Look for SVG elements within the clicked div
    const svgElement = target.closest('svg') || target.querySelector('svg');
    if (svgElement) {
      const titleElem = svgElement.querySelector('title');
      if (titleElem && onNodeClick) {
        const nodeName = titleElem.textContent;
        if (nodeName) onNodeClick(nodeName);
      }
    }
  };

  return (
    <Card className={`h-full border rounded-lg overflow-hidden ${theme === 'dark' ? 'bg-gray-800 text-white' : 'bg-white'}`}>
      <div className="p-4 flex flex-col h-full">
        {model ? (
          <div className="flex-1 overflow-auto" onClick={handleNodeClick}>
            <Graphviz
              dot={generateDotGraph()}
              options={{
                fit: true,
                height: 700,
                width: '100%',
                zoom: true
              }}
            />
          </div>
        ) : (
          <div className="flex items-center justify-center h-full text-gray-500">
            <p>Select a model to visualize or create a new one</p>
          </div>
        )}
      </div>
    </Card>
  );
};
