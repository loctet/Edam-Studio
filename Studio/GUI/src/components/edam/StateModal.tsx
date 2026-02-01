
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import type {EDAMModel} from "@edams-models/edam/types";

interface StateModalProps {
  model: EDAMModel | null;
  onClose: () => void;
  onSubmit: (state: string, oldStateName?: string) => void;
  editingState?: string;
}

export const StateModal: React.FC<StateModalProps> = ({
  model,
  onClose,
  onSubmit,
  editingState
}) => {
  const [stateName, setStateName] = useState('');
  const [isInitial, setIsInitial] = useState(false);
  const [isFinal, setIsFinal] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    if (editingState && model) {
      setStateName(editingState);
      setIsInitial(editingState === model.initialState);
      setIsFinal(model.finalStates?.includes(editingState) || false);
    }
  }, [editingState, model]);

  const validateStateName = (name: string) => {
    if (!name.trim()) {
      return "State name cannot be empty";
    }
    
    // If we're editing and the name hasn't changed, it's valid
    if (editingState && name.trim() === editingState) {
      return null;
    }
    
    if (model?.states.includes(name.trim())) {
      return "A state with this name already exists";
    }
    
    // Check for valid characters (alphanumeric, underscore)
    if (!/^[a-zA-Z0-9_]+$/.test(name.trim())) {
      return "State name can only contain letters, numbers, and underscores";
    }
    
    return null;
  };

  const handleStateNameChange = (value: string) => {
    setStateName(value);
    setError(validateStateName(value));
  };

  const handleSubmit = () => {
    // Validate state name
    const validationError = validateStateName(stateName);
    if (validationError) {
      setError(validationError);
      return;
    }

    // Submit the state - if editingState is provided, we pass it as the old state name
    onSubmit(stateName.trim(), editingState);
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{editingState ? 'Edit State' : 'Add State'}</DialogTitle>
          <DialogDescription>
            {editingState 
              ? 'Edit the state properties. Renaming the state will update all related transitions.'
              : 'Add a new state to your EDAM model.'}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="stateName">State Name</Label>
            <Input
              id="stateName"
              value={stateName}
              onChange={(e) => handleStateNameChange(e.target.value)}
              placeholder="e.g., S0, Deployed, Active"
              className={error ? "border-red-500" : ""}
            />
            {error && (
              <p className="text-xs text-red-500 mt-1">{error}</p>
            )}
            <p className="text-xs text-muted-foreground mt-1">
              Use a descriptive name for this state
            </p>
          </div>

          <div className="flex items-center space-x-2">
            <Checkbox
              id="isInitial"
              checked={isInitial}
              onCheckedChange={(checked) => {
                setIsInitial(checked === true);
                if (checked) setIsFinal(false); // Can't be both initial and final
              }}
              disabled={editingState ? isInitial : false} // Prevent changing initial state when editing
            />
            <Label htmlFor="isInitial" className="cursor-pointer">Set as initial state</Label>
          </div>
          <p className="text-xs text-muted-foreground -mt-2">
            Each model must have exactly one initial state
          </p>

          <div className="flex items-center space-x-2">
            <Checkbox
              id="isFinal"
              checked={isFinal}
              onCheckedChange={(checked) => {
                setIsFinal(checked === true);
                if (checked) setIsInitial(false); // Can't be both initial and final
              }}
            />
            <Label htmlFor="isFinal" className="cursor-pointer">Set as final state</Label>
          </div>
          <p className="text-xs text-muted-foreground -mt-2">
            Final states represent the end of a process
          </p>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSubmit} disabled={!!error}>
            {editingState ? 'Update State' : 'Add State'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
