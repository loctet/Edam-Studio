
import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Alert, AlertDescription } from '@/components/ui/alert';
import type {EDAMModel} from "@edams-models/edam/types";
import { toast } from '@/hooks/use-toast';

interface TraceTestModalProps {
  isOpen: boolean;
  onClose: () => void;
  model: EDAMModel | null;
  onTest: (trace: string) => Promise<void>;
  testResult?: string | null;
}

export const TraceTestModal: React.FC<TraceTestModalProps> = ({
  isOpen,
  onClose,
  model,
  onTest,
  testResult
}) => {
  const [trace, setTrace] = useState('');

  const handleTest = async () => {
    if(!trace) {
      toast({
        variant: "destructive",
        title: "Test Trace",
        description: 'The trace should not be empty'
      });
    }
    await onTest(trace);
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Trace Test</DialogTitle>
          <DialogDescription>
            Enter trace test commands to verify model behavior
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          <Textarea
            value={trace}
            onChange={(e) => setTrace(e.target.value)}
            className="min-h-[200px]"
            placeholder={`Enter trace test... caller>edam_name.function [participants] [data] example 
p1>Token1.deploy [] [10]
p1>Token2.deploy [] [10]
p1>AMM.deploy [] [] 
p1>Token1.mint [p1] [20]
p1>Token2.mint [p1] [20]
p1>Token1.approve [AMM] [20]
p1>Token2.approve [AMM] [10]
p1>AMM.addLiquidity [] [10, 10]
p1>AMM.swapBForA [] [10] //fails because of low allowance to token 2`}
          />
        </div>

        {testResult && (
          <Alert>
            <AlertDescription>
              <div dangerouslySetInnerHTML={{ __html: testResult }} />
            </AlertDescription>
          </Alert>
        )}

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleTest}>
            Test Trace
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
