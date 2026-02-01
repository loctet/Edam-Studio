
import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Plus, Edit, Trash2 } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useTheme } from './ThemeProvider';
import type {EDAMModel, EDAMTransition} from "@edams-models/edam/types";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { ScrollArea } from '@/components/ui/scroll-area';

interface EDAMSidebarProps {
  model: EDAMModel | null;
  selectedElement: any;
  onAddTransition: () => void;
  onAddState: () => void;
  onDeleteState?: (stateName: string) => void;
  onDeleteTransition?: (transitionIndex: number) => void;
  onEditState?: (stateName: string) => void;
  onEditTransition?: (transition: EDAMTransition, index: number) => void;
}

export const EDAMSidebar: React.FC<EDAMSidebarProps> = ({
  model,
  selectedElement,
  onAddTransition,
  onAddState,
  onDeleteState,
  onDeleteTransition,
  onEditState,
  onEditTransition
}) => {
  const { theme } = useTheme();

  const findTransitionIndex = (source: string, target: string, operation: string) => {
    if (!model) return -1;
    return model.transitions.findIndex(
      t => t.from === source && t.to === target && t.operation === operation
    );
  };

  const formatPi = (rho: any[] | undefined) => {
    if (!rho || rho.length === 0) return 'None';
    return rho.map(item => {
      if (typeof item === 'object' && item !== null) {
        const entries = Object.entries(item);
        return entries.map(([role, contract]) => `<span className="text-sm ml-2 text-blue-700 dark:text-blue-300">${contract}</span>`).join(':');
      }
      return String(item);
    }).join('<br/>_____<br/>');
  };

  // Get incoming transitions for a state
  const getIncomingTransitions = (stateName: string) => {
    if (!model) return [];
    return model.transitions.filter(t => t.to === stateName);
  };

  // Get outgoing transitions for a state
  const getOutgoingTransitions = (stateName: string) => {
    if (!model) return [];
    return model.transitions.filter(t => t.from === stateName);
  };

  return (
    <div className={`w-80 border-r overflow-auto p-4 ${theme === 'dark' ? 'bg-gray-800 border-gray-700' : 'bg-gray-50 border-gray-200'}`}>
      <Accordion type="single" collapsible defaultValue="model" className="mb-4">
        <AccordionItem value="model">
          <AccordionTrigger>Model Properties</AccordionTrigger>
          <AccordionContent>
            {model ? (
              <Card className="border-0">
                <CardContent className=" space-y-2">
                  <div> 
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Name:</span>
                    <span className="ml-2 text-purple-700 dark:text-purple-300">{model?.name}</span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Roles:</span>
                    <span className="ml-2 text-blue-700 dark:text-blue-300">{model?.roles.join(', ')}</span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">States:</span>
                    <span className="ml-2 text-indigo-700 dark:text-indigo-300">
                      {model?.states.join(', ')}
                    </span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Initial State:</span>
                    <span className="ml-2 text-green-700 dark:text-green-300">{model?.initialState}</span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Final States:</span>
                    <span className="ml-2 text-orange-700 dark:text-orange-300">
                      {model?.finalStates?.join(', ')}
                    </span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Transitions:</span>
                    <span className="ml-2 text-cyan-700 dark:text-cyan-300">{model?.transitions.length}</span>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Variables:</span>
                    <div className="mt-1 space-y-1">
                      {Object.entries(model?.variables || {}).map(([key, value]) => (
                        <div key={key} className="text-sm pl-4">
                          {key}: <span className=" text-violet-700 dark:text-violet-300">{value}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
            </Card>
            ) : (
              <p className="text-gray-500">No model selected</p>
            )}
          </AccordionContent>
        </AccordionItem>
      </Accordion>

      <div className="flex space-x-2 mb-4">
        <Button 
          onClick={onAddState} 
          disabled={!model}
          className="flex-1"
          variant="outline"
        >
          <Plus className="mr-1 h-4 w-4" />
          Add State
        </Button>
        <Button 
          onClick={onAddTransition} 
          disabled={!model}
          className="flex-1"
          variant="outline"
        >
          <Plus className="mr-1 h-4 w-4" />
          Add Transition
        </Button>
      </div>

      {selectedElement && selectedElement.type === 'node' && selectedElement.data && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>
              State Details
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div>
                <span className="font-medium">State:</span> {selectedElement.data.id}
              </div>
              <div>
                <span className="font-medium">Type:</span>{' '}
                {model?.initialState === selectedElement.data.id
                  ? 'Initial'
                  : model?.finalStates?.includes(selectedElement.data.id)
                  ? 'Final'
                  : 'Normal'}
              </div>
              
              <div className="flex space-x-2 mt-4">
                <Button 
                  size="sm" 
                  variant="outline" 
                  className="flex-1"
                  onClick={() => onEditState?.(selectedElement.data.id)}
                >
                  <Edit className="mr-1 h-3 w-3" /> Edit
                </Button>
                <Button 
                  size="sm" 
                  variant="outline" 
                  className="flex-1 text-red-500 hover:text-red-700"
                  onClick={() => onDeleteState?.(selectedElement.data.id)}
                >
                  <Trash2 className="mr-1 h-3 w-3" /> Delete
                </Button>
              </div>
              
              <Accordion type="single" collapsible className="mt-4">
                <AccordionItem value="incoming">
                  <AccordionTrigger className="text-sm font-medium">
                    Incoming Transitions ({getIncomingTransitions(selectedElement.data.id).length})
                  </AccordionTrigger>
                  <AccordionContent>
                    <ScrollArea className="h-[200px]">
                      {getIncomingTransitions(selectedElement.data.id).length > 0 ? (
                        getIncomingTransitions(selectedElement.data.id).map((transition, idx) => {
                          const transitionIndex = findTransitionIndex(
                            transition.from, 
                            transition.to, 
                            transition.operation
                          );
                          
                          return (
                            <div key={idx} className="border-b border-gray-200 dark:border-gray-700 py-2">
                              <div className="flex justify-between items-center">
                                <div>
                                  <span className="font-medium">From:</span> {transition.from}
                                  <div className="text-xs text-gray-500 mt-1">
                                    {transition.operation}
                                  </div>
                                </div>
                                <Button 
                                  size="sm" 
                                  variant="ghost"
                                  onClick={() => onEditTransition?.(transition, transitionIndex)}
                                >
                                  <Edit className="h-3 w-3" />
                                </Button>
                              </div>
                            </div>
                          );
                        })
                      ) : (
                        <div className="text-sm text-gray-500">No incoming transitions</div>
                      )}
                    </ScrollArea>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="outgoing">
                  <AccordionTrigger className="text-sm font-medium">
                    Outgoing Transitions ({getOutgoingTransitions(selectedElement.data.id).length})
                  </AccordionTrigger>
                  <AccordionContent>
                    <ScrollArea className="h-[200px]">
                      {getOutgoingTransitions(selectedElement.data.id).length > 0 ? (
                        getOutgoingTransitions(selectedElement.data.id).map((transition, idx) => {
                          const transitionIndex = findTransitionIndex(
                            transition.from, 
                            transition.to, 
                            transition.operation
                          );
                          
                          return (
                            <div key={idx} className="border-b border-gray-200 dark:border-gray-700 py-2">
                              <div className="flex justify-between items-center">
                                <div>
                                  <span className="font-medium">To:</span> {transition.to}
                                  <div className="text-xs text-gray-500 mt-1">
                                    {transition.operation}
                                  </div>
                                </div>
                                <Button 
                                  size="sm" 
                                  variant="ghost"
                                  onClick={() => onEditTransition?.(transition, transitionIndex)}
                                >
                                  <Edit className="h-3 w-3" />
                                </Button>
                              </div>
                            </div>
                          );
                        })
                      ) : (
                        <div className="text-sm text-gray-500">No outgoing transitions</div>
                      )}
                    </ScrollArea>
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </div>
          </CardContent>
        </Card>
      )}
      
      {selectedElement && selectedElement.type === 'edge' && selectedElement.data && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>
              Transition Details
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div>
                <span className="font-medium">From:</span> {selectedElement.data.source}
              </div>
              <div>
                <span className="font-medium">To:</span> {selectedElement.data.target}
              </div>
              
              {model?.transitions
                .filter(t => t.from === selectedElement.data.source && t.to === selectedElement.data.target)
                .map((transition, idx) => {
                  const transitionIndex = findTransitionIndex(
                    transition.from, 
                    transition.to, 
                    transition.operation
                  );
                  
                  return (
                    <div key={idx} className="mt-4 pt-2 border-t">
                      
                      {transition.guard && (
                        <div className="whitespace-pre-wrap">
                          <span className="font-medium">Guard:</span> <br/>{JSON.stringify(transition.guard, null, 2)}
                        </div>
                      )}

                      <hr/>
                      <div className="whitespace-pre-wrap">
                          <>
                            <span className="font-medium">Rho:</span><br/>
                            <div dangerouslySetInnerHTML={{__html: formatPi(transition.rho)}} />
                          </>
                        <hr/>
                      </div>

                      {transition.ptpVar && (
                        <div>
                          <span className="font-medium">Participant:</span> {transition.ptpVar}
                        </div>
                      )}
                      <hr/>

                      <div>
                        <span className="font-medium">Operation:</span> {transition.operation}
                      </div>
                      
                      <div className="whitespace-pre-wrap">
                            <span className="font-medium">Participants Params:</span><br/>
                            <div dangerouslySetInnerHTML={{__html: transition.ptpVarList.join(',')}} />
                        <hr/>
                      </div>
                      
                      <div className="whitespace-pre-wrap">
                          <div>
                            <span className="font-medium">Data Params:</span><br/>
                            {Object.entries(transition?.paramVar || {}).map(([key, value]) => (
                              <div key={key} className="text-sm pl-4">
                                {key}: <span className=" text-violet-700 dark:text-violet-300">{value}</span>
                              </div>
                            ))}
                          </div>
                        
                        <hr/>
                      </div>
                      
                      <div className="whitespace-pre-wrap">
                          <span className="font-medium">Rho':</span><br/>
                          <div dangerouslySetInnerHTML={{__html: formatPi(transition.rhoPrime)}} />
                        <hr/>
                      </div>
                      
                      
                      
                      <div className="whitespace-pre-wrap">
                        
                          <div>
                            <span className="font-medium">Assignments:</span><br/>
                            {Object.entries(transition?.assignments || {}).map(([key, value]) => (
                              <div key={key} className="text-sm pl-4">
                                {key}: <span className=" text-violet-700 dark:text-violet-300">{value}</span>
                              </div>
                            ))}
                          </div>
                        
                        <hr/>
                      </div>
                      
                      
                      <div className="flex space-x-2 mt-2">
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="flex-1"
                          onClick={() => onEditTransition?.(transition, transitionIndex)}
                        >
                          <Edit className="mr-1 h-3 w-3" /> Edit
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="flex-1 text-red-500 hover:text-red-700"
                          onClick={() => {
                            if (transitionIndex !== -1) {
                              onDeleteTransition?.(transitionIndex);
                            }
                          }}
                        >
                          <Trash2 className="mr-1 h-3 w-3" /> Delete
                        </Button>
                      </div>
                    </div>
                  );
                })}
            </div>
          </CardContent>
        </Card>
      )}
      
      {model && (
        <div className="mt-4">
          <h3 className="text-sm font-medium mb-2">Quick Stats</h3>
          <div className={`p-3 rounded text-xs ${theme === 'dark' ? 'bg-gray-700' : 'bg-gray-100'}`}>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <div className="font-medium">Total States</div>
                <div className="text-xl">{model.states.length}</div>
              </div>
              <div>
                <div className="font-medium">Transitions</div>
                <div className="text-xl">{model.transitions.length}</div>
              </div>
              <div>
                <div className="font-medium">Roles</div>
                <div className="text-xl">{model.roles.length}</div>
              </div>
              <div>
                <div className="font-medium">Final States</div>
                <div className="text-xl">{model.finalStates?.length || 0}</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
