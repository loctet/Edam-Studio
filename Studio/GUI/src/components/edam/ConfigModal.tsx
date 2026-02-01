
import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';

// Key for local storage
const LOCAL_STORAGE_KEY = "server_config_settings";

export const initialConfig = {
  probability_new_participant: 0.01,
  probability_right_participant: 0.5,
  probability_true_for_bool: 0.5,
  min_int_value: 0,
  max_int_value: 100,
  max_gen_array_size: 10,
  min_gen_string_length: 5,
  max_gen_string_length: 10,
  z3_check_enabled: true,
  number_symbolic_traces: 200,
  number_transition_per_trace: 10,
  number_real_traces: 5,
  max_fail_try: 4,
  add_pi_to_test: false,
  add_test_of_state: true,
  add_test_of_variables: true
};

export const getConfigSettings = () => {
  const savedConfig = localStorage.getItem(LOCAL_STORAGE_KEY);
  return savedConfig ? JSON.parse(savedConfig) : initialConfig;
};

interface ConfigModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const ConfigModal: React.FC<ConfigModalProps> = ({ open, onOpenChange }) => {
  const [config, setConfig] = useState(initialConfig);

  // Load settings from local storage on component mount
  useEffect(() => {
    const savedConfig = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (savedConfig) {
      setConfig(JSON.parse(savedConfig));
    } else {
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(config));
    }
  }, []);

  const handleInputChange = (key: string, value: any) => {
    setConfig({
      ...config,
      [key]: value,
    });
  };

  const resetSettings = () => {
    setConfig(initialConfig);
    localStorage.removeItem(LOCAL_STORAGE_KEY);
  };

  const saveSettings = () => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(config));
    alert("Settings saved to local storage.");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-auto">
        <DialogHeader>
          <DialogTitle>Configuration Settings</DialogTitle>
          <DialogDescription>
            Configure parameters for EDAM code generation
          </DialogDescription>
        </DialogHeader>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="probability_new_participant">Probability of New Participant</Label>
            <Input
              id="probability_new_participant"
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={config.probability_new_participant}
              onChange={(e) => handleInputChange("probability_new_participant", parseFloat(e.target.value))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="probability_right_participant">Probability of Right Participant</Label>
            <Input
              id="probability_right_participant"
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={config.probability_right_participant}
              onChange={(e) => handleInputChange("probability_right_participant", parseFloat(e.target.value))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="probability_true_for_bool">Probability of True for Boolean</Label>
            <Input
              id="probability_true_for_bool"
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={config.probability_true_for_bool}
              onChange={(e) => handleInputChange("probability_true_for_bool", parseFloat(e.target.value))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="min_int_value">Min Integer Value</Label>
            <Input
              id="min_int_value"
              type="number"
              value={config.min_int_value}
              onChange={(e) => handleInputChange("min_int_value", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="max_int_value">Max Integer Value</Label>
            <Input
              id="max_int_value"
              type="number"
              value={config.max_int_value}
              onChange={(e) => handleInputChange("max_int_value", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="max_gen_array_size">Max Generated Array Size</Label>
            <Input
              id="max_gen_array_size"
              type="number"
              value={config.max_gen_array_size}
              onChange={(e) => handleInputChange("max_gen_array_size", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="min_gen_string_length">Min Generated String Length</Label>
            <Input
              id="min_gen_string_length"
              type="number"
              value={config.min_gen_string_length}
              onChange={(e) => handleInputChange("min_gen_string_length", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="max_gen_string_length">Max Generated String Length</Label>
            <Input
              id="max_gen_string_length"
              type="number"
              value={config.max_gen_string_length}
              onChange={(e) => handleInputChange("max_gen_string_length", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="max_fail_try">Max Fail Try</Label>
            <Input
              id="max_fail_try"
              type="number"
              value={config.max_fail_try}
              onChange={(e) => handleInputChange("max_fail_try", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="number_symbolic_traces">Number of Symbolic Traces</Label>
            <Input
              id="number_symbolic_traces"
              type="number"
              value={config.number_symbolic_traces}
              onChange={(e) => handleInputChange("number_symbolic_traces", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="number_real_traces">Number of Real Traces</Label>
            <Input
              id="number_real_traces"
              type="number"
              value={config.number_real_traces}
              onChange={(e) => handleInputChange("number_real_traces", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="number_transition_per_trace">Number of Transitions Per Trace</Label>
            <Input
              id="number_transition_per_trace"
              type="number"
              value={config.number_transition_per_trace}
              onChange={(e) => handleInputChange("number_transition_per_trace", parseInt(e.target.value, 10))}
            />
          </div>
          
          <div className="flex items-center space-x-2">
            <Checkbox 
              id="z3_check_enabled"
              checked={config.z3_check_enabled}
              onCheckedChange={(checked) => handleInputChange("z3_check_enabled", !!checked)}
            />
            <Label htmlFor="z3_check_enabled">Z3 Check Enabled</Label>
          </div>
          
          <div className="flex items-center space-x-2">
            <Checkbox 
              id="add_pi_to_test"
              checked={config.add_pi_to_test}
              onCheckedChange={(checked) => handleInputChange("add_pi_to_test", !!checked)}
            />
            <Label htmlFor="add_pi_to_test">Add PI to Test</Label>
          </div>
          
          <div className="flex items-center space-x-2">
            <Checkbox 
              id="add_test_of_state"
              checked={config.add_test_of_state}
              onCheckedChange={(checked) => handleInputChange("add_test_of_state", !!checked)}
            />
            <Label htmlFor="add_test_of_state">Add Test of State</Label>
          </div>
          
          <div className="flex items-center space-x-2">
            <Checkbox 
              id="add_test_of_variables"
              checked={config.add_test_of_variables}
              onCheckedChange={(checked) => handleInputChange("add_test_of_variables", !!checked)}
            />
            <Label htmlFor="add_test_of_variables">Add Test of Variables</Label>
          </div>
        </div>
        
        <Alert className="my-4">
          <AlertDescription>
            The total number of test will be <strong>{config.number_real_traces * config.number_symbolic_traces}</strong>. 
            Each with maximum <strong>{config.number_transition_per_trace}</strong> transitions.
          </AlertDescription>
        </Alert>
        
        <Alert variant="destructive" className="my-4">
          <AlertDescription>
            You have to <strong>Save Settings</strong> after any changes to apply them.
          </AlertDescription>
        </Alert>
        
        <DialogFooter>
          <Button variant="outline" onClick={resetSettings}>
            Reset to Defaults
          </Button>
          <Button onClick={saveSettings}>
            Save Settings
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
