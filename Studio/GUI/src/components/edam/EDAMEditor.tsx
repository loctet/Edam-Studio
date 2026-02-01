import React, { useState, useCallback, useEffect, useRef } from 'react';
import axios from 'axios';
import { EDAMHeader } from './EDAMHeader';
import { EDAMSidebar } from './EDAMSidebar';
import { EDAMGraph } from './EDAMGraph';
import { EDAMJsonEditor } from './EDAMJsonEditor';
import { EDAMTextEditor } from './EDAMTextEditor';
import { TransitionModal } from './TransitionModal';
import { StateModal } from './StateModal';
import { HelpModal } from './HelpModal';
import { NewModelModal } from './NewModelModal';
import { ConfigModal, getConfigSettings } from './ConfigModal';
import CodeGenerationResults from './CodeGenerationResults';
import { useTheme } from './ThemeProvider';
import { createEmptyModel, exportModelAsJson, validateModel } from './utils';
import { generateEDAM } from '@edams-models/edam/modelGenerator';
import { getPremadeModelsArray } from './premadeModels';
import { useToast } from "@/components/ui/use-toast";
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ResizablePanelGroup, ResizablePanel, ResizableHandle } from '@/components/ui/resizable';
import { ScrollArea } from '@/components/ui/scroll-area';
import { TraceTestModal } from './TraceTestModal';
import { EDAMGraphviz } from './EDAMGraphviz';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import type { EDAMModel, EDAMTransition, ExternalCall } from "@edams-models/edam/types";
import config from '@config';

const SERVER_URL = `http://${config.api.host}:${config.api.default_port}`;

