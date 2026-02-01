import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type {EDAMModel, EDAMTransition, ExternalCall} from "@edams-models/edam/types";
import { parseExpression, parseAssignments } from './utils/expressionHelper';

interface TransitionModalProps {
  model: EDAMModel | null;
  onClose: () => void;
  onSubmit: (transition: EDAMTransition) => void;
  selectedElement: any;
  editTransition?: EDAMTransition;
}

// Define explicit type for the transition form state
interface TransitionFormState {
  from: string;
  to: string;
  operation: string;
  guard: [string, ExternalCall[]];
  ptpVar: string;
  ptpVarList: string[];
  rho: any[];
  rhoPrime: any[];
  paramVar: Record<string, string>;  // {"name":"type"}
  assignments: Record<string, string>; // {"variable":"expression"}
}

export const TransitionModal: React.FC<TransitionModalProps> = ({
  model,
  onClose,
  onSubmit,
  selectedElement,
  editTransition
}) => {
  const [transition, setTransition] = useState<TransitionFormState>(() => {
    if (editTransition) {
      return {
        from: editTransition.from || '',
        to: editTransition.to || '',
        operation: editTransition.operation || '',
        guard: editTransition.guard || ['', []],
        ptpVar: editTransition.ptpVar || '',
        ptpVarList: editTransition.ptpVarList || [],
        rho: editTransition.rho || [],
        rhoPrime: editTransition.rhoPrime || [],
        paramVar: editTransition.paramVar ? editTransition.paramVar : {},
        assignments: editTransition.assignments || {}
      };
    }
    return {
      from: selectedElement?.id || '',
      to: '',
      operation: '',
      guard: ['', []],
      ptpVar: '',
      ptpVarList: [],
      rho: [],
      rhoPrime: [],
      paramVar: {},
      assignments: {}
    };
  });

  useEffect(() => {
    if (editTransition) {
      // Convert guard to string if it's in tuple format
      const guardStr = editTransition.guard ? 
        (Array.isArray(editTransition.guard) ? editTransition.guard[0] : String(editTransition.guard)) : 
        '';
        
      setTransition({
        from: editTransition.from || '',
        to: editTransition.to || '',
        operation: editTransition.operation || '',
        guard: editTransition.guard || ['', []],
        ptpVar: editTransition.ptpVar || '',
        ptpVarList: editTransition.ptpVarList || [],
        rho: editTransition.rho || [],
        rhoPrime: editTransition.rhoPrime || [],
        paramVar: Array.isArray(editTransition.paramVar) ? editTransition.paramVar : {},
        assignments: typeof editTransition.assignments === 'object' ? editTransition.assignments || {} : {}
      });
    }
  }, [editTransition]);

  const handleChange = (field: keyof TransitionFormState, value: any) => {
    setTransition(prev => ({ ...prev, [field]: value }));
  };

  const handleArrayChange = (field: keyof TransitionFormState, value: string) => {
    const array = value.split(',').map(item => item.trim()).filter(item => item !== '');
    setTransition(prev => ({ ...prev, [field]: array }));
  };

  const handlePiChange = (field: keyof TransitionFormState, value: string) => {
    const roleslist = value.split(",").map((item) => {
      const [user, role, mode] = item.split(":").map((e)=> e.trim());
      return {
        [user]:user,
        [role]:role,
        [mode]:mode
      }
    })
    setTransition(prev => ({ ...prev, [field]: roleslist }));
  };

  const createRecordsFromDelimiter = (delim1, delim2, value) => {
    return value.split(delim1)
      .map(item => item.trim())
      .filter(item => item !== '')
      .reduce((acc, item) => {
        const [key, val] = item.split(delim2).map(part => part.trim());
        if (key && val) {
          acc[key] = val;
        }
        return acc;
      }, {} as Record<string, string>);
    
  }
  const handleArrayVarListChange = (field: keyof TransitionFormState, value: string) => {
    
    setTransition(prev => ({ ...prev, [field]: createRecordsFromDelimiter(",", ":", value) }));
  };

  const handleAssignmentsChange = (value: string) => {
    try {
      setTransition(prev => ({ 
        ...prev, 
        assignments: createRecordsFromDelimiter("\n", ":=", value) 
      }));
    } catch (error) {
      // For invalid JSON, store the string for editing but don't update the actual state
      console.log("Invalid JSON in assignments:", error);
    }
  };

  const handleGuardChange = (guardExpression: string, externalCalls: string) => {
    const parsedCalls: ExternalCall[] = externalCalls ? 
      externalCalls.split('\n')
        .filter(call => call.trim())
        .map(call => {
          try {
            return JSON.parse(call.trim()) as ExternalCall;
          } catch (error) {
            console.error('Failed to parse external call JSON:', call, error);
            return {
              type: 'externalCall',
              modelName: 'Unknown',
              operation: 'unknown',
              args: [[], []],
              enabled: true
            };
          }
        }) : [];

    setTransition(prev => ({
      ...prev,
      guard: [guardExpression, parsedCalls]
    }));
  };

  const handleSubmit = () => {
    if (!transition.from || !transition.to || !transition.operation) {
      alert('Please fill in all required fields: From, To, and Operation');
      return;
    }

    try {
      const finalTransition: EDAMTransition = {
        from: transition.from,
        to: transition.to,
        operation: transition.operation,
        guard: transition.guard,
        ptpVar: transition.ptpVar,
        ptpVarList: transition.ptpVarList,
        rho: transition.rho,
        rhoPrime: transition.rhoPrime,
        paramVar: transition.paramVar,
        assignments: transition.assignments
      };

      onSubmit(finalTransition);
    } catch (error) {
      alert(`Error processing transition: ${error}`);
    }
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{editTransition ? 'Edit' : 'Add'} Transition</DialogTitle>
          <DialogDescription>
            Define {editTransition ? 'an existing' : 'a new'} transition between states in your EDAM model.
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="basic">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="basic">Basic</TabsTrigger>
            <TabsTrigger value="participants">Caller and Parameter</TabsTrigger>
            <TabsTrigger value="advanced">Pi and Assignments</TabsTrigger>
          </TabsList>
          
          <TabsContent value="basic" className="space-y-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="from">From State *</Label>
                <Select 
                  value={transition.from} 
                  onValueChange={(value) => handleChange('from', value)}
                >
                  <SelectTrigger id="from">
                    <SelectValue placeholder="Select source state" />
                  </SelectTrigger>
                  <SelectContent>
                    {model?.states.map(state => (
                      <SelectItem key={state} value={state}>{state}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="to">To State *</Label>
                <Select 
                  value={transition.to} 
                  onValueChange={(value) => handleChange('to', value)}
                >
                  <SelectTrigger id="to">
                    <SelectValue placeholder="Select target state" />
                  </SelectTrigger>
                  <SelectContent>
                    {model?.states.map(state => (
                      <SelectItem key={state} value={state}>{state}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="operation">Operation *</Label>
              <Input
                id="operation"
                value={transition.operation}
                onChange={(e) => handleChange('operation', e.target.value)}
                placeholder="e.g., deploy, transfer, swap"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="guard">Guard Expression</Label>
              <Input
                id="guardExpression"
                value={transition.guard[0]}
                onChange={(e) => handleGuardChange(e.target.value, transition.guard[1]?.map(call => JSON.stringify(call)).join('\n') || '')}
                placeholder="e.g., token.owner == p1"
              />
              
              <Label htmlFor="externalCalls">External Calls</Label>
              <Textarea
                id="externalCalls"
                value={transition.guard[1]?.map(call => JSON.stringify(call)).join('\n') || ''}
                onChange={(e) => handleGuardChange(transition.guard[0], e.target.value)}
                placeholder="One JSON object per line, e.g., {&quot;type&quot;:&quot;externalCall&quot;,&quot;modelName&quot;:&quot;Token1&quot;,&quot;operation&quot;:&quot;transfer&quot;,&quot;args&quot;:[[],[]],&quot;enabled&quot;:true}"
                rows={3}
              />
            </div>
          </TabsContent>
          
          <TabsContent value="participants" className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="ptpVar">Caller</Label>
              <Input
                id="ptpVar"
                value={transition.ptpVar || ''}
                onChange={(e) => handleChange('ptpVar', e.target.value)}
                placeholder="e.g., p1, deployer"
              />
              <p className="text-xs text-muted-foreground mt-1">
                The caller performing this operation
              </p>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="ptpVarList">Participant Parameters</Label>
              <Input
                id="ptpVarList"
                value={transition.ptpVarList?.join(', ') || ''}
                onChange={(e) => handleArrayChange('ptpVarList', e.target.value)}
                placeholder="Comma separated, e.g., p1, p2"
              />
              <p className="text-xs text-muted-foreground mt-1">
                Other participants involved in this operation
              </p>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="paramVar">Parameter Variables</Label>
              <Input
                id="paramVar"
                value={
                  typeof transition.paramVar === 'string' 
                    ? transition.paramVar 
                    : Object.entries(transition.paramVar || {})
                        .map(([key, val]) => `${key}:${val}`)
                        .join(",")
                }
                onChange={(e) => handleArrayVarListChange('paramVar', e.target.value)}
                placeholder="Comma separated (name:type), e.g., name:string, age:number, active:boolean"
              />
              <p className="text-xs text-muted-foreground mt-1">
                Parameters passed to the operation
              </p>
            </div>
          </TabsContent>
          
          <TabsContent value="advanced" className="space-y-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="rho">Rho</Label>
                <Input
                  id="rho"
                  value={transition.rho?.map((rho)=>`${rho.user}:${rho.role}:${rho.mode}`).join(', ') || ''}
                  onChange={(e) => handlePiChange('rho', e.target.value)}
                  placeholder="Comma separated (User:Role:Top/Bottom), e.g., p:owner:Top"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Smart contracts created in this transition
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="rhoPrime">Rho' (Rho Prime)</Label>
                <Input
                  id="rhoPrime"
                  value={transition.rhoPrime?.map((rho)=>`${rho.user}:${rho.role}:${rho.mode}`).join(', ') || ''}
                  onChange={(e) => handlePiChange('rhoPrime', e.target.value)}
                  placeholder="Comma separated (User:Role:Top/Bottom), e.g., p:owner:Top"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Smart contracts accessed in this transition
                </p>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="assignments">Assignments (JSON format)</Label>
              <Textarea
                id="assignments"
                value={
                  typeof transition.assignments === 'string' 
                    ? transition.assignments 
                    : Object.entries(transition.assignments || {})
                        .map(([key, val]) => `${key}:=${val}`)
                        .join("\n")
                }
                onChange={(e) => handleAssignmentsChange(e.target.value)}
                placeholder='e.g., counter:=counter + 1 \n one assignement per line'
                rows={5}
              />
              <p className="text-xs text-muted-foreground mt-1">
                State changes applied during this transition (as a JSON object)
              </p>
            </div>
          </TabsContent>
        </Tabs>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSubmit}>{editTransition ? 'Update' : 'Add'} Transition</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
