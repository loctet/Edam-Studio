
import React from 'react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { useTheme } from './ThemeProvider';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

interface HelpModalProps {
  onClose: () => void;
}

export const HelpModal: React.FC<HelpModalProps> = ({ onClose }) => {
  const { theme } = useTheme();

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>EDAM Modeling Studio Help</DialogTitle>
          <DialogDescription>
            Learn how to use the EDAM Modeling Studio effectively
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="basics">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="basics">Basics</TabsTrigger>
            <TabsTrigger value="states">States</TabsTrigger>
            <TabsTrigger value="transitions">Transitions</TabsTrigger>
            <TabsTrigger value="tips">Tips & Shortcuts</TabsTrigger>
          </TabsList>
          
          <TabsContent value="basics" className="space-y-4 py-4">
            <h3 className="text-lg font-medium">Getting Started</h3>
            <p>
              The EDAM Modeling Studio allows you to create, visualize, and edit Distributed Automata for 
              Smart Contract Models (EDAMs).
            </p>
            
            <h4 className="text-md font-medium mt-4">Key Features</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>Select from predefined models or create your own</li>
              <li>Interactive graph visualization of states and transitions</li>
              <li>Add, edit, and delete states and transitions</li>
              <li>Define complex transition properties like guards and assignments</li>
              <li>Edit models directly in JSON format</li>
              <li>Dark/light mode support</li>
              <li>Export your models as JSON or SVG</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Graph Navigation</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>Pan:</strong> Middle-click and drag (or Alt + left-click and drag)</li>
              <li><strong>Zoom:</strong> Use the zoom buttons or mouse wheel</li>
              <li><strong>Reset View:</strong> Click the Reset button in the toolbar</li>
              <li><strong>Move Nodes:</strong> Drag nodes to reposition them</li>
              <li><strong>Select:</strong> Click on states or transitions to view details</li>
            </ul>
          </TabsContent>
          
          <TabsContent value="states" className="space-y-4 py-4">
            <h3 className="text-lg font-medium">Working with States</h3>
            <p>
              States represent the different stages of your model. Each state has a unique name and can be 
              marked as either an initial state or a final state.
            </p>
            
            <h4 className="text-md font-medium mt-4">State Types</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>Initial state:</strong> The starting point of the model (green border)</li>
              <li><strong>Final state:</strong> An end state of the model (double border)</li>
              <li><strong>Regular state:</strong> An intermediate state in the model</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Creating States</h4>
            <p>
              Use the "Add State" button in the sidebar to create a new state. You'll need to:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Enter a unique name for the state</li>
              <li>Optionally mark it as an initial or final state</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Managing States</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>Click on a state in the graph to view its details</li>
              <li>Delete a state by selecting it and clicking "Delete" (note: you cannot delete states that have associated transitions)</li>
              <li>Drag states in the graph to arrange your model visually</li>
            </ul>
          </TabsContent>
          
          <TabsContent value="transitions" className="space-y-4 py-4">
            <h3 className="text-lg font-medium">Working with Transitions</h3>
            <p>
              Transitions connect states and define how the model evolves. Each transition includes source and 
              target states along with various properties.
            </p>
            
            <h4 className="text-md font-medium mt-4">Transition Properties</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>From/To:</strong> Source and target states</li>
              <li><strong>Operation:</strong> The action performed during this transition</li>
              <li><strong>Guard Condition:</strong> A boolean expression that must be true for the transition to occur</li>
              <li><strong>Participant Variables:</strong> Entities involved in the transition</li>
              <li><strong>Rho and Rho':</strong> Smart contract variables</li>
              <li><strong>Assignments:</strong> State changes to execute during the transition</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Creating Transitions</h4>
            <p>
              Use the "Add Transition" button in the sidebar to create a new transition. You must specify:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Source state (where the transition starts)</li>
              <li>Target state (where the transition ends)</li>
              <li>Operation name (what action is performed)</li>
              <li>Optionally add guards, participants, and other properties</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Managing Transitions</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>Click on a transition in the graph to view its details</li>
              <li>Delete a transition by selecting it and clicking "Delete"</li>
              <li>Two states can have multiple transitions between them with different operations</li>
            </ul>
          </TabsContent>
          
          <TabsContent value="tips" className="space-y-4 py-4">
            <h3 className="text-lg font-medium">Tips & Shortcuts</h3>
            
            <h4 className="text-md font-medium">Graph Interaction</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>Click on the background to deselect nodes and transitions</li>
              <li>Use the mini-map in the bottom-right corner for navigation in complex graphs</li>
              <li>The zoom controls allow precise adjustments to the view</li>
              <li>Export your visualization as an SVG file for use in documentation</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">JSON Editor</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>The JSON editor allows direct editing of the model structure</li>
              <li>Changes in the JSON editor are reflected in the graph visualization</li>
              <li>Validation errors will be displayed at the bottom of the editor</li>
              <li>Use the Import/Export buttons to save and load models</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Best Practices</h4>
            <ul className="list-disc pl-5 space-y-1">
              <li>Keep your model organized by arranging states logically</li>
              <li>Use descriptive state names that reflect their purpose</li>
              <li>Add guard conditions to make transition logic clear</li>
              <li>Export your models regularly to avoid data loss</li>
              <li>Check the validation before finalizing your model</li>
            </ul>
            
            <h4 className="text-md font-medium mt-4">Theme</h4>
            <p>
              Toggle between dark and light mode using the sun/moon icon in the header.
              Your preference will be remembered for future sessions.
            </p>
          </TabsContent>
        </Tabs>

        <DialogFooter className="mt-6">
          <Button onClick={onClose}>Close</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