export const EDAMEditor: React.FC = () => {
  const premadeModels = getPremadeModelsArray();
  
  const [allModels, setAllModels] = useState<EDAMModel[]>(premadeModels);
  const [selectedModel, setSelectedModel] = useState<EDAMModel | null>(null);
  const [edamList, setEdamList] = useState<EDAMModel[]>([]);
  const [showTransitionModal, setShowTransitionModal] = useState(false);
  const [showStateModal, setShowStateModal] = useState(false);
  const [showHelpModal, setShowHelpModal] = useState(false);
  const [showNewModelModal, setShowNewModelModal] = useState(false);
  const [showConfigModal, setShowConfigModal] = useState(false);
  const [jsonValue, setJsonValue] = useState("");
  const [selectedElement, setSelectedElement] = useState<any>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [testLang, setTestLang] = useState("solidity");
  const [codeError, setCodeError] = useState<string | null>(null);
  const [responseImages, setResponseImages] = useState<string[]>([]);
  const [responseContents, setResponseContents] = useState<string[]>([]);
  const [emptyRoleCheck, setEmptyRoleCheck] = useState<string[]>([]);
  const [emptyRoleCheckIssues, setEmptyRoleCheckIssues] = useState<[string, string][]>([]);
  const [downloadLink, setDownloadLink] = useState<string | null>(null);
  const [testingResultData, setTestingResultData] = useState<string | null>(null);
  const [editingTransition, setEditingTransition] = useState<EDAMTransition | undefined>();
  const [isTraceTestOpen, setIsTraceTestOpen] = useState(false);
  const [testResult, setTestResult] = useState<string | null>(null);
  const { theme } = useTheme();
  const svgRef = useRef<SVGElement | null>(null);
  const { toast } = useToast();
  const [editingStateName, setEditingStateName] = useState<string | undefined>();
  const [activeTab, setActiveTab] = useState<string>("force-directed");
  const [showAIModal, setShowAIModal] = useState(false);
  const [textEditorValue, setTextEditorValue] = useState<string>("");

  useEffect(() => {
    const hasVisitedBefore = localStorage.getItem('edam_visited');
    if (!hasVisitedBefore) {
      setShowHelpModal(true);
      localStorage.setItem('edam_visited', 'true');
    }
    
    if (allModels.length > 0 && !selectedModel) {
      handleModelSelect(allModels[0]);
    }
  }, []);

  const handleModelSelect = useCallback((model: EDAMModel) => {
    setSelectedModel(model);
    setJsonValue(JSON.stringify(model, null, 2));
    setSelectedElement(null);
  }, []);

  const handleCreateNewModel = useCallback(() => {
    setShowNewModelModal(true);
  }, []);

  const handleNewModelSubmit = useCallback((model: EDAMModel) => {
    if (allModels.some(m => m.name === model.name)) {
      let counter = 1;
      let newName = `${model.name} (${counter})`;
      while (allModels.some(m => m.name === newName)) {
        counter++;
        newName = `${model.name} (${counter})`;
      }
      model.name = newName;
    }
    
    setAllModels(prev => [...prev, model]);
    handleModelSelect(model);
    toast({
      title: "Model created",
      description: `Model "${model.name}" has been created successfully.`
    });
  }, [allModels, handleModelSelect, toast]);

  const handleComposedModelCreated = useCallback((model: EDAMModel) => {
    handleNewModelSubmit(model);
  }, [handleNewModelSubmit]);

  const handleImportModel = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const content = event.target?.result as string;
          const newModel = JSON.parse(content) as EDAMModel;
          
          if (allModels.some(m => m.name === newModel.name)) {
            let counter = 1;
            let newName = `${newModel.name} (${counter})`;
            while (allModels.some(m => m.name === newName)) {
              counter++;
              newName = `${newModel.name} (${counter})`;
            }
            newModel.name = newName;
          }
          
          setAllModels(prev => [...prev, newModel]);
          handleModelSelect(newModel);
          toast({
            title: "Model imported",
            description: `Model "${newModel.name}" has been imported successfully.`
          });
        } catch (error) {
          toast({
            variant: "destructive",
            title: "Import Error",
            description: 'Invalid JSON file: ' + (error as Error).message
          });
        }
      };
      reader.readAsText(file);
    };
    input.click();
  }, [allModels, handleModelSelect, toast]);

  const handleExportModel = useCallback(() => {
    if (selectedModel) {
      exportModelAsJson(selectedModel);
      toast({
        title: "Model exported",
        description: `Model "${selectedModel.name}" has been exported as JSON.`
      });
    }
  }, [selectedModel, toast]);

  const handleJsonChange = useCallback((value: string) => {
    setJsonValue(value);
    try {
      const updatedModel = JSON.parse(value) as EDAMModel;
      
      setSelectedModel(updatedModel);
      setAllModels(prev => 
        prev.map(m => m.name === updatedModel.name ? updatedModel : m)
      );
    } catch (e) {
      console.error("Invalid JSON", e);
    }
  }, []);

  const handleNodeClick = useCallback((node: any) => {
    setSelectedElement({ type: 'node', data: node });
  }, []);

  const handleEdgeClick = useCallback((edge: any) => {
    setSelectedElement({ type: 'edge', data: edge });
  }, []);

  const handleAddTransition = useCallback((newTransition: EDAMTransition) => {
    if (!selectedModel) return;
    
    let updatedTransitions: EDAMTransition[];
    
    if (editingTransition) {
      updatedTransitions = selectedModel.transitions.map(t => 
        t === editingTransition ? newTransition : t
      );
      setEditingTransition(undefined);
    } else {
      updatedTransitions = [...selectedModel.transitions, newTransition];
    }
    
    const updatedModel = {
      ...selectedModel,
      transitions: updatedTransitions
    };
    
    setSelectedModel(updatedModel);
    setAllModels(prev => 
      prev.map(m => m.name === updatedModel.name ? updatedModel : m)
    );
    setJsonValue(JSON.stringify(updatedModel, null, 2));
    setShowTransitionModal(false);
  }, [selectedModel, editingTransition]);

  const handleAddState = useCallback((state: string, oldStateName?: string) => {
    if (!selectedModel) return;
    
    if (oldStateName) {
      // Edit existing state - update state name and all references in transitions
      const updatedStates = selectedModel.states.map(s => 
        s === oldStateName ? state : s
      );
      
      // Update transitions that reference this state
      const updatedTransitions = selectedModel.transitions.map(t => ({
        ...t,
        from: t.from === oldStateName ? state : t.from,
        to: t.to === oldStateName ? state : t.to
      }));
      
      // Update initialState if needed
      let updatedInitialState = selectedModel.initialState;
      if (selectedModel.initialState === oldStateName) {
        updatedInitialState = state;
      }
      
      // Update finalStates if needed
      let updatedFinalStates = selectedModel.finalStates || [];
      if (updatedFinalStates.includes(oldStateName)) {
        updatedFinalStates = updatedFinalStates.map(s => 
          s === oldStateName ? state : s
        );
      }
      
      const updatedModel = {
        ...selectedModel,
        states: updatedStates,
        transitions: updatedTransitions,
        initialState: updatedInitialState,
        finalStates: updatedFinalStates
      };
      
      setSelectedModel(updatedModel);
      setAllModels(prev => 
        prev.map(m => m.name === updatedModel.name ? updatedModel : m)
      );
      setJsonValue(JSON.stringify(updatedModel, null, 2));
      
      // Update selected element if it's the renamed state
      if (selectedElement?.type === 'node' && selectedElement?.data?.id === oldStateName) {
        setSelectedElement({
          ...selectedElement,
          data: { ...selectedElement.data, id: state }
        });
      }
      
      toast({
        title: "State updated",
        description: `State "${oldStateName}" has been renamed to "${state}".`
      });
    } else {
      // Add new state
      const updatedModel = {
        ...selectedModel,
        states: [...selectedModel.states, state]
      };
      
      setSelectedModel(updatedModel);
      setAllModels(prev => 
        prev.map(m => m.name === updatedModel.name ? updatedModel : m)
      );
      setJsonValue(JSON.stringify(updatedModel, null, 2));
      
      toast({
        title: "State added",
        description: `State "${state}" has been added successfully.`
      });
    }
    
    setEditingStateName(undefined);
    setShowStateModal(false);
  }, [selectedModel, selectedElement, toast]);

  const handleDeleteTransition = useCallback((transitionIndex: number) => {
    if (!selectedModel) return;
    
    const updatedTransitions = [...selectedModel.transitions];
    updatedTransitions.splice(transitionIndex, 1);
    
    const updatedModel = {
      ...selectedModel,
      transitions: updatedTransitions
    };
    
    setSelectedModel(updatedModel);
    setAllModels(prev => 
      prev.map(m => m.name === updatedModel.name ? updatedModel : m)
    );
    setJsonValue(JSON.stringify(updatedModel, null, 2));
    setSelectedElement(null);
  }, [selectedModel]);

  const handleDeleteState = useCallback((stateName: string) => {
    if (!selectedModel) return;
    
    const isStateUsed = selectedModel.transitions.some(
      t => t.from === stateName || t.to === stateName
    );
    
    if (isStateUsed) {
      toast({
        variant: "destructive",
        title: "Cannot delete state",
        description: "Cannot delete state that is used in transitions. Remove related transitions first."
      });
      return;
    }
    
    const updatedStates = selectedModel.states.filter(s => s !== stateName);
    
    let updatedInitialState = selectedModel.initialState;
    let updatedFinalStates = selectedModel.finalStates || [];
    
    if (selectedModel.initialState === stateName && updatedStates.length > 0) {
      updatedInitialState = updatedStates[0];
    }
    
    if (selectedModel.finalStates?.includes(stateName)) {
      updatedFinalStates = updatedFinalStates.filter(s => s !== stateName);
    }
    
    const updatedModel = {
      ...selectedModel,
      states: updatedStates,
      initialState: updatedInitialState,
      finalStates: updatedFinalStates
    };
    
    setSelectedModel(updatedModel);
    setAllModels(prev => 
      prev.map(m => m.name === updatedModel.name ? updatedModel : m)
    );
    setJsonValue(JSON.stringify(updatedModel, null, 2));
    setSelectedElement(null);
  }, [selectedModel, toast]);

  const handleSvgRef = useCallback((node: SVGElement | null) => {
    svgRef.current = node;
  }, []);

  const handleExportForBackend = useCallback(() => {
    if (selectedModel) {
      try {
        const ocamlModel = generateEDAM(selectedModel);
        console.log('Generated OCAML model:', ocamlModel);
        
        const blob = new Blob([ocamlModel], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${selectedModel.name.replace(/\s+/g, '_')}.ml`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        toast({
          title: "OCaml model exported",
          description: `Model "${selectedModel.name}" has been exported as OCaml.`
        });
      } catch (error) {
        toast({
          variant: "destructive",
          title: "Export Error",
          description: 'Error generating OCaml model: ' + (error as Error).message
        });
      }
    }
  }, [selectedModel, toast]);

  // Helper function to extract model dependencies from variables
  const getModelDependencies = useCallback((model: EDAMModel, visited: Set<string> = new Set()): EDAMModel[] => {
    const dependencies: EDAMModel[] = [];
    
    // Prevent infinite recursion
    if (visited.has(model.name)) {
      return dependencies;
    }
    visited.add(model.name);
    
    if (!model.variables) {
      return dependencies;
    }
    
    // Get all model names for matching
    const allModelNames = allModels.map(m => m.name);
    
    // Check each variable
    for (const [varName, varType] of Object.entries(model.variables)) {
      if (!varType) continue;
      
      // Skip primitive types
      const primitiveTypes = ['int', 'string', 'bool', 'address', 'list_int', 'list_string', 
        'map_address_int', 'map_map_address_address_int'];
      const isPrimitive = primitiveTypes.some(pt => {
        const lowerType = varType.toLowerCase();
        return lowerType === pt || lowerType.startsWith(pt + '_') || lowerType.includes('_' + pt);
      });
      if (isPrimitive) {
        continue;
      }
      
      // Try to find matching model
      let matchingModel: EDAMModel | undefined;
      
      // 1. Exact match: variable type exactly matches a model name (most common case)
      matchingModel = allModels.find(m => m.name === varType);
      
      // 2. Exact match: variable name exactly matches a model name
      if (!matchingModel) {
        matchingModel = allModels.find(m => m.name === varName);
      }
      
      // 3. Partial match: type contains a model name (prioritize longer matches)
      if (!matchingModel) {
        // Sort model names by length (longest first) to prioritize better matches
        const sortedModelNames = [...allModelNames].sort((a, b) => b.length - a.length);
        for (const modelName of sortedModelNames) {
          if (varType === modelName || varType.includes(modelName)) {
            matchingModel = allModels.find(m => m.name === modelName);
            if (matchingModel) break;
          }
        }
      }
      
      // 4. Variable name contains a model name
      if (!matchingModel) {
        const sortedModelNames = [...allModelNames].sort((a, b) => b.length - a.length);
        for (const modelName of sortedModelNames) {
          if (varName === modelName || varName.includes(modelName)) {
            matchingModel = allModels.find(m => m.name === modelName);
            if (matchingModel) break;
          }
        }
      }
      
      // If we found a matching model and it's not already added
      if (matchingModel && !dependencies.some(d => d.name === matchingModel!.name)) {
        // Recursively get dependencies of this dependency
        const depDependencies = getModelDependencies(matchingModel, new Set(visited));
        for (const depDep of depDependencies) {
          if (!dependencies.some(d => d.name === depDep.name)) {
            dependencies.push(depDep);
          }
        }
        // Add the dependency itself
        dependencies.push(matchingModel);
      }
    }
    
    return dependencies;
  }, [allModels]);

  const handleAddModelToList = useCallback(() => {
    if (selectedModel) {
      const errorsList = validateModel(selectedModel);
      console.log(errorsList)
      if (errorsList.length != 0)  {
        toast({
          variant: "destructive",
          title: "Model is not valid",
          description: `Model "${selectedModel.name}" is  not valid. ${errorsList}`
        });
        return
      }
      
      // Check if model is already in the list
      if (edamList.some(m => m.name === selectedModel.name)) {
        toast({
          variant: "destructive",
          title: "Model already in list",
          description: `Model "${selectedModel.name}" is already in the generation list.`
        });
        return;
      }

      // Get model dependencies
      const dependencies = getModelDependencies(selectedModel);
      const allModelsToAdd: EDAMModel[] = [];
      const addedNames = new Set<string>(edamList.map(m => m.name));
      
      // Add dependencies first
      for (const dep of dependencies) {
        if (!addedNames.has(dep.name)) {
          allModelsToAdd.push(dep);
          addedNames.add(dep.name);
        }
      }
      
      // Add the main model last
      allModelsToAdd.push(selectedModel);
      
      // Update the list with dependencies first, then the model
      setEdamList(prev => [...prev, ...allModelsToAdd]);
      
      if (dependencies.length > 0) {
        const depNames = dependencies.map(d => d.name).join(', ');
        toast({
          title: "Models added to list",
          description: `Added dependencies (${depNames}) and model "${selectedModel.name}" to the generation list.`
        });
      } else {
        toast({
          title: "Model added to list",
          description: `Model "${selectedModel.name}" has been added to the generation list.`
        });
      }
    }
  }, [selectedModel, edamList, toast, getModelDependencies]);

  const handleRemoveModelFromList = useCallback((index: number) => {
    setEdamList(prev => prev.filter((_, i) => i !== index));
  }, []);

  const handleGenerateCode = useCallback(async () => {
    setIsGenerating(true);
    setCodeError(null);
    setResponseImages([]);
    setResponseContents([]);
    setEmptyRoleCheck([]);
    setEmptyRoleCheckIssues([]);
    setDownloadLink(null);
    setTestingResultData(null);

    const modelList = edamList.length > 0 ? edamList : (selectedModel ? [selectedModel] : []);
    
    if (modelList.length === 0) {
      toast({
        variant: "destructive",
        title: "No models to generate",
        description: "Please add at least one model to the generation list."
      });
      setIsGenerating(false);
      return;
    }
  
    const payload = {
      models: modelList.map((model) => ({
        edamCode: generateEDAM(model),
        name: model.name,
      })),
      server_settings: getConfigSettings(),
      target_language: testLang
    };
  
    try {
      console.log('Sending payload to server:', payload);
      const response = await axios.post(
          `${SERVER_URL}/api/convert-bulk`,
          payload,
          {
              validateStatus: (status) => status >= 200 && status < 300, // Accept only 2xx status codes
          }
      );

      if (response.status === 200) {
          const {
              zip_url,
              images,
              list_contents,
              list_empty_role_check,
              list_empty_role_check_issues,
          } = response.data;
          console.log(zip_url,
            images,
            list_contents,
            list_empty_role_check,
            list_empty_role_check_issues)
          setResponseImages(images);
          setResponseContents(list_contents);
          setEmptyRoleCheck(list_empty_role_check);
          setEmptyRoleCheckIssues(list_empty_role_check_issues as [string, string][]);
          setDownloadLink(zip_url);
          toast({
            title: "Code generated",
            description: "Code has been generated successfully."
          });
          setIsGenerating(false);
      }
    } catch (error) {
      console.error("Error generating code:", error);
  
      if (error instanceof Error) {
        setCodeError(error.message);
      } else {
        setCodeError("An unknown error occurred during code generation.");
      }
      
      toast({
        variant: "destructive",
        title: "Generation Error",
        description: "Failed to generate code. See details below."
      });
      
      setIsGenerating(false);
    }
  }, [edamList, selectedModel, testLang, toast]);

  const handleDownloadFile = useCallback(async () => {
    if (!downloadLink) return;

    const response = await axios.get(`${SERVER_URL}/api/download-file/${downloadLink}`, {
      responseType: "blob",
    });
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", downloadLink);
    document.body.appendChild(link);
    link.click();
    link.remove();
    
    toast({
      title: "Download started",
      description: "Your file is being downloaded."
    });
  }, [downloadLink, toast]);

  const handleRunTestFile = useCallback(async () => {
    if (!downloadLink) return;

    setTestingResultData(null);
    setIsGenerating(true);
    const response = await axios.get(`${SERVER_URL}/api/run-test-file/${downloadLink}`);
    setTestingResultData(response.data.data);
    setIsGenerating(false);
    
    toast({
      title: "Test run started",
      description: ""
    });
  }, [downloadLink, toast]);


  const handleEditTransition = useCallback((transition: EDAMTransition, index: number) => {
    setEditingTransition(transition);
    setShowTransitionModal(true);
  }, []);

  const handleEditState = useCallback((stateName: string) => {
    setEditingStateName(stateName);
    setShowStateModal(true);
  }, []);

  const handleGraphvizNodeClick = useCallback((nodeName: string) => {
    if (selectedModel) {
      const nodeData = { id: nodeName };
      setSelectedElement({ type: 'node', data: nodeData });
    }
  }, [selectedModel]);

  const handleGraphvizEdgeClick = useCallback((source: string, target: string, operation: string) => {
    if (selectedModel) {
      const edgeData = { source, target, operation };
      setSelectedElement({ type: 'edge', data: edgeData });
    }
  }, [selectedModel]);
  
  const handleTraceTest = async (trace: string) => {
    const modelList = edamList.length > 0 ? edamList : (selectedModel ? [selectedModel] : []);

    if (modelList.length === 0) {
      toast({
        variant: "destructive",
        title: "No models to generate",
        description: "Please add at least one model to the generation list."
      });
      return;
    }
    try {
      const response = await fetch(`${SERVER_URL}/api/execute-edam-trace`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          models: modelList.map((model) => ({
            edamCode: generateEDAM(model),
            name: model.name,
          })),
          
          trace_text: trace
        }),
      });

      const data = await response.json();
      if (response.ok) {
        setTestResult(data.result);
      } else {
        throw new Error(data.error || 'Failed to execute trace test');
      }
    } catch (error) {
      console.error('Error executing trace test:', error);
      setTestResult(`Error: ${error.message}`);
    }
  };

  const handleCreateNewModelAI = useCallback(() => {
    setShowAIModal(true);
  }, []);

  const handleTextEditorViewEDAM = useCallback((model: EDAMModel) => {
    // Check if model name already exists
    if (allModels.some(m => m.name === model.name)) {
      let counter = 1;
      let newName = `${model.name} (${counter})`;
      while (allModels.some(m => m.name === newName)) {
        counter++;
        newName = `${model.name} (${counter})`;
      }
      model.name = newName;
    }
    
    setAllModels(prev => [...prev, model]);
    handleModelSelect(model);
    toast({
      title: "EDAM loaded",
      description: `EDAM "${model.name}" has been loaded from text editor.`
    });
  }, [allModels, handleModelSelect, toast]);


  return (
    <div className={`edam-editor ${theme === 'dark' ? 'bg-gray-900 text-gray-100' : 'bg-white text-gray-900'} min-h-screen flex flex-col`}>
      <EDAMHeader 
        models={allModels} 
        selectedModel={selectedModel}
        onModelSelect={handleModelSelect}
        onCreateNewModel={handleCreateNewModel}
        onExportModel={handleExportModel}
        onImportModel={handleImportModel}
        onHelp={() => setShowHelpModal(true)}
        onExportOcaml={handleExportForBackend}
        onGenerateCode={handleGenerateCode}
        onOpenConfig={() => setShowConfigModal(true)}
        isGenerating={isGenerating}
        onCreateNewModelAI={handleCreateNewModelAI}
      />
      
      <div className="flex flex-1 overflow-hidden">
        <EDAMSidebar 
          model={selectedModel} 
          selectedElement={selectedElement}
          onAddTransition={() => {
            setEditingTransition(undefined);
            setShowTransitionModal(true);
          }}
          onAddState={() => setShowStateModal(true)}
          onDeleteState={handleDeleteState}
          onDeleteTransition={handleDeleteTransition}
          onEditState={handleEditState}
          onEditTransition={handleEditTransition}
        />
        
        <div className="flex-1 flex flex-col overflow-hidden">
          <ResizablePanelGroup direction="vertical">
            <ResizablePanel defaultSize={70}>
              <ScrollArea className="h-full">
                <div className="p-4">
                  <div className="mb-4 flex justify-between">
                    <div>
                      {selectedModel && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={handleAddModelToList}
                          className="mr-2"
                        >
                          Add to Generation List
                        </Button>
                      )}
                      
                      <span className="text-sm">
                        Models in Generation List: {edamList.length}
                      </span>
                    </div>
                    
                    <div>
                      <label className="mr-2 text-sm">Target Language:</label>
                      <Select value={testLang} onValueChange={setTestLang}>
                        <SelectTrigger className="w-[150px]">
                          <SelectValue placeholder="Select language" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="solidity">Solidity</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                  
                  {edamList.length > 0 && (
                    <div className="mb-4 border p-4 rounded-md">
                      <h3 className="font-semibold mb-2">Generation List</h3>
                      <div className="space-y-2">
                        {edamList.map((model, index) => (
                          <div key={index} className="flex justify-between items-center border-b pb-2">
                            <span>{model.name}</span>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleRemoveModelFromList(index)}
                            >
                              Remove
                            </Button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                    <TabsList className="grid grid-cols-3 mb-4">
                      <TabsTrigger value="force-directed">Force-Directed Graph</TabsTrigger>
                      <TabsTrigger value="graphviz">GraphViz</TabsTrigger>
                      <TabsTrigger value="text-editor">Manual Editor</TabsTrigger>
                    </TabsList>
                    
                    <TabsContent value="force-directed" className="mt-0">
                      <EDAMGraph 
                        model={selectedModel} 
                        onNodeClick={handleNodeClick} 
                        onEdgeClick={handleEdgeClick}
                        svgRef={handleSvgRef}
                      />
                    </TabsContent>
                    
                    <TabsContent value="graphviz" className="mt-0">
                      <EDAMGraphviz 
                        model={selectedModel}
                        onNodeClick={handleGraphvizNodeClick}
                        onEdgeClick={handleGraphvizEdgeClick}
                      />
                    </TabsContent>
                    
                    <TabsContent value="text-editor" className="mt-0 h-[600px]">
                      <EDAMTextEditor 
                        value={textEditorValue}
                        onChange={setTextEditorValue}
                        onViewEDAM={handleTextEditorViewEDAM}
                      />
                    </TabsContent>
                  </Tabs>
                  
                  <CodeGenerationResults
                    codeError={codeError}
                    generatedCode={responseContents}
                    generatedImages={responseImages}
                    emptyRoleCheck={emptyRoleCheck}
                    emptyRoleCheckIssues={emptyRoleCheckIssues}
                    testingResultData={testingResultData}
                    downloadLink={downloadLink}
                    onDownload={handleDownloadFile}
                    onRunTestFile={handleRunTestFile}
                    isGenerating={isGenerating}
                  />
                </div>
              </ScrollArea>
            </ResizablePanel>
            
            <ResizableHandle />
            
            <ResizablePanel defaultSize={30}>
              <EDAMJsonEditor 
                value={jsonValue} 
                onChange={handleJsonChange} 
              />
            </ResizablePanel>
          </ResizablePanelGroup>
        </div>
      </div>
      
      {showTransitionModal && (
        <TransitionModal 
          model={selectedModel} 
          onClose={() => {
            setShowTransitionModal(false);
            setEditingTransition(undefined);
          }}
          onSubmit={handleAddTransition}
          selectedElement={selectedElement?.type === 'node' ? selectedElement.data : null}
          editTransition={editingTransition}
        />
      )}
      
      {showStateModal && (
        <StateModal 
          model={selectedModel} 
          onClose={() => {
            setShowStateModal(false);
            setEditingStateName(undefined);
          }}
          onSubmit={handleAddState}
          editingState={editingStateName}
        />
      )}
      
      {showHelpModal && (
        <HelpModal 
          onClose={() => setShowHelpModal(false)}
        />
      )}
      
      <NewModelModal
        open={showNewModelModal}
        onOpenChange={setShowNewModelModal}
        onSubmit={handleNewModelSubmit}
      />
      
      <ConfigModal
        open={showConfigModal}
        onOpenChange={setShowConfigModal}
      />
      
      <Button
        onClick={() => setIsTraceTestOpen(true)}
        className="fixed bottom-4 right-4"
      >
        Run A Trace Test
      </Button>

      {isTraceTestOpen && (
        <TraceTestModal
          isOpen={isTraceTestOpen}
          onClose={() => setIsTraceTestOpen(false)}
          model={selectedModel}
          onTest={handleTraceTest}
          testResult={testResult}
        />
      )}
    </div>
  );
};

export default EDAMEditor;
