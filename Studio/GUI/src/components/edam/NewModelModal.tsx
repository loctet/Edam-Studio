
import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Pencil } from 'lucide-react';
import type {EDAMModel} from "@edams-models/edam/types";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface ParamEntry {
  type: string;
  name: string;
}

interface NewModelModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (model: EDAMModel) => void;
}

export const NewModelModal: React.FC<NewModelModalProps> = ({ open, onOpenChange, onSubmit }) => {
  const [name, setName] = useState('');
  const [roles, setRoles] = useState(['R1', 'R2']);
  const [states, setStates] = useState(['S0', 'S1', 'S2']);
  const [initialState, setInitialState] = useState('S0');
  const [variables, setVariables] = useState<ParamEntry[]>([]);
  const [testLang, setTestLang] = useState('solidity');
  const [paramModalOpen, setParamModalOpen] = useState(false);
  const [newParamType, setNewParamType] = useState('int');
  const [newParamName, setNewParamName] = useState('');

  useEffect(() => {
    if (states.length > 0 && !states.includes(initialState)) {
      setInitialState(states[0]);
    }
  }, [states, initialState]);

  const handleSubmit = () => {
    if (!name) {
      alert('Please enter a name for the EDAM.');
      return;
    }

    const model: EDAMModel = {
      name,
      roles,
      states,
      initialState,
      transitions: [],
      variables: variables.reduce((acc, item) => {
        acc[item.name] = item.type;
        return acc;
      }, {} as Record<string, any>),
      participantsList: {}  // Added missing required property
    };
    
    onSubmit(model);
    onOpenChange(false);
    
    // Reset form
    setName('');
    setRoles(['R1', 'R2']);
    setStates(['S0', 'S1', 'S2']);
    setInitialState('S0');
    setVariables([]);
  };

  const addParam = () => {
    if (!newParamName) {
      alert('Please enter a parameter name');
      return;
    }
    
    setVariables([...variables, { type: newParamType, name: newParamName }]);
    setNewParamName('');
  };

  const removeParam = (index: number) => {
    const updatedParams = variables.filter((_, i) => i !== index);
    setVariables(updatedParams);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[525px]">
        <DialogHeader>
          <DialogTitle>Add New EDAM Model</DialogTitle>
        </DialogHeader>
        
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="name">EDAM Name</Label>
            <Input 
              id="name" 
              placeholder="Name" 
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          </div>
          
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="roles">Roles</Label>
            <Input
              id="roles"
              placeholder="List of Roles (comma-separated)"
              value={roles.join(',')}
              onChange={(e) => setRoles(e.target.value.split(',').map(role => role.trim()).filter(Boolean))}
            />
          </div>
          
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="testLang">Test Language</Label>
            <Select value={testLang} onValueChange={setTestLang}>
              <SelectTrigger>
                <SelectValue placeholder="Select language" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="solidity">Solidity</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="states">States</Label>
            <Input
              id="states"
              placeholder="List of States (comma-separated)"
              value={states.join(',')}
              onChange={(e) => setStates(e.target.value.split(',').map(state => state.trim()).filter(Boolean))}
            />
          </div>
          
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="initialState">Initial State</Label>
            <Select value={initialState} onValueChange={setInitialState}>
              <SelectTrigger>
                <SelectValue placeholder="Select initial state" />
              </SelectTrigger>
              <SelectContent>
                {states.map((state) => (
                  <SelectItem key={state} value={state}>{state}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          
          <div className="grid grid-cols-1 items-center gap-2">
            <Label htmlFor="variables">C Variables</Label>
            <div className="flex">
              <Input
                id="variables"
                readOnly
                value={variables.map(v => `(${v.type}, ${v.name})`).join(', ')}
                placeholder="No variables defined"
              />
              <Button 
                variant="outline" 
                size="icon"
                className="ml-2"
                onClick={() => setParamModalOpen(true)}
              >
                <Pencil className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>

        {paramModalOpen && (
          <Dialog open={paramModalOpen} onOpenChange={setParamModalOpen}>
            <DialogContent className="sm:max-w-[425px]">
              <DialogHeader>
                <DialogTitle>Edit Variables</DialogTitle>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                {variables.map((param, index) => (
                  <div key={index} className="flex items-center justify-between">
                    <span>{`(${param.type}, ${param.name})`}</span>
                    <Button variant="destructive" size="sm" onClick={() => removeParam(index)}>Remove</Button>
                  </div>
                ))}
                
                <div className="flex space-x-2">
                  <Select value={newParamType} onValueChange={setNewParamType}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select type" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="int">int</SelectItem>
                      <SelectItem value="uint">uint</SelectItem>
                      <SelectItem value="bool">bool</SelectItem>
                      <SelectItem value="address">address</SelectItem>
                      <SelectItem value="contract">contract</SelectItem>
                      <SelectItem value="string">string</SelectItem>
                      <SelectItem value="list_int">list_int</SelectItem>
                      <SelectItem value="list_bool">list_bool</SelectItem>
                      <SelectItem value="list_string">list_string</SelectItem>
                      <SelectItem value="map_address_bool">map_address_bool</SelectItem>
                      <SelectItem value="map_address_int">map_address_int</SelectItem>
                      <SelectItem value="map_string_int">map_string_int</SelectItem>
                      <SelectItem value="map_string_string">map_string_string</SelectItem>
                      <SelectItem value="map_address_string">map_address_string</SelectItem>
                      <SelectItem value="map_map_address_string_bool">map_map_address_string_bool</SelectItem>
                      <SelectItem value="map_map_address_string_int">map_map_address_string_int</SelectItem>
                      <SelectItem value="map_map_address_address_int">map_map_address_address_int</SelectItem>
                    </SelectContent>
                  </Select>
                  
                  <Input 
                    placeholder="Name" 
                    value={newParamName} 
                    onChange={(e) => setNewParamName(e.target.value)}
                  />
                  
                  <Button onClick={addParam}>Add</Button>
                </div>
              </div>
              
              <DialogFooter>
                <Button variant="outline" onClick={() => setParamModalOpen(false)}>Close</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        )}
        
        <DialogFooter>
          <Button onClick={handleSubmit}>Create EDAM</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
